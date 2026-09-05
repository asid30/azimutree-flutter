import 'dart:io';

import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:azimutree/data/database/plot_dao.dart';
import 'package:azimutree/data/database/titik_ikat_dao.dart';
import 'package:azimutree/data/database/tree_dao.dart';
import 'package:azimutree/data/models/cluster_model.dart';
import 'package:azimutree/data/models/plot_model.dart';
import 'package:azimutree/data/models/titik_ikat_model.dart';
import 'package:azimutree/data/models/tree_model.dart';
import 'package:azimutree/data/global_variables/logger_global.dart';

class ExcelExportService {
  /// Backward-compatible wrapper for callers that export one cluster.
  static Future<String> exportClusterToExcel({
    required ClusterModel cluster,
    bool preferDownloads = true,
    String? directoryPath,
  }) => exportClustersToExcel(
    clusters: [cluster],
    preferDownloads: preferDownloads,
    directoryPath: directoryPath,
  );

  /// Export one or more clusters and all their related data to one workbook.
  static Future<String> exportClustersToExcel({
    required List<ClusterModel> clusters,
    bool preferDownloads = true,
    String? directoryPath,
  }) async {
    if (clusters.isEmpty) {
      throw ArgumentError.value(
        clusters,
        'clusters',
        'Pilih minimal satu klaster',
      );
    }

    final validClusters =
        clusters.where((cluster) => cluster.id != null).toList();
    if (validClusters.length != clusters.length) {
      throw StateError('Terdapat klaster yang belum tersimpan');
    }
    final incompleteClusters =
        validClusters
            .where(
              (cluster) =>
                  cluster.namaPengukur?.trim().isEmpty != false ||
                  cluster.tanggalPengukuran == null,
            )
            .map((cluster) => cluster.kodeCluster)
            .toList();
    if (incompleteClusters.isNotEmpty) {
      throw StateError(
        'Nama pengukur dan tanggal pengukuran wajib dilengkapi pada klaster: '
        '${incompleteClusters.join(', ')}.',
      );
    }

    logger.i(
      '[ExcelExport] Exporting ${validClusters.length} cluster(s): '
      '${validClusters.map((cluster) => cluster.kodeCluster).join(', ')}',
    );

    final clusterIds = validClusters.map((cluster) => cluster.id!).toSet();
    final allAnchors = await TitikIkatDao.getAllTitikIkat();
    final allPlots = await PlotDao.getAllPlots();
    final allTrees = await TreeDao.getAllTrees();
    final anchors =
        allAnchors
            .where((anchor) => clusterIds.contains(anchor.idCluster))
            .toList();
    final plots =
        allPlots.where((plot) => clusterIds.contains(plot.idCluster)).toList();
    final plotById = {
      for (final plot in plots)
        if (plot.id != null) plot.id!: plot,
    };
    final trees =
        allTrees.where((tree) => plotById.containsKey(tree.plotId)).toList();

    final excel = buildWorkbook(
      clusters: validClusters,
      anchors: anchors,
      plots: plots,
      trees: trees,
    );

    // Prepare file path
    final now = DateTime.now();
    final formatted = DateFormat('yyyyMMdd_HHmmss').format(now);
    final exportLabel =
        validClusters.length == 1
            ? validClusters.first.kodeCluster
            : '${validClusters.length}_klaster';
    final filename = 'azimutree_export_${exportLabel}_$formatted.xlsx';

    final dir = await _getOutputDirectory(
      preferDownloads: preferDownloads,
      directoryPath: directoryPath,
    );
    final filePath = p.join(dir.path, filename);

    final bytes = excel.encode();
    if (bytes == null) {
      throw Exception('Failed to encode Excel');
    }

    final outFile = File(filePath);
    await outFile.writeAsBytes(bytes, flush: true);

    logger.i('[ExcelExport] Saved export to $filePath');
    return filePath;
  }

  /// Builds the workbook separately from database and file-system access so
  /// its structure and relationships can be covered by unit tests.
  static Excel buildWorkbook({
    required List<ClusterModel> clusters,
    required List<TitikIkatModel> anchors,
    required List<PlotModel> plots,
    required List<TreeModel> trees,
  }) {
    final excel = Excel.createExcel();
    final clusterById = {
      for (final cluster in clusters)
        if (cluster.id != null) cluster.id!: cluster,
    };
    final plotById = {
      for (final plot in plots)
        if (plot.id != null) plot.id!: plot,
    };

    final Sheet guideSheet = excel['panduan'];
    excel.setDefaultSheet('panduan');
    guideSheet.appendValues(['PANDUAN DATA AZIMUTREE']);
    guideSheet.appendValues([]);
    guideSheet.appendValues([
      '1.',
      'Pastikan tidak ada baris atau field yang kosong pada kolom bertanda *. Kolom * wajib diisi.',
    ]);
    guideSheet.appendValues([
      '2.',
      'URL gambar yang digunakan adalah URL Google Drive.',
    ]);
    guideSheet.appendValues(['3.', 'Jumlah plot maksimal 4 per klaster.']);
    guideSheet.appendValues([
      '4.',
      'Pastikan lintang dan bujur menggunakan format angka desimal.',
    ]);
    guideSheet.appendValues([
      '5.',
      'Nama sheet tidak boleh diubah. Nama file boleh diubah.',
    ]);
    guideSheet.appendValues([
      '6.',
      'Format tanggal pengukuran yang benar adalah YYYY-MM-DD, contoh: 2026-09-05.',
    ]);
    guideSheet.appendValues([
      '7.',
      'Contoh kode: kode klaster CL1, kode plot 1, dan kode pohon 1.',
    ]);

    // Cluster sheet. Every other sheet uses kode klaster as its stable,
    // human-readable relationship key.
    final Sheet clustersSheet = excel['klaster'];
    clustersSheet.appendValues([
      'kode klaster *',
      'nama pengukur *',
      'tanggal pengukuran *',
    ]);
    for (final cluster in clusters) {
      clustersSheet.appendValues([
        cluster.kodeCluster,
        cluster.namaPengukur,
        cluster.tanggalPengukuran == null
            ? null
            : DateFormat('yyyy-MM-dd').format(cluster.tanggalPengukuran!),
      ]);
    }

    // One Titik Ikat belongs to one cluster.
    final Sheet anchorsSheet = excel['titik_ikat'];
    anchorsSheet.appendValues([
      'kode klaster *',
      'lintang *',
      'bujur *',
      'altitude',
      'keterangan',
      'url gambar',
    ]);
    for (final anchor in anchors) {
      final cluster = clusterById[anchor.idCluster];
      if (cluster == null) continue;
      anchorsSheet.appendValues([
        cluster.kodeCluster,
        anchor.latitude,
        anchor.longitude,
        anchor.altitude,
        anchor.keterangan,
        anchor.urlFoto,
      ]);
    }

    // Plots sheet
    final Sheet plotsSheet = excel['plot'];
    plotsSheet.appendValues([
      'kode klaster *',
      'kode plot *',
      'lintang *',
      'bujur *',
      'altitude',
    ]);
    for (final PlotModel plot in plots) {
      final cluster = clusterById[plot.idCluster];
      if (cluster == null) continue;
      plotsSheet.appendValues([
        cluster.kodeCluster,
        plot.kodePlot,
        plot.latitude,
        plot.longitude,
        plot.altitude,
      ]);
    }

    // Trees sheet
    final Sheet treesSheet = excel['pohon'];
    treesSheet.appendValues([
      'kode klaster *',
      'kode plot *',
      'kode pohon *',
      'nama pohon *',
      'nama ilmiah *',
      'azimuth *',
      'jarak *',
      'altitude',
      'keterangan',
      'url gambar',
    ]);
    for (final tree in trees) {
      final plot = plotById[tree.plotId];
      if (plot == null) continue;
      final cluster = clusterById[plot.idCluster];
      if (cluster == null) continue;
      treesSheet.appendValues([
        cluster.kodeCluster,
        plot.kodePlot,
        tree.kodePohon,
        tree.namaPohon,
        tree.namaIlmiah,
        tree.azimut,
        tree.jarakPusatM,
        tree.altitude,
        tree.keterangan,
        tree.urlFoto,
      ]);
    }

    // Excel creates this empty sheet by default; it is not part of the
    // Azimutree interchange format.
    if (excel.tables.containsKey('Sheet1')) excel.delete('Sheet1');

    return excel;
  }

  static Future<Directory> _getOutputDirectory({
    bool preferDownloads = true,
    String? directoryPath,
  }) async {
    if (directoryPath != null && directoryPath.trim().isNotEmpty) {
      final dir = Directory(directoryPath);
      if (!dir.existsSync()) {
        await dir.create(recursive: true);
      }
      return dir;
    }

    // If preferDownloads is true, try Downloads first; otherwise prefer app documents
    if (preferDownloads) {
      try {
        final externals = await getExternalStorageDirectories(
          type: StorageDirectory.downloads,
        );
        if (externals != null && externals.isNotEmpty) {
          return externals.first;
        }
      } catch (_) {}
    }

    try {
      final directory = await getApplicationDocumentsDirectory();
      return directory;
    } catch (e) {
      // Fallback to temporary directory
      return await getTemporaryDirectory();
    }
  }
}

extension on Sheet {
  void appendValues(List<Object?> values) {
    appendRow(
      values.map((value) {
        if (value == null) return null;
        if (value is String) return TextCellValue(value);
        if (value is int) return IntCellValue(value);
        if (value is double) return DoubleCellValue(value);
        if (value is bool) return BoolCellValue(value);
        return TextCellValue(value.toString());
      }).toList(),
    );
  }
}
