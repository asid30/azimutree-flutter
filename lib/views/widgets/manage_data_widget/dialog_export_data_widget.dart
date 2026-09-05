// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:azimutree/data/notifiers/cluster_notifier.dart';
import 'package:azimutree/data/notifiers/notifiers.dart';
import 'package:azimutree/services/excel_export_service.dart';
import 'package:azimutree/views/widgets/alert_dialog_widget/alert_warning_widget.dart';
import 'package:file_picker/file_picker.dart';

class DialogExportDataWidget extends StatefulWidget {
  final ClusterNotifier clusterNotifier;

  const DialogExportDataWidget({super.key, required this.clusterNotifier});

  @override
  State<DialogExportDataWidget> createState() => _DialogExportDataWidgetState();
}

class _DialogExportDataWidgetState extends State<DialogExportDataWidget> {
  final Set<int> _selectedClusterIds = {};
  String? _selectedDirectoryPath;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _selectedClusterIds.addAll(
      widget.clusterNotifier.value
          .map((cluster) => cluster.id)
          .whereType<int>(),
    );
  }

  void _toggleAll(bool selected, List<int> availableIds) {
    setState(() {
      _selectedClusterIds
        ..clear()
        ..addAll(selected ? availableIds : const <int>[]);
    });
  }

  @override
  Widget build(BuildContext context) {
    final clusters = widget.clusterNotifier.value;
    final availableIds =
        clusters.map((cluster) => cluster.id).whereType<int>().toList();
    final allSelected =
        availableIds.isNotEmpty &&
        availableIds.every(_selectedClusterIds.contains);
    return ValueListenableBuilder<bool>(
      valueListenable: isLightModeNotifier,
      builder: (context, isLightMode, _) {
        final isDark = !isLightMode;
        final dialogBgColor =
            isDark ? const Color.fromARGB(255, 32, 72, 43) : Colors.white;
        final dialogText = isDark ? Colors.white : Colors.black;
        final checkboxFillColor = WidgetStateProperty.resolveWith<Color?>((
          states,
        ) {
          if (isDark) {
            return states.contains(WidgetState.disabled)
                ? Colors.grey.shade400
                : Colors.white;
          }
          return states.contains(WidgetState.selected)
              ? const Color(0xFF1F4226)
              : null;
        });
        final checkboxCheckColor =
            isDark ? const Color(0xFF1F4226) : Colors.white;
        final checkboxSide = BorderSide(
          color: isDark ? Colors.white : const Color(0xFF1F4226),
          width: 1.5,
        );

        return AlertDialog(
          backgroundColor: dialogBgColor,
          title: Text(
            'Ekspor Data ke Excel',
            style: TextStyle(color: dialogText),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (clusters.isEmpty)
                  Text(
                    'Belum ada klaster tersedia.',
                    style: TextStyle(color: dialogText),
                  )
                else ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Pilih klaster yang akan diekspor:',
                      style: TextStyle(color: dialogText),
                    ),
                  ),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    value: allSelected,
                    fillColor: checkboxFillColor,
                    checkColor: checkboxCheckColor,
                    side: checkboxSide,
                    title: Text(
                      'Pilih semua (${availableIds.length} klaster)',
                      style: TextStyle(
                        color: dialogText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onChanged:
                        availableIds.isEmpty
                            ? null
                            : (value) =>
                                _toggleAll(value ?? false, availableIds),
                  ),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 220),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: dialogText.withValues(alpha: 0.25),
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: clusters.length,
                      itemBuilder: (context, index) {
                        final cluster = clusters[index];
                        final id = cluster.id;
                        final selected =
                            id != null && _selectedClusterIds.contains(id);
                        final surveyor = cluster.namaPengukur?.trim();
                        return CheckboxListTile(
                          dense: true,
                          value: selected,
                          fillColor: checkboxFillColor,
                          checkColor: checkboxCheckColor,
                          side: checkboxSide,
                          title: Text(
                            'Klaster ${cluster.kodeCluster}',
                            style: TextStyle(color: dialogText),
                          ),
                          subtitle:
                              surveyor == null || surveyor.isEmpty
                                  ? null
                                  : Text(
                                    surveyor,
                                    style: TextStyle(
                                      color: dialogText.withValues(alpha: 0.7),
                                    ),
                                  ),
                          onChanged:
                              id == null
                                  ? null
                                  : (value) {
                                    setState(() {
                                      if (value ?? false) {
                                        _selectedClusterIds.add(id);
                                      } else {
                                        _selectedClusterIds.remove(id);
                                      }
                                    });
                                  },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${_selectedClusterIds.length} klaster dipilih',
                      style: TextStyle(color: dialogText, fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Simpan ke folder:',
                      style: TextStyle(color: dialogText),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _selectedDirectoryPath ??
                          'Folder tujuan wajib dipilih sebelum ekspor.',
                      style: TextStyle(
                        color:
                            _selectedDirectoryPath == null
                                ? (isDark
                                    ? Colors.orange.shade200
                                    : Colors.red.shade700)
                                : dialogText,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () async {
                      final picked =
                          await FilePicker.platform.getDirectoryPath();
                      if (!mounted) return;
                      if (picked == null || picked.trim().isEmpty) return;
                      setState(() => _selectedDirectoryPath = picked);
                    },
                    child: Text(
                      'Pilih Folder Simpan',
                      style: TextStyle(color: dialogText),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Batal', style: TextStyle(color: dialogText)),
            ),
            TextButton(
              onPressed:
                  clusters.isEmpty ||
                          _selectedClusterIds.isEmpty ||
                          _selectedDirectoryPath == null ||
                          _isExporting
                      ? null
                      : () async {
                        final selectedClusters =
                            clusters
                                .where(
                                  (cluster) =>
                                      cluster.id != null &&
                                      _selectedClusterIds.contains(cluster.id),
                                )
                                .toList();
                        setState(() => _isExporting = true);
                        final rootNavigator = Navigator.of(
                          context,
                          rootNavigator: true,
                        );
                        final loadingDialog = showDialog<void>(
                          context: context,
                          barrierDismissible: false,
                          builder:
                              (_) => const PopScope(
                                canPop: false,
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                        );
                        try {
                          final path =
                              await ExcelExportService.exportClustersToExcel(
                                clusters: selectedClusters,
                                directoryPath: _selectedDirectoryPath,
                                preferDownloads: false,
                              );
                          if (!mounted) return;
                          rootNavigator.pop();
                          await loadingDialog;
                          if (!mounted) return;
                          Navigator.of(context).pop();
                          await showDialog(
                            context: rootNavigator.context,
                            builder:
                                (_) => AlertWarningWidget(
                                  title: 'Sukses',
                                  warningMessage:
                                      'Ekspor selesai. File disimpan di:\n$path',
                                  backgroundColor: Colors.lightGreen.shade200,
                                ),
                          );
                        } catch (e) {
                          if (!mounted) return;
                          rootNavigator.pop();
                          await loadingDialog;
                          if (!mounted) return;
                          setState(() => _isExporting = false);
                          await showDialog(
                            context: context,
                            builder:
                                (_) => AlertWarningWidget(
                                  title: 'Gagal',
                                  warningMessage:
                                      'Ekspor gagal: ${e.toString()}',
                                  backgroundColor: Colors.red.shade200,
                                ),
                          );
                        }
                      },
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all(dialogBgColor),
                foregroundColor: WidgetStateProperty.resolveWith((states) {
                  if (isDark) {
                    return states.contains(WidgetState.disabled)
                        ? Colors.grey
                        : Colors.white;
                  }
                  return states.contains(WidgetState.disabled)
                      ? Colors.grey
                      : Colors.black;
                }),
              ),
              child: const Text('Ekspor'),
            ),
          ],
        );
      },
    );
  }
}
