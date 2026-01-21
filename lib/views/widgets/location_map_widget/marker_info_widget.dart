import 'package:flutter/material.dart';
import 'package:azimutree/data/notifiers/notifiers.dart';

import 'package:azimutree/data/models/tree_model.dart';
import 'package:azimutree/data/models/plot_model.dart';

class MarkerInfoWidget extends StatelessWidget {
  const MarkerInfoWidget({super.key});

  Widget _cardForTree(TreeModel tree) {
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
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: () {
                selectedTreeNotifier.value = null;
                selectedMarkerScreenOffsetNotifier.value = null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _cardForPlot(PlotModel plot) {
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
                  Text(
                    'Cluster ${plot.idCluster}',
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
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
            return _cardForTree(tree);
          },
        ),
        ValueListenableBuilder<PlotModel?>(
          valueListenable: selectedPlotNotifier,
          builder: (context, plot, child) {
            if (plot == null) return const SizedBox.shrink();
            return _cardForPlot(plot);
          },
        ),
      ],
    );
  }
}
