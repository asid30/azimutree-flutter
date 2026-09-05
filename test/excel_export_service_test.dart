import 'package:azimutree/data/models/cluster_model.dart';
import 'package:azimutree/data/models/plot_model.dart';
import 'package:azimutree/data/models/titik_ikat_model.dart';
import 'package:azimutree/data/models/tree_model.dart';
import 'package:azimutree/services/excel_export_service.dart';
import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('multi-cluster export keeps all entity relationships', () {
    final clusters = [
      ClusterModel(
        id: 1,
        kodeCluster: 'CL01',
        namaPengukur: 'Andi',
        tanggalPengukuran: DateTime(2026, 9, 5),
      ),
      ClusterModel(id: 2, kodeCluster: 'CL02', namaPengukur: 'Budi'),
    ];
    final anchors = [
      TitikIkatModel(
        id: 1,
        idCluster: 1,
        nama: 'Titik Ikat CL01',
        latitude: -5.1,
        longitude: 105.1,
      ),
      TitikIkatModel(
        id: 2,
        idCluster: 2,
        nama: 'Titik Ikat CL02',
        latitude: -5.2,
        longitude: 105.2,
      ),
    ];
    final plots = [
      PlotModel(
        id: 11,
        idCluster: 1,
        kodePlot: 1,
        latitude: -5.11,
        longitude: 105.11,
      ),
      PlotModel(
        id: 21,
        idCluster: 2,
        kodePlot: 2,
        latitude: -5.22,
        longitude: 105.22,
      ),
    ];
    final trees = [
      TreeModel(
        id: 111,
        plotId: 11,
        kodePohon: 7,
        namaPohon: 'Meranti',
        namaIlmiah: 'Shorea',
        azimut: 30,
        jarakPusatM: 12,
        latitude: -5.111,
        longitude: 105.111,
      ),
      TreeModel(
        id: 211,
        plotId: 21,
        kodePohon: 8,
        namaPohon: 'Damar',
        namaIlmiah: 'Agathis',
        azimut: 120,
        jarakPusatM: 15,
        latitude: -5.221,
        longitude: 105.221,
      ),
    ];

    final workbook = ExcelExportService.buildWorkbook(
      clusters: clusters,
      anchors: anchors,
      plots: plots,
      trees: trees,
    );
    final encoded = workbook.encode();
    expect(encoded, isNotNull);

    final decoded = Excel.decodeBytes(encoded!);
    expect(
      decoded.tables.keys,
      containsAll(['panduan', 'klaster', 'titik_ikat', 'plot', 'pohon']),
    );
    expect(decoded.tables.keys, isNot(contains('Sheet1')));

    final clusterRows = decoded['klaster'].rows;
    final guideRows = decoded['panduan'].rows;
    final anchorRows = decoded['titik_ikat'].rows;
    final plotRows = decoded['plot'].rows;
    final treeRows = decoded['pohon'].rows;

    expect(clusterRows, hasLength(3));
    expect(guideRows, hasLength(8));
    expect(anchorRows, hasLength(3));
    expect(plotRows, hasLength(3));
    expect(treeRows, hasLength(3));

    expect(_values(anchorRows[1]).first, 'CL01');
    expect(_values(anchorRows[2]).first, 'CL02');
    expect(_values(plotRows[1]).take(2), ['CL01', 1]);
    expect(_values(plotRows[2]).take(2), ['CL02', 2]);
    expect(_values(treeRows[1]).take(3), ['CL01', 1, 7]);
    expect(_values(treeRows[2]).take(3), ['CL02', 2, 8]);
    expect(_values(clusterRows.first).first, 'kode klaster *');
    expect(
      _values(clusterRows.first),
      containsAll(['nama pengukur *', 'tanggal pengukuran *']),
    );
    expect(_values(anchorRows.first).skip(1).take(2), ['lintang *', 'bujur *']);
    expect(_values(anchorRows[1]), isNot(contains('Titik Ikat CL01')));
    expect(_values(treeRows.first), isNot(contains('lintang *')));
    expect(_values(treeRows.first), isNot(contains('bujur *')));
    expect(_values(treeRows.first), containsAll(['azimuth *', 'jarak *']));
    expect(_values(guideRows[1])[1], contains('Kolom * wajib diisi'));
    expect(_values(guideRows[5])[1], contains('Nama sheet tidak boleh diubah'));
    expect(_values(guideRows[6])[1], contains('YYYY-MM-DD'));
    expect(_values(guideRows[7])[1], contains('kode klaster CL1'));
  });
}

List<dynamic> _values(List<Data?> row) =>
    row.map((cell) {
      final value = cell?.value;
      return switch (value) {
        TextCellValue() => value.toString(),
        IntCellValue() => value.value,
        DoubleCellValue() => value.value,
        _ => value,
      };
    }).toList();
