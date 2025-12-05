import 'package:azimutree/data/models/cluster_model.dart';
import 'package:azimutree/data/models/plot_model.dart';
import 'package:azimutree/data/models/tree_model.dart';
import 'package:azimutree/data/notifiers/cluster_notifier.dart';
import 'package:azimutree/data/notifiers/notifiers.dart';
import 'package:azimutree/data/notifiers/plot_notifier.dart';
import 'package:azimutree/data/notifiers/tree_notifier.dart';
import 'package:azimutree/views/widgets/manage_data_widget/dialog_edit_cluster_widget.dart';
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
        if (selectedClusterCode != null && clustersData.isNotEmpty) {
          try {
            selectedCluster = clustersData.firstWhere(
              (c) => c.kodeCluster == selectedClusterCode,
            );
            if (selectedCluster.id != null) {
              final plotsForCluster = plotData
                  .where((plot) => plot.idCluster == selectedCluster?.id)
                  .toList();

              plotCount = plotsForCluster.length;

              if (plotsForCluster.isNotEmpty) {
                final plot1 = plotsForCluster.firstWhere(
                  (p) => p.kodePlot == 1,
                  orElse: () => plotsForCluster.first,
                );

                // Kalau plot 1 ada: pakai koordinatnya; kalau tidak, pakai rata-rata plot yang ada.
                clusterLat = plot1.latitude;
                clusterLon = plot1.longitude;

                if (plot1.kodePlot != 1 && plotsForCluster.length > 1) {
                  clusterLat =
                      plotsForCluster.map((p) => p.latitude).reduce((a, b) => a + b) /
                      plotsForCluster.length;
                  clusterLon =
                      plotsForCluster.map((p) => p.longitude).reduce((a, b) => a + b) /
                      plotsForCluster.length;
                }
              }

              final clusterPlotIds =
                  plotsForCluster.where((plot) => plot.id != null).map((plot) => plot.id!).toSet();
              treeCount =
                  treeData.where((tree) => clusterPlotIds.contains(tree.plotId)).length;
            }
          } catch (_) {
            selectedCluster = null; // kalau tidak ketemu
          }
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
                          _coordinateRow(clusterLat, clusterLon),
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
                            onPressed: () => _editCluster(context, selectedCluster!),
                            icon: const Icon(Icons.edit),
                          ),
                          IconButton(
                            tooltip: "Hapus klaster",
                            onPressed: () => _deleteCluster(context, selectedCluster!),
                            icon: const Icon(Icons.delete, color: Colors.redAccent),
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

  TableRow _coordinateRow(double? lat, double? lon) {
    String value;
    String tooltip;
    if (lat != null && lon != null) {
      value = "${lat.toStringAsFixed(6)}, ${lon.toStringAsFixed(6)}";
      tooltip =
          "Koordinat klaster diambil dari plot 1 jika ada, atau rata-rata plot yang tersedia.";
    } else {
      value = "-";
      tooltip = "Belum ada plot, koordinat klaster belum tersedia.";
    }

    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 0),
          child: Text("Koordinat"),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 0),
          child: Tooltip(
            message: tooltip,
            child: Text(": $value"),
          ),
        ),
      ],
    );
  }

  Future<void> _editCluster(BuildContext context, ClusterModel cluster) async {
    final result = await showDialog<ClusterModel>(
      context: context,
      builder: (_) => DialogEditClusterWidget(
        cluster: cluster,
        clusterNotifier: clusterNotifier,
      ),
    );

    if (result != null && cluster.id == result.id) {
      selectedDropdownClusterNotifier.value = result.kodeCluster;
    }
  }

  Future<void> _deleteCluster(BuildContext context, ClusterModel cluster) async {
    if (cluster.id == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Hapus klaster?"),
        content: const Text("Semua plot dan pohon di klaster ini akan ikut terhapus."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Hapus"),
          ),
        ],
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Klaster dihapus")),
      );
    }
  }
}
