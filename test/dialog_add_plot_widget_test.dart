import 'package:azimutree/data/models/cluster_model.dart';
import 'package:azimutree/data/models/plot_model.dart';
import 'package:azimutree/data/models/titik_ikat_model.dart';
import 'package:azimutree/data/notifiers/plot_notifier.dart';
import 'package:azimutree/services/azimuth_latlong_service.dart';
import 'package:azimutree/views/widgets/manage_data_widget/dialog_add_plot_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final cluster = ClusterModel(
    id: 1,
    kodeCluster: 'K-01',
    namaPengukur: 'Pengukur',
    tanggalPengukuran: DateTime(2026, 9, 2),
  );
  final anchor = TitikIkatModel(
    id: 1,
    idCluster: 1,
    nama: 'TI-K-01',
    latitude: -5.4,
    longitude: 105.2,
  );

  Widget form(PlotNotifier notifier) => MaterialApp(
    home: Scaffold(
      body: DialogAddPlotWidget(
        plotNotifier: notifier,
        clusters: [cluster],
        titikIkat: [anchor],
      ),
    ),
  );

  testWidgets('first plot only offers Titik Ikat as reference', (tester) async {
    final notifier = PlotNotifier();
    addTearDown(notifier.dispose);
    await tester.pumpWidget(form(notifier));

    expect(find.text('Titik Ikat'), findsOneWidget);
    expect(find.text('Azimut & Jarak'), findsOneWidget);
    expect(find.text('Lintang & Bujur'), findsOneWidget);
    expect(find.text('Plot 1'), findsOneWidget);
  });

  testWidgets('saved plots become additional references', (tester) async {
    final notifier = PlotNotifier();
    addTearDown(notifier.dispose);
    notifier.value = [
      PlotModel(
        id: 10,
        idCluster: 1,
        kodePlot: 1,
        latitude: -5.399,
        longitude: 105.2,
      ),
    ];
    await tester.pumpWidget(form(notifier));

    await tester.tap(find.text('Titik Ikat').last);
    await tester.pumpAndSettle();
    expect(find.text('Plot 1'), findsWidgets);
  });

  test('geodesic conversion round-trips azimuth and distance', () {
    final target = AzimuthLatLongService.fromAzimuthDistance(
      centerLatDeg: -5.4,
      centerLonDeg: 105.2,
      azimuthDeg: 123.4,
      distanceM: 250,
    );
    final restored = AzimuthLatLongService.toAzimuthDistance(
      centerLatDeg: -5.4,
      centerLonDeg: 105.2,
      targetLatDeg: target.latitude,
      targetLonDeg: target.longitude,
    );

    expect(restored.azimuthDeg, closeTo(123.4, 0.0001));
    expect(restored.distanceM, closeTo(250, 0.001));
  });
}
