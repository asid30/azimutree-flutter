import 'package:azimutree/data/models/plot_model.dart';
import 'package:azimutree/data/models/tree_model.dart';
import 'package:azimutree/data/models/cluster_model.dart';
import 'package:azimutree/data/notifiers/plot_notifier.dart';
import 'package:azimutree/data/notifiers/tree_notifier.dart';
import 'package:azimutree/views/widgets/manage_data_widget/dialog_edit_plot_widget.dart';
import 'package:azimutree/views/widgets/alert_dialog_widget/alert_confirmation_widget.dart';
import 'package:azimutree/views/widgets/manage_data_widget/tree_plot_manage_data_widget.dart';
import 'package:flutter/material.dart';

class PlotClusterManageDataWidget extends StatefulWidget {
  final List<PlotModel> plotData;
  final List<TreeModel> treeData;
  final List<ClusterModel> clustersData;
  final PlotNotifier plotNotifier;
  final TreeNotifier treeNotifier;
  final bool isEmpty; // true = klaster ini tidak punya plot

  const PlotClusterManageDataWidget({
    super.key,
    required this.plotData,
    required this.treeData,
    required this.clustersData,
    required this.plotNotifier,
    required this.treeNotifier,
    this.isEmpty = false,
  });

  @override
  State<PlotClusterManageDataWidget> createState() =>
      _PlotClusterManageDataWidgetState();
}

class _PlotClusterManageDataWidgetState
    extends State<PlotClusterManageDataWidget> {
  String? _expandedKey;

  String _tileKey(PlotModel plot) =>
      plot.id != null ? "id_${plot.id}" : "kode_${plot.kodePlot}";

  @override
  Widget build(BuildContext context) {
    // Kalau dari parent sudah dibilang klaster ini tidak punya plot,
    // langsung tampilkan pesan dan jangan render list plot sama sekali.
    if (widget.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: const Color.fromARGB(240, 180, 216, 187),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Data Plot",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text("Tidak ada data plot untuk klaster ini"),
          ],
        ),
      );
    }

    // Fallback: kalau isEmpty == false tapi plotData kosong (just in case)
    if (widget.plotData.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: const Color.fromARGB(240, 180, 216, 187),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Data Plot",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text("Tidak ada data plot untuk klaster ini"),
          ],
        ),
      );
    }

    // Normal case: ada plot untuk klaster ini
    final sortedPlotData = [...widget.plotData]
      ..sort((a, b) => a.kodePlot.compareTo(b.kodePlot));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color.fromARGB(240, 180, 216, 187),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Data Plot",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          for (final plot in sortedPlotData) ...[
            Builder(
              builder: (context) {
                final tileKey = _tileKey(plot);
                final isExpanded = _expandedKey == tileKey;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  color: const Color.fromARGB(239, 188, 228, 196),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                "Plot ${plot.kodePlot}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit),
                              tooltip: "Edit plot",
                              onPressed:
                                  plot.id != null
                                      ? () => _editPlot(context, plot)
                                      : null,
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: Color.fromARGB(255, 98, 32, 32),
                              ),
                              tooltip: "Hapus plot",
                              onPressed:
                                  plot.id != null
                                      ? () => _deletePlot(context, plot)
                                      : null,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Theme(
                          data: ThemeData().copyWith(
                            dividerColor: Colors.transparent,
                          ),
                          child: ExpansionTile(
                            key: ValueKey("${isExpanded}_$tileKey"),
                            initiallyExpanded: isExpanded,
                            onExpansionChanged: (expanded) {
                              setState(() {
                                if (expanded) {
                                  _expandedKey = tileKey;
                                } else if (_expandedKey == tileKey) {
                                  _expandedKey = null;
                                }
                              });
                            },
                            tilePadding: EdgeInsets.zero,
                            title: const Text(
                              "Detail plot",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Table(
                              columnWidths: const {
                                0: FlexColumnWidth(2),
                                1: FlexColumnWidth(3),
                              },
                              children: [
                                _row(
                                  "Latitude",
                                  plot.latitude.toStringAsFixed(6),
                                ),
                                _row(
                                  "Longitude",
                                  plot.longitude.toStringAsFixed(6),
                                ),
                                _row(
                                  "Altitude",
                                  plot.altitude != null
                                      ? "${plot.altitude} m"
                                      : "-",
                                ),
                                _row(
                                  "Jumlah Pohon",
                                  plot.id != null
                                      ? widget.treeData
                                          .where(
                                            (tree) => tree.plotId == plot.id,
                                          )
                                          .length
                                          .toString()
                                      : "0",
                                ),
                              ],
                            ),
                            children: [
                              const Divider(height: 1),
                              if (plot.id != null)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8.0,
                                  ),
                                  child: TreePlotManageDataWidget(
                                    plotId: plot.id!,
                                    treeData: widget.treeData,
                                    plots: widget.plotData,
                                    clusters: widget.clustersData,
                                    treeNotifier: widget.treeNotifier,
                                  ),
                                )
                              else
                                const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text("ID plot tidak tersedia"),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

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

  Future<void> _editPlot(BuildContext context, PlotModel plot) async {
    final updated = await showDialog<PlotModel>(
      context: context,
      builder:
          (_) => DialogEditPlotWidget(
            plot: plot,
            clusters: widget.clustersData,
            plotNotifier: widget.plotNotifier,
          ),
    );

    if (updated != null && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Plot diperbarui")));
    }
  }

  Future<void> _deletePlot(BuildContext context, PlotModel plot) async {
    if (plot.id == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertConfirmationWidget(
            title: 'Hapus plot?',
            message: 'Semua pohon di plot ini akan ikut terhapus.',
            confirmText: 'Hapus',
            cancelText: 'Batal',
          ),
    );

    if (confirm != true) return;
    await widget.plotNotifier.deletePlot(plot.id!);
    await widget.treeNotifier.loadTrees();

    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Plot dihapus")));
    }
  }
}
