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
                padding: const EdgeInsets.symmetric(horizontal: 16),
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
                                  iconColor: isDark ? Colors.white : null,
                                  collapsedIconColor:
                                      isDark ? Colors.white : null,
                                  childrenPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  children: [
                                    bold('Menu Tombol Besar'),
                                    normal(
                                      '• Kelola Data Klaster Plot – Mengelola data Klaster, plot, dan pohon.\n'
                                      '• Peta Lokasi Klaster Plot – Menampilkan visualisasi data di peta.\n'
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
                                      '2. Kelola Data Klaster Plot 🌳',
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
                                  iconColor: isDark ? Colors.white : null,
                                  collapsedIconColor:
                                      isDark ? Colors.white : null,
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

                                    bold('Input Manual Klaster'),
                                    normal(
                                      '1. Masukkan Kode Klaster.\n'
                                      '2. Masukkan Nama Pengukur.\n'
                                      '3. Pilih Tanggal Pengukuran.\n'
                                      '4. Tekan Simpan untuk menyimpan informasi klaster.',
                                    ),

                                    const SizedBox(height: 8),
                                    bold('Input Manual Plot'),
                                    normal(
                                      '1. Pilih Klaster (dropdown).\n'
                                      '2. Pilih Plot (maksimal 4 plot per klaster).\n'
                                      '   • Jika semua plot dalam klaster sudah terisi, '
                                      'opsi tidak dapat dipilih.\n'
                                      '3. Masukkan Lintang.\n'
                                      '4. Masukkan Bujur.\n'
                                      '5. Masukkan Altitude (opsional).',
                                    ),

                                    const SizedBox(height: 8),
                                    bold('Input Manual Pohon'),
                                    normal(
                                      '1. Pilih Klaster.\n'
                                      '2. Pilih Plot.\n'
                                      '3. Pilih metode input posisi:\n'
                                      '   • Azimut & Jarak, atau\n'
                                      '   • Koordinat Bebas (Lintang & Bujur).\n'
                                      '   (Hanya bisa memilih salah satu).\n'
                                      '4. Masukkan Altitude (opsional).\n'
                                      '5. Masukkan Kode Pohon (gunakan angka).\n'
                                      '6. Masukkan Nama Pohon.\n'
                                      '7. Masukkan Nama Ilmiah.\n'
                                      '8. Masukkan Keterangan (opsional).\n'
                                      '9. Masukkan URL Foto.\n'
                                      '   • Disarankan Google Drive.\n'
                                      '   • Pastikan URL bersifat Public.\n'
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
                                    const SizedBox(height: 8),
                                    bold('Impor Data Menggunakan Excel'),
                                    normal(
                                      'Azimutree menyediakan fitur impor data menggunakan file Excel untuk mempermudah input data dalam jumlah besar.\n'
                                      'Langkah-langkah impor data:\n'
                                      '1. Tekan Unduh Template untuk mendapatkan format Excel resmi.\n'
                                      '2. Isi file Excel sesuai format template (format harus sama persis).\n'
                                      '3. Tekan Impor Data.\n'
                                      '4. Isi dialog impor:\n'
                                      '   • Kode Klaster\n'
                                      '   • Nama Pengukur\n'
                                      '   • Tanggal Pengukuran\n'
                                      '   • Pilih File Excel\n'
                                      '   • Berikan izin akses penyimpanan jika diminta.\n'
                                      '5. Tekan tombol Impor.',
                                    ),
                                    const SizedBox(height: 8),
                                    normal(
                                      'Catatan:\n'
                                      '• Pastikan data pada file Excel sudah benar sebelum mengimpor.\n'
                                      '• Jika terdapat kesalahan format atau data duplikat, proses impor akan gagal dan menampilkan pesan error.\n'
                                      '• Data yang berhasil diimpor akan langsung muncul di daftar Kelola Data dan di peta.',
                                    ),
                                    const SizedBox(height: 8),
                                    bold('Ekspor Data'),
                                    normal(
                                      'Menu Ekspor Data digunakan untuk membagikan data antar pengguna Azimutree.\n'
                                      'Data akan diekspor dalam bentuk file Excel.\n'
                                      'File hasil ekspor dapat langsung diimpor oleh pengguna Azimutree lainnya.',
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
                                      '3. Peta Lokasi Klaster Plot 🗺️',
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
                                  iconColor: isDark ? Colors.white : null,
                                  collapsedIconColor:
                                      isDark ? Colors.white : null,
                                  childrenPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  children: [
                                    // 3.1 Marker dan Warna
                                    bold('Marker dan Warna'),
                                    normal(
                                      'Pada peta lokasi klaster plot, marker dan warna memiliki arti sebagai berikut:\n'
                                      '• Biru 🔵 : Marker Plot\n'
                                      '• Ungu 🟣 : Sentroid otomatis (jika klaster tidak memiliki Plot 1)\n'
                                      '• Oranye 🟠 : Marker Pohon\n'
                                      '• Hijau 🟢 : Pohon yang sudah diinspeksi\n'
                                      '• Merah 🔴 : Marker hasil pencarian lokasi\n',
                                    ),

                                    // Garis pada peta (inline examples)
                                    bold('Garis pada peta'),
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: RichText(
                                        text: TextSpan(
                                          style: TextStyle(
                                            color: bodyColor,
                                            fontSize: 14,
                                          ),
                                          children: [
                                            const TextSpan(
                                              text: '• Garis Merah ',
                                            ),
                                            WidgetSpan(
                                              alignment:
                                                  PlaceholderAlignment.middle,
                                              child: Container(
                                                width: 24,
                                                height: 6,
                                                margin:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Colors.redAccent,
                                                  borderRadius:
                                                      BorderRadius.circular(2),
                                                ),
                                              ),
                                            ),
                                            const TextSpan(
                                              text:
                                                  ': Relasi antara pohon ke plot.\n',
                                            ),
                                            const TextSpan(
                                              text: '• Garis Biru ',
                                            ),
                                            WidgetSpan(
                                              alignment:
                                                  PlaceholderAlignment.middle,
                                              child: Container(
                                                width: 24,
                                                height: 6,
                                                margin:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Colors.blueAccent,
                                                  borderRadius:
                                                      BorderRadius.circular(2),
                                                ),
                                              ),
                                            ),
                                            const TextSpan(
                                              text:
                                                  ': Relasi antara plot ke plot atau plot ke sentroid.\n\n',
                                            ),
                                            const TextSpan(
                                              text:
                                                  'Informasi warna marker dan garis dapat dilihat pada legenda di kanan bawah peta.',
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 12),

                                    // 3.2 Bottom Sheet Peta
                                    bold('Bottom Sheet Peta'),
                                    normal(
                                      'Di bagian bawah peta tersedia bottom sheet dengan fungsi:\n'
                                      '• Pencarian lokasi (nama kota, tempat, dll).\n'
                                      '• Mengganti tipe peta: Satelit / Medan.\n'
                                      '• Tombol menyalakan lokasi pengguna.\n'
                                      '• Tombol mengarahkan peta ke utara.\n\n'
                                      'Catatan: Nama tempat pada peta bersifat non-interaktif karena keterbatasan layanan peta.',
                                    ),

                                    const SizedBox(height: 12),

                                    // 3.3 Interaksi Marker
                                    bold('Interaksi Marker'),
                                    normal(
                                      'Data klaster dari menu Kelola Data akan otomatis muncul di peta.\n'
                                      '• Marker dapat ditekan untuk melihat relasi antar plot dan pohon.\n'
                                      '• Saat marker ditekan, informasi muncul di pojok kiri atas dan juga tersedia di bottom sheet.\n'
                                      '• Pengguna dapat melakukan centering kamera ke marker.',
                                    ),

                                    const SizedBox(height: 12),

                                    // 3.4 Map Tools
                                    bold('Map Tools'),
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: RichText(
                                        text: TextSpan(
                                          style: TextStyle(
                                            color: bodyColor,
                                            fontSize: 14,
                                          ),
                                          children: [
                                            const TextSpan(
                                              text:
                                                  'Di pojok kanan atas terdapat Map Tools, yang membuka sidebar kanan dengan beberapa fitur:\n\n',
                                            ),
                                            TextSpan(
                                              text: '• Klik Marker',
                                              style: TextStyle(
                                                fontStyle: FontStyle.italic,
                                                color: bodyColor,
                                              ),
                                            ),
                                            TextSpan(
                                              text:
                                                  ' – mengaktifkan/menonaktifkan interaksi sentuhan marker.\n\n',
                                              style: TextStyle(
                                                color: bodyColor,
                                              ),
                                            ),
                                            TextSpan(
                                              text: '• Tampilkan Legenda',
                                              style: TextStyle(
                                                fontStyle: FontStyle.italic,
                                                color: bodyColor,
                                              ),
                                            ),
                                            TextSpan(
                                              text:
                                                  ' – menampilkan atau menyembunyikan legenda peta.\n\n',
                                              style: TextStyle(
                                                color: bodyColor,
                                              ),
                                            ),
                                            TextSpan(
                                              text: '• Tampilkan Info Marker',
                                              style: TextStyle(
                                                fontStyle: FontStyle.italic,
                                                color: bodyColor,
                                              ),
                                            ),
                                            TextSpan(
                                              text:
                                                  ' – menampilkan atau menyembunyikan info marker di layar.\n\n',
                                              style: TextStyle(
                                                color: bodyColor,
                                              ),
                                            ),
                                            TextSpan(
                                              text: '• Workflow Inspeksi',
                                              style: TextStyle(
                                                fontStyle: FontStyle.italic,
                                                color: bodyColor,
                                              ),
                                            ),
                                            TextSpan(
                                              text:
                                                  ' – menampilkan tombol Tandai (Mark) pada marker; pohon yang ditandai akan berubah warna menjadi hijau.\n\n',
                                              style: TextStyle(
                                                color: bodyColor,
                                              ),
                                            ),
                                            TextSpan(
                                              text: '• Tampilkan Garis Relasi',
                                              style: TextStyle(
                                                fontStyle: FontStyle.italic,
                                                color: bodyColor,
                                              ),
                                            ),
                                            TextSpan(
                                              text:
                                                  ' – menampilkan atau menyembunyikan garis relasi antar marker.\n',
                                              style: TextStyle(
                                                color: bodyColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 12),

                                    // 3.5 Navigasi Lapangan
                                    bold('Navigasi Lapangan'),
                                    normal(
                                      'Jika fitur Workflow Inspeksi dan Lokasi Pengguna aktif, informasi jarak dan arah dari posisi pengguna ke marker yang dipilih akan ditampilkan pada Marker Info di pojok kiri atas.\n'
                                      'Fitur ini sangat membantu peneliti dalam bergerak menuju pohon atau plot yang akan diamati secara langsung di lapangan.',
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
                                  iconColor: isDark ? Colors.white : null,
                                  collapsedIconColor:
                                      isDark ? Colors.white : null,
                                  childrenPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  children: [
                                    normal(
                                      '• Ganti Tema Terang / Gelap.\n'
                                      '• Mode Debug pada fitur kelola data:\n'
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
