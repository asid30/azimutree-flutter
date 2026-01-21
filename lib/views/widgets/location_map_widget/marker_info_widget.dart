import 'package:flutter/material.dart';
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
      child: Padding(
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
                    tree.namaPohon ?? 'Pohon #${tree.kodePohon}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  if (tree.namaIlmiah != null)
                    Text(
                      tree.namaIlmiah!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  const SizedBox(height: 4),
                  if (plot != null)
                    Text(
                      'Plot ${plot.kodePlot}',
                      style: const TextStyle(fontSize: 12),
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
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: () {
                selectedTreeNotifier.value = null;
                selectedMarkerScreenOffsetNotifier.value = null;
                selectedTreePlotNotifier.value = null;
                selectedTreeClusterNotifier.value = null;
              },
            ),
            const SizedBox(width: 6),
            // Mark done / Re-add button (only enabled when inspection workflow active)
            ValueListenableBuilder<bool>(
              valueListenable: isInspectionWorkflowEnabledNotifier,
              builder: (context, workflowEnabled, child) {
                if (!workflowEnabled) return const SizedBox.shrink();
                return ValueListenableBuilder<Set<int>>(
                  valueListenable: inspectedTreeIdsNotifier,
                  builder: (context, inspectedSet, child) {
                    final inspected = inspectedSet.contains(tree.id);
                    return ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor:
                            inspected ? Colors.green : Colors.orange,
                        foregroundColor: Color(0xFF1F4226),
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
                      label: Text(inspected ? 'Done' : 'Mark'),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _cardForPlot(PlotModel plot, ClusterModel? cluster) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
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
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: () {
                selectedPlotNotifier.value = null;
                selectedMarkerScreenOffsetNotifier.value = null;
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                    return _cardForTree(tree, plot, cluster);
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
                return _cardForPlot(plot, cluster);
              },
            );
          },
        ),
      ],
    );
  }
}
