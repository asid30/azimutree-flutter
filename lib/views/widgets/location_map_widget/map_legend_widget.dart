import 'package:flutter/material.dart';
import 'package:azimutree/views/widgets/location_map_widget/mapbox_widget.dart';
import 'package:azimutree/data/notifiers/notifiers.dart';

class MapLegendWidget extends StatelessWidget {
  const MapLegendWidget({super.key});

  Widget _legendItem({
    required Color fill,
    Color? stroke,
    required String label,
    double size = 14,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: fill,
            shape: BoxShape.circle,
            border:
                stroke != null ? Border.all(color: stroke, width: 1.2) : null,
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isLightModeNotifier,
      builder: (context, isLightMode, _) {
        final isDark = !isLightMode;
        final bgColor =
            isDark
                ? Colors.black.withAlpha((0.6 * 255).round())
                : Colors.white.withAlpha((0.95 * 255).round());
        final textColor = isDark ? Colors.white : Colors.black87;

        return Material(
          color: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(minWidth: 180),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha((0.15 * 255).round()),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: DefaultTextStyle(
              style: TextStyle(color: textColor, fontSize: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _legendItem(
                    fill: Color(kPlotColor),
                    stroke: Color(kPlotStrokeColor),
                    label: 'Plot',
                  ),
                  const SizedBox(height: 6),
                  // Centroid marker (generated for clusters without Plot 1)
                  _legendItem(
                    fill: Color(kCentroidColor),
                    stroke: Colors.white,
                    label: 'Centroid',
                  ),
                  const SizedBox(height: 6),
                  _legendItem(
                    fill: Color(kTreeColor),
                    stroke: Color(kTreeStrokeColor),
                    label: 'Tree',
                  ),
                  const SizedBox(height: 6),
                  // Inspection workflow: show Done marker color when enabled
                  ValueListenableBuilder<bool>(
                    valueListenable: isInspectionWorkflowEnabledNotifier,
                    builder: (context, enabled, child) {
                      if (!enabled) return const SizedBox.shrink();
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _legendItem(
                            fill: Color(kTreeInspectedColor),
                            stroke: Colors.white,
                            label: 'Inspected (Done)',
                          ),
                          const SizedBox(height: 6),
                        ],
                      );
                    },
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 18,
                        height: 3,
                        color: Color(kPlotConnectionColor),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Koneksi Plot→Plot',
                        style: TextStyle(color: textColor, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 18,
                        height: 3,
                        color: Color(kConnectionColor),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Koneksi Plot→Pohon',
                        style: TextStyle(color: textColor, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  _legendItem(
                    fill: const Color(0xFFFF5252),
                    stroke: Colors.white,
                    label: 'Hasil Pencarian',
                    size: 12,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
