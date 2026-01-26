import 'package:flutter/material.dart';
import 'package:azimutree/data/notifiers/notifiers.dart';

class AlertDevelopmentWidget extends StatelessWidget {
  final String title;
  final String warningMessage;
  const AlertDevelopmentWidget({
    super.key,
    this.title = "Sorry!",
    this.warningMessage = "This feature is not available yet 😔",
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isLightModeNotifier,
      builder: (context, isLightMode, _) {
        final isDark = !isLightMode;
        final dialogBg =
            isDark ? const Color.fromARGB(255, 32, 72, 43) : Colors.white;
        final textColor = isDark ? Colors.white : Colors.black;
        return AlertDialog(
          backgroundColor: dialogBg,
          title: Text(title, style: TextStyle(color: textColor)),
          content: Text(warningMessage, style: TextStyle(color: textColor)),
          actions: [
            TextButton(
              child: Text("OK", style: TextStyle(color: textColor)),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        );
      },
    );
  }
}
