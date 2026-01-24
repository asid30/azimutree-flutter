//* tutorial page
import 'package:azimutree/views/widgets/core_widget/appbar_widget.dart';
import 'package:azimutree/views/widgets/core_widget/background_app_widget.dart';
import 'package:azimutree/views/widgets/core_widget/sidebar_widget.dart';
import 'package:azimutree/data/notifiers/notifiers.dart';
import 'package:flutter/material.dart';

class TutorialPage extends StatelessWidget {
  const TutorialPage({super.key});

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
        appBar: const AppbarWidget(title: "Panduan Aplikasi"),
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
                        ValueListenableBuilder<bool>(
                          valueListenable: isLightModeNotifier,
                          builder: (context, isLight, child) {
                            return BackButton(
                              color: isLight ? null : Colors.white,
                              onPressed: () {
                                Navigator.popAndPushNamed(context, "home");
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

                    Card(
                      color: const Color.fromARGB(240, 180, 216, 187),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Panduan Singkat Azimutree',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Panduan ini memperkenalkan alur kerja dasar aplikasi: membuat klaster, menambahkan plot, lalu merekam pohon beserta lokasi dan foto. Ikuti langkah-langkah di bawah untuk memulai.',
                              textAlign: TextAlign.justify,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    Card(
                      color: const Color.fromARGB(240, 180, 216, 187),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Langkah Awal',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              '• Buat Klaster baru: buka Kelola Data → Tambah Klaster.',
                            ),
                            const Text(
                              '• Tambah Plot: setelah klaster dibuat, tambahkan plot pada klaster tersebut.',
                            ),
                            const Text(
                              '• Rekam Pohon: pada plot, tambahkan data pohon termasuk azimut, jarak, dan (opsional) foto.',
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Setiap perubahan disimpan secara lokal.',
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    Card(
                      color: const Color.fromARGB(240, 180, 216, 187),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Fitur Utama',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              '• Visualisasi plot dan pohon di peta interaktif.',
                            ),
                            const Text(
                              '• Edit dan hapus data plot/pohon melalui antarmuka manajemen data.',
                            ),
                            const Text(
                              '• Pratinjau foto pohon dan tracking lokasi ke peta.',
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    Card(
                      color: const Color.fromARGB(240, 180, 216, 187),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Tips & Praktik Lapangan',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 8),
                            Text(
                              '• Pastikan perangkat memiliki GPS aktif dan akurasi yang baik saat merekam lokasi.',
                            ),
                            Text(
                              '• Ambil beberapa foto dari sudut berbeda jika kondisi pencahayaan buruk.',
                            ),
                            Text(
                              '• Simpan data secara berkala saat bekerja di lapangan untuk menghindari kehilangan data.',
                            ),
                          ],
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
