import 'dart:math' as math;

import 'package:azimutree/data/models/tree_model.dart';
import 'package:azimutree/services/compass_navigation_service.dart';
import 'package:azimutree/services/survey_ui_constants.dart';
import 'package:flutter/material.dart';

class TreeRadarWidget extends StatelessWidget {
  const TreeRadarWidget({
    super.key,
    required this.trees,
    required this.heading,
    required this.isDark,
    this.tolerance = compassAlignmentTolerance,
  });

  final List<TreeModel> trees;
  final double? heading;
  final bool isDark;
  final double tolerance;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Radar pohon berdasarkan azimuth dan jarak dari pusat plot',
      child: AspectRatio(
        aspectRatio: 1,
        child: CustomPaint(
          painter: _TreeRadarPainter(
            trees: trees,
            heading: heading,
            tolerance: tolerance,
            isDark: isDark,
          ),
        ),
      ),
    );
  }
}

class _TreeRadarPainter extends CustomPainter {
  const _TreeRadarPainter({
    required this.trees,
    required this.heading,
    required this.tolerance,
    required this.isDark,
  });

  final List<TreeModel> trees;
  final double? heading;
  final double tolerance;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 14;
    final radarColor = isDark ? Colors.white : const Color(0xFF1F4226);
    final grid =
        Paint()
          ..color = radarColor.withValues(alpha: isDark ? 0.38 : 0.55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;
    final cone =
        Paint()
          ..color = (isDark ? Colors.lightGreenAccent : const Color(0xFF1F4226))
              .withValues(alpha: isDark ? 0.22 : 0.28)
          ..style = PaintingStyle.fill;
    final treePaint =
        Paint()
          ..color = isDark ? Colors.lightGreenAccent : const Color(0xFF2E7D32);

    for (final fraction in const [0.25, 0.5, 0.75, 1.0]) {
      canvas.drawCircle(center, radius * fraction, grid);
    }
    canvas.drawLine(
      Offset(center.dx, center.dy - radius),
      Offset(center.dx, center.dy + radius),
      grid,
    );
    canvas.drawLine(
      Offset(center.dx - radius, center.dy),
      Offset(center.dx + radius, center.dy),
      grid,
    );

    if (heading != null) {
      final start = (heading! - tolerance - 90) * math.pi / 180;
      final sweep = tolerance * 2 * math.pi / 180;
      final path =
          Path()
            ..moveTo(center.dx, center.dy)
            ..arcTo(
              Rect.fromCircle(center: center, radius: radius),
              start,
              sweep,
              false,
            )
            ..close();
      canvas.drawPath(path, cone);
    }

    for (final tree in trees) {
      final azimuth = tree.azimut;
      final distance = tree.jarakPusatM;
      if (azimuth == null ||
          distance == null ||
          !azimuth.isFinite ||
          !distance.isFinite ||
          distance < 0) {
        continue;
      }
      final angle = (azimuth - 90) * math.pi / 180;
      final scaledDistance =
          (distance / SurveyUiConstants.radarMaxDistanceM).clamp(0.0, 1.0) *
          radius;
      final point = Offset(
        center.dx + scaledDistance * math.cos(angle),
        center.dy + scaledDistance * math.sin(angle),
      );
      canvas.drawCircle(point, 4, treePaint);
    }
    canvas.drawCircle(center, 5, Paint()..color = radarColor);
  }

  @override
  bool shouldRepaint(covariant _TreeRadarPainter oldDelegate) =>
      oldDelegate.heading != heading ||
      oldDelegate.tolerance != tolerance ||
      oldDelegate.isDark != isDark ||
      oldDelegate.trees != trees;
}
