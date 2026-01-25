import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:azimutree/data/notifiers/notifiers.dart';
import 'package:azimutree/data/database/tree_dao.dart';

import 'package:azimutree/data/models/tree_model.dart';
import 'package:azimutree/data/models/plot_model.dart';
import 'package:azimutree/data/models/cluster_model.dart';

class MarkerInfoWidget extends StatelessWidget {
  const MarkerInfoWidget({super.key});

  double _degrees(double rad) => rad * 180.0 / math.pi;

  double _haversineDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    // returns distance in meters
    const R = 6371000; // Earth radius meters
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRad(lat1)) *
            math.cos(_toRad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c;
  }

  double _toRad(double deg) => deg * math.pi / 180.0;

  double? _posLat(dynamic p) {
    if (p == null) return null;
    if (p is List && p.length >= 2) return (p[1] as num).toDouble();
    try {
      final v = (p.latitude as num?)?.toDouble();
      if (v != null) return v;
    } catch (_) {}
    try {
      final v = (p.lat as num?)?.toDouble();
      if (v != null) return v;
    } catch (_) {}
    try {
      final v = (p['latitude'] as num?)?.toDouble();
      if (v != null) return v;
    } catch (_) {}
    try {
      final v = (p['lat'] as num?)?.toDouble();
      if (v != null) return v;
    } catch (_) {}
    return null;
  }

  double? _posLng(dynamic p) {
    if (p == null) return null;
    if (p is List && p.length >= 2) return (p[0] as num).toDouble();
    try {
      final v = (p.longitude as num?)?.toDouble();
      if (v != null) return v;
    } catch (_) {}
    try {
      final v = (p.lng as num?)?.toDouble();
      if (v != null) return v;
    } catch (_) {}
    try {
      final v = (p['longitude'] as num?)?.toDouble();
      if (v != null) return v;
    } catch (_) {}
    try {
      final v = (p['lon'] as num?)?.toDouble();
      if (v != null) return v;
    } catch (_) {}
    return null;
  }

  double _computeBearing(double lat1, double lon1, double lat2, double lon2) {
    final y = math.sin(_toRad(lon2 - lon1)) * math.cos(_toRad(lat2));
    final x =
        math.cos(_toRad(lat1)) * math.sin(_toRad(lat2)) -
        math.sin(_toRad(lat1)) *
            math.cos(_toRad(lat2)) *
            math.cos(_toRad(lon2 - lon1));
    final brng = math.atan2(y, x);
    final deg = (_degrees(brng) + 360) % 360;
    return deg;
  }

  Widget _cardForTree(TreeModel tree, PlotModel? plot, ClusterModel? cluster) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 44.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              tree.namaPohon ?? 'Pohon #${tree.kodePohon}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (tree.namaIlmiah != null)
                              Text(
                                tree.namaIlmiah!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            const SizedBox(height: 4),
                            if (plot != null)
                              Text(
                                'Plot ${plot.kodePlot}',
                                style: const TextStyle(fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            if (cluster != null)
                              Text(
                                'Cluster ${cluster.kodeCluster}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            // Inspection: show bearing and distance to user when enabled
                            ValueListenableBuilder<bool>(
                              valueListenable:
                                  isInspectionWorkflowEnabledNotifier,
                              builder: (context, enabled, child) {
                                if (!enabled) return const SizedBox.shrink();
                                return ValueListenableBuilder<dynamic>(
                                  valueListenable: userLocationNotifier,
                                  builder: (context, userPos, child) {
                                    if (userPos == null ||
                                        tree.latitude == null ||
                                        tree.longitude == null) {
                                      return const SizedBox.shrink();
                                    }
                                    final fromLat = _posLat(userPos);
                                    final fromLng = _posLng(userPos);
                                    final toLat = tree.latitude!;
                                    final toLng = tree.longitude!;
                                    if (fromLat == null || fromLng == null) {
                                      return const SizedBox.shrink();
                                    }
                                    final bearing =
                                        _computeBearing(
                                          fromLat,
                                          fromLng,
                                          toLat,
                                          toLng,
                                        ).round();
                                    final distanceMeters = _haversineDistance(
                                      fromLat,
                                      fromLng,
                                      toLat,
                                      toLng,
                                    );
                                    final distText =
                                        (distanceMeters < 1000)
                                            ? '${distanceMeters.round()} m'
                                            : '${(distanceMeters / 1000).toStringAsFixed(2)} km';
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 6.0),
                                      child: Text(
                                        'Arah: $bearing° • Jarak: $distText',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Spacer(),
                    ValueListenableBuilder<bool>(
                      valueListenable: isInspectionWorkflowEnabledNotifier,
                      builder: (context, workflowEnabled, child) {
                        if (!workflowEnabled) return const SizedBox.shrink();
                        return ValueListenableBuilder<Set<int>>(
                          valueListenable: inspectedTreeIdsNotifier,
                          builder: (context, inspectedSet, child) {
                            final inspected = inspectedSet.contains(tree.id);
                            return ConstrainedBox(
                              constraints: const BoxConstraints(minWidth: 72),
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  elevation: 0,
                                  backgroundColor:
                                      inspected ? Colors.green : Colors.orange,
                                  foregroundColor: Color(0xFF1F4226),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 8,
                                  ),
                                ),
                                onPressed: () async {
                                  final setCopy = Set<int>.from(inspectedSet);
                                  if (inspected) {
                                    setCopy.remove(tree.id);
                                  } else {
                                    if (tree.id != null) setCopy.add(tree.id!);
                                  }
                                  inspectedTreeIdsNotifier.value = setCopy;
                                  // Persist the inspected flag to DB for this tree
                                  try {
                                    if (tree.id != null) {
                                      await TreeDao.setInspectedForTree(
                                        tree.id!,
                                        setCopy.contains(tree.id),
                                      );
                                    }
                                  } catch (_) {}
                                },
                                icon: Icon(
                                  inspected ? Icons.check : Icons.checklist,
                                  size: 16,
                                ),
                                label: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(inspected ? 'Done' : 'Mark'),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            top: -8,
            right: 8,
            child: SizedBox(
              width: 44,
              height: 44,
              child: Material(
                color: Colors.transparent,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () {
                    selectedTreeNotifier.value = null;
                    selectedMarkerScreenOffsetNotifier.value = null;
                    selectedTreePlotNotifier.value = null;
                    selectedTreeClusterNotifier.value = null;
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardForPlot(PlotModel plot, ClusterModel? cluster) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Plot ${plot.kodePlot}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      if (cluster != null)
                        Text(
                          'Cluster ${cluster.kodeCluster}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      ValueListenableBuilder<bool>(
                        valueListenable: isInspectionWorkflowEnabledNotifier,
                        builder: (context, enabled, child) {
                          if (!enabled) return const SizedBox.shrink();
                          return ValueListenableBuilder<dynamic>(
                            valueListenable: userLocationNotifier,
                            builder: (context, userPos, child) {
                              if (userPos == null) {
                                return const SizedBox.shrink();
                              }
                              final fromLat = _posLat(userPos);
                              final fromLng = _posLng(userPos);
                              final toLat = plot.latitude;
                              final toLng = plot.longitude;
                              if (fromLat == null || fromLng == null) {
                                return const SizedBox.shrink();
                              }
                              final bearing =
                                  _computeBearing(
                                    fromLat,
                                    fromLng,
                                    toLat,
                                    toLng,
                                  ).round();
                              final distanceMeters = _haversineDistance(
                                fromLat,
                                fromLng,
                                toLat,
                                toLng,
                              );
                              final distText =
                                  (distanceMeters < 1000)
                                      ? '${distanceMeters.round()} m'
                                      : '${(distanceMeters / 1000).toStringAsFixed(2)} km';
                              return Padding(
                                padding: const EdgeInsets.only(top: 6.0),
                                child: Text(
                                  'Arah: $bearing° • Jarak: $distText',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black54,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: -8,
            right: 8,
            child: SizedBox(
              width: 44,
              height: 44,
              child: Material(
                color: Colors.transparent,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () {
                    selectedPlotNotifier.value = null;
                    selectedMarkerScreenOffsetNotifier.value = null;
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardForCentroid(ClusterModel cluster) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Centroid',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        'Cluster ${cluster.kodeCluster}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: -8,
            right: 8,
            child: SizedBox(
              width: 44,
              height: 44,
              child: Material(
                color: Colors.transparent,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () {
                    selectedCentroidNotifier.value = null;
                    selectedMarkerScreenOffsetNotifier.value = null;
                    selectedPlotClusterNotifier.value = null;
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isMarkerInfoOnSelectNotifier,
      builder: (context, enabled, child) {
        if (!enabled) return const SizedBox.shrink();
        return LayoutBuilder(
          builder: (context, constraints) {
            // Limit card width so it doesn't become too narrow and wrap badly on
            // small devices. Use up to ~92% of available width and a minimum
            // that matches the legend widget's `minWidth` so they can be
            // visually similar without clipping internal content.
            final maxCardWidth = math.max(180.0, constraints.maxWidth * 0.92);
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ValueListenableBuilder<TreeModel?>(
                  valueListenable: selectedTreeNotifier,
                  builder: (context, tree, child) {
                    if (tree == null) return const SizedBox.shrink();
                    return ValueListenableBuilder<PlotModel?>(
                      valueListenable: selectedTreePlotNotifier,
                      builder: (context, plot, child) {
                        return ValueListenableBuilder<ClusterModel?>(
                          valueListenable: selectedTreeClusterNotifier,
                          builder: (context, cluster, child) {
                            return ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: maxCardWidth,
                              ),
                              child: _cardForTree(tree, plot, cluster),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
                ValueListenableBuilder<PlotModel?>(
                  valueListenable: selectedPlotNotifier,
                  builder: (context, plot, child) {
                    if (plot == null) return const SizedBox.shrink();
                    return ValueListenableBuilder<ClusterModel?>(
                      valueListenable: selectedPlotClusterNotifier,
                      builder: (context, cluster, child) {
                        return ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: maxCardWidth),
                          child: _cardForPlot(plot, cluster),
                        );
                      },
                    );
                  },
                ),
                // Centroid marker info: shown when a generated centroid is selected.
                ValueListenableBuilder<ClusterModel?>(
                  valueListenable: selectedCentroidNotifier,
                  builder: (context, cluster, child) {
                    if (cluster == null) return const SizedBox.shrink();
                    return ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxCardWidth),
                      child: _cardForCentroid(cluster),
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
}
