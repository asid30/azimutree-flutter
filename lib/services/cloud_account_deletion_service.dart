import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

/// Deletes all Firestore data owned by one cloud account.
///
/// Authentication is deliberately deleted by [CloudAuthService] only after
/// this operation succeeds, so an interrupted deletion can be retried by the
/// same signed-in user.
class CloudAccountDeletionService {
  CloudAccountDeletionService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _locations =>
      _firestore.collection('researchLocations');

  CollectionReference<Map<String, dynamic>> get _locationNames =>
      _firestore.collection('researchLocationNames');

  DocumentReference<Map<String, dynamic>> _profile(String uid) =>
      _firestore.collection('users').doc(uid);

  Future<void> deleteAllOwnedData(String uid) async {
    final locations = await _locations
        .where('ownerId', isEqualTo: uid)
        .get()
        .timeout(const Duration(seconds: 20));

    for (final location in locations.docs) {
      await _deleteLocation(uid: uid, location: location);
    }

    await _profile(uid).delete().timeout(const Duration(seconds: 15));
  }

  Future<void> _deleteLocation({
    required String uid,
    required QueryDocumentSnapshot<Map<String, dynamic>> location,
  }) async {
    final locationReference = location.reference;
    final clusters = await locationReference
        .collection('clusters')
        .get()
        .timeout(const Duration(seconds: 20));

    // Stay below Firestore's maximum number of writes per batch.
    for (var start = 0; start < clusters.docs.length; start += 400) {
      final end = (start + 400).clamp(0, clusters.docs.length);
      final batch = _firestore.batch();
      for (final cluster in clusters.docs.sublist(start, end)) {
        batch.delete(cluster.reference);
      }
      await batch.commit().timeout(const Duration(seconds: 20));
    }

    // Location deletion is allowed by the security rules only when its
    // denormalized cluster count has reached zero.
    await locationReference
        .update({
          'clusterCount': 0,
          'clusterCodes': <String>[],
          'updatedAt': FieldValue.serverTimestamp(),
        })
        .timeout(const Duration(seconds: 15));

    await _firestore
        .runTransaction((transaction) async {
          final current = await transaction.get(locationReference);
          if (!current.exists) return;
          final data = current.data();
          if (data?['ownerId'] != uid) {
            throw StateError('Lokasi penelitian bukan milik akun ini.');
          }

          final nameKey = _resolveNameKey(data);
          DocumentReference<Map<String, dynamic>>? nameReference;
          DocumentSnapshot<Map<String, dynamic>>? nameReservation;
          if (nameKey != null) {
            nameReference = _locationNames.doc(nameKey);
            nameReservation = await transaction.get(nameReference);
          }

          transaction.delete(locationReference);
          if (nameReference != null &&
              nameReservation?.data()?['locationId'] == locationReference.id &&
              nameReservation?.data()?['ownerId'] == uid) {
            transaction.delete(nameReference);
          }
        })
        .timeout(const Duration(seconds: 20));
  }

  String? _resolveNameKey(Map<String, dynamic>? data) {
    final storedKey = (data?['nameKey'] as String?)?.trim();
    if (storedKey?.isNotEmpty == true) return storedKey;
    final name = (data?['name'] as String?)?.trim();
    if (name == null || name.isEmpty) return null;
    final normalized = name.replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
    return base64Url.encode(utf8.encode(normalized)).replaceAll('=', '');
  }
}
