import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:azimutree/data/notifiers/notifiers.dart';

import 'package:azimutree/data/models/tree_model.dart';
import 'package:azimutree/data/models/plot_model.dart';
import 'package:azimutree/data/models/cluster_model.dart';

class MarkerInfoWidget extends StatelessWidget {
  const MarkerInfoWidget({super.key});

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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            tree.namaPohon ?? 'Pohon #${tree.kodePohon}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
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
                        ],
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
                                onPressed: () {
                                  final setCopy = Set<int>.from(inspectedSet);
                                  if (inspected) {
                                    setCopy.remove(tree.id);
                                  } else {
                                    if (tree.id != null) setCopy.add(tree.id!);
                                  }
                                  inspectedTreeIdsNotifier.value = setCopy;
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
            top: 6,
            right: 6,
            child: SizedBox(
              width: 36,
              height: 36,
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
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 6,
            right: 6,
            child: SizedBox(
              width: 36,
              height: 36,
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

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isMarkerInfoOnSelectNotifier,
      builder: (context, enabled, child) {
        if (!enabled) return const SizedBox.shrink();
        return LayoutBuilder(
          builder: (context, constraints) {
            // Limit card width so it doesn't become too narrow and wrap badly on
            // small devices. Use up to 85% of available width.
            final maxCardWidth = math.max(200.0, constraints.maxWidth * 0.85);
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
              ],
            );
          },
        );
      },
    );
  }
}
