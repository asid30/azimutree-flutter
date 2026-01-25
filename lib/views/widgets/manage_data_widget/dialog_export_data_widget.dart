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
  String? _selectedKode;
  String? _selectedDirectoryPath;

  @override
  void initState() {
    super.initState();
    final clusters = widget.clusterNotifier.value;
    _selectedKode = clusters.isNotEmpty ? clusters.first.kodeCluster : null;
  }

  @override
  Widget build(BuildContext context) {
    final clusters = widget.clusterNotifier.value;
    return ValueListenableBuilder<bool>(
      valueListenable: isLightModeNotifier,
      builder: (context, isLightMode, _) {
        final isDark = !isLightMode;
        final dialogBgColor =
            isDark ? const Color.fromARGB(255, 32, 72, 43) : Colors.white;
        final dialogText = isDark ? Colors.white : Colors.black;

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
                      'Pilih klaster:',
                      style: TextStyle(color: dialogText),
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButton<String>(
                    value: _selectedKode,
                    isExpanded: true,
                    dropdownColor: dialogBgColor,
                    style: TextStyle(color: dialogText),
                    items:
                        clusters
                            .map<DropdownMenuItem<String>>(
                              (c) => DropdownMenuItem(
                                value: c.kodeCluster,
                                child: Text(
                                  c.kodeCluster + (c.namaPengukur ?? ''),
                                  style: TextStyle(color: dialogText),
                                ),
                              ),
                            )
                            .toList(),
                    onChanged: (v) => setState(() => _selectedKode = v),
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
                      _selectedDirectoryPath ?? 'Default: Download',
                      style: TextStyle(color: dialogText, fontSize: 12),
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
                  clusters.isEmpty
                      ? null
                      : () async {
                        final cluster = clusters.firstWhere(
                          (c) => c.kodeCluster == _selectedKode,
                          orElse: () => clusters.first,
                        );
                        Navigator.of(context).pop();
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder:
                              (_) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                        );
                        try {
                          final path =
                              await ExcelExportService.exportClusterToExcel(
                                cluster: cluster,
                                directoryPath: _selectedDirectoryPath,
                                preferDownloads: _selectedDirectoryPath == null,
                              );
                          if (!mounted) return;
                          Navigator.of(context, rootNavigator: true).pop();
                          await showDialog(
                            context: context,
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
                          Navigator.of(context, rootNavigator: true).pop();
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
