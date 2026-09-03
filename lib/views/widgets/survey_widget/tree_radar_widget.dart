import 'dart:async';
import 'dart:math' as math;

import 'package:azimutree/data/models/tree_model.dart';
import 'package:azimutree/services/compass_navigation_service.dart';
import 'package:azimutree/services/survey_ui_constants.dart';
import 'package:flutter/material.dart';

class TreeRadarWidget extends StatefulWidget {
  const TreeRadarWidget({
    super.key,
    required this.trees,
    required this.heading,
    required this.isDark,
    this.plotCode = 1,
    this.compassEnabled = true,
    this.tolerance = compassAlignmentTolerance,
  });

  final List<TreeModel> trees;
  final double? heading;
  final bool isDark;
  final int plotCode;
  final bool compassEnabled;
  final double tolerance;

  @override
  State<TreeRadarWidget> createState() => _TreeRadarWidgetState();
}

class _TreeRadarWidgetState extends State<TreeRadarWidget> {
  Timer? _timer;
  Offset? _down;
  int? _selectedTree;
  bool _selectedCenter = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _pointerDown(PointerDownEvent event, Size size) {
    _down = event.localPosition;
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 180), () {
      if (!mounted || _down == null) return;
      final hit = _hitTest(_down!, size);
      setState(() {
        _selectedTree = hit.$1;
        _selectedCenter = hit.$2;
      });
    });
  }

  void _pointerMove(PointerMoveEvent event) {
    if (_down != null && (event.localPosition - _down!).distance > 12) {
      _timer?.cancel();
      _down = null;
    }
  }

  (int?, bool) _hitTest(Offset tap, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 14;
    if ((tap - center).distance <= 18) return (null, true);
    int? closest;
    var closestDistance = 20.0;
    for (final tree in widget.trees) {
      final point = _treePoint(tree, center, radius);
      if (point == null) continue;
      final distance = (tap - point).distance;
      if (distance < closestDistance) {
        closestDistance = distance;
        closest = tree.id ?? tree.kodePohon;
      }
    }
    return (closest, false);
  }

  TreeModel? get _selectedTreeModel {
    for (final tree in widget.trees) {
      if ((tree.id ?? tree.kodePohon) == _selectedTree) return tree;
    }
    return null;
  }

  void _clear() {
    if (_selectedTree == null && !_selectedCenter) return;
    setState(() {
      _selectedTree = null;
      _selectedCenter = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tree = _selectedTreeModel;
    final info =
        _selectedCenter
            ? 'P${widget.plotCode}'
            : tree == null
            ? null
            : [
              'Pohon ${tree.kodePohon.toString().padLeft(3, '0')}',
              if (tree.namaPohon?.trim().isNotEmpty == true)
                tree.namaPohon!.trim(),
              if (tree.namaIlmiah?.trim().isNotEmpty == true)
                tree.namaIlmiah!.trim(),
            ].join(' · ');
    return TapRegion(
      onTapOutside: (_) => _clear(),
      child: Column(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child:
                info == null
                    ? const SizedBox.shrink()
                    : Container(
                      key: ValueKey(info),
                      constraints: const BoxConstraints(minHeight: 36),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1F4226),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        info,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
          ),
          AspectRatio(
            aspectRatio: 1,
            child: LayoutBuilder(
              builder: (_, constraints) {
                final size = Size(constraints.maxWidth, constraints.maxHeight);
                return Listener(
                  onPointerDown: (event) => _pointerDown(event, size),
                  onPointerMove: _pointerMove,
                  onPointerUp: (_) {
                    _timer?.cancel();
                    _down = null;
                  },
                  onPointerCancel: (_) {
                    _timer?.cancel();
                    _down = null;
                  },
                  child: Semantics(
                    label:
                        'Radar pohon berdasarkan azimuth dan jarak dari pusat plot',
                    child: CustomPaint(
                      painter: _TreeRadarPainter(
                        trees: widget.trees,
                        heading: widget.compassEnabled ? widget.heading : null,
                        tolerance: widget.tolerance,
                        isDark: widget.isDark,
                        selectedTree: _selectedTree,
                        selectedCenter: _selectedCenter,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

Offset? _treePoint(TreeModel tree, Offset center, double radius) {
  final azimuth = tree.azimut;
  final distance = tree.jarakPusatM;
  if (azimuth == null ||
      distance == null ||
      !azimuth.isFinite ||
      !distance.isFinite ||
      distance < 0) {
    return null;
  }
  final angle = (azimuth - 90) * math.pi / 180;
  final scaled =
      (distance / SurveyUiConstants.radarMaxDistanceM).clamp(0.0, 1.0) * radius;
  return Offset(
    center.dx + scaled * math.cos(angle),
    center.dy + scaled * math.sin(angle),
  );
}

class _TreeRadarPainter extends CustomPainter {
  const _TreeRadarPainter({
    required this.trees,
    required this.heading,
    required this.tolerance,
    required this.isDark,
    required this.selectedTree,
    required this.selectedCenter,
  });

  final List<TreeModel> trees;
  final double? heading;
  final double tolerance;
  final bool isDark;
  final int? selectedTree;
  final bool selectedCenter;

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
    final north = TextPainter(
      text: TextSpan(
        text: 'N',
        style: TextStyle(
          color: radarColor,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    north.paint(canvas, Offset(center.dx - north.width / 2, 0));

    if (heading != null) {
      final start = (heading! - tolerance - 90) * math.pi / 180;
      final sweep = tolerance * 2 * math.pi / 180;
      canvas.drawPath(
        Path()
          ..moveTo(center.dx, center.dy)
          ..arcTo(
            Rect.fromCircle(center: center, radius: radius),
            start,
            sweep,
            false,
          )
          ..close(),
        Paint()
          ..color = (isDark ? Colors.lightGreenAccent : const Color(0xFF1F4226))
              .withValues(alpha: isDark ? 0.22 : 0.28),
      );
    }

    for (final tree in trees) {
      final point = _treePoint(tree, center, radius);
      if (point == null) continue;
      final selected = (tree.id ?? tree.kodePohon) == selectedTree;
      if (selected) {
        canvas.drawCircle(
          point,
          10,
          Paint()
            ..color = Colors.white.withValues(alpha: 0.8)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3,
        );
      }
      canvas.drawCircle(
        point,
        selected ? 7 : 4,
        Paint()
          ..color = isDark ? Colors.lightGreenAccent : const Color(0xFF2E7D32),
      );
    }
    if (selectedCenter) {
      canvas.drawCircle(
        center,
        11,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }
    canvas.drawCircle(
      center,
      selectedCenter ? 7 : 5,
      Paint()..color = radarColor,
    );
  }

  @override
  bool shouldRepaint(covariant _TreeRadarPainter old) =>
      old.heading != heading ||
      old.tolerance != tolerance ||
      old.isDark != isDark ||
      old.trees != trees ||
      old.selectedTree != selectedTree ||
      old.selectedCenter != selectedCenter;
}
