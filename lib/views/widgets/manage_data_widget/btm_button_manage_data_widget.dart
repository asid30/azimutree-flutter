import 'package:flutter/material.dart';
import 'package:azimutree/data/notifiers/notifiers.dart';

class BtmButtonManageDataWidget extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onPressed;
  final Size minSize;
  final Size maxSize;
  final bool? isEnabled;
  final Color? backgroundColor;

  const BtmButtonManageDataWidget({
    super.key,
    required this.label,
    this.icon,
    this.minSize = const Size(150, 75),
    this.maxSize = const Size(200, 125),
    this.isEnabled = true,
    this.backgroundColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isLightModeNotifier,
      builder: (context, isLightMode, _) {
        final isDark = !isLightMode;
        final disabledBg =
            isDark ? const Color.fromARGB(255, 67, 67, 67) : Colors.grey;
        return ElevatedButton(
          // Keep the button clickable even when `isEnabled` is false;
          // visual state only changes (background color). Do not set
          // `onPressed` to null so it is not actually disabled.
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            foregroundColor: isEnabled! ? Colors.white : Colors.white70,
            backgroundColor:
                isEnabled!
                    ? (backgroundColor ??
                        const Color.fromARGB(255, 85, 146, 98))
                    : disabledBg,
            minimumSize: minSize,
            maximumSize: maxSize,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) Icon(icon, size: 30),
              Text(label, textAlign: TextAlign.center),
            ],
          ),
        );
      },
    );
  }
}
