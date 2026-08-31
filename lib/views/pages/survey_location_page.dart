import 'package:azimutree/data/notifiers/notifiers.dart';
import 'package:azimutree/services/compass_navigation_service.dart';
import 'package:azimutree/services/compass_service.dart';
import 'package:azimutree/views/widgets/core_widget/appbar_widget.dart';
import 'package:azimutree/views/widgets/core_widget/background_app_widget.dart';
import 'package:azimutree/views/widgets/core_widget/sidebar_widget.dart';
import 'package:flutter/material.dart';

class SurveyLocationPage extends StatelessWidget {
  const SurveyLocationPage({
    super.key,
    this.compassService = const CompassService(),
  });

  final CompassService compassService;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.pushNamedAndRemoveUntil(context, 'home', (route) => false);
      },
      child: Scaffold(
        appBar: const AppbarWidget(title: 'Survey Lokasi'),
        drawer: const SidebarWidget(),
        body: Stack(
          children: [
            const BackgroundAppWidget(
              lightBackgroundImage: 'assets/images/light-bg-notitle.png',
              darkBackgroundImage: 'assets/images/dark-bg-notitle.png',
            ),
            SafeArea(
              child: ValueListenableBuilder<bool>(
                valueListenable: isLightModeNotifier,
                builder: (context, isLight, _) {
                  final isDark = !isLight;
                  final foreground = isDark ? Colors.white : Colors.black87;

                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () {
                            Navigator.popAndPushNamed(context, 'home');
                          },
                          icon: Icon(Icons.arrow_back, color: foreground),
                          label: Text(
                            'Kembali',
                            style: TextStyle(color: foreground),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _CompassProofOfConcept(
                        compassService: compassService,
                        isDark: isDark,
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompassProofOfConcept extends StatelessWidget {
  const _CompassProofOfConcept({
    required this.compassService,
    required this.isDark,
  });

  final CompassService compassService;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<double?>(
      stream: compassService.headingStream,
      builder: (context, snapshot) {
        final heading = snapshot.data;
        final sensorActive = heading != null;
        final cardColor =
            isDark
                ? const Color.fromARGB(255, 36, 67, 42)
                : const Color.fromARGB(240, 180, 216, 187);
        final foreground = isDark ? Colors.white : Colors.black87;

        return Card(
          color: cardColor,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(
                  'KOMPAS TEST',
                  style: TextStyle(
                    color: foreground,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                Icon(Icons.navigation, size: 72, color: foreground),
                const SizedBox(height: 16),
                if (sensorActive) ...[
                  Text(
                    '${heading.toStringAsFixed(1)}°',
                    style: TextStyle(
                      color: foreground,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    cardinalDirection(heading),
                    style: TextStyle(color: foreground, fontSize: 22),
                  ),
                ] else
                  Text(
                    'Sensor kompas tidak tersedia\natau belum dapat dibaca.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: foreground, fontSize: 18),
                  ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      sensorActive ? Icons.sensors : Icons.sensors_off,
                      color: sensorActive ? Colors.greenAccent : Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Sensor: ${sensorActive ? 'Aktif' : 'Tidak tersedia'}',
                      style: TextStyle(color: foreground),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Jika arah tidak stabil, jauhkan perangkat dari magnet '
                  'atau benda logam lalu lakukan kalibrasi kompas.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: foreground.withValues(alpha: 0.8)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
