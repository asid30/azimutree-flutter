import 'dart:io';

import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:azimutree/data/database/plot_dao.dart';
import 'package:azimutree/data/database/tree_dao.dart';
import 'package:azimutree/data/models/cluster_model.dart';
import 'package:azimutree/data/models/plot_model.dart';
import 'package:azimutree/data/global_variables/logger_global.dart';

class ExcelExportService {
  /// Export given cluster (by id) to an Excel file and return file path.
  static Future<String> exportClusterToExcel({
    required ClusterModel cluster,
    bool preferDownloads = true,
    String? directoryPath,
  }) async {
    logger.i('[ExcelExport] Exporting cluster ${cluster.kodeCluster}');

    final excel = Excel.createExcel();

    // Plots sheet
    final plotsSheetName = 'titik_pusat_plot';
    final Sheet plotsSheet = excel[plotsSheetName];
    // Template expects header at row 3 (A3:D3)
    plotsSheet.appendRow([]);
    plotsSheet.appendRow([]);
    plotsSheet.appendRow(['plot', 'latitude', 'longitude', 'altitude']);

    final allPlots = await PlotDao.getAllPlots();
    final plotsForCluster =
        allPlots.where((p) => p.idCluster == cluster.id).toList();
    for (final PlotModel plot in plotsForCluster) {
      plotsSheet.appendRow([
        plot.kodePlot,
        plot.latitude,
        plot.longitude,
        plot.altitude,
      ]);
    }

    // Trees sheet
    final treesSheetName = 'jenis_dan_lokasi_pohon';
    final Sheet treesSheet = excel[treesSheetName];
    // Template expects header at row 6 (A6:I6)
    treesSheet.appendRow([]);
    treesSheet.appendRow([]);
    treesSheet.appendRow([]);
    treesSheet.appendRow([]);
    treesSheet.appendRow([]);
    treesSheet.appendRow([
      'kode plot',
      'kode pohon',
      'nama pohon',
      'nama ilmiah',
      'azimut',
      'jarak',
      'altitude',
      'urlFoto',
      'keterangan',
    ]);

    final allTrees = await TreeDao.getAllTrees();
    // map plot.id -> kodePlot for cluster plots
    final plotIdToKode = <int, int>{};
    for (final p in plotsForCluster) {
      if (p.id != null) plotIdToKode[p.id!] = p.kodePlot;
    }

    final treesForCluster =
        allTrees.where((t) => plotIdToKode.containsKey(t.plotId)).toList();
    for (final tree in treesForCluster) {
      final kodePlot = plotIdToKode[tree.plotId] ?? tree.plotId;
      treesSheet.appendRow([
        kodePlot,
        tree.kodePohon,
        tree.namaPohon,
        tree.namaIlmiah,
        tree.azimut,
        tree.jarakPusatM,
        tree.altitude,
        tree.urlFoto,
        tree.keterangan,
      ]);
    }

    // Prepare file path
    final now = DateTime.now();
    final formatted = DateFormat('yyyyMMdd_HHmmss').format(now);
    final filename = 'azimutree_export_${cluster.kodeCluster}_$formatted.xlsx';

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
