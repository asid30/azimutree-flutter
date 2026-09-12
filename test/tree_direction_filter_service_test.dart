import 'package:azimutree/data/models/tree_model.dart';
import 'package:azimutree/services/tree_direction_filter_service.dart';
import 'package:flutter_test/flutter_test.dart';

TreeModel tree({
  required int id,
  required int plotId,
  double? azimuth,
  double? distance,
}) => TreeModel(
  id: id,
  plotId: plotId,
  kodePohon: id,
  azimut: azimuth,
  jarakPusatM: distance,
);

void main() {
  test('filters trees by active plot and heading tolerance', () {
    final result = TreeDirectionFilterService.filter(
      trees: [
        tree(id: 1, plotId: 3, azimuth: 85, distance: 9.2),
        tree(id: 2, plotId: 3, azimuth: 93, distance: 14.7),
        tree(id: 3, plotId: 3, azimuth: 150, distance: 2),
        tree(id: 4, plotId: 4, azimuth: 90, distance: 1),
        tree(id: 5, plotId: 3, distance: 1),
      ],
      plotId: 3,
      heading: 90,
    );

    expect(result.map((item) => item.id), [2, 1]);
  });

  test('sorts equal angle differences by shortest distance', () {
    final result = TreeDirectionFilterService.filter(
      trees: [
        tree(id: 1, plotId: 1, azimuth: 95, distance: 12),
        tree(id: 2, plotId: 1, azimuth: 85, distance: 6),
      ],
      plotId: 1,
      heading: 90,
    );
    expect(result.map((item) => item.id), [2, 1]);
  });

  test('handles north wrap-around and invalid azimuth safely', () {
    final result = TreeDirectionFilterService.filter(
      trees: [
        tree(id: 1, plotId: 1, azimuth: 359, distance: 2),
        tree(id: 2, plotId: 1, azimuth: 5, distance: 3),
        tree(id: 3, plotId: 1, azimuth: double.nan, distance: 1),
        tree(id: 4, plotId: 1),
      ],
      plotId: 1,
      heading: 1,
    );
    expect(result.map((item) => item.id), [1, 2]);
  });
}
