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

                          // Latar Belakang
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
                                        'Azimutree 🌲🧭',
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
                                      _sectionTitle(context, 'Latar Belakang'),
                                      Text(
                                        'Dalam penelitian kesehatan hutan, kondisi lingkungan dapat berubah dari waktu ke waktu akibat faktor internal maupun eksternal. Perubahan ini sering menyebabkan lokasi cluster plot hasil penelitian terdahulu mengalami perbedaan kondisi vegetasi dan lingkungan, sehingga menyulitkan peneliti saat melakukan pengamatan lanjutan. Permasalahan semakin kompleks karena pengamatan kesehatan hutan dilakukan secara berkala dan tidak jarang melibatkan peneliti yang berbeda. Meskipun data penelitian sebelumnya biasanya menyertakan koordinat lokasi, data tersebut umumnya masih disimpan dalam bentuk file Excel, sehingga kurang praktis untuk digunakan langsung di lapangan.',
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

                          // Konsep Cluster Plot
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
                                        'Konsep Cluster Plot',
                                      ),
                                      const SizedBox(height: 8),
                                      Center(
                                        child: InkWell(
                                          onTap: () {
                                            final asset =
                                                isDark
                                                    ? 'assets/images/dark-cl-plot.png'
                                                    : 'assets/images/light-cl-plot.png';
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder:
                                                    (context) => Scaffold(
                                                      backgroundColor:
                                                          isDark
                                                              ? Colors.black
                                                              : Colors.white,
                                                      appBar: AppBar(
                                                        backgroundColor:
                                                            Colors.transparent,
                                                        elevation: 0,
                                                        iconTheme: IconThemeData(
                                                          color:
                                                              isDark
                                                                  ? Colors.white
                                                                  : Colors
                                                                      .black,
                                                        ),
                                                      ),
                                                      body: Center(
                                                        child: Hero(
                                                          tag:
                                                              'cluster-plot-image',
                                                          child: Image.asset(
                                                            asset,
                                                            fit: BoxFit.contain,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                              ),
                                            );
                                          },
                                          child: Container(
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              color:
                                                  isDark
                                                      ? Colors.black
                                                      : Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            padding: const EdgeInsets.all(8),
                                            child: Hero(
                                              tag: 'cluster-plot-image',
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                child: Image.asset(
                                                  isDark
                                                      ? 'assets/images/dark-cl-plot.png'
                                                      : 'assets/images/light-cl-plot.png',
                                                  height: 180,
                                                  fit: BoxFit.contain,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      _bullet(
                                        'Satu cluster maksimal memiliki 4 plot.',
                                      ),
                                      _bullet(
                                        'Plot 1 berfungsi sebagai sentroid (pusat cluster).',
                                      ),
                                      _bullet(
                                        'Plot lainnya mengelilingi plot pusat.',
                                      ),
                                      _bullet(
                                        'Setiap plot terdiri dari beberapa pohon terpilih yang merepresentasikan kondisi kesehatan hutan.',
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 12),

                          // Tujuan Aplikasi
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
                                      _sectionTitle(context, 'Tujuan Aplikasi'),
                                      _bullet(
                                        'Memvisualisasikan titik koordinat cluster dan plot pada peta digital.',
                                      ),
                                      _bullet(
                                        'Mempermudah peneliti menemukan kembali lokasi penelitian sebelumnya di lapangan.',
                                      ),
                                      _bullet(
                                        'Mengurangi kesalahan penentuan posisi plot akibat perubahan kondisi hutan.',
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Aplikasi ini berfokus pada pencatatan dan visualisasi lokasi, bukan pada pencatatan detail nilai kesehatan pohon atau hutan.',
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

                          // Fitur Utama
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
                                        'Visualisasi peta digital menggunakan Mapbox.',
                                      ),
                                      _bullet(
                                        'Penentuan posisi cluster dan plot berdasarkan koordinat geografis.',
                                      ),
                                      _bullet(
                                        'Informasi sudut azimut, jarak dari pusat cluster, dan jarak dari posisi pengguna.',
                                      ),
                                      _bullet(
                                        'Impor data dalam jumlah besar (dibatasi untuk satu cluster).',
                                      ),
                                      _bullet(
                                        'Ekspor data ke format Excel untuk memudahkan berbagi data antar peneliti.',
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 12),

                          // Teknologi yang Digunakan
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
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 6,
                                        ),
                                        child: RichText(
                                          text: TextSpan(
                                            children: [
                                              TextSpan(
                                                text: 'Flutter',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color:
                                                      isDark
                                                          ? Colors.white
                                                          : Colors.black,
                                                ),
                                              ),
                                              TextSpan(
                                                text:
                                                    ' sebagai framework pengembangan aplikasi.',
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
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 6,
                                        ),
                                        child: RichText(
                                          text: TextSpan(
                                            children: [
                                              TextSpan(
                                                text: 'SQLite',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color:
                                                      isDark
                                                          ? Colors.white
                                                          : Colors.black,
                                                ),
                                              ),
                                              TextSpan(
                                                text:
                                                    ' untuk penyimpanan data lokal.',
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
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 6,
                                        ),
                                        child: RichText(
                                          text: TextSpan(
                                            children: [
                                              TextSpan(
                                                text: 'Mapbox',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color:
                                                      isDark
                                                          ? Colors.white
                                                          : Colors.black,
                                                ),
                                              ),
                                              TextSpan(
                                                text:
                                                    ' untuk pemetaan dan visualisasi lokasi.',
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
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 12),

                          // Manfaat
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
                                      _sectionTitle(context, 'Manfaat'),
                                      _bullet(
                                        'Lebih mudah melakukan pengamatan ulang di lokasi yang sama pada periode penelitian berikutnya.',
                                      ),
                                      _bullet(
                                        'Menghemat waktu pencarian lokasi cluster dan plot di lapangan.',
                                      ),
                                      _bullet(
                                        'Berbagi data lokasi penelitian secara lebih praktis dan terstruktur.',
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 12),

                          // Penutup
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
                                      _sectionTitle(context, 'Penutup'),
                                      Text(
                                        'Azimutree diharapkan dapat menjadi alat bantu yang efektif bagi peneliti kesehatan hutan dalam menjaga konsistensi lokasi penelitian, serta mendukung keberlanjutan pengamatan kondisi hutan dari waktu ke waktu.',
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
