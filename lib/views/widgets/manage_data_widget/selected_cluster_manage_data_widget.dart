import 'package:azimutree/data/models/cluster_model.dart';
import 'package:azimutree/data/models/plot_model.dart';
import 'package:azimutree/data/models/tree_model.dart';
import 'package:azimutree/data/notifiers/cluster_notifier.dart';
import 'package:azimutree/data/notifiers/notifiers.dart';
import 'package:azimutree/data/notifiers/plot_notifier.dart';
import 'package:azimutree/data/notifiers/tree_notifier.dart';
import 'package:azimutree/views/widgets/manage_data_widget/dialog_edit_cluster_widget.dart';
import 'package:azimutree/views/widgets/alert_dialog_widget/alert_confirmation_widget.dart';
import 'package:flutter/material.dart';

class SelectedClusterManageDataWidget extends StatelessWidget {
  final List<ClusterModel> clustersData;
  final List<PlotModel> plotData;
  final List<TreeModel> treeData;
  final ClusterNotifier clusterNotifier;
  final PlotNotifier plotNotifier;
  final TreeNotifier treeNotifier;

  const SelectedClusterManageDataWidget({
    super.key,
    this.clustersData = const [],
    this.plotData = const [],
    this.treeData = const [],
    required this.clusterNotifier,
    required this.plotNotifier,
    required this.treeNotifier,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: selectedDropdownClusterNotifier,
      builder: (context, selectedClusterCode, child) {
        ClusterModel? selectedCluster;
        int plotCount = 0;
        int treeCount = 0;
        double? clusterLat;
        double? clusterLon;
        String? coordinateNote;
        bool usedPlot1 = false;
        try {
          selectedCluster = clustersData.firstWhere(
            (c) => c.kodeCluster == selectedClusterCode,
          );
          final sel = selectedCluster;
          if (sel.id != null) {
            final plotsForCluster =
                plotData.where((plot) => plot.idCluster == sel.id).toList();

            plotCount = plotsForCluster.length;

            if (plotsForCluster.isNotEmpty) {
              // Prefer plot with kodePlot == 1 as the cluster center.
              final hasPlot1 = plotsForCluster.any((p) => p.kodePlot == 1);
              if (hasPlot1) {
                final plot1 = plotsForCluster.firstWhere(
                  (p) => p.kodePlot == 1,
                );
                clusterLat = plot1.latitude;
                clusterLon = plot1.longitude;
                coordinateNote = '(plot 1)';
                usedPlot1 = true;
              } else {
                // Calculate centroid from available plot coordinates in the cluster.
                final plotsWithCoords = plotsForCluster;
                if (plotsWithCoords.isNotEmpty) {
                  final latSum = plotsWithCoords.fold<double>(
                    0.0,
                    (sum, p) => sum + p.latitude,
                  );
                  final lonSum = plotsWithCoords.fold<double>(
                    0.0,
                    (sum, p) => sum + p.longitude,
                  );
                  clusterLat = latSum / plotsWithCoords.length;
                  clusterLon = lonSum / plotsWithCoords.length;
                  coordinateNote = '(centroid)';
                } else {
                  // No plot 1 and no usable coordinates to compute centroid.
                  clusterLat = null;
                  clusterLon = null;
                  coordinateNote = 'tidak ada plot satu';
                }
              }
            }

            final clusterPlotIds =
                plotsForCluster
                    .where((plot) => plot.id != null)
                    .map((plot) => plot.id!)
                    .toSet();
            treeCount =
                treeData
                    .where((tree) => clusterPlotIds.contains(tree.plotId))
                    .length;
          }
        } catch (_) {
          selectedCluster = null; // kalau tidak ketemu
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color.fromARGB(240, 180, 216, 187),
            borderRadius: BorderRadius.circular(8),
          ),
          child:
              selectedCluster == null
                  ? const Text(
                    "Tidak ada data / belum ada klaster dipilih",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  )
                  : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Data Cluster",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Table(
                        columnWidths: const {
                          0: FlexColumnWidth(2),
                          1: FlexColumnWidth(3),
                        },
                        children: [
                          _row("Kode Klaster", selectedCluster.kodeCluster),
                          _row("Pengukur", selectedCluster.namaPengukur ?? "-"),
                          _row("Jumlah Plot", plotCount.toString()),
                          _row("Jumlah Pohon", treeCount.toString()),
                          _row(
                            "Pusat Klaster",
                            usedPlot1
                                ? 'Plot 1'
                                : (clusterLat != null
                                    ? 'Generated Centroid'
                                    : (coordinateNote ?? '-')),
                          ),
                          _row(
                            "Latitude",
                            clusterLat != null
                                ? clusterLat.toStringAsFixed(6)
                                : '-',
                          ),
                          _row(
                            "Longitude",
                            clusterLon != null
                                ? clusterLon.toStringAsFixed(6)
                                : '-',
                          ),
                          _row(
                            "Tanggal Pengukuran",
                            selectedCluster.tanggalPengukuran != null
                                ? _formatDate(
                                  selectedCluster.tanggalPengukuran!,
                                )
                                : "-",
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          IconButton(
                            tooltip: "Edit klaster",
                            onPressed:
                                () => _editCluster(context, selectedCluster!),
                            icon: const Icon(Icons.edit),
                          ),
                          IconButton(
                            tooltip: "Hapus klaster",
                            onPressed:
                                () => _deleteCluster(context, selectedCluster!),
                            icon: const Icon(
                              Icons.delete,
                              color: Color.fromARGB(255, 98, 32, 32),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
        );
      },
    );
  }

  /// Row helper biar kodenya ga berantakan
  TableRow _row(String label, String value) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 0),
          child: Text(label),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 0),
          child: Text(": $value"),
        ),
      ],
    );
  }

  /// Format tanggal jadi dd-mm-yyyy
  String _formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final y = date.year.toString();
    return "$d-$m-$y";
  }

  Future<void> _editCluster(BuildContext context, ClusterModel cluster) async {
    final result = await showDialog<ClusterModel>(
      context: context,
      builder:
          (_) => DialogEditClusterWidget(
            cluster: cluster,
            clusterNotifier: clusterNotifier,
          ),
    );

    if (result != null && cluster.id == result.id) {
      selectedDropdownClusterNotifier.value = result.kodeCluster;
    }
  }

  Future<void> _deleteCluster(
    BuildContext context,
    ClusterModel cluster,
  ) async {
    if (cluster.id == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertConfirmationWidget(
            title: 'Hapus klaster?',
            message: 'Semua plot dan pohon di klaster ini akan ikut terhapus.',
            confirmText: 'Hapus',
            cancelText: 'Batal',
          ),
    );

    if (confirm != true) return;
    await clusterNotifier.deleteCluster(cluster.id!);
    await plotNotifier.loadPlots();
    await treeNotifier.loadTrees();

    final clusters = clusterNotifier.value;
    selectedDropdownClusterNotifier.value =
        clusters.isNotEmpty ? clusters.first.kodeCluster : null;

    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Klaster dihapus")));
    }
  }
}
