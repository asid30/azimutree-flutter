import 'package:azimutree/data/notifiers/titik_ikat_notifier.dart';
import 'package:azimutree/data/notifiers/cluster_notifier.dart';
import 'package:azimutree/views/widgets/manage_data_widget/dialog_add_cluster_widget.dart';
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
}
