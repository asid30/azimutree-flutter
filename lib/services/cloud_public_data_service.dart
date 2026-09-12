import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:azimutree/services/cloud_owned_data_service.dart';

/// Public metadata for a research location shared through Firestore.
class CloudResearchLocation {
  const CloudResearchLocation({
    required this.id,
    required this.name,
    required this.ownerName,
    required this.researchDate,
    required this.clusterCount,
    required this.clusterCodes,
  });

  final String id;
  final String name;
  final String ownerName;
  final DateTime? researchDate;
  final int clusterCount;
  final List<String> clusterCodes;
}

/// Lightweight cluster metadata shown in the public cloud browser.
class CloudClusterSummary {
  const CloudClusterSummary({
    required this.id,
    required this.code,
    required this.surveyorName,
    required this.surveyDate,
  });

  final String id;
  final String code;
  final String surveyorName;
  final DateTime? surveyDate;
}

/// Retrieves public research locations and downloadable cluster data.
class CloudPublicDataService {
  CloudPublicDataService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _clusterStorage = CloudOwnedDataService(
        firestore: firestore ?? FirebaseFirestore.instance,
      );

  final FirebaseFirestore _firestore;
  final CloudOwnedDataService _clusterStorage;

  Future<bool> localCodeExists(String code) =>
      _clusterStorage.localCodeExists(code);

  Future<void> downloadCluster({
    required String locationId,
    required String clusterId,
    required String localCode,
  }) => _clusterStorage.downloadCluster(
    locationId: locationId,
    clusterId: clusterId,
    localCode: localCode,
  );

  Stream<List<CloudResearchLocation>> watchPublicLocations() {
    return _firestore
        .collection('researchLocations')
        .where('isPublic', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          final locations =
              snapshot.docs.map((document) {
                  final data = document.data();
                  return CloudResearchLocation(
                    id: document.id,
                    name: (data['name'] as String?)?.trim() ?? '',
                    ownerName:
                        (data['ownerName'] as String?)?.trim() ??
                        'Pengguna Azimutree',
                    researchDate:
                        (data['researchDate'] as Timestamp?)?.toDate(),
                    clusterCount: (data['clusterCount'] as num?)?.toInt() ?? 0,
                    clusterCodes:
                        (data['clusterCodes'] as List?)
                            ?.whereType<String>()
                            .toList() ??
                        const [],
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

  Stream<List<CloudClusterSummary>> watchPublicClusters(String locationId) {
    return _firestore
        .collection('researchLocations')
        .doc(locationId)
        .collection('clusters')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((document) {
                  final data = document.data();
                  return CloudClusterSummary(
                    id: document.id,
                    code: (data['code'] as String?)?.trim() ?? '',
                    surveyorName:
                        (data['surveyorName'] as String?)?.trim() ?? '-',
                    surveyDate: (data['surveyDate'] as Timestamp?)?.toDate(),
                  );
                }).toList()
                ..sort((a, b) => a.code.compareTo(b.code)),
        );
  }
}
