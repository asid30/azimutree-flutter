import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CloudUserProfile {
  const CloudUserProfile({
    required this.uid,
    required this.displayName,
    required this.email,
  });

  final String uid;
  final String displayName;
  final String email;
}

class CloudUserProfileService {
  CloudUserProfileService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _profileReference(String uid) =>
      _firestore.collection('users').doc(uid);

  Stream<CloudUserProfile?> watchProfile(String uid) {
    return _profileReference(uid).snapshots().map((snapshot) {
      final data = snapshot.data();
      if (!snapshot.exists || data == null) return null;
      return CloudUserProfile(
        uid: uid,
        displayName: (data['displayName'] as String?)?.trim() ?? '',
        email: (data['email'] as String?)?.trim() ?? '',
      );
    });
  }

  Future<void> ensureProfile(User user) async {
    final reference = _profileReference(user.uid);
    final fallbackName = user.displayName?.trim();
    final initialName =
        fallbackName == null || fallbackName.length < 2
            ? 'Pengguna Azimutree'
            : fallbackName;

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(reference);
      if (snapshot.exists) {
        transaction.update(reference, {
          'email': user.email ?? '',
          'updatedAt': FieldValue.serverTimestamp(),
          'lastLoginAt': FieldValue.serverTimestamp(),
        });
        return;
      }
      transaction.set(reference, {
        'displayName': initialName,
        'email': user.email ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> updateDisplayName({
    required String uid,
    required String displayName,
  }) async {
    final normalized = displayName.trim();
    if (normalized.length < 2 || normalized.length > 80) {
      throw ArgumentError('Nama harus terdiri dari 2 sampai 80 karakter.');
    }
    await _profileReference(uid)
        .update({
          'displayName': normalized,
          'updatedAt': FieldValue.serverTimestamp(),
        })
        .timeout(const Duration(seconds: 10));
  }
}
