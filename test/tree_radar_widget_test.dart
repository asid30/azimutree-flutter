import 'package:azimutree/data/models/tree_model.dart';
import 'package:azimutree/views/widgets/survey_widget/tree_radar_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('radar paints valid trees and ignores incomplete data', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox.square(
            dimension: 240,
            child: TreeRadarWidget(
              heading: 90,
              isDark: false,
              trees: [
                TreeModel(
                  id: 1,
                  plotId: 1,
                  kodePohon: 1,
                  azimut: 85,
                  jarakPusatM: 9.2,
                ),
                TreeModel(id: 2, plotId: 1, kodePohon: 2),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.byType(CustomPaint), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('radar handles unavailable compass heading', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox.square(
            dimension: 240,
            child: TreeRadarWidget(trees: [], heading: null, isDark: true),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });
}
