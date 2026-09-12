import 'package:azimutree/data/notifiers/notifiers.dart';
import 'package:flutter/material.dart';

/// Displays a non-interactive progress dialog during asynchronous work.
class AlertLoadingWidget extends StatelessWidget {
  const AlertLoadingWidget({super.key, this.message = 'Memproses...'});

  final String message;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isLightModeNotifier,
      builder: (context, isLight, _) {
        final foreground = isLight ? Colors.black87 : Colors.white;
        return PopScope(
          canPop: false,
          child: AlertDialog(
            backgroundColor:
                isLight ? Colors.white : const Color.fromARGB(255, 32, 72, 43),
            content: Row(
              children: [
                const CircularProgressIndicator(),
                const SizedBox(width: 18),
                Expanded(
                  child: Text(message, style: TextStyle(color: foreground)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
