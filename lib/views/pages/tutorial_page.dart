import 'package:azimutree/data/notifiers/notifiers.dart';
import 'package:azimutree/views/widgets/appbar_widget.dart';
import 'package:azimutree/views/widgets/sidebar_widget.dart';
import 'package:flutter/material.dart';

class TutorialPage extends StatelessWidget {
  const TutorialPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppbarWidget(title: "Panduan Aplikasi"),
      drawer: const SidebarWidget(),
      body: Stack(
        children: [
          //* Background App
          ValueListenableBuilder(
            valueListenable: isLightModeNotifier,
            builder: (context, isLightMode, child) {
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 800),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(opacity: animation, child: child);
                },
                child: Image(
                  key: ValueKey<bool>(isLightMode),
                  image: AssetImage(
                    isLightMode
                        ? "assets/images/light-bg-notitle.png"
                        : "assets/images/dark-bg-notitle.png",
                  ),
                  fit: BoxFit.cover,
                  height: double.infinity,
                  width: double.infinity,
                ),
              );
            },
          ),
          //* Konten Panduan
          // Bungkus konten panduan dengan ValueListenableBuilder untuk warna teks dinamis
          ValueListenableBuilder(
            valueListenable: isLightModeNotifier,
            builder: (context, isLightMode, child) {
              final Color textColor = isLightMode ? Colors.black : Colors.white;
              final Color secondaryTextColor =
                  isLightMode ? Colors.black87 : Colors.white70;
              final Color iconColor =
                  isLightMode ? Colors.green[700]! : Colors.greenAccent[100]!;
              final Color dividerColor =
                  isLightMode ? Colors.black38 : Colors.white38;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selamat Datang di Aplikasi Azimutree!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: textColor, // Warna teks dinamis
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      'Panduan ini akan membantu Anda memahami cara menggunakan aplikasi Azimutree untuk mengelola data klaster, plot, dan pohon.',
                      style: TextStyle(
                        fontSize: 16,
                        color: secondaryTextColor, // Warna teks dinamis
                      ),
                    ),
                    Divider(
                      height: 30,
                      thickness: 1,
                      color: dividerColor,
                    ), // Warna divider dinamis

                    _buildSection(
                      context,
                      title: '1. Pengelolaan Data Klaster & Plot',
                      content:
                          'Aplikasi ini memungkinkan Anda untuk mengelola data klaster dan plot kehutanan. Setiap klaster dapat memiliki banyak plot, dan setiap plot memiliki koordinat titik pusat (Latitude, Longitude, Altitude) yang wajib diisi. Koordinat klaster ditentukan oleh titik pusat plot pertamanya.',
                      icon: Icons.map,
                      textColor: textColor,
                      secondaryTextColor: secondaryTextColor,
                      iconColor: iconColor,
                    ),
                    const SizedBox(height: 20),

                    _buildSection(
                      context,
                      title: '2. Data Pohon dan Perhitungan Koordinat',
                      content:
                          'Untuk setiap pohon di dalam plot, Anda akan mendata Azimuth (sudut dari titik pusat plot) dan Jarak dari Titik Pusat (dalam meter). Aplikasi secara otomatis akan menghitung koordinat Latitude dan Longitude pohon berdasarkan data ini dan koordinat titik pusat plot. Ketinggian pohon akan mengikuti ketinggian plot.',
                      icon: Icons.forest,
                      textColor: textColor,
                      secondaryTextColor: secondaryTextColor,
                      iconColor: iconColor,
                    ),
                    const SizedBox(height: 20),

                    _buildSection(
                      context,
                      title: '3. Impor Data dari Excel',
                      content:
                          'Anda dapat dengan mudah mengimpor data klaster, plot, dan pohon dari file Excel yang sudah terstandardisasi. Pastikan format Excel Anda sesuai dengan template yang disediakan agar data dapat terbaca dengan benar. Fitur ini akan mempermudah Anda dalam memasukkan data dalam jumlah besar.',
                      icon: Icons.upload_file,
                      textColor: textColor,
                      secondaryTextColor: secondaryTextColor,
                      iconColor: iconColor,
                    ),
                    const SizedBox(height: 20),

                    _buildSection(
                      context,
                      title: '4. Tampilan Data',
                      content:
                          'Setelah data diimpor, Anda dapat melihat ringkasan data klaster, daftar plot beserta koordinatnya, dan detail setiap pohon termasuk koordinat yang sudah dihitung. Ini membantu Anda memvisualisasikan struktur data dan distribusi pohon.',
                      icon: Icons.list_alt,
                      textColor: textColor,
                      secondaryTextColor: secondaryTextColor,
                      iconColor: iconColor,
                    ),
                    const SizedBox(height: 20),

                    _buildSection(
                      context,
                      title: '5. Pengaturan Tema',
                      content:
                          'Aplikasi dilengkapi dengan fitur Light/Dark Mode. Anda bisa mengubah tema aplikasi melalui sidebar untuk pengalaman visual yang lebih nyaman sesuai preferensi Anda.',
                      icon: Icons.brightness_6,
                      textColor: textColor,
                      secondaryTextColor: secondaryTextColor,
                      iconColor: iconColor,
                    ),
                    const SizedBox(height: 30),

                    Text(
                      'Terima kasih telah menggunakan Azimutree!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor, // Warna teks dinamis
                      ),
                    ),
                    const SizedBox(height: 50),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // Helper method untuk membuat bagian panduan
  Widget _buildSection(
    BuildContext context, {
    required String title,
    required String content,
    required IconData icon,
    required Color textColor, // Tambahkan parameter warna teks
    required Color
    secondaryTextColor, // Tambahkan parameter warna teks sekunder
    required Color iconColor, // Tambahkan parameter warna ikon
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: iconColor,
              size: 28,
            ), // Gunakan warna ikon dinamis
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textColor, // Gunakan warna teks dinamis
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: TextStyle(
            fontSize: 15,
            color: secondaryTextColor, // Gunakan warna teks sekunder dinamis
          ),
        ),
      ],
    );
  }
}
