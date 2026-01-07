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
import 'package:azimutree/views/widgets/manage_data_widget/dialog_import_data_widget.dart';
import 'package:azimutree/data/models/cluster_model.dart';
import 'package:azimutree/services/excel_import_service.dart';
import 'package:azimutree/services/excel_export_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class BottomsheetManageDataWidget extends StatefulWidget {
  final ClusterNotifier clusterNotifier;
  final PlotNotifier plotNotifier;
  final TreeNotifier treeNotifier;
  final DraggableScrollableController? draggableController;

  const BottomsheetManageDataWidget({
    super.key,
    required this.clusterNotifier,
    required this.plotNotifier,
    required this.treeNotifier,
    this.draggableController,
  });

  @override
  State<BottomsheetManageDataWidget> createState() =>
      _BottomsheetManageDataWidgetState();
}

class _BottomsheetManageDataWidgetState
    extends State<BottomsheetManageDataWidget> {
  late final DraggableScrollableController _draggableScrollableController;
  late final bool _ownsController;
  final double _maxChildSize = 0.9;
  final double _minChildSize = 0.03;
  late final DebugDataService _debugDataService;
  @override
  void initState() {
    super.initState();
    // Use external controller if parent provided one, otherwise create our own
    if (widget.draggableController != null) {
      _draggableScrollableController = widget.draggableController!;
      _ownsController = false;
    } else {
      _draggableScrollableController = DraggableScrollableController();
      _ownsController = true;
    }

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

  /// Public method so parent widgets can request the bottom sheet to expand.
  void expandBottomSheet() => _expandBottomSheet();

  @override
  void dispose() {
    if (_ownsController) {
      _draggableScrollableController.dispose();
    }
    super.dispose();
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

  Future<void> _generateRandomData() async {
    try {
      await _debugDataService.seedRandomData();
      if (!mounted) return;
      await _showAlert(
        message: "Data acak berhasil dibuat",
        backgroundColor: Colors.lightGreen.shade200,
      );
    } catch (e) {
      if (!mounted) return;
      await _showAlert(
        message: "Gagal membuat data acak: $e",
        backgroundColor: Colors.red.shade200,
      );
    }
  }

  Future<void> _showAlert({
    String title = 'Warning!',
    required String message,
    required Color backgroundColor,
  }) {
    return showDialog(
      barrierDismissible: false,
      context: context,
      builder:
          (_) => AlertWarningWidget(
            title: title,
            warningMessage: message,
            backgroundColor: backgroundColor,
          ),
    );
  }

  Future<void> _showWarningNeedCluster({required String target}) async {
    if (!mounted) return;
    await showDialog(
      barrierDismissible: false,
      context: context,
      builder:
          (_) => AlertWarningWidget(
            warningMessage:
                'Harap tambahkan klaster terlebih dahulu sebelum menambahkan $target.',
            backgroundColor: Colors.orange.shade200,
          ),
    );
  }

  Future<void> _showWarningNeedPlot({required String target}) async {
    if (!mounted) return;
    await showDialog(
      barrierDismissible: false,
      context: context,
      builder:
          (_) => AlertWarningWidget(
            warningMessage:
                'Harap tambahkan plot terlebih dahulu sebelum menambahkan $target.',
            backgroundColor: Colors.orange.shade200,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      controller: _draggableScrollableController,
      initialChildSize: 0.03,
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
                // Header with drag handle and a rounded button to expand sheet
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // subtle drag handle
                      Container(
                        width: 48,
                        height: 6,
                        margin: const EdgeInsets.only(bottom: 8.0),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      Center(
                        child: OutlinedButton.icon(
                          onPressed: _expandBottomSheet,
                          icon: const Icon(Icons.menu, size: 18),
                          label: const Text(
                            'Menu Kelola Data',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.black87,
                            side: BorderSide.none,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18.0,
                              vertical: 12.0,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24.0),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 30),
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
                        showDialog<void>(
                          barrierDismissible: false,
                          context: context,
                          builder: (dialogContext) {
                            final clusters = widget.clusterNotifier.value;
                            String? selectedKode;
                            if (clusters.isNotEmpty) {
                              selectedKode = clusters.first.kodeCluster;
                            }
                            String? selectedDirectoryPath;

                            return StatefulBuilder(
                              builder: (builderContext, setState) {
                                return AlertDialog(
                                  title: const Text('Ekspor Data ke Excel'),
                                  content: SizedBox(
                                    width: double.maxFinite,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (clusters.isEmpty) ...[
                                          const Text(
                                            'Belum ada klaster tersedia.',
                                          ),
                                        ] else ...[
                                          const Align(
                                            alignment: Alignment.centerLeft,
                                            child: Text('Pilih klaster:'),
                                          ),
                                          const SizedBox(height: 8),
                                          DropdownButton<String>(
                                            isExpanded: true,
                                            value: selectedKode,
                                            items:
                                                clusters
                                                    .map(
                                                      (c) => DropdownMenuItem(
                                                        value: c.kodeCluster,
                                                        child: Text(
                                                          c.kodeCluster +
                                                              (c.namaPengukur !=
                                                                      null
                                                                  ? ' - ${c.namaPengukur}'
                                                                  : ''),
                                                        ),
                                                      ),
                                                    )
                                                    .toList(),
                                            onChanged:
                                                (v) => setState(
                                                  () => selectedKode = v,
                                                ),
                                          ),
                                          const SizedBox(height: 12),
                                          const Align(
                                            alignment: Alignment.centerLeft,
                                            child: Text('Simpan ke folder:'),
                                          ),
                                          const SizedBox(height: 8),
                                          Align(
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                              selectedDirectoryPath == null
                                                  ? 'Default: Download'
                                                  : selectedDirectoryPath!,
                                              style: const TextStyle(
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          OutlinedButton(
                                            onPressed: () async {
                                              final picked =
                                                  await FilePicker.platform
                                                      .getDirectoryPath();
                                              if (!builderContext.mounted) {
                                                return;
                                              }
                                              if (picked == null ||
                                                  picked.trim().isEmpty) {
                                                return;
                                              }
                                              setState(
                                                () =>
                                                    selectedDirectoryPath =
                                                        picked,
                                              );
                                            },
                                            child: const Text(
                                              'Pilih Folder Simpan',
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed:
                                          () =>
                                              Navigator.of(dialogContext).pop(),
                                      child: const Text('Batal'),
                                    ),
                                    ElevatedButton(
                                      onPressed:
                                          clusters.isEmpty
                                              ? null
                                              : () async {
                                                final cluster = clusters
                                                    .firstWhere(
                                                      (c) =>
                                                          c.kodeCluster ==
                                                          selectedKode,
                                                      orElse:
                                                          () => clusters.first,
                                                    );

                                                // Close selection dialog (no async gap before using dialogContext)
                                                Navigator.of(
                                                  dialogContext,
                                                ).pop();

                                                // Show progress dialog on root navigator
                                                showDialog<void>(
                                                  barrierDismissible: false,
                                                  context: this.context,
                                                  useRootNavigator: true,
                                                  builder:
                                                      (_) => const Center(
                                                        child:
                                                            CircularProgressIndicator(),
                                                      ),
                                                );

                                                try {
                                                  final path =
                                                      await ExcelExportService.exportClusterToExcel(
                                                        cluster: cluster,
                                                        directoryPath:
                                                            selectedDirectoryPath,
                                                        preferDownloads:
                                                            selectedDirectoryPath ==
                                                            null,
                                                      );

                                                  if (!mounted) return;
                                                  // Close progress dialog (root)
                                                  Navigator.of(
                                                    this.context,
                                                    rootNavigator: true,
                                                  ).pop();
                                                  await _showAlert(
                                                    title: 'Sukses',
                                                    message:
                                                        'Ekspor selesai. File disimpan di:\n$path',
                                                    backgroundColor:
                                                        Colors
                                                            .lightGreen
                                                            .shade200,
                                                  );
                                                } catch (e) {
                                                  if (!mounted) return;
                                                  Navigator.of(
                                                    this.context,
                                                    rootNavigator: true,
                                                  ).pop();
                                                  await _showAlert(
                                                    title: 'Gagal',
                                                    message:
                                                        'Ekspor gagal: ${e.toString()}',
                                                    backgroundColor:
                                                        Colors.red.shade200,
                                                  );
                                                }
                                              },
                                      child: const Text('Ekspor'),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                    BtmButtonManageDataWidget(
                      label: "Impor Data",
                      icon: Icons.file_download,
                      onPressed: () async {
                        final result = await showDialog(
                          barrierDismissible: false,
                          context: context,
                          builder:
                              (context) => DialogImportDataWidget(
                                clusterNotifier: widget.clusterNotifier,
                              ),
                        );

                        if (result != null) {
                          try {
                            final cluster = ClusterModel(
                              kodeCluster: result['kodeCluster'] as String,
                              namaPengukur: result['namaPengukur'] as String?,
                              tanggalPengukuran:
                                  (result['tanggalPengukuran'] as String?)
                                              ?.isNotEmpty ==
                                          true
                                      ? DateTime.tryParse(
                                        result['tanggalPengukuran'] as String,
                                      )
                                      : null,
                            );

                            // Use file uploaded by user (picked in dialog)
                            final uploadedPath = result['filePath'] as String;
                            final importResult =
                                await ExcelImportService.importFile(
                                  filePath: uploadedPath,
                                  cluster: cluster,
                                );

                            // reload notifiers
                            await widget.clusterNotifier.loadClusters();
                            await widget.plotNotifier.loadPlots();
                            await widget.treeNotifier.loadTrees();

                            if (!mounted) return;
                            await _showAlert(
                              title: 'Sukses',
                              message:
                                  'Impor selesai. Plots: ${importResult['plots']}, Trees: ${importResult['trees']}',
                              backgroundColor: Colors.lightGreen.shade200,
                            );
                          } catch (e) {
                            if (!context.mounted) return;
                            await _showAlert(
                              title: 'Gagal',
                              message: 'Impor gagal: ${e.toString()}',
                              backgroundColor: Colors.red.shade200,
                            );
                          }
                        }
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
