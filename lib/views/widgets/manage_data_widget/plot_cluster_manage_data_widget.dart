import 'package:azimutree/data/models/plot_model.dart';
import 'package:azimutree/data/models/tree_model.dart';
import 'package:azimutree/data/models/cluster_model.dart';
import 'package:azimutree/data/notifiers/plot_notifier.dart';
import 'package:azimutree/data/notifiers/tree_notifier.dart';
import 'package:azimutree/views/widgets/manage_data_widget/dialog_edit_plot_widget.dart';
import 'package:azimutree/views/widgets/alert_dialog_widget/alert_confirmation_widget.dart';
import 'package:azimutree/views/widgets/manage_data_widget/tree_plot_manage_data_widget.dart';
import 'package:flutter/material.dart';
import 'package:azimutree/data/notifiers/notifiers.dart';

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
    extends State<PlotClusterManageDataWidget>
    with SingleTickerProviderStateMixin {
  String? _expandedKey;

  String _tileKey(PlotModel plot) =>
      plot.id != null ? "id_${plot.id}" : "kode_${plot.kodePlot}";

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isLightModeNotifier,
      builder: (context, isLightMode, child) {
        final isDark = !isLightMode;
        // Kalau dari parent sudah dibilang klaster ini tidak punya plot,
        // langsung tampilkan pesan dan jangan render list plot sama sekali.
        if (widget.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color:
                  isDark
                      ? const Color.fromARGB(255, 36, 67, 42)
                      : const Color.fromARGB(240, 180, 216, 187),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Data Plot",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : null,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Tidak ada data plot untuk klaster ini",
                  style: TextStyle(color: isDark ? Colors.white : null),
                ),
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
              color:
                  isDark
                      ? const Color.fromARGB(255, 36, 67, 42)
                      : const Color.fromARGB(240, 180, 216, 187),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Data Plot",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : null,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Tidak ada data plot untuk klaster ini",
                  style: TextStyle(color: isDark ? Colors.white : null),
                ),
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
            color:
                isDark
                    ? const Color.fromARGB(255, 36, 67, 42)
                    : const Color.fromARGB(240, 180, 216, 187),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Data Plot",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : null,
                ),
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
                      color:
                          isDark
                              ? const Color.fromARGB(255, 25, 48, 30)
                              : const Color.fromARGB(239, 188, 228, 196),
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
                                  child: Row(
                                    children: [
                                      Flexible(
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Flexible(
                                              child: Text(
                                                "Plot ${plot.kodePlot}",
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  color:
                                                      isDark
                                                          ? Colors.white
                                                          : null,
                                                ),
                                              ),
                                            ),
                                            if (plot.kodePlot == 1) ...[
                                              const SizedBox(width: 6),
                                              Icon(
                                                Icons.star,
                                                size: 18,
                                                color:
                                                    isDark
                                                        ? Colors.white
                                                        : const Color(
                                                          0xFF1F4226,
                                                        ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Theme(
                              data: ThemeData().copyWith(
                                dividerColor: const Color.fromARGB(
                                  0,
                                  255,
                                  255,
                                  255,
                                ),
                              ),
                              child: AnimatedSize(
                                duration: const Duration(milliseconds: 800),
                                curve: Curves.easeInOut,
                                alignment: Alignment.topCenter,
                                child: ExpansionTile(
                                  key: ValueKey("${isExpanded}_$tileKey"),
                                  maintainState: true,
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
                                  title: Text(
                                    "Detail plot",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: isDark ? Colors.white : null,
                                    ),
                                  ),
                                  subtitle: Table(
                                    columnWidths: const {
                                      0: FlexColumnWidth(2),
                                      1: FlexColumnWidth(3),
                                    },
                                    children: [
                                      _row(
                                        context,
                                        isDark,
                                        "Latitude",
                                        plot.latitude.toStringAsFixed(6),
                                      ),
                                      _row(
                                        context,
                                        isDark,
                                        "Longitude",
                                        plot.longitude.toStringAsFixed(6),
                                      ),
                                      _row(
                                        context,
                                        isDark,
                                        "Altitude",
                                        plot.altitude != null
                                            ? "${plot.altitude} m"
                                            : "-",
                                      ),
                                      _row(
                                        context,
                                        isDark,
                                        "Jumlah Pohon",
                                        plot.id != null
                                            ? widget.treeData
                                                .where(
                                                  (tree) =>
                                                      tree.plotId == plot.id,
                                                )
                                                .length
                                                .toString()
                                            : "0",
                                      ),
                                    ],
                                  ),
                                  // Ensure expansion icon is visible in dark mode
                                  iconColor: isDark ? Colors.white : null,
                                  collapsedIconColor:
                                      isDark ? Colors.white : null,
                                  children: [
                                    const Divider(
                                      height: 1,
                                      color: Colors.transparent,
                                    ),
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
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(
                                          "ID plot tidak tersedia",
                                          style: TextStyle(
                                            color: isDark ? Colors.white : null,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                IconButton(
                                  tooltip: "Edit plot",
                                  onPressed:
                                      plot.id != null
                                          ? () => _editPlot(context, plot)
                                          : null,
                                  icon: Icon(
                                    Icons.edit,
                                    color:
                                        isDark
                                            ? const Color.fromARGB(
                                              255,
                                              219,
                                              219,
                                              219,
                                            )
                                            : null,
                                  ),
                                ),
                                IconButton(
                                  tooltip: "Hapus plot",
                                  onPressed:
                                      plot.id != null
                                          ? () => _deletePlot(context, plot)
                                          : null,
                                  icon: Icon(
                                    Icons.delete,
                                    color:
                                        isDark
                                            ? const Color.fromARGB(
                                              255,
                                              215,
                                              83,
                                              83,
                                            )
                                            : const Color.fromARGB(
                                              255,
                                              98,
                                              32,
                                              32,
                                            ),
                                  ),
                                ),
                              ],
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
      },
    );
  }

  TableRow _row(BuildContext context, bool isDark, String label, String value) {
    final style = TextStyle(color: isDark ? Colors.white : null);

    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 0),
          child: Text(label, style: style),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 0),
          child: Text(": $value", style: style),
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
