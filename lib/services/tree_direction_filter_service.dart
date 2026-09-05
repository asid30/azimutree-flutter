import 'package:azimutree/data/models/tree_model.dart';
import 'package:azimutree/services/compass_navigation_service.dart';

class TreeDirectionFilterService {
  const TreeDirectionFilterService._();

  static List<TreeModel> filter({
    required Iterable<TreeModel> trees,
    required int plotId,
    required double heading,
    double tolerance = compassAlignmentTolerance,
  }) {
    final matches =
        trees.where((tree) {
          final azimuth = tree.azimut;
          return tree.plotId == plotId &&
              azimuth != null &&
              azimuth.isFinite &&
              signedAngleDifference(azimuth, heading).abs() <= tolerance;
        }).toList();
    matches.sort((a, b) {
      final angleComparison = signedAngleDifference(
        a.azimut!,
        heading,
      ).abs().compareTo(signedAngleDifference(b.azimut!, heading).abs());
      if (angleComparison != 0) return angleComparison;
      return (a.jarakPusatM ?? double.infinity).compareTo(
        b.jarakPusatM ?? double.infinity,
      );
    });
    return matches;
  }
}
