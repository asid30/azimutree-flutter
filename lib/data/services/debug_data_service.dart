import 'dart:math';

import 'package:azimutree/data/database/azimutree_db.dart';
import 'package:azimutree/data/database/cluster_dao.dart';
import 'package:azimutree/data/database/plot_dao.dart';
import 'package:azimutree/data/database/tree_dao.dart';
import 'package:azimutree/data/models/cluster_model.dart';
import 'package:azimutree/data/models/plot_model.dart';
import 'package:azimutree/data/models/tree_model.dart';
import 'package:azimutree/data/notifiers/cluster_notifier.dart';
import 'package:azimutree/data/notifiers/plot_notifier.dart';
import 'package:azimutree/data/notifiers/tree_notifier.dart';

/// Utility untuk kebutuhan pengembangan: seed data random dan menghapus semua
/// data. Simpan semua logic di satu tempat supaya UI tetap ringkas.
class DebugDataService {
  final ClusterNotifier clusterNotifier;
  final PlotNotifier plotNotifier;
  final TreeNotifier treeNotifier;

  final Random _rng = Random();

  DebugDataService({
    required this.clusterNotifier,
    required this.plotNotifier,
    required this.treeNotifier,
  });

  /// Generate beberapa klaster, plot, dan pohon secara acak.
  Future<void> seedRandomData({
    int clusterCount = 3,
    int minPlotPerCluster = 4,
    int maxPlotPerCluster = 4,
    int minTreePerPlot = 3,
    int maxTreePerPlot = 6,
  }) async {
    final now = DateTime.now();

    for (int i = 0; i < clusterCount; i++) {
      final cluster = ClusterModel(
        kodeCluster: _generateClusterCode(i),
        namaPengukur: "Tester ${i + 1}",
        tanggalPengukuran: now.subtract(Duration(days: _rng.nextInt(60))),
      );

      final clusterId = await ClusterDao.insertCluster(cluster);
      final plotCount =
          minPlotPerCluster +
          _rng.nextInt((maxPlotPerCluster - minPlotPerCluster) + 1);

      for (int j = 0; j < plotCount; j++) {
        final plot = PlotModel(
          idCluster: clusterId,
          kodePlot: j + 1,
          latitude: _randomCoordinate(-6.9, -6.1),
          longitude: _randomCoordinate(106.5, 107.1),
          altitude: 100 + _rng.nextInt(250).toDouble(),
        );

        final plotId = await PlotDao.insertPlot(plot);
        final treeCount =
            minTreePerPlot +
            _rng.nextInt((maxTreePerPlot - minTreePerPlot) + 1);

        for (int k = 0; k < treeCount; k++) {
          final tree = TreeModel(
            plotId: plotId,
            kodePohon: k + 1,
            namaPohon: "Pohon ${k + 1}",
            namaIlmiah: "Species ${_rng.nextInt(90) + 10}",
            azimut: _rng.nextDouble() * 360,
            jarakPusatM: (_rng.nextDouble() * 20).roundToDouble(),
            latitude: plot.latitude + _rng.nextDouble() * 0.001,
            longitude: plot.longitude + _rng.nextDouble() * 0.001,
            altitude: plot.altitude,
            keterangan: "Auto generated",
            urlFoto: _maybePhotoUrl(
              clusterIndex: i,
              plotIndex: j,
              treeIndex: k,
            ),
          );
          await TreeDao.insertTree(tree);
        }
      }
    }

    await _refreshNotifiers();
  }

  /// Bersihkan seluruh tabel supaya database kembali kosong.
  Future<void> clearAllData() async {
    final db = await AzimutreeDB.instance.database;

    await db.transaction((txn) async {
      await txn.delete(TreeDao.tableName);
      await txn.delete(PlotDao.tableName);
      await txn.delete(ClusterDao.tableName);
      await txn.delete(
        'sqlite_sequence',
        where: "name IN (?, ?, ?)",
        whereArgs: [ClusterDao.tableName, PlotDao.tableName, TreeDao.tableName],
      );
    });

    await _refreshNotifiers();
  }

  String _generateClusterCode(int index) {
    final suffix = (_rng.nextInt(900) + 100).toString();
    return "CLS-${index + 1}-$suffix";
  }

  double _randomCoordinate(double min, double max) {
    return min + _rng.nextDouble() * (max - min);
  }

  Future<void> _refreshNotifiers() async {
    await Future.wait([
      clusterNotifier.loadClusters(),
      plotNotifier.loadPlots(),
      treeNotifier.loadTrees(),
    ]);
  }

  String? _maybePhotoUrl({
    required int clusterIndex,
    required int plotIndex,
    required int treeIndex,
  }) {
    // Tidak semua pohon dikasih foto supaya bisa lihat perbedaan loading.
    final shouldAttachPhoto = _rng.nextBool();
    if (!shouldAttachPhoto) return null;

    final seed =
        "cls${clusterIndex}_plt${plotIndex}_tree${treeIndex}_${_rng.nextInt(9999)}";
    return "https://picsum.photos/seed/$seed/600/600";
  }
}
