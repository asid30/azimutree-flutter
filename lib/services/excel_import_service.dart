import 'dart:io';

import 'package:excel/excel.dart';
import 'package:azimutree/data/database/cluster_dao.dart';
import 'package:azimutree/data/database/plot_dao.dart';
import 'package:azimutree/data/database/tree_dao.dart';
import 'package:azimutree/data/models/cluster_model.dart';
import 'package:azimutree/data/models/plot_model.dart';
import 'package:azimutree/data/models/tree_model.dart';
import 'package:azimutree/data/global_variables/logger_global.dart';
import 'package:azimutree/services/azimuth_latlong_service.dart';

class ExcelImportService {
  /// Parse the given Excel file and insert cluster, plots and trees.
  ///
  /// - [filePath]: full path to the uploaded xlsx/xls file
  /// - [cluster]: ClusterModel to create first (must contain kodeCluster, nama, tanggal)
  /// Returns a Map with counts: {'clusterId': id, 'plots': n, 'trees': m}
  static Future<Map<String, int>> importFile({
    required String filePath,
    required ClusterModel cluster,
  }) async {
    logger.i('[ExcelImport] Importing file: $filePath');
    final f = File(filePath);
    logger.i(
      '[ExcelImport] file exists: ${f.existsSync()}, size: ${f.existsSync() ? f.lengthSync() : 0}',
    );

    final bytes = f.readAsBytesSync();
    final excel = Excel.decodeBytes(bytes);

    // insert cluster and get id
    final clusterId = await ClusterDao.insertCluster(cluster);
    var plotsInserted = 0;
    var treesInserted = 0;

    logger.i('[ExcelImport] Available sheets: ${excel.tables.keys.toList()}');

    // --- PLOTS (titik_pusat_plot)
    String? usedTitikSheet = _findSheetName(excel, [
      'titik_pusat_plot',
      'titik pusat',
      'titik_pusat',
      'titik',
    ]);
    if (usedTitikSheet == null) {
      for (final n in excel.tables.keys) {
        final s = excel[n];
        if (_findHeaderRow(s, [
              'plot',
              'latitude',
              'longitude',
              'altitude',
              'ketinggian',
            ]) !=
            null) {
          usedTitikSheet = n;
          break;
        }
      }
    }

    if (usedTitikSheet != null) {
      final sheet = excel[usedTitikSheet];
      final headerIndex = _findHeaderRow(sheet, [
        'plot',
        'latitude',
        'longitude',
        'altitude',
        'ketinggian',
      ]);
      final dataStart = (headerIndex != null) ? headerIndex + 1 : 3;
      logger.i(
        '[ExcelImport] Using plot sheet: $usedTitikSheet, headerIndex: $headerIndex, dataStart: $dataStart, maxRows: ${sheet.maxRows}',
      );

      const maxPlotsPerCluster = 4;
      for (
        var r = dataStart;
        r < sheet.maxRows && plotsInserted < maxPlotsPerCluster;
        r++
      ) {
        final row = sheet.row(r);
        if (_isRowEmpty(row)) continue;

        final cell0 = row.isNotEmpty ? row[0] : null; // kodePlot
        final cell1 = row.length > 1 ? row[1] : null; // latitude
        final cell2 = row.length > 2 ? row[2] : null; // longitude
        final cell3 = row.length > 3 ? row[3] : null; // altitude (optional)

        final v0 = (cell0 is Data) ? cell0.value : cell0;
        final v1 = (cell1 is Data) ? cell1.value : cell1;
        final v2 = (cell2 is Data) ? cell2.value : cell2;
        final v3 = (cell3 is Data) ? cell3.value : cell3;

        final kodePlot = _toInt(v0);
        final latitude = _toDouble(v1);
        final longitude = _toDouble(v2);
        final altitude = _toDouble(v3); // may be null

        if (kodePlot == null || latitude == null || longitude == null) {
          logger.w(
            '[ExcelImport] Plot parse fail at row $r: kode=$kodePlot, lat=$latitude, lon=$longitude -- raw: [$v0, $v1, $v2]',
          );
          continue;
        }

        final plot = PlotModel(
          idCluster: clusterId,
          kodePlot: kodePlot,
          latitude: latitude,
          longitude: longitude,
          altitude: altitude,
        );

        await PlotDao.insertPlot(plot);
        plotsInserted++;
      }
      logger.i('[ExcelImport] Plots inserted: $plotsInserted');
    } else {
      logger.w('[ExcelImport] No plot sheet found');
    }

    // Load all plots for this cluster to map.kodePlot -> id
    final allPlots = await PlotDao.getAllPlots();
    final plotsForCluster =
        allPlots.where((p) => p.idCluster == clusterId).toList();

    // --- TREES (jenis_dan_lokasi_pohon)
    String? usedPohonSheet = _findSheetName(excel, [
      'jenis_dan_lokasi_pohon',
      'jenis dan lokasi pohon',
      'jenis_dan_lokasi',
      'pohon',
    ]);
    if (usedPohonSheet == null) {
      for (final n in excel.tables.keys) {
        final s = excel[n];
        if (_findHeaderRow(s, ['kode plot', 'kode pohon']) != null) {
          usedPohonSheet = n;
          break;
        }
      }
    }

    if (usedPohonSheet != null) {
      final sheet = excel[usedPohonSheet];
      final headerIndex = _findHeaderRow(sheet, ['kode plot', 'kode pohon']);
      final dataStart = (headerIndex != null) ? headerIndex + 1 : 6;
      logger.i(
        '[ExcelImport] Using tree sheet: $usedPohonSheet, headerIndex: $headerIndex, dataStart: $dataStart, maxRows: ${sheet.maxRows}',
      );

      for (var r = dataStart; r < sheet.maxRows; r++) {
        final row = sheet.row(r);
        if (_isRowEmpty(row)) continue;

        final cell0 = row.isNotEmpty ? row[0] : null; // kode plot
        final cell1 = row.length > 1 ? row[1] : null; // kode pohon
        final cell2 = row.length > 2 ? row[2] : null; // nama pohon
        final cell3 = row.length > 3 ? row[3] : null; // nama ilmiah
        final cell4 = row.length > 4 ? row[4] : null; // azimut
        final cell5 = row.length > 5 ? row[5] : null; // jarak
        final cell6 = row.length > 6 ? row[6] : null; // altitude (optional)
        final cell7 = row.length > 7 ? row[7] : null; // urlFoto (optional)
        final cell8 = row.length > 8 ? row[8] : null; // keterangan (optional)

        final v0 = (cell0 is Data) ? cell0.value : cell0;
        final v1 = (cell1 is Data) ? cell1.value : cell1;
        final v2 = (cell2 is Data) ? cell2.value : cell2;
        final v3 = (cell3 is Data) ? cell3.value : cell3;
        final v4 = (cell4 is Data) ? cell4.value : cell4;
        final v5 = (cell5 is Data) ? cell5.value : cell5;
        final v6 = (cell6 is Data) ? cell6.value : cell6;
        final v7 = (cell7 is Data) ? cell7.value : cell7;
        final v8 = (cell8 is Data) ? cell8.value : cell8;

        final kodePlot = _toInt(v0);
        final kodePohon = _toInt(v1);
        if (kodePlot == null || kodePohon == null) {
          logger.w(
            '[ExcelImport] Tree parse fail at row $r: kodePlot=$kodePlot, kodePohon=$kodePohon -- raw: [$v0, $v1]',
          );
          continue;
        }

        final matchedPlots =
            plotsForCluster.where((p) => p.kodePlot == kodePlot).toList();
        if (matchedPlots.isEmpty) {
          logger.w(
            '[ExcelImport] No matching plot for kodePlot=$kodePlot at row $r',
          );
          continue;
        }
        final plot = matchedPlots.first;

        final azimutVal = _toDouble(v4);
        final jarakVal = _toDouble(v5);
        double? treeLat;
        double? treeLon;
        if (azimutVal != null && jarakVal != null) {
          try {
            final pt = AzimuthLatLongService.fromAzimuthDistance(
              centerLatDeg: plot.latitude,
              centerLonDeg: plot.longitude,
              azimuthDeg: azimutVal,
              distanceM: jarakVal,
            );
            treeLat = pt.latitude;
            treeLon = pt.longitude;
          } catch (e) {
            logger.w(
              '[ExcelImport] Azimuth->LatLon conversion failed at row $r: $e',
            );
          }
        }

        final tree = TreeModel(
          plotId: plot.id!,
          kodePohon: kodePohon,
          namaPohon: v2?.toString(),
          namaIlmiah: v3?.toString(),
          azimut: azimutVal,
          jarakPusatM: jarakVal,
          latitude: treeLat,
          longitude: treeLon,
          altitude: _toDouble(v6), // optional
          urlFoto: v7?.toString(), // optional
          keterangan: v8?.toString(), // optional
        );

        await TreeDao.insertTree(tree);
        treesInserted++;
      }
      logger.i('[ExcelImport] Trees inserted: $treesInserted');
    } else {
      logger.w('[ExcelImport] No tree sheet found');
    }

    return {
      'clusterId': clusterId,
      'plots': plotsInserted,
      'trees': treesInserted,
    };
  }

  static int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.toInt();
    var s = v.toString().trim();
    s = s.replaceAll(',', '.');
    if (s.contains('.')) {
      s = s.split('.').first;
    }
    s = s.replaceAll(RegExp(r'[^0-9\-+]'), '');
    final parsed = int.tryParse(s);
    if (parsed != null) return parsed;

    // Fallback: if the value is a date-like string, convert to excel serial then to int
    try {
      final dt = DateTime.tryParse(v.toString());
      if (dt != null) {
        final serial = _excelSerialFromDate(dt);
        logger.d(
          '[ExcelImport] Converted DateTime to numeric serial (int): $dt -> $serial',
        );
        return serial.toInt();
      }
    } catch (_) {}

    return null;
  }

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    var s = v.toString().trim();
    s = s.replaceAll(',', '.');
    s = s.replaceAll(RegExp(r'[^0-9\.\-+]'), '');
    final parsed = double.tryParse(s);
    if (parsed != null) return parsed;

    // Fallback: if value looks like ISO datetime or is DateTime, convert to excel serial
    try {
      DateTime? dt;
      if (v is DateTime) {
        dt = v;
      } else {
        dt = DateTime.tryParse(v.toString());
      }

      if (dt != null) {
        final serial = _excelSerialFromDate(dt);
        logger.d(
          '[ExcelImport] Converted DateTime to numeric serial (double): $dt -> $serial',
        );
        // clamp tiny values to 0
        if (serial.abs() < 1e-9) return 0.0;
        return serial;
      }
    } catch (_) {}

    return null;
  }

  static double _excelSerialFromDate(DateTime dt) {
    // Excel's serial date uses 1899-12-30 as day 0 for compatibility.
    // Treat the parsed DateTime as a naive/local date (don't convert to UTC)
    final base = DateTime(1899, 12, 30);
    final localDt = DateTime(
      dt.year,
      dt.month,
      dt.day,
      dt.hour,
      dt.minute,
      dt.second,
      dt.millisecond,
    );
    final diff = localDt.difference(base).inMilliseconds;
    final serial = diff / (24 * 60 * 60 * 1000);
    if (serial.abs() < 1e-9) return 0.0;
    return serial;
  }

  static String? _cellString(dynamic cell) {
    if (cell == null) return null;
    final val = (cell is Data) ? cell.value : cell;
    return val?.toString();
  }

  static String? _findSheetName(Excel excel, List<String> candidates) {
    final names = excel.tables.keys.toList();
    for (final c in candidates) {
      for (final n in names) {
        if (n.toLowerCase().contains(c.toLowerCase())) return n;
      }
    }
    return null;
  }

  static int? _findHeaderRow(Sheet sheet, List<String> requiredKeywords) {
    for (var r = 0; r < sheet.maxRows; r++) {
      final row = sheet.row(r);
      final lower =
          row.map((c) => _cellString(c)?.toLowerCase() ?? '').toList();
      var matchCount = 0;
      for (final kw in requiredKeywords) {
        if (lower.any((cell) => cell.contains(kw))) matchCount++;
      }
      // Require at least two keyword matches (or 1 if only one keyword provided)
      final threshold = requiredKeywords.length >= 2 ? 2 : 1;
      if (matchCount >= threshold) return r; // found a header-like row
    }
    return null;
  }

  static bool _isRowEmpty(List<Data?> row) {
    if (row.isEmpty) return true;
    for (final c in row) {
      final s = _cellString(c);
      if (s != null && s.trim().isNotEmpty) return false;
    }
    return true;
  }
}
