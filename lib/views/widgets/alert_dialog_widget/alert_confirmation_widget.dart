import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:azimutree/data/notifiers/notifiers.dart';
import 'package:azimutree/views/widgets/alert_dialog_widget/app_alert_service.dart';

class AlertConfirmationWidget extends StatelessWidget {
  final String title;
  final String message;
  final Color? backgroundColor;
  final String confirmText;
  final String cancelText;
  final String? copyableLink;
  final bool keepBackgroundColorInDarkMode;

  const AlertConfirmationWidget({
    super.key,
    this.title = 'Konfirmasi',
    required this.message,
    this.backgroundColor = const Color.fromARGB(255, 197, 225, 165),
    this.confirmText = 'Hapus',
    this.cancelText = 'Batal',
    this.copyableLink,
    this.keepBackgroundColorInDarkMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isLightModeNotifier,
      builder: (context, isLightMode, _) {
        final isDark = !isLightMode;
        final dialogBg =
            isDark && !keepBackgroundColorInDarkMode
                ? const Color.fromARGB(255, 32, 72, 43)
                : backgroundColor;
        final textColor =
            isDark && !keepBackgroundColorInDarkMode
                ? Colors.white
                : Colors.black;
        return AlertDialog(
          backgroundColor: dialogBg,
          title: Text(title, style: TextStyle(color: textColor)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message, style: TextStyle(color: textColor)),
              if (copyableLink != null) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: SelectableText(
                        copyableLink!,
                        style: TextStyle(
                          color: isDark ? Colors.lightBlue[200] : Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Salin tautan',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: copyableLink!));
                        showAppSuccess(context, 'Tautan disalin ke clipboard.');
                      },
                      icon: Icon(Icons.copy, color: textColor),
                    ),
                  ],
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(cancelText, style: TextStyle(color: textColor)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(confirmText, style: TextStyle(color: textColor)),
            ),
          ],
        );
      },
    );
  }
}
