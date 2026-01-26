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
        if (didPop) return;
        Navigator.pushNamedAndRemoveUntil(context, 'home', (route) => false);
      },
      child: Scaffold(
        appBar: const AppbarWidget(title: 'Panduan Aplikasi'),
        drawer: const SidebarWidget(),
        body: Stack(
          children: [
            BackgroundAppWidget(
              lightBackgroundImage: 'assets/images/light-bg-notitle.png',
              darkBackgroundImage: 'assets/images/dark-bg-notitle.png',
            ),
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: ValueListenableBuilder<bool>(
                  valueListenable: isLightModeNotifier,
                  builder: (context, isLight, _) {
                    final isDark = !isLight;
                    final bodyColor = isDark ? Colors.white70 : Colors.black87;

                    Widget bold(String text) => Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        text,
                        textAlign: TextAlign.left,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: bodyColor,
                        ),
                      ),
                    );

                    Widget normal(String text) => Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        text,
                        textAlign: TextAlign.left,
                        style: TextStyle(color: bodyColor),
                      ),
                    );

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            BackButton(
                              color: isDark ? Colors.white : null,
                              onPressed:
                                  () => Navigator.popAndPushNamed(
                                    context,
                                    'home',
                                  ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Panduan Aplikasi',
                              textAlign: TextAlign.left,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        Card(
                          color:
                              isDark
                                  ? const Color.fromARGB(255, 36, 67, 42)
                                  : const Color.fromARGB(240, 180, 216, 187),
                          child: Theme(
                            data: Theme.of(
                              context,
                            ).copyWith(dividerColor: Colors.transparent),
                            child: Column(
                              children: [
                                /// =============================
                                /// 1. DASHBOARD
                                /// =============================
                                ExpansionTile(
                                  title: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      '1. Tampilan Dashboard 🏠',
                                      textAlign: TextAlign.left,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color:
                                            isDark
                                                ? Colors.white
                                                : Colors.black,
                                      ),
                                    ),
                                  ),
                                  childrenPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  children: [
                                    bold('Menu Tombol Besar'),
                                    normal(
                                      '• Kelola Data Cluster Plot – Mengelola data cluster, plot, dan pohon.\n'
                                      '• Peta Lokasi Cluster Plot – Menampilkan visualisasi data di peta.\n'
                                      '• Panduan Aplikasi – Membuka halaman panduan ini.',
                                    ),

                                    const SizedBox(height: 8),
                                    bold('Menu Tombol Kecil'),
                                    normal(
                                      '• Settings – Pengaturan tema dan mode debug.\n'
                                      '• About Aplikasi – Informasi aplikasi.\n'
                                      '• Keluar – Menutup sesi aplikasi.',
                                    ),

                                    const SizedBox(height: 8),
                                    normal(
                                      'Sidebar dapat diakses dari pojok kiri atas. '
                                      'Tombol ganti tema tersedia di pojok kanan atas. 🌗',
                                    ),
                                  ],
                                ),

                                /// =============================
                                /// 2. KELOLA DATA
                                /// =============================
                                ExpansionTile(
                                  title: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      '2. Kelola Data Cluster Plot 🌳',
                                      textAlign: TextAlign.left,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color:
                                            isDark
                                                ? Colors.white
                                                : Colors.black,
                                      ),
                                    ),
                                  ),
                                  childrenPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  children: [
                                    bold('Akses Menu'),
                                    normal(
                                      'Gunakan Floating Action Button (FAB) untuk:\n'
                                      '• Input manual\n• Impor data Excel\n• Ekspor data\n• Unduh template',
                                    ),

                                    const SizedBox(height: 8),
                                    bold('Input Manual Plot'),
                                    normal(
                                      '1. Pilih Cluster (dropdown).\n'
                                      '2. Pilih Plot (maksimal 4 plot per cluster).\n'
                                      '   • Jika semua plot dalam cluster sudah terisi, '
                                      'opsi tidak dapat dipilih.\n'
                                      '3. Masukkan Latitude.\n'
                                      '4. Masukkan Longitude.\n'
                                      '5. Masukkan Altitude (opsional).',
                                    ),

                                    const SizedBox(height: 8),
                                    bold('Input Manual Pohon'),
                                    normal(
                                      '1. Pilih Cluster.\n'
                                      '2. Pilih Plot.\n'
                                      '3. Pilih metode input posisi:\n'
                                      '   • Azimut & Jarak, ATAU\n'
                                      '   • Koordinat Bebas (Latitude & Longitude).\n'
                                      '   (Hanya bisa memilih salah satu).\n'
                                      '4. Masukkan Altitude (opsional).\n'
                                      '5. Masukkan Kode Pohon (gunakan angka).\n'
                                      '6. Masukkan Nama Pohon.\n'
                                      '7. Masukkan Nama Ilmiah.\n'
                                      '8. Masukkan Keterangan (opsional).\n'
                                      '9. Masukkan URL Foto.\n'
                                      '   • Disarankan Google Drive.\n'
                                      '   • Pastikan URL bersifat PUBLIC.\n'
                                      '   • URL harus langsung menuju file gambar.',
                                    ),

                                    const SizedBox(height: 8),
                                    bold('Edit & Hapus Data Pohon'),
                                    normal(
                                      '• Geser ke kiri → Edit data ✏️\n'
                                      '• Geser ke kanan → Hapus data 🗑️\n'
                                      '• Data yang dihapus akan hilang permanen dan '
                                      'tidak dapat dikembalikan.',
                                    ),
                                  ],
                                ),

                                /// =============================
                                /// 3. MAP
                                /// =============================
                                ExpansionTile(
                                  title: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      '3. Peta Lokasi Cluster Plot 🗺️',
                                      textAlign: TextAlign.left,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color:
                                            isDark
                                                ? Colors.white
                                                : Colors.black,
                                      ),
                                    ),
                                  ),
                                  childrenPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  children: [
                                    bold('Marker & Warna'),
                                    normal(
                                      '• Biru 🔵 : Marker Plot\n'
                                      '• Ungu 🟣 : Sentroid otomatis (jika cluster tidak memiliki plot)\n'
                                      '• Oranye 🟠 : Marker Pohon\n'
                                      '• Hijau 🟢 : Pohon yang sudah diinspeksi\n'
                                      '• Merah 🔴 : Hasil pencarian lokasi',
                                    ),

                                    const SizedBox(height: 8),
                                    bold('Garis Relasi'),
                                    normal(
                                      '• Garis merah: hubungan pohon ke plot.\n'
                                      '• Garis biru: hubungan antar plot atau plot ke sentroid.',
                                    ),

                                    const SizedBox(height: 8),
                                    bold('Tipe Peta'),
                                    normal(
                                      '• Satelit 🛰️\n'
                                      '• Medan 🌄',
                                    ),

                                    const SizedBox(height: 8),
                                    bold('Workflow Inspeksi'),
                                    normal(
                                      'Jika lokasi pengguna aktif:\n'
                                      '• Jarak dan arah dari posisi pengguna ke marker '
                                      'yang dipilih akan ditampilkan.\n'
                                      '• Informasi muncul pada marker info di pojok kiri atas.\n'
                                      '• Sangat membantu peneliti menuju pohon atau plot '
                                      'yang akan diamati. 🧭',
                                    ),
                                  ],
                                ),

                                /// =============================
                                /// 4. SETTINGS
                                /// =============================
                                ExpansionTile(
                                  title: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      '4. Settings ⚙️',
                                      textAlign: TextAlign.left,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color:
                                            isDark
                                                ? Colors.white
                                                : Colors.black,
                                      ),
                                    ),
                                  ),
                                  childrenPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  children: [
                                    normal(
                                      '• Ganti Tema Terang / Gelap.\n'
                                      '• Mode Debug:\n'
                                      '  – Generate data acak.\n'
                                      '  – Hapus seluruh data (khusus pengujian).',
                                    ),
                                    SizedBox(height: 24),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
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
