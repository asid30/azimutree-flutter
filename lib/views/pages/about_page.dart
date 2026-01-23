import 'package:azimutree/views/widgets/core_widget/appbar_widget.dart';
import 'package:azimutree/views/widgets/core_widget/background_app_widget.dart';
import 'package:azimutree/views/widgets/core_widget/sidebar_widget.dart';
import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  Widget _sectionTitle(BuildContext context, String text) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text('• $text', textAlign: TextAlign.left),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        BackButton(
                          onPressed: () {
                            Navigator.popAndPushNamed(context, "home");
                          },
                        ),
                        const Text("Kembali", style: TextStyle(fontSize: 18)),
                      ],
                    ),

                    Card(
                      color: Color.fromARGB(240, 180, 216, 187),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Azimutree - Pemantauan Kesehatan Hutan',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Azimutree adalah aplikasi Android yang dikembangkan untuk membantu proses pemantauan kesehatan hutan menggunakan metode Forest Health Monitoring (FHM). Aplikasi ini dirancang untuk mendukung kegiatan penelitian lapangan dengan fitur pemetaan digital yang efisien dan akurat.',
                              textAlign: TextAlign.justify,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    Card(
                      color: Color.fromARGB(240, 180, 216, 187),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
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
                    ),
                    const SizedBox(height: 12),

                    Card(
                      color: Color.fromARGB(240, 180, 216, 187),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _sectionTitle(context, 'Teknologi yang Digunakan'),
                            _bullet('Flutter (Frontend App Development)'),
                            _bullet(
                              'SQLite (Local database untuk penyimpanan data offline)',
                            ),
                            _bullet(
                              'MapBox (Platform peta digital untuk menampilkan dan mengelola data lokasi berbasis koordinat secara interaktif)',
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    const Center(
                      child: Text(
                        'Dikembangkan oleh Asid30 © 2026',
                        style: TextStyle(
                          fontSize: 12,
                          backgroundColor: Color.fromARGB(240, 180, 216, 187),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
