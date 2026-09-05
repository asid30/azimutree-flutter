import 'package:azimutree/data/database/azimutree_db.dart';
import 'package:azimutree/data/database/cluster_dao.dart';
import 'package:azimutree/data/database/plot_dao.dart';
import 'package:azimutree/data/database/titik_ikat_dao.dart';
import 'package:azimutree/data/database/tree_dao.dart';
import 'package:azimutree/data/models/cluster_model.dart';
import 'package:azimutree/data/models/plot_model.dart';
import 'package:azimutree/data/models/titik_ikat_model.dart';
import 'package:azimutree/data/models/tree_model.dart';
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

class CloudOwnedCluster {
  const CloudOwnedCluster({
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
    final normalizedName = name.trim();
    final existingLocations =
        await _locations.where('ownerId', isEqualTo: ownerId).get();
    final duplicate = existingLocations.docs.any(
      (document) =>
          (document.data()['name'] as String?)?.trim().toLowerCase() ==
          normalizedName.toLowerCase(),
    );
    if (duplicate) {
      throw StateError('Nama lokasi penelitian sudah digunakan.');
    }
    final now = FieldValue.serverTimestamp();
    await _locations.add({
      'ownerId': ownerId,
      'ownerName': ownerName.trim(),
      'name': normalizedName,
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

  Stream<List<CloudOwnedCluster>> watchClusters(String locationId) {
    return _locations.doc(locationId).collection('clusters').snapshots().map((
      snapshot,
    ) {
      return snapshot.docs.map((document) {
          final data = document.data();
          return CloudOwnedCluster(
            id: document.id,
            code: (data['code'] as String?)?.trim() ?? '',
            surveyorName: (data['surveyorName'] as String?)?.trim() ?? '-',
            surveyDate: (data['surveyDate'] as Timestamp?)?.toDate(),
          );
        }).toList()
        ..sort((a, b) => a.code.compareTo(b.code));
    });
  }

  Future<void> deleteCluster({
    required String locationId,
    required CloudOwnedCluster cluster,
  }) async {
    final locationReference = _locations.doc(locationId);
    final clusterReference = locationReference
        .collection('clusters')
        .doc(cluster.id);
    await _firestore.runTransaction((transaction) async {
      final location = await transaction.get(locationReference);
      if (!location.exists) {
        throw StateError('Lokasi penelitian tidak ditemukan');
      }
      final codes =
          (location.data()?['clusterCodes'] as List?)
              ?.whereType<String>()
              .where((code) => code != cluster.code)
              .toList() ??
          <String>[];
      transaction.delete(clusterReference);
      transaction.update(locationReference, {
        'clusterCodes': codes,
        'clusterCount': codes.length,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<bool> localCodeExists(String code) async {
    final normalized = code.trim().toLowerCase();
    final clusters = await ClusterDao.getAllClusters();
    return clusters.any(
      (cluster) => cluster.kodeCluster.trim().toLowerCase() == normalized,
    );
  }

  Future<void> downloadCluster({
    required String locationId,
    required String clusterId,
    required String localCode,
  }) async {
    final document =
        await _locations
            .doc(locationId)
            .collection('clusters')
            .doc(clusterId)
            .get();
    final data = document.data();
    if (!document.exists || data == null) {
      throw StateError('Snapshot klaster tidak ditemukan');
    }
    if (await localCodeExists(localCode)) {
      throw StateError('Kode klaster lokal sudah digunakan');
    }
    final anchor = data['anchor'];
    if (anchor is! Map) {
      throw const FormatException('Data Titik Ikat tidak valid');
    }
    final plotRows = data['plots'];
    if (plotRows is! List) throw const FormatException('Data plot tidak valid');

    final database = await AzimutreeDB.instance.database;
    await database.transaction((transaction) async {
      final clusterId = await transaction.insert(
        ClusterDao.tableName,
        ClusterModel(
          kodeCluster: localCode.trim(),
          namaPengukur: data['surveyorName'] as String?,
          tanggalPengukuran: (data['surveyDate'] as Timestamp?)?.toDate(),
        ).toMap(),
      );
      final anchorModel = TitikIkatModel(
        idCluster: clusterId,
        nama: 'Titik Ikat ${localCode.trim()}',
        latitude: (anchor['latitude'] as num?)?.toDouble(),
        longitude: (anchor['longitude'] as num?)?.toDouble(),
        altitude: (anchor['altitude'] as num?)?.toDouble(),
        keterangan: anchor['description'] as String?,
        urlFoto: anchor['imageUrl'] as String?,
      );
      anchorModel.validate();
      await transaction.insert(TitikIkatDao.tableName, anchorModel.toMap());

      for (final rawPlot in plotRows.whereType<Map>()) {
        final plot = PlotModel(
          idCluster: clusterId,
          kodePlot: (rawPlot['code'] as num).toInt(),
          latitude: (rawPlot['latitude'] as num).toDouble(),
          longitude: (rawPlot['longitude'] as num).toDouble(),
          altitude: (rawPlot['altitude'] as num?)?.toDouble(),
        );
        final plotId = await transaction.insert(
          PlotDao.tableName,
          plot.toMap(),
        );
        final rawTrees = rawPlot['trees'];
        if (rawTrees is! List) continue;
        for (final rawTree in rawTrees.whereType<Map>()) {
          await transaction.insert(
            TreeDao.tableName,
            TreeModel(
              plotId: plotId,
              kodePohon: (rawTree['code'] as num).toInt(),
              namaPohon: rawTree['name'] as String?,
              namaIlmiah: rawTree['scientificName'] as String?,
              azimut: (rawTree['azimuth'] as num?)?.toDouble(),
              jarakPusatM: (rawTree['distanceM'] as num?)?.toDouble(),
              latitude: (rawTree['latitude'] as num?)?.toDouble(),
              longitude: (rawTree['longitude'] as num?)?.toDouble(),
              altitude: (rawTree['altitude'] as num?)?.toDouble(),
              keterangan: rawTree['description'] as String?,
              urlFoto: rawTree['imageUrl'] as String?,
              inspected: rawTree['inspected'] as bool?,
            ).toMap(),
          );
        }
      }
    });
  }

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
