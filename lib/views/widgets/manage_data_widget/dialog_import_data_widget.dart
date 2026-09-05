import 'package:azimutree/data/notifiers/notifiers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class DialogImportDataWidget extends StatefulWidget {
  const DialogImportDataWidget({super.key});

  @override
  State<DialogImportDataWidget> createState() => _DialogImportDataWidgetState();
}

class _DialogImportDataWidgetState extends State<DialogImportDataWidget> {
  String? _pickedFilePath;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );
    if (!mounted || result == null || result.files.isEmpty) return;
    setState(() => _pickedFilePath = result.files.first.path);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isLightModeNotifier,
      builder: (context, isLightMode, _) {
        final isDark = !isLightMode;
        final background =
            isDark ? const Color.fromARGB(255, 32, 72, 43) : Colors.white;
        final textColor = isDark ? Colors.white : Colors.black;
        return AlertDialog(
          backgroundColor: background,
          title: Text(
            'Impor Data dari Excel',
            style: TextStyle(color: textColor),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pilih file hasil ekspor Azimutree. Klaster, Titik Ikat, plot, dan pohon akan dibaca langsung dari file.',
                style: TextStyle(color: textColor),
              ),
              const SizedBox(height: 12),
              Text(
                _pickedFilePath ?? 'Belum memilih file',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color:
                      _pickedFilePath == null
                          ? (isDark
                              ? Colors.orange.shade200
                              : Colors.red.shade700)
                          : textColor,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _pickFile,
                icon: const Icon(Icons.description),
                label: const Text('Pilih File Excel'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: textColor,
                  side: BorderSide(color: textColor.withValues(alpha: 0.7)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Batal', style: TextStyle(color: textColor)),
            ),
            TextButton(
              onPressed:
                  _pickedFilePath == null
                      ? null
                      : () => Navigator.of(context).pop(_pickedFilePath),
              style: ButtonStyle(
                foregroundColor: WidgetStateProperty.resolveWith(
                  (states) =>
                      states.contains(WidgetState.disabled)
                          ? Colors.grey
                          : textColor,
                ),
              ),
              child: const Text('Impor'),
            ),
          ],
        );
      },
    );
  }
}
