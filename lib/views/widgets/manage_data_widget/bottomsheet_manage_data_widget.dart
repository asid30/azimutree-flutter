import 'package:azimutree/data/models/plot_model.dart';
import 'package:azimutree/data/notifiers/cluster_notifier.dart';
import 'package:azimutree/data/notifiers/notifiers.dart';
import 'package:azimutree/data/notifiers/plot_notifier.dart';
import 'package:azimutree/data/notifiers/tree_notifier.dart';
import 'package:azimutree/services/debug_data_service.dart';
import 'package:azimutree/views/widgets/manage_data_widget/btm_button_manage_data_widget.dart';
import 'package:azimutree/views/widgets/manage_data_widget/dialog_add_cluster_widget.dart';
import 'package:azimutree/views/widgets/alert_dialog_widget/alert_warning_widget.dart';
import 'package:azimutree/views/widgets/manage_data_widget/dialog_add_plot_widget.dart';
import 'package:azimutree/views/widgets/manage_data_widget/dialog_add_tree_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class BottomsheetManageDataWidget extends StatefulWidget {
  final ClusterNotifier clusterNotifier;
  final PlotNotifier plotNotifier;
  final TreeNotifier treeNotifier;

  const BottomsheetManageDataWidget({
    super.key,
    required this.clusterNotifier,
    required this.plotNotifier,
    required this.treeNotifier,
  });

  @override
  State<BottomsheetManageDataWidget> createState() =>
      _BottomsheetManageDataWidgetState();
}

class _BottomsheetManageDataWidgetState
    extends State<BottomsheetManageDataWidget> {
  late final DraggableScrollableController _draggableScrollableController;
  final double _maxChildSize = 0.9;
  final double _minChildSize = 0.1;
  late final DebugDataService _debugDataService;
  @override
  void initState() {
    super.initState();
    _draggableScrollableController = DraggableScrollableController();
    _debugDataService = DebugDataService(
      clusterNotifier: widget.clusterNotifier,
      plotNotifier: widget.plotNotifier,
      treeNotifier: widget.treeNotifier,
    );
  }

  void _expandBottomSheet() {
    _draggableScrollableController.animateTo(
      _maxChildSize,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _draggableScrollableController.dispose();
    super.dispose();
  }

  void _showWarningNeedCluster({required String target}) {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder:
          (context) => AlertWarningWidget(
            warningMessage:
                "Anda harus menambahkan setidaknya satu klaster sebelum menambahkan $target.",
            backgroundColor: Colors.lightGreen.shade200,
          ),
    );
  }

  void _showWarningNeedPlot({required String target}) {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder:
          (context) => AlertWarningWidget(
            warningMessage:
                "Anda harus menambahkan setidaknya satu plot sebelum menambahkan $target.",
            backgroundColor: Colors.lightGreen.shade200,
      ),
    );
  }

  Future<void> _generateRandomData() async {
    try {
      await _debugDataService.seedRandomData();
      if (!mounted) return;
      await _showAlert(
        message: "Berhasil generate data random",
        backgroundColor: Colors.lightGreen.shade200,
      );
    } catch (e) {
      if (!mounted) return;
      await _showAlert(
        message: "Gagal generate data: $e",
        backgroundColor: Colors.red.shade200,
      );
    }
  }

  Future<void> _clearAllData() async {
    try {
      await _debugDataService.clearAllData();
      if (!mounted) return;
      await _showAlert(
        message: "Semua data berhasil dihapus",
        backgroundColor: Colors.lightGreen.shade200,
      );
    } catch (e) {
      if (!mounted) return;
      await _showAlert(
        message: "Gagal menghapus data: $e",
        backgroundColor: Colors.red.shade200,
      );
    }
  }

  Future<void> _showAlert({
    required String message,
    required Color backgroundColor,
  }) {
    return showDialog(
      barrierDismissible: false,
      context: context,
      builder:
          (_) => AlertWarningWidget(
            warningMessage: message,
            backgroundColor: backgroundColor,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      controller: _draggableScrollableController,
      initialChildSize: 0.1,
      minChildSize: _minChildSize,
      maxChildSize: _maxChildSize,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 205, 237, 211),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: ListView(
              controller: scrollController,
              children: [
                ListTile(
                  title: TextButton(
                    onPressed: _expandBottomSheet,
                    child: const Text(
                      'Menu Kelola Data',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const Text(
                  'Pilih salah satu opsi di bawah untuk mengelola data Anda. Impor data untuk menambahkan data dari file eksternal (sheet), ekspor data untuk menyimpan salinan data Anda, atau unduh template untuk format data (sheet) yang benar.',
                  textAlign: TextAlign.justify,
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 20,
                  runSpacing: 20,
                  alignment: WrapAlignment.spaceEvenly,
                  children: [
                    BtmButtonManageDataWidget(
                      label: "Ekspor Data",
                      icon: Icons.file_upload,
                      onPressed: () {
                        //? TODO: Handle export data action
                      },
                    ),
                    BtmButtonManageDataWidget(
                      label: "Impor Data",
                      icon: Icons.file_download,
                      onPressed: () {
                        //? TODO: Handle import data action
                      },
                    ),
                    BtmButtonManageDataWidget(
                      label: "Unduh Template",
                      icon: Icons.description,
                      onPressed: () {
                        //? TODO: Handle download template action
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text("Atau tambah data baru secara manual:"),
                ValueListenableBuilder(
                  valueListenable: widget.clusterNotifier,
                  builder: (context, clusterState, child) {
                    final hasCluster = clusterState.isNotEmpty;
                    return ValueListenableBuilder<String?>(
                      valueListenable: selectedDropdownClusterNotifier,
                      builder: (context, selectedClusterCode, _) {
                        final selectedCluster =
                            hasCluster
                                ? clusterState.firstWhere(
                                  (cluster) =>
                                      cluster.kodeCluster ==
                                      selectedClusterCode,
                                  orElse: () => clusterState.first,
                                )
                                : null;

                        return ValueListenableBuilder(
                          valueListenable: widget.plotNotifier,
                          builder: (context, plotState, child) {
                            final plotsForSelectedCluster =
                                selectedCluster == null
                                    ? <PlotModel>[]
                                    : plotState
                                        .where(
                                          (plot) =>
                                              plot.idCluster ==
                                              selectedCluster.id,
                                        )
                                        .toList();
                            final hasPlotForSelectedCluster =
                                plotsForSelectedCluster.isNotEmpty;

                            return Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              alignment: WrapAlignment.spaceEvenly,
                              children: [
                                //* K L A S T E R
                                BtmButtonManageDataWidget(
                                  label: "Klaster",
                                  minSize: const Size(100, 40),
                                  maxSize: const Size(150, 70),
                                  onPressed: () {
                                    showDialog(
                                      barrierDismissible: false,
                                      context: context,
                                      builder:
                                          (context) => DialogAddClusterWidget(
                                            clusterNotifier:
                                                widget.clusterNotifier,
                                          ),
                                    );
                                  },
                                ),
                                //* P L O T
                                BtmButtonManageDataWidget(
                                  label: "Plot",
                                  minSize: const Size(100, 40),
                                  maxSize: const Size(150, 70),
                                  // kalau kamu mau beda warna ketika belum ada klaster:
                                  isEnabled: hasCluster,
                                  onPressed: () {
                                    if (!hasCluster) {
                                      _showWarningNeedCluster(target: "plot");
                                      return;
                                    }

                                    showDialog(
                                      barrierDismissible: false,
                                      context: context,
                                      builder:
                                          (context) => DialogAddPlotWidget(
                                            plotNotifier: widget.plotNotifier,
                                            clusters: clusterState,
                                          ),
                                    );
                                  },
                                ),
                                //* P O H O N
                                BtmButtonManageDataWidget(
                                  label: "Pohon",
                                  minSize: const Size(100, 40),
                                  maxSize: const Size(150, 70),
                                  isEnabled: hasPlotForSelectedCluster,
                                  onPressed: () {
                                    if (!hasPlotForSelectedCluster) {
                                      _showWarningNeedPlot(target: "pohon");
                                      return;
                                    }

                                    showDialog(
                                      barrierDismissible: false,
                                      context: context,
                                      builder:
                                          (context) => DialogAddTreeWidget(
                                            treeNotifier: widget.treeNotifier,
                                            clusters: clusterState,
                                            plots: plotState,
                                          ),
                                    );
                                  },
                                ),
                              ],
                            );
                          },
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 20),
                if (kDebugMode) ...[
                  const Text("Debug options:"),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _generateRandomData,
                    child: const Text("Generate Data Random"),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _clearAllData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 131, 30, 23),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text("Hapus Semua Data"),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
