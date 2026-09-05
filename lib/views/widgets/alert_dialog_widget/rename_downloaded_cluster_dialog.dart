import 'package:azimutree/data/notifiers/notifiers.dart';
import 'package:azimutree/views/widgets/alert_dialog_widget/app_form_dialog.dart';
import 'package:flutter/material.dart';

class RenameDownloadedClusterDialog extends StatefulWidget {
  const RenameDownloadedClusterDialog({super.key, required this.initialCode});

  final String initialCode;

  @override
  State<RenameDownloadedClusterDialog> createState() =>
      _RenameDownloadedClusterDialogState();
}

class _RenameDownloadedClusterDialogState
    extends State<RenameDownloadedClusterDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialCode);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isLightModeNotifier,
      builder: (context, isLight, _) {
        final isDark = !isLight;
        final foreground = isDark ? Colors.white : Colors.black87;
        final labelColor = isDark ? Colors.white70 : Colors.black54;
        final background =
            isDark ? const Color.fromARGB(255, 32, 72, 43) : Colors.white;
        return AppFormDialog(
          backgroundColor: background,
          title: Text('Kode Klaster Baru', style: TextStyle(color: foreground)),
          content: Form(
            key: _formKey,
            child: TextFormField(
              controller: _controller,
              autofocus: true,
              maxLength: 30,
              textCapitalization: TextCapitalization.characters,
              style: TextStyle(color: foreground),
              decoration: InputDecoration(
                labelText: 'Kode klaster',
                helperText: 'Kode asli sudah tersedia di penyimpanan lokal.',
                labelStyle: TextStyle(color: labelColor),
                helperStyle: TextStyle(color: labelColor),
                counterStyle: TextStyle(color: labelColor),
                border: const OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: isDark ? Colors.white54 : Colors.grey,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color:
                        isDark
                            ? Colors.white
                            : Theme.of(context).colorScheme.primary,
                    width: 2,
                  ),
                ),
              ),
              validator:
                  (value) =>
                      (value?.trim().isEmpty ?? true)
                          ? 'Kode wajib diisi'
                          : null,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(foregroundColor: foreground),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                if (!_formKey.currentState!.validate()) return;
                Navigator.pop(context, _controller.text.trim().toUpperCase());
              },
              style: TextButton.styleFrom(foregroundColor: foreground),
              child: const Text('Unduh'),
            ),
          ],
        );
      },
    );
  }
}
