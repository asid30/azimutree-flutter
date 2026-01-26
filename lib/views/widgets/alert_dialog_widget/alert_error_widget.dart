import 'package:flutter/material.dart';
import 'package:azimutree/data/notifiers/notifiers.dart';

class AlertErrorWidget extends StatelessWidget {
  final Object errorMessage;
  const AlertErrorWidget({super.key, required this.errorMessage});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isLightModeNotifier,
      builder: (context, isLightMode, _) {
        final isDark = !isLightMode;
        final bg =
            isDark
                ? const Color.fromARGB(255, 32, 72, 43)
                : const Color.fromARGB(255, 241, 111, 101);
        final textColor = isDark ? Colors.white : Colors.black;
        return AlertDialog(
          backgroundColor: bg,
          title: Text("Error!", style: TextStyle(color: textColor)),
          content: Text(
            "Error Message: $errorMessage",
            style: TextStyle(color: textColor),
          ),
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
