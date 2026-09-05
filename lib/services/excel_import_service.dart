import 'dart:io';

import 'package:azimutree/data/database/azimutree_db.dart';
import 'package:azimutree/data/database/cluster_dao.dart';
import 'package:azimutree/data/database/plot_dao.dart';
import 'package:azimutree/data/database/titik_ikat_dao.dart';
import 'package:azimutree/data/database/tree_dao.dart';
import 'package:azimutree/data/global_variables/logger_global.dart';
import 'package:azimutree/data/models/cluster_model.dart';
import 'package:azimutree/data/models/plot_model.dart';
import 'package:azimutree/data/models/titik_ikat_model.dart';
import 'package:azimutree/data/models/tree_model.dart';
import 'package:azimutree/services/azimuth_latlong_service.dart';
import 'package:excel/excel.dart';

class ExcelImportService {
  static const requiredSheetNames = <String>{
    'panduan',
    'klaster',
    'titik_ikat',
    'plot',
    'pohon',
  };

  static Future<Map<String, int>> importFile({required String filePath}) async {
    logger.i('[ExcelImport] Importing file: $filePath');
    final file = File(filePath);
    if (!await file.exists()) {
      throw const FormatException('File Excel tidak ditemukan.');
    }
    final parsed = parseWorkbook(Excel.decodeBytes(await file.readAsBytes()));
    final existingCodes =
        (await ClusterDao.getAllClusters())
            .map((cluster) => cluster.kodeCluster.trim().toUpperCase())
            .toSet();
    final duplicateCodes =
        parsed.clusters
            .map((cluster) => cluster.kodeCluster)
            .where(existingCodes.contains)
            .toList();
    if (duplicateCodes.isNotEmpty) {
      throw FormatException(
        'Kode klaster sudah tersedia: ${duplicateCodes.join(', ')}.',
      );
    }

    final database = await AzimutreeDB.instance.database;
    await database.transaction((transaction) async {
      final clusterIdByCode = <String, int>{};
      for (final cluster in parsed.clusters) {
        final id = await transaction.insert(
          ClusterDao.tableName,
          cluster.toMap(),
        );
        clusterIdByCode[cluster.kodeCluster] = id;
      }
      for (final anchor in parsed.anchors) {
        final model = TitikIkatModel(
          idCluster: clusterIdByCode[anchor.clusterCode]!,
          nama: 'Titik Ikat ${anchor.clusterCode}',
          latitude: anchor.latitude,
          longitude: anchor.longitude,
          altitude: anchor.altitude,
          keterangan: anchor.description,
          urlFoto: anchor.imageUrl,
        );
        model.validate();
        await transaction.insert(TitikIkatDao.tableName, model.toMap());
      }

      final plotIdByKey = <String, int>{};
      final plotByKey = <String, PlotModel>{};
      for (final plot in parsed.plots) {
        final model = PlotModel(
          idCluster: clusterIdByCode[plot.clusterCode]!,
          kodePlot: plot.plotCode,
          latitude: plot.latitude,
          longitude: plot.longitude,
          altitude: plot.altitude,
        );
        final id = await transaction.insert(PlotDao.tableName, model.toMap());
        final key = _plotKey(plot.clusterCode, plot.plotCode);
        plotIdByKey[key] = id;
        plotByKey[key] = model;
      }
      for (final tree in parsed.trees) {
        final key = _plotKey(tree.clusterCode, tree.plotCode);
        final plot = plotByKey[key]!;
        final coordinate = AzimuthLatLongService.fromAzimuthDistance(
          centerLatDeg: plot.latitude,
          centerLonDeg: plot.longitude,
          azimuthDeg: tree.azimuth,
          distanceM: tree.distanceM,
        );
        await transaction.insert(
          TreeDao.tableName,
          TreeModel(
            plotId: plotIdByKey[key]!,
            kodePohon: tree.treeCode,
            namaPohon: tree.commonName,
            namaIlmiah: tree.scientificName,
            azimut: tree.azimuth,
            jarakPusatM: tree.distanceM,
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            altitude: tree.altitude,
            keterangan: tree.description,
            urlFoto: tree.imageUrl,
          ).toMap(),
        );
      }
    });

    return {
      'clusters': parsed.clusters.length,
      'anchors': parsed.anchors.length,
      'plots': parsed.plots.length,
      'trees': parsed.trees.length,
    };
  }

  static ParsedImportWorkbook parseWorkbook(Excel excel) {
    final missing = requiredSheetNames.difference(excel.tables.keys.toSet());
    if (missing.isNotEmpty) {
      throw FormatException(
        'Sheet wajib tidak ditemukan: ${missing.join(', ')}. Nama sheet tidak boleh diubah.',
      );
    }
    final clusterRows = _rows(excel.tables['klaster']!, const [
      'kode klaster',
      'nama pengukur',
      'tanggal pengukuran',
    ]);
    final anchorRows = _rows(excel.tables['titik_ikat']!, const [
      'kode klaster',
      'lintang',
      'bujur',
    ]);
    final plotRows = _rows(excel.tables['plot']!, const [
      'kode klaster',
      'kode plot',
      'lintang',
      'bujur',
    ]);
    final treeRows = _rows(excel.tables['pohon']!, const [
      'kode klaster',
      'kode plot',
      'kode pohon',
      'nama pohon',
      'nama ilmiah',
      'azimuth',
      'jarak',
    ]);

    final clusters = <ClusterModel>[];
    final clusterCodes = <String>{};
    for (final row in clusterRows) {
      final code = _requiredText(row, 'kode klaster').toUpperCase();
      if (!clusterCodes.add(code)) _fail(row, 'Kode klaster $code duplikat.');
      clusters.add(
        ClusterModel(
          kodeCluster: code,
          namaPengukur: _requiredText(row, 'nama pengukur'),
          tanggalPengukuran: _parseDate(
            _requiredText(row, 'tanggal pengukuran'),
            row,
          ),
        ),
      );
    }
    if (clusters.isEmpty) {
      throw const FormatException('Sheet klaster tidak memiliki data.');
    }

    final anchors = <ParsedAnchor>[];
    final anchorCodes = <String>{};
    for (final row in anchorRows) {
      final code = _requiredClusterCode(row, clusterCodes);
      if (!anchorCodes.add(code)) {
        _fail(row, 'Klaster $code hanya boleh memiliki satu Titik Ikat.');
      }
      anchors.add(
        ParsedAnchor(
          clusterCode: code,
          latitude: _coordinate(row, 'lintang', -90, 90),
          longitude: _coordinate(row, 'bujur', -180, 180),
          altitude: _optionalNumber(row, 'altitude'),
          description: _optionalText(row, 'keterangan'),
          imageUrl: _optionalText(row, 'url gambar'),
        ),
      );
    }
    final withoutAnchor = clusterCodes.difference(anchorCodes);
    if (withoutAnchor.isNotEmpty) {
      throw FormatException(
        'Titik Ikat belum tersedia untuk klaster: ${withoutAnchor.join(', ')}.',
      );
    }

    final plots = <ParsedPlot>[];
    final plotKeys = <String>{};
    final plotCount = <String, int>{};
    for (final row in plotRows) {
      final code = _requiredClusterCode(row, clusterCodes);
      final plotCode = _requiredInt(row, 'kode plot');
      if (plotCode < 1 || plotCode > 4) {
        _fail(row, 'Kode plot harus berada dalam rentang 1 sampai 4.');
      }
      final key = _plotKey(code, plotCode);
      if (!plotKeys.add(key)) {
        _fail(row, 'Plot $plotCode pada klaster $code duplikat.');
      }
      plotCount[code] = (plotCount[code] ?? 0) + 1;
      if (plotCount[code]! > 4) {
        _fail(row, 'Jumlah plot pada klaster $code melebihi 4.');
      }
      plots.add(
        ParsedPlot(
          clusterCode: code,
          plotCode: plotCode,
          latitude: _coordinate(row, 'lintang', -90, 90),
          longitude: _coordinate(row, 'bujur', -180, 180),
          altitude: _optionalNumber(row, 'altitude'),
        ),
      );
    }

    final trees = <ParsedTree>[];
    final treeKeys = <String>{};
    for (final row in treeRows) {
      final code = _requiredClusterCode(row, clusterCodes);
      final plotCode = _requiredInt(row, 'kode plot');
      final plotKey = _plotKey(code, plotCode);
      if (!plotKeys.contains(plotKey)) {
        _fail(row, 'Plot $plotCode pada klaster $code tidak ditemukan.');
      }
      final treeCode = _requiredInt(row, 'kode pohon');
      if (!treeKeys.add('$plotKey::$treeCode')) {
        _fail(row, 'Kode pohon $treeCode pada plot $plotCode duplikat.');
      }
      final azimuth = _requiredNumber(row, 'azimuth');
      if (azimuth < 0 || azimuth >= 360) {
        _fail(row, 'Azimuth harus antara 0 dan kurang dari 360.');
      }
      final distance = _requiredNumber(row, 'jarak');
      if (distance < 0) _fail(row, 'Jarak tidak boleh negatif.');
      trees.add(
        ParsedTree(
          clusterCode: code,
          plotCode: plotCode,
          treeCode: treeCode,
          commonName: _requiredText(row, 'nama pohon'),
          scientificName: _requiredText(row, 'nama ilmiah'),
          azimuth: azimuth,
          distanceM: distance,
          altitude: _optionalNumber(row, 'altitude'),
          description: _optionalText(row, 'keterangan'),
          imageUrl: _optionalText(row, 'url gambar'),
        ),
      );
    }
    return ParsedImportWorkbook(
      clusters: clusters,
      anchors: anchors,
      plots: plots,
      trees: trees,
    );
  }

  static List<_ImportRow> _rows(Sheet sheet, List<String> requiredHeaders) {
    if (sheet.rows.isEmpty) {
      throw FormatException('Sheet ${sheet.sheetName} kosong.');
    }
    final headers = <String, int>{};
    for (var index = 0; index < sheet.rows.first.length; index++) {
      final header = _normalizeHeader(_cellValue(sheet.rows.first[index]));
      if (header.isNotEmpty) headers[header] = index;
    }
    final missing = requiredHeaders.where(
      (header) => !headers.containsKey(header),
    );
    if (missing.isNotEmpty) {
      throw FormatException(
        'Kolom wajib pada sheet ${sheet.sheetName} tidak ditemukan: ${missing.join(', ')}.',
      );
    }
    final rows = <_ImportRow>[];
    for (var index = 1; index < sheet.rows.length; index++) {
      final cells = sheet.rows[index];
      if (cells.every((cell) => _cellValue(cell).isEmpty)) continue;
      rows.add(
        _ImportRow(
          sheetName: sheet.sheetName,
          excelRow: index + 1,
          headers: headers,
          cells: cells,
        ),
      );
    }
    return rows;
  }

  static String _normalizeHeader(String value) =>
      value.replaceAll('*', '').trim().toLowerCase();

  static String _cellValue(Data? cell) => switch (cell?.value) {
    null => '',
    TextCellValue value => value.toString().trim(),
    IntCellValue value => value.value.toString(),
    DoubleCellValue value => value.value.toString(),
    DateCellValue value =>
      '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}',
    DateTimeCellValue value => value.asDateTimeLocal().toIso8601String(),
    BoolCellValue value => value.value.toString(),
    final value => value.toString().trim(),
  };

  static String _value(_ImportRow row, String header) {
    final index = row.headers[header];
    return index == null || index >= row.cells.length
        ? ''
        : _cellValue(row.cells[index]);
  }

  static String _requiredText(_ImportRow row, String header) {
    final value = _value(row, header).trim();
    if (value.isEmpty) _fail(row, 'Kolom "$header" wajib diisi.');
    return value;
  }

  static String? _optionalText(_ImportRow row, String header) {
    final value = _value(row, header).trim();
    return value.isEmpty ? null : value;
  }

  static double _requiredNumber(_ImportRow row, String header) {
    final value = double.tryParse(
      _requiredText(row, header).replaceAll(',', '.'),
    );
    if (value == null || !value.isFinite) {
      _fail(row, 'Kolom "$header" harus berupa angka yang valid.');
    }
    return value;
  }

  static double? _optionalNumber(_ImportRow row, String header) {
    final text = _value(row, header).trim();
    if (text.isEmpty) return null;
    final value = double.tryParse(text.replaceAll(',', '.'));
    if (value == null || !value.isFinite) {
      _fail(row, 'Kolom "$header" harus berupa angka yang valid.');
    }
    return value;
  }

  static int _requiredInt(_ImportRow row, String header) {
    final value = _requiredNumber(row, header);
    if (value != value.roundToDouble()) {
      _fail(row, 'Kolom "$header" harus bilangan bulat.');
    }
    return value.toInt();
  }

  static double _coordinate(
    _ImportRow row,
    String header,
    double minimum,
    double maximum,
  ) {
    final value = _requiredNumber(row, header);
    if (value < minimum || value > maximum) {
      _fail(row, 'Nilai "$header" harus antara $minimum dan $maximum.');
    }
    return value;
  }

  static DateTime _parseDate(String value, _ImportRow row) {
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
      _fail(row, 'Tanggal harus menggunakan format YYYY-MM-DD.');
    }
    final parsed = DateTime.tryParse(value);
    final normalized =
        parsed == null
            ? ''
            : '${parsed.year.toString().padLeft(4, '0')}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')}';
    if (parsed == null || normalized != value) {
      _fail(row, 'Tanggal "$value" tidak valid.');
    }
    return parsed;
  }

  static String _requiredClusterCode(_ImportRow row, Set<String> codes) {
    final code = _requiredText(row, 'kode klaster').toUpperCase();
    if (!codes.contains(code)) {
      _fail(row, 'Kode klaster $code tidak ditemukan pada sheet klaster.');
    }
    return code;
  }

  static Never _fail(_ImportRow row, String message) =>
      throw FormatException(
        '${row.sheetName}, baris ${row.excelRow}: $message',
      );
  static String _plotKey(String clusterCode, int plotCode) =>
      '$clusterCode::$plotCode';
}

class ParsedImportWorkbook {
  const ParsedImportWorkbook({
    required this.clusters,
    required this.anchors,
    required this.plots,
    required this.trees,
  });
  final List<ClusterModel> clusters;
  final List<ParsedAnchor> anchors;
  final List<ParsedPlot> plots;
  final List<ParsedTree> trees;
}

class ParsedAnchor {
  const ParsedAnchor({
    required this.clusterCode,
    required this.latitude,
    required this.longitude,
    this.altitude,
    this.description,
    this.imageUrl,
  });
  final String clusterCode;
  final double latitude;
  final double longitude;
  final double? altitude;
  final String? description;
  final String? imageUrl;
}

class ParsedPlot {
  const ParsedPlot({
    required this.clusterCode,
    required this.plotCode,
    required this.latitude,
    required this.longitude,
    this.altitude,
  });
  final String clusterCode;
  final int plotCode;
  final double latitude;
  final double longitude;
  final double? altitude;
}

class ParsedTree {
  const ParsedTree({
    required this.clusterCode,
    required this.plotCode,
    required this.treeCode,
    required this.commonName,
    required this.scientificName,
    required this.azimuth,
    required this.distanceM,
    this.altitude,
    this.description,
    this.imageUrl,
  });
  final String clusterCode;
  final int plotCode;
  final int treeCode;
  final String commonName;
  final String scientificName;
  final double azimuth;
  final double distanceM;
  final double? altitude;
  final String? description;
  final String? imageUrl;
}

class _ImportRow {
  const _ImportRow({
    required this.sheetName,
    required this.excelRow,
    required this.headers,
    required this.cells,
  });
  final String sheetName;
  final int excelRow;
  final Map<String, int> headers;
  final List<Data?> cells;
}
