import 'package:azimutree/data/database/cluster_dao.dart';
import 'package:azimutree/data/database/plot_dao.dart';
import 'package:azimutree/data/database/titik_ikat_dao.dart';
import 'package:azimutree/data/database/tree_dao.dart';
import 'package:azimutree/data/models/cluster_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CloudOwnedResearchLocation {
  const CloudOwnedResearchLocation({
    required this.id,
    required this.name,
    required this.researchDate,
    required this.isPublic,
    required this.clusterCount,
    required this.clusterCodes,
  });

  final String id;
  final String name;
  final DateTime? researchDate;
  final bool isPublic;
  final int clusterCount;
  final List<String> clusterCodes;
}

class LocalClusterSnapshot {
  const LocalClusterSnapshot({
    required this.cluster,
    required this.data,
    required this.plotCount,
    required this.treeCount,
  });

  final ClusterModel cluster;
  final Map<String, dynamic> data;
  final int plotCount;
  final int treeCount;
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

  Future<List<LocalClusterSnapshot>> loadLocalSnapshots() async {
    final clusters = await ClusterDao.getAllClusters();
    final anchors = await TitikIkatDao.getAllTitikIkat();
    final plots = await PlotDao.getAllPlots();
    final trees = await TreeDao.getAllTrees();

    return clusters.map((cluster) {
        final clusterPlots =
            plots.where((plot) => plot.idCluster == cluster.id).toList()
              ..sort((a, b) => a.kodePlot.compareTo(b.kodePlot));
        final anchor =
            anchors.where((item) => item.idCluster == cluster.id).firstOrNull;
        var treeCount = 0;
        final plotData =
            clusterPlots.map((plot) {
              final plotTrees =
                  trees.where((tree) => tree.plotId == plot.id).toList()
                    ..sort((a, b) => a.kodePohon.compareTo(b.kodePohon));
              treeCount += plotTrees.length;
              return <String, dynamic>{
                'code': plot.kodePlot,
                'latitude': plot.latitude,
                'longitude': plot.longitude,
                'altitude': plot.altitude,
                'trees':
                    plotTrees
                        .map(
                          (tree) => <String, dynamic>{
                            'code': tree.kodePohon,
                            'name': tree.namaPohon,
                            'scientificName': tree.namaIlmiah,
                            'azimuth': tree.azimut,
                            'distanceM': tree.jarakPusatM,
                            'latitude': tree.latitude,
                            'longitude': tree.longitude,
                            'altitude': tree.altitude,
                            'description': tree.keterangan,
                            'imageUrl': tree.urlFoto,
                            'inspected': tree.inspected,
                          },
                        )
                        .toList(),
              };
            }).toList();
        return LocalClusterSnapshot(
          cluster: cluster,
          plotCount: clusterPlots.length,
          treeCount: treeCount,
          data: {
            'code': cluster.kodeCluster,
            'surveyorName': cluster.namaPengukur,
            'surveyDate':
                cluster.tanggalPengukuran == null
                    ? null
                    : Timestamp.fromDate(cluster.tanggalPengukuran!),
            'anchor':
                anchor == null
                    ? null
                    : <String, dynamic>{
                      'latitude': anchor.latitude,
                      'longitude': anchor.longitude,
                      'altitude': anchor.altitude,
                      'description': anchor.keterangan,
                      'imageUrl': anchor.urlFoto,
                    },
            'plots': plotData,
          },
        );
      }).toList()
      ..sort((a, b) => a.cluster.kodeCluster.compareTo(b.cluster.kodeCluster));
  }

  Future<void> uploadSnapshots({
    required String locationId,
    required List<LocalClusterSnapshot> snapshots,
  }) async {
    if (snapshots.isEmpty) return;
    final locationReference = _locations.doc(locationId);
    await _firestore.runTransaction((transaction) async {
      final location = await transaction.get(locationReference);
      if (!location.exists) {
        throw StateError('Lokasi penelitian tidak ditemukan');
      }
      final currentCodes =
          (location.data()?['clusterCodes'] as List?)
              ?.whereType<String>()
              .toSet() ??
          <String>{};
      for (final snapshot in snapshots) {
        final code = snapshot.cluster.kodeCluster.trim();
        final documentId = Uri.encodeComponent(code);
        transaction.set(
          locationReference.collection('clusters').doc(documentId),
          {...snapshot.data, 'uploadedAt': FieldValue.serverTimestamp()},
        );
        currentCodes.add(code);
      }
      final sortedCodes = currentCodes.toList()..sort();
      transaction.update(locationReference, {
        'clusterCodes': sortedCodes,
        'clusterCount': sortedCodes.length,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
