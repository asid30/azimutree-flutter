import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AlertConfirmationWidget extends StatelessWidget {
  final String title;
  final String message;
  final Color? backgroundColor;
  final String confirmText;
  final String cancelText;
  final String? copyableLink;

  const AlertConfirmationWidget({
    super.key,
    this.title = 'Konfirmasi',
    required this.message,
    this.backgroundColor = const Color.fromARGB(255, 197, 225, 165),
    this.confirmText = 'Hapus',
    this.cancelText = 'Batal',
    this.copyableLink,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: backgroundColor,
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message, style: const TextStyle(color: Colors.black)),
          if (copyableLink != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: SelectableText(
                    copyableLink!,
                    style: const TextStyle(
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Salin tautan',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: copyableLink!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Tautan disalin ke clipboard')),
                    );
                  },
                  icon: const Icon(Icons.copy),
                ),
              ],
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelText),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmText),
        ),
      ],
    );
  }
}
