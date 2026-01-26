import 'package:flutter/material.dart';
import 'package:azimutree/data/notifiers/notifiers.dart';

class AlertWarningWidget extends StatelessWidget {
  final String title;
  final String warningMessage;
  final Color? backgroundColor;
  final Color? textColor;
  const AlertWarningWidget({
    super.key,
    this.title = "Warning!",
    required this.warningMessage,
    this.backgroundColor = const Color.fromARGB(255, 248, 233, 93),
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isLightModeNotifier,
      builder: (context, isLightMode, _) {
        final isDark = !isLightMode;
        final dialogBg =
            isDark ? const Color.fromARGB(255, 32, 72, 43) : backgroundColor;
        final contentColor =
            isDark ? Colors.white : (textColor ?? Colors.black);
        return AlertDialog(
          backgroundColor: dialogBg,
          title: Text(title, style: TextStyle(color: contentColor)),
          content: Text(warningMessage, style: TextStyle(color: contentColor)),
          actions: [
            TextButton(
              child: Text("OK", style: TextStyle(color: contentColor)),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        );
      },
    );
  }
}
