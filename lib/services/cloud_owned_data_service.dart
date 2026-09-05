import 'package:cloud_firestore/cloud_firestore.dart';

class CloudOwnedResearchLocation {
  const CloudOwnedResearchLocation({
    required this.id,
    required this.name,
    required this.researchDate,
    required this.isPublic,
    required this.clusterCount,
  });

  final String id;
  final String name;
  final DateTime? researchDate;
  final bool isPublic;
  final int clusterCount;
}

class CloudOwnedDataService {
  CloudOwnedDataService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _locations =>
      _firestore.collection('researchLocations');

  Stream<List<CloudOwnedResearchLocation>> watchLocations(String ownerId) {
    return _locations.where('ownerId', isEqualTo: ownerId).snapshots().map((
      snapshot,
    ) {
      final locations =
          snapshot.docs.map((document) {
              final data = document.data();
              return CloudOwnedResearchLocation(
                id: document.id,
                name: (data['name'] as String?)?.trim() ?? '',
                researchDate: (data['researchDate'] as Timestamp?)?.toDate(),
                isPublic: data['isPublic'] == true,
                clusterCount: (data['clusterCount'] as num?)?.toInt() ?? 0,
              );
            }).toList()
            ..sort((a, b) {
              final aDate = a.researchDate;
              final bDate = b.researchDate;
              if (aDate == null && bDate == null) {
                return a.name.compareTo(b.name);
              }
              if (aDate == null) return 1;
              if (bDate == null) return -1;
              return bDate.compareTo(aDate);
            });
      return locations;
    });
  }

  Future<void> createLocation({
    required String ownerId,
    required String ownerName,
    required String name,
    required DateTime researchDate,
    bool isPublic = true,
  }) async {
    final now = FieldValue.serverTimestamp();
    await _locations.add({
      'ownerId': ownerId,
      'ownerName': ownerName.trim(),
      'name': name.trim(),
      'researchDate': Timestamp.fromDate(researchDate),
      'isPublic': isPublic,
      'clusterCount': 0,
      'clusterCodes': <String>[],
      'createdAt': now,
      'updatedAt': now,
    });
  }

  Future<void> updateVisibility({
    required String locationId,
    required bool isPublic,
  }) => _locations.doc(locationId).update({
    'isPublic': isPublic,
    'updatedAt': FieldValue.serverTimestamp(),
  });

  Future<void> deleteEmptyLocation(String locationId) =>
      _locations.doc(locationId).delete();
}
