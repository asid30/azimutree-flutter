import 'package:azimutree/data/notifiers/notifiers.dart';
import 'package:azimutree/views/widgets/core_widget/appbar_widget.dart';
import 'package:azimutree/views/widgets/core_widget/background_app_widget.dart';
import 'package:azimutree/views/widgets/core_widget/sidebar_widget.dart';
import 'package:flutter/material.dart';

/// Explains the application's primary data and field-survey workflows.
class TutorialPage extends StatelessWidget {
  const TutorialPage({super.key});

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) {
        Navigator.pushNamedAndRemoveUntil(context, 'home', (_) => false);
      }
    },
    child: Scaffold(
      appBar: const AppbarWidget(title: 'Panduan Aplikasi'),
      drawer: const SidebarWidget(),
      body: Stack(
        children: [
          const BackgroundAppWidget(
            lightBackgroundImage: 'assets/images/light-bg-notitle.png',
            darkBackgroundImage: 'assets/images/dark-bg-notitle.png',
          ),
          ValueListenableBuilder<bool>(
            valueListenable: isLightModeNotifier,
            builder: (context, isLight, _) {
              final foreground = isLight ? Colors.black87 : Colors.white;
              final cardColor =
                  isLight
                      ? const Color.fromARGB(240, 180, 216, 187)
                      : const Color.fromARGB(255, 36, 67, 42);
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                children: [
                  Row(
                    children: [
                      BackButton(
                        color: foreground,
                        onPressed:
                            () => Navigator.popAndPushNamed(context, 'home'),
                      ),
                      Text(
                        'Kembali',
                        style: TextStyle(fontSize: 18, color: foreground),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Card(
                    color: cardColor,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Panduan Azimutree 🌲🧭',
                            style: TextStyle(
                              color: foreground,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Buka bagian sesuai fitur yang ingin digunakan. Data disimpan di perangkat, kecuali data yang sengaja diunggah ke Penyimpanan Awan.',
                            style: TextStyle(color: foreground),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    clipBehavior: Clip.antiAlias,
                    color: cardColor,
                    child: Theme(
                      data: Theme.of(
                        context,
                      ).copyWith(dividerColor: Colors.transparent),
                      child: Column(
                        children: [
                          _GuideSection(
                            number: 1,
                            icon: Icons.home,
                            title: 'Beranda dan Navigasi',
                            foreground: foreground,
                            children: const [
                              _GuideParagraph(
                                'Empat menu utama adalah Kelola Data Klaster Plot, Peta Lokasi Klaster Plot, Survey Lokasi, dan Panduan Aplikasi.',
                              ),
                              _GuideSubtitle('Sidebar'),
                              _GuideBullets([
                                'Tekan ikon menu di kiri atas untuk berpindah halaman.',
                                'Kelola Data memiliki submenu Data Klaster dan Penyimpanan Awan.',
                                'Versi Aplikasi memuat catatan perubahan yang dipublikasikan melalui Firebase.',
                                'Tema dapat diganti melalui ikon kanan atas atau halaman Pengaturan.',
                              ]),
                            ],
                          ),
                          _GuideSection(
                            number: 2,
                            icon: Icons.storage,
                            title: 'Kelola Data Lokal',
                            foreground: foreground,
                            children: const [
                              _GuideSubtitle('Susunan data'),
                              _GuideParagraph(
                                'Satu klaster memiliki satu titik ikat, maksimal empat plot, dan setiap plot dapat memiliki banyak pohon.',
                              ),
                              _GuideSubtitle('Tambah Klaster dan titik ikat'),
                              _GuideBullets([
                                'Isi kode tanpa spasi. Huruf otomatis kapital, misalnya CL1.',
                                'Nama pengukur, tanggal, lintang, dan bujur titik ikat wajib diisi.',
                                'Nama titik ikat dibuat otomatis dari kode klaster.',
                                'Ketinggian, keterangan, dan link gambar bersifat opsional.',
                                'Gunakan Pilih dari Peta untuk mengambil koordinat secara visual.',
                              ]),
                              _GuideSubtitle('Tambah Plot'),
                              _GuideBullets([
                                'Pilih salah satu metode: Azimut & Jarak atau Lintang & Bujur.',
                                'Plot pertama mengacu pada titik ikat. Plot tersimpan kemudian dapat dipilih sebagai referensi.',
                                'Koordinat dari Azimut & Jarak dihitung berdasarkan referensi yang dipilih.',
                                'Jika pusat plot diedit, lokasi pohon tetap, sedangkan azimut dan jaraknya dihitung ulang.',
                              ]),
                              _GuideSubtitle('Tambah Pohon'),
                              _GuideBullets([
                                'Pilih klaster dan plot tempat pohon berada.',
                                'Gunakan salah satu metode posisi: Azimut & Jarak atau Lintang & Bujur.',
                                'Kode pohon wajib berupa angka. Lengkapi nama, nama ilmiah, ketinggian, keterangan, dan link gambar sesuai kebutuhan.',
                                'Pada pemilih koordinat, geser peta hingga pin tepat lalu tekan Gunakan Lokasi Ini.',
                              ]),
                              _GuideSubtitle('Kelola dan tracking'),
                              _GuideBullets([
                                'Pilih klaster dari dropdown untuk menampilkan seluruh data terkait.',
                                'Gunakan tombol edit, hapus, atau Tracking Data pada kartu data.',
                                'Menghapus klaster turut menghapus titik ikat, plot, dan pohon di dalamnya.',
                                'Tracking Data membuka peta dan memilih marker tujuan.',
                              ]),
                            ],
                          ),
                          _GuideSection(
                            number: 3,
                            icon: Icons.table_view,
                            title: 'Impor dan Ekspor Excel',
                            foreground: foreground,
                            children: const [
                              _GuideSubtitle('Ekspor'),
                              _GuideBullets([
                                'Pilih satu atau beberapa klaster yang akan diekspor.',
                                'Pilih folder tujuan terlebih dahulu, kemudian simpan file.',
                                'File berisi sheet panduan, klaster, titik_ikat, plot, dan pohon.',
                                'Nama file boleh diubah, tetapi nama sheet tidak boleh diubah.',
                              ]),
                              _GuideSubtitle('Impor'),
                              _GuideBullets([
                                'Gunakan template atau file hasil ekspor Azimutree.',
                                'Kolom bertanda * wajib diisi dan tidak boleh memiliki baris kosong.',
                                'Ikuti format tanggal pada sheet panduan.',
                                'Lintang dan bujur memakai desimal; azimut memakai derajat; jarak dan ketinggian memakai meter.',
                                'Periksa data setelah impor sebelum digunakan di lapangan.',
                              ]),
                            ],
                          ),
                          _GuideSection(
                            number: 4,
                            icon: Icons.map,
                            title: 'Peta Lokasi',
                            foreground: foreground,
                            children: const [
                              _GuideSubtitle('Marker dan area'),
                              _GuideBullets([
                                'Titik ikat memakai pin merah, plot berwarna biru, centroid ungu, dan pohon memakai ikon pohon.',
                                'Pohon yang selesai pada Workflow Inspeksi berubah menjadi hijau.',
                                'Area biru muda menunjukkan area plot berdasarkan pohon terjauh ditambah margin.',
                                'Tekan dan tahan marker untuk memilih. Detail tersedia pada kartu layar dan bottom sheet.',
                                'Tombol Sebelumnya/Berikutnya digunakan untuk berpindah marker.',
                              ]),
                              _GuideSubtitle('Pencarian dan kontrol'),
                              _GuideBullets([
                                'Pencarian mencakup lokasi Mapbox serta klaster, titik ikat, plot, dan pohon lokal.',
                                'Hasil lokal tetap tersedia jika Mapbox atau internet bermasalah.',
                                'Bottom sheet menyediakan tipe peta, lokasi pengguna, dan arah utara.',
                              ]),
                              _GuideSubtitle('Map Tools'),
                              _GuideBullets([
                                'Atur pemilihan marker, legenda, info marker, dan Workflow Inspeksi.',
                                'Garis Pohon → Plot dan Plot → Plot dapat diatur terpisah.',
                                'Ukuran marker titik ikat, plot, centroid, dan pohon dapat diubah satu per satu.',
                                'Pengaturan Map Tools disimpan untuk penggunaan berikutnya.',
                              ]),
                            ],
                          ),
                          _GuideSection(
                            number: 5,
                            icon: Icons.explore,
                            title: 'Survey Lokasi',
                            foreground: foreground,
                            children: const [
                              _GuideSubtitle('Sebelum mulai'),
                              _GuideBullets([
                                'Pilih klaster dan pastikan GPS serta izin lokasi aktif.',
                                'Gunakan tombol refresh jika GPS baru dinyalakan.',
                                'Mulai survey setelah berada di sekitar lokasi penelitian.',
                                'Sesi disimpan dan dapat dilanjutkan setelah kembali ke Beranda.',
                              ]),
                              _GuideSubtitle('Alur survey'),
                              _GuideBullets([
                                'Langkah 1: menuju titik ikat dengan jarak GPS dan peta kecil interaktif.',
                                'Langkah 2: dari titik ikat menuju pusat Plot 1 berdasarkan arah dan jarak.',
                                'Langkah 3: pilih plot tujuan lain atau cari pohon pada plot aktif menggunakan radar.',
                                'Batal dan kembali ke titik ikat tidak mengakhiri sesi.',
                                'Gunakan Akhiri Sesi Survey untuk menutup sesi sepenuhnya.',
                              ]),
                              _GuideSubtitle('Radar pohon'),
                              _GuideBullets([
                                'Pusat radar adalah pusat plot, bukan posisi ponsel. Sebaiknya berdiri dekat pusat plot.',
                                'Huruf N menunjukkan utara.',
                                'Saat kompas aktif, sektor mengikuti arah ponsel.',
                                'Saat kompas mati, semua pohon tetap terlihat dengan orientasi utara dan tanpa animasi sektor.',
                                'Tekan dan tahan pohon atau pusat plot untuk melihat info; tekan area kosong untuk menutupnya.',
                              ]),
                            ],
                          ),
                          _GuideSection(
                            number: 6,
                            icon: Icons.cloud,
                            title: 'Penyimpanan Awan',
                            foreground: foreground,
                            children: const [
                              _GuideParagraph(
                                'Unggah dan unduh dilakukan manual. Data lokal tidak berubah otomatis ketika data awan diperbarui.',
                              ),
                              _GuideSubtitle('Data Penelitian Publik'),
                              _GuideBullets([
                                'Data publik dapat dicari dan diunduh tanpa login.',
                                'Pencarian dilakukan berdasarkan nama folder lokasi penelitian.',
                                'Sembunyikan Folder Kosong aktif secara default dan tersimpan persisten.',
                                'Jika kode sudah ada di perangkat, masukkan kode salinan yang baru.',
                              ]),
                              _GuideSubtitle('Kelola Data Sendiri'),
                              _GuideBullets([
                                'Login Google hanya diperlukan untuk mengelola data sendiri.',
                                'Buat folder lokasi dengan nama unik dan tanggal penelitian.',
                                'Unggah satu atau beberapa klaster lokal ke folder yang dipilih.',
                                'Folder dapat dijadikan publik atau privat; nilai awalnya publik.',
                                'Klaster sendiri dapat diunduh atau dihapus. Folder harus kosong sebelum dihapus.',
                              ]),
                              _GuideParagraph(
                                'Gambar disimpan sebagai link. Pastikan link dapat diakses oleh penerima data.',
                              ),
                            ],
                          ),
                          _GuideSection(
                            number: 7,
                            icon: Icons.settings,
                            title: 'Pengaturan dan Catatan',
                            foreground: foreground,
                            children: const [
                              _GuideBullets([
                                'Pengaturan menyediakan tema terang/gelap dan Mode Debug.',
                                'Mode Debug untuk data contoh dan penghapusan data pengujian; gunakan dengan hati-hati.',
                                'Versi Aplikasi mengambil catatan perubahan dari Firebase dan membutuhkan internet.',
                                'Akurasi dipengaruhi GPS, kompas perangkat, medan, dan kualitas data.',
                                'Kalibrasikan kompas dan jauhkan ponsel dari magnet atau logam jika arah tidak stabil.',
                                'Ekspor cadangan sebelum perubahan atau penghapusan data dalam jumlah besar.',
                              ]),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    ),
  );
}

class _GuideSection extends StatelessWidget {
  const _GuideSection({
    required this.number,
    required this.icon,
    required this.title,
    required this.foreground,
    required this.children,
  });

  final int number;
  final IconData icon;
  final String title;
  final Color foreground;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => ExpansionTile(
    shape: const Border(),
    collapsedShape: const Border(),
    leading: Icon(icon, color: foreground),
    iconColor: foreground,
    collapsedIconColor: foreground,
    title: Text(
      '$number. $title',
      style: TextStyle(color: foreground, fontWeight: FontWeight.w600),
    ),
    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    children: [
      DefaultTextStyle(
        style: TextStyle(color: foreground, height: 1.4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    ],
  );
}

class _GuideSubtitle extends StatelessWidget {
  const _GuideSubtitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 10, bottom: 5),
    child: Align(
      alignment: Alignment.centerLeft,
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
    ),
  );
}

class _GuideParagraph extends StatelessWidget {
  const _GuideParagraph(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Align(alignment: Alignment.centerLeft, child: Text(text)),
  );
}

class _GuideBullets extends StatelessWidget {
  const _GuideBullets(this.items);
  final List<String> items;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (final item in items)
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [const Text('•  '), Expanded(child: Text(item))],
          ),
        ),
    ],
  );
}
