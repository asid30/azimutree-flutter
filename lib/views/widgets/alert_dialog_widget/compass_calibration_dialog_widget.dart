import 'package:azimutree/data/notifiers/notifiers.dart';
import 'package:flutter/material.dart';

class CompassCalibrationDialogWidget extends StatelessWidget {
  const CompassCalibrationDialogWidget({super.key});

  static const _assetPath = 'assets/images/calibrate_compass_azimutree.gif';

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isLightModeNotifier,
      builder: (context, isLightMode, _) {
        final isDark = !isLightMode;
        final backgroundColor =
            isDark
                ? const Color.fromARGB(255, 32, 72, 43)
                : const Color.fromARGB(255, 220, 238, 223);
        final foregroundColor = isDark ? Colors.white : Colors.black87;

        return AlertDialog(
          backgroundColor: backgroundColor,
          title: Text(
            'Cara Kalibrasi Kompas',
            style: TextStyle(color: foregroundColor),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    _assetPath,
                    width: double.infinity,
                    fit: BoxFit.contain,
                    errorBuilder:
                        (_, __, ___) => Container(
                          height: 160,
                          alignment: Alignment.center,
                          color: foregroundColor.withValues(alpha: 0.08),
                          child: Icon(
                            Icons.broken_image_outlined,
                            color: foregroundColor,
                            size: 42,
                          ),
                        ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Gerakkan ponsel membentuk angka delapan seperti pada animasi. Ulangi beberapa kali hingga arah kompas stabil.',
                  style: TextStyle(color: foregroundColor),
                ),
                const SizedBox(height: 8),
                Text(
                  'Jauhkan ponsel dari magnet, benda logam, dan perangkat elektronik lain saat melakukan kalibrasi.',
                  style: TextStyle(
                    color: foregroundColor.withValues(alpha: 0.75),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK', style: TextStyle(color: foregroundColor)),
            ),
          ],
        );
      },
    );
  }
}
