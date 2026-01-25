import 'package:azimutree/views/widgets/core_widget/appbar_widget.dart';
import 'package:azimutree/views/widgets/core_widget/background_app_widget.dart';
import 'package:azimutree/views/widgets/core_widget/sidebar_widget.dart';
import 'package:azimutree/data/notifiers/notifiers.dart';
import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  Widget _sectionTitle(BuildContext context, String text) {
    final theme = Theme.of(context);
    final isDark = !isLightModeNotifier.value;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : Colors.black,
        ),
      ),
    );
  }

  Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        '• $text',
        textAlign: TextAlign.left,
        style: TextStyle(
          color: !isLightModeNotifier.value ? Colors.white : Colors.black,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }
        Navigator.pushNamedAndRemoveUntil(context, 'home', (route) => false);
      },
      child: Scaffold(
        appBar: const AppbarWidget(title: "Tentang Aplikasi"),
        drawer: const SidebarWidget(),
        body: Stack(
          children: [
            //* Background App
            BackgroundAppWidget(
              lightBackgroundImage: "assets/images/light-bg-notitle.png",
              darkBackgroundImage: "assets/images/dark-bg-notitle.png",
            ),
            //* Content
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 0,
                ),
                child: ValueListenableBuilder<bool>(
                  valueListenable: isLightModeNotifier,
                  builder: (context, isLight, child) {
                    final isDark = !isLight;
                    return DefaultTextStyle(
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              ValueListenableBuilder<bool>(
                                valueListenable: isLightModeNotifier,
                                builder: (context, isLight, child) {
                                  return BackButton(
                                    color: isLight ? null : Colors.white,
                                    onPressed: () {
                                      Navigator.popAndPushNamed(
                                        context,
                                        "home",
                                      );
                                    },
                                  );
                                },
                              ),
                              ValueListenableBuilder<bool>(
                                valueListenable: isLightModeNotifier,
                                builder: (context, isLight, child) {
                                  return Text(
                                    "Kembali",
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: isLight ? null : Colors.white,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ValueListenableBuilder<bool>(
                            valueListenable: isLightModeNotifier,
                            builder: (context, isLightMode, _) {
                              final isDark = !isLightMode;
                              return Card(
                                color:
                                    isDark
                                        ? const Color.fromARGB(255, 36, 67, 42)
                                        : const Color.fromARGB(
                                          240,
                                          180,
                                          216,
                                          187,
                                        ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Azimutree - Pemantauan Kesehatan Hutan',
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color:
                                              isDark
                                                  ? Colors.white
                                                  : Colors.black,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Azimutree adalah aplikasi Android yang dikembangkan untuk membantu proses pemantauan kesehatan hutan menggunakan metode Forest Health Monitoring (FHM). Aplikasi ini dirancang untuk mendukung kegiatan penelitian lapangan dengan fitur pemetaan digital yang efisien dan akurat.',
                                        textAlign: TextAlign.justify,
                                        style: TextStyle(
                                          color:
                                              isDark
                                                  ? Colors.white
                                                  : Colors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          ValueListenableBuilder<bool>(
                            valueListenable: isLightModeNotifier,
                            builder: (context, isLightMode, _) {
                              final isDark = !isLightMode;
                              return Card(
                                color:
                                    isDark
                                        ? const Color.fromARGB(255, 36, 67, 42)
                                        : const Color.fromARGB(
                                          240,
                                          180,
                                          216,
                                          187,
                                        ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _sectionTitle(context, 'Fitur Utama'),
                                      _bullet(
                                        'Mapping Lokasi Pohon: menampilkan posisi pohon dalam satu klaster menggunakan data azimut dan jarak dari titik pusat klaster.',
                                      ),
                                      _bullet(
                                        'Manajemen Data Klaster: menyimpan dan menampilkan informasi lengkap tentang plot, klaster, dan pohon-pohon yang berada dalam area monitoring.',
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          ValueListenableBuilder<bool>(
                            valueListenable: isLightModeNotifier,
                            builder: (context, isLightMode, _) {
                              final isDark = !isLightMode;
                              return Card(
                                color:
                                    isDark
                                        ? const Color.fromARGB(255, 36, 67, 42)
                                        : const Color.fromARGB(
                                          240,
                                          180,
                                          216,
                                          187,
                                        ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _sectionTitle(
                                        context,
                                        'Teknologi yang Digunakan',
                                      ),
                                      _bullet(
                                        'Flutter (Frontend App Development)',
                                      ),
                                      _bullet(
                                        'SQLite (Local database untuk penyimpanan data offline)',
                                      ),
                                      _bullet(
                                        'MapBox (Platform peta digital untuk menampilkan dan mengelola data lokasi berbasis koordinat secara interaktif)',
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
