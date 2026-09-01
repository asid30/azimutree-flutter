import 'package:azimutree/data/models/cluster_model.dart';
import 'package:azimutree/data/models/plot_model.dart';
import 'package:azimutree/data/notifiers/titik_ikat_notifier.dart';
import 'package:azimutree/data/notifiers/cluster_notifier.dart';
import 'package:azimutree/views/widgets/manage_data_widget/dialog_add_cluster_widget.dart';
import 'package:azimutree/views/widgets/manage_data_widget/dialog_titik_ikat_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('new Cluster form requires Titik Ikat coordinates', (
    tester,
  ) async {
    final clusterNotifier = ClusterNotifier();
    final titikIkatNotifier = TitikIkatNotifier();
    addTearDown(clusterNotifier.dispose);
    addTearDown(titikIkatNotifier.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DialogAddClusterWidget(
            clusterNotifier: clusterNotifier,
            titikIkatNotifier: titikIkatNotifier,
          ),
        ),
      ),
    );

    expect(find.text('Koordinat Titik Ikat'), findsOneWidget);
    expect(find.text('Lintang Titik Ikat (wajib)'), findsOneWidget);
    expect(find.text('Bujur Titik Ikat (wajib)'), findsOneWidget);
    expect(find.textContaining('Nama dibuat otomatis'), findsOneWidget);
  });

  testWidgets('Titik Ikat position methods are mutually exclusive', (
    tester,
  ) async {
    final notifier = TitikIkatNotifier();
    addTearDown(notifier.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DialogTitikIkatWidget(
            clusters: [ClusterModel(id: 1, kodeCluster: 'CL1')],
            plots: [
              PlotModel(
                id: 1,
                idCluster: 1,
                kodePlot: 1,
                latitude: -5.4,
                longitude: 105.2,
              ),
            ],
            titikIkatNotifier: notifier,
            initialClusterId: 1,
          ),
        ),
      ),
    );

    expect(find.text('Azimut menuju Plot 1 (wajib)'), findsOneWidget);
    expect(find.text('Lintang Titik Ikat (wajib)'), findsNothing);

    await tester.tap(find.text('Koordinat'));
    await tester.pump();

    expect(find.text('Azimut menuju Plot 1 (wajib)'), findsNothing);
    expect(find.text('Jarak menuju Plot 1, meter (wajib)'), findsNothing);
    expect(find.text('Lintang Titik Ikat (wajib)'), findsOneWidget);
    expect(find.text('Bujur Titik Ikat (wajib)'), findsOneWidget);
  });
}
