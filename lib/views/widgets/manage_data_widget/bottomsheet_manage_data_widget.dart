import 'package:azimutree/data/models/plot_model.dart';
import 'package:azimutree/data/notifiers/cluster_notifier.dart';
import 'package:azimutree/data/notifiers/notifiers.dart';
import 'package:azimutree/data/notifiers/plot_notifier.dart';
import 'package:azimutree/data/notifiers/tree_notifier.dart';
import 'package:azimutree/services/debug_data_service.dart';
import 'package:azimutree/services/debug_mode_service.dart';
import 'package:azimutree/views/widgets/manage_data_widget/btm_button_manage_data_widget.dart';
import 'package:azimutree/views/widgets/manage_data_widget/dialog_add_cluster_widget.dart';
import 'package:azimutree/views/widgets/alert_dialog_widget/alert_warning_widget.dart';
import 'package:azimutree/views/widgets/alert_dialog_widget/alert_confirmation_widget.dart';
import 'package:azimutree/views/widgets/manage_data_widget/dialog_add_plot_widget.dart';
import 'package:azimutree/views/widgets/manage_data_widget/dialog_add_tree_widget.dart';
import 'package:azimutree/views/widgets/manage_data_widget/dialog_import_data_widget.dart';
import 'package:azimutree/views/widgets/manage_data_widget/dialog_export_data_widget.dart';
import 'package:azimutree/data/models/cluster_model.dart';
import 'package:azimutree/services/excel_import_service.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

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
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertConfirmationWidget(
            title: 'Hapus semua data?',
            message: 'Semua klaster, plot, dan pohon akan dihapus permanen.',
            confirmText: 'Hapus',
            cancelText: 'Batal',
          ),
    );

    if (confirm != true) return;

    try {
      await _debugDataService.clearAllData();
      if (!mounted) return;
      await _showAlert(
        title: 'Sukses',
        message: "Semua data berhasil dihapus",
        backgroundColor: Colors.lightGreen.shade200,
      );
    } catch (e) {
      if (!mounted) return;
      await _showAlert(
        title: 'Gagal',
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
        title: 'Sukses',
        message: "Data acak berhasil dibuat",
        backgroundColor: Colors.lightGreen.shade200,
      );
    } catch (e) {
      if (!mounted) return;
      await _showAlert(
        title: 'Gagal',
        message: "Gagal membuat data acak: $e",
        backgroundColor: Colors.red.shade200,
      );
    }
  }

  Future<void> _showAlert({
    String title = 'Warning!',
    required String message,
    required Color backgroundColor,
    Color? textColor,
  }) {
    return showDialog(
      barrierDismissible: false,
      context: context,
      builder:
          (_) => AlertWarningWidget(
            title: title,
            warningMessage: message,
            backgroundColor: backgroundColor,
            textColor: textColor,
          ),
    );
  }

  Future<void> _showWarningNeedCluster({required String target}) async {
    if (!mounted) return;
    final isDark = !isLightModeNotifier.value;
    final bg =
        isDark ? const Color.fromARGB(255, 32, 72, 43) : Colors.orange.shade200;
    final txt = isDark ? Colors.white : Colors.black;
    await showDialog(
      barrierDismissible: false,
      context: context,
      builder:
          (_) => AlertWarningWidget(
            title: 'Gagal!',
            warningMessage:
                'Harap tambahkan klaster terlebih dahulu sebelum menambahkan $target.',
            backgroundColor: bg,
            textColor: txt,
          ),
    );
  }

  Future<void> _showWarningNeedPlot({required String target}) async {
    if (!mounted) return;
    final isDark = !isLightModeNotifier.value;
    final bg =
        isDark ? const Color.fromARGB(255, 32, 72, 43) : Colors.orange.shade200;
    final txt = isDark ? Colors.white : Colors.black;
    await showDialog(
      barrierDismissible: false,
      context: context,
      builder:
          (_) => AlertWarningWidget(
            title: 'Gagal!',
            warningMessage:
                'Harap tambahkan plot terlebih dahulu sebelum menambahkan $target.',
            backgroundColor: bg,
            textColor: txt,
          ),
    );
  }

  Future<void> _confirmAndOpenTemplate() async {
    final templateEnv = dotenv.env['TEMPLATE_URL'];
    if (templateEnv == null || templateEnv.trim().isEmpty) {
      await _showAlert(
        title: 'Gagal',
        message:
            'Template belum dikonfigurasi. Silakan tambahkan TEMPLATE_URL di file .env.',
        backgroundColor: Colors.red.shade200,
      );
      return;
    }
    final templateUrl = templateEnv.trim();

    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertConfirmationWidget(
            title: 'Unduh Template',
            message:
                'Apakah Anda ingin membuka browser untuk mengunduh template?',
            confirmText: 'Buka',
            cancelText: 'Batal',
            copyableLink: templateUrl,
          ),
    );

    if (confirm != true) return;

    final uri = Uri.parse(templateUrl);
    try {
      if (!await canLaunchUrl(uri)) {
        if (!mounted) return;
        final isDark = !isLightModeNotifier.value;
        final bg =
            isDark
                ? const Color.fromARGB(255, 131, 30, 23)
                : Colors.red.shade200;
        final txt = isDark ? Colors.white : Colors.black;
        await showDialog(
          barrierDismissible: false,
          context: context,
          builder:
              (_) => AlertWarningWidget(
                title: 'Gagal',
                warningMessage:
                    'Tidak dapat membuka browser pada perangkat ini.',
                backgroundColor: bg,
                textColor: txt,
              ),
        );
        return;
      }

      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (!mounted) return;
      final isDark = !isLightModeNotifier.value;
      final bg =
          isDark ? const Color.fromARGB(255, 131, 30, 23) : Colors.red.shade200;
      final txt = isDark ? Colors.white : Colors.black;
      await showDialog(
        barrierDismissible: false,
        context: context,
        builder:
            (_) => AlertWarningWidget(
              title: 'Gagal',
              warningMessage: 'Terjadi kesalahan saat membuka tautan: $e',
              backgroundColor: bg,
              textColor: txt,
            ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      controller: _draggableScrollableController,
      initialChildSize: 0.03,
      minChildSize: _minChildSize,
      maxChildSize: _maxChildSize,
      builder: (context, scrollController) {
        return ValueListenableBuilder<bool>(
          valueListenable: isLightModeNotifier,
          builder: (context, isLightMode, _) {
            final isDark = !isLightMode;
            return Container(
              decoration: BoxDecoration(
                color:
                    isDark
                        ? const Color.fromARGB(255, 44, 85, 51)
                        : const Color.fromARGB(255, 205, 237, 211),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
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
                          ValueListenableBuilder<bool>(
                            valueListenable: isLightModeNotifier,
                            builder: (context, isLightMode, _) {
                              final isDark = !isLightMode;
                              return Center(
                                child: OutlinedButton.icon(
                                  onPressed: _expandBottomSheet,
                                  icon: Icon(
                                    Icons.menu,
                                    size: 18,
                                    color: isDark ? Colors.white : null,
                                  ),
                                  label: Text(
                                    'Menu Kelola Data',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : null,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    foregroundColor:
                                        isDark ? Colors.white : Colors.black87,
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
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 30),
                    ValueListenableBuilder<bool>(
                      valueListenable: isLightModeNotifier,
                      builder: (context, isLightMode, _) {
                        final isDark = !isLightMode;
                        return Text(
                          'Pilih salah satu opsi di bawah untuk mengelola data Anda. Impor data untuk menambahkan data dari file eksternal (sheet), ekspor data untuk menyimpan salinan data Anda, atau unduh template untuk format data (sheet) yang benar.',
                          textAlign: TextAlign.justify,
                          style: TextStyle(color: isDark ? Colors.white : null),
                        );
                      },
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
                          backgroundColor:
                              isDark
                                  ? const Color.fromARGB(255, 18, 43, 25)
                                  : const Color.fromARGB(255, 32, 72, 43),
                          onPressed:
                              () => showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder:
                                    (_) => DialogExportDataWidget(
                                      clusterNotifier: widget.clusterNotifier,
                                    ),
                              ),
                        ),
                        BtmButtonManageDataWidget(
                          label: "Impor Data",
                          icon: Icons.file_download,
                          backgroundColor:
                              isDark
                                  ? const Color.fromARGB(255, 18, 43, 25)
                                  : const Color.fromARGB(255, 32, 72, 43),
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
                                  namaPengukur:
                                      result['namaPengukur'] as String?,
                                  tanggalPengukuran:
                                      (result['tanggalPengukuran'] as String?)
                                                  ?.isNotEmpty ==
                                              true
                                          ? DateTime.tryParse(
                                            result['tanggalPengukuran']
                                                as String,
                                          )
                                          : null,
                                );

                                // Use file uploaded by user (picked in dialog)
                                final uploadedPath =
                                    result['filePath'] as String;
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
                          backgroundColor:
                              isDark
                                  ? const Color.fromARGB(255, 18, 43, 25)
                                  : const Color.fromARGB(255, 32, 72, 43),
                          onPressed: () {
                            _confirmAndOpenTemplate();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ValueListenableBuilder<bool>(
                      valueListenable: isLightModeNotifier,
                      builder: (context, isLightMode, _) {
                        final isDark = !isLightMode;
                        return Text(
                          "Atau tambah data baru secara manual:",
                          style: TextStyle(color: isDark ? Colors.white : null),
                        );
                      },
                    ),
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
                                      backgroundColor:
                                          isDark
                                              ? const Color.fromARGB(
                                                255,
                                                18,
                                                43,
                                                25,
                                              )
                                              : const Color.fromARGB(
                                                255,
                                                32,
                                                72,
                                                43,
                                              ),
                                      onPressed: () {
                                        showDialog(
                                          barrierDismissible: false,
                                          context: context,
                                          builder:
                                              (context) =>
                                                  DialogAddClusterWidget(
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
                                      backgroundColor:
                                          isDark
                                              ? const Color.fromARGB(
                                                255,
                                                18,
                                                43,
                                                25,
                                              )
                                              : const Color.fromARGB(
                                                255,
                                                32,
                                                72,
                                                43,
                                              ),
                                      onPressed: () {
                                        if (!hasCluster) {
                                          _showWarningNeedCluster(
                                            target: "plot",
                                          );
                                          return;
                                        }

                                        showDialog(
                                          barrierDismissible: false,
                                          context: context,
                                          builder:
                                              (context) => DialogAddPlotWidget(
                                                plotNotifier:
                                                    widget.plotNotifier,
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
                                      backgroundColor:
                                          isDark
                                              ? const Color.fromARGB(
                                                255,
                                                18,
                                                43,
                                                25,
                                              )
                                              : const Color.fromARGB(
                                                255,
                                                32,
                                                72,
                                                43,
                                              ),
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
                                                treeNotifier:
                                                    widget.treeNotifier,
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
                    ValueListenableBuilder<bool>(
                      valueListenable: DebugModeService.instance.enabled,
                      builder: (context, enabled, _) {
                        if (!enabled) return const SizedBox.shrink();
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ValueListenableBuilder<bool>(
                              valueListenable: isLightModeNotifier,
                              builder: (context, isLightMode, _) {
                                final isDark = !isLightMode;
                                return Text(
                                  "Debug options:",
                                  style: TextStyle(
                                    color: isDark ? Colors.white : null,
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: _generateRandomData,
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    isDark
                                        ? const Color.fromARGB(255, 18, 43, 25)
                                        : const Color.fromARGB(255, 32, 72, 43),
                                foregroundColor: Colors.white,
                              ),
                              child: const Text("Generate Data Random"),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: _clearAllData,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color.fromARGB(
                                  255,
                                  131,
                                  30,
                                  23,
                                ),
                                foregroundColor: Colors.white,
                              ),
                              child: const Text("Hapus Semua Data"),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
