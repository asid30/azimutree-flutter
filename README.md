## Tentang Aplikasi

**Azimutree** adalah aplikasi Android yang dikembangkan untuk membantu proses **pemantauan kesehatan hutan** menggunakan metode **Forest Health Monitoring (FHM)**. Aplikasi ini dirancang untuk mendukung kegiatan **penelitian lapangan**, khususnya dalam memetakan dan memvisualisasikan lokasi **klaster plot** pada peta digital.

## Latar Belakang

Dalam penelitian kesehatan hutan, kondisi lingkungan dapat berubah dari waktu ke waktu akibat faktor internal maupun eksternal. Perubahan ini sering menyebabkan **lokasi klaster plot hasil penelitian terdahulu** mengalami perbedaan kondisi vegetasi dan lingkungan, sehingga menyulitkan peneliti saat melakukan pengamatan lanjutan.

Permasalahan semakin kompleks karena pengamatan kesehatan hutan dilakukan secara **berkala** dan tidak jarang melibatkan **peneliti yang berbeda**. Meskipun data penelitian sebelumnya biasanya menyertakan koordinat lokasi, data tersebut umumnya masih disimpan dalam bentuk **file Excel**, sehingga kurang praktis untuk digunakan langsung di lapangan.

## Konsep Klaster Plot

Dalam metode Forest Health Monitoring, satu **klaster** terdiri dari beberapa **plot**, dengan ketentuan:

- Satu klaster maksimal memiliki **4 plot**.
- **Plot 1** berfungsi sebagai **sentroid (pusat klaster)**.
- Plot lainnya mengelilingi plot pusat.
- Setiap plot terdiri dari beberapa pohon terpilih yang merepresentasikan kondisi kesehatan hutan.

Struktur ini penting untuk memastikan konsistensi dan akurasi data dalam setiap periode penelitian.

## Tujuan Aplikasi

<!-- `Tujuan Aplikasi` moved below Fitur Utama; screenshots will be inserted here -->

## Fitur Utama

Beberapa fitur utama yang tersedia dalam aplikasi Azimutree antara lain:

- **Visualisasi peta digital** menggunakan Mapbox.
- **Penentuan posisi klaster dan plot** berdasarkan koordinat geografis.
- Informasi **sudut azimut**, **jarak dari pusat klaster**, dan **jarak dari posisi pengguna**.
- **Impor data** dalam jumlah besar (dibatasi untuk satu klaster).
- **Ekspor data ke format Excel** untuk memudahkan berbagi data antar peneliti.

## Screenshots

<p align="center">
  <strong>Light mode</strong>
</p>

<p align="center">
  <img src="assets/repo-git-images/1.jpg" alt="Light 1" width="240" style="margin:8px;border-radius:12px;box-shadow:0 6px 18px rgba(0,0,0,0.18);" />
  <img src="assets/repo-git-images/2.jpg" alt="Light 2" width="240" style="margin:8px;border-radius:12px;box-shadow:0 6px 18px rgba(0,0,0,0.18);" />
  <img src="assets/repo-git-images/3.jpg" alt="Light 3" width="240" style="margin:8px;border-radius:12px;box-shadow:0 6px 18px rgba(0,0,0,0.18);" />
</p>

<p align="center">
  <strong>Dark mode</strong>
</p>

<p align="center">
  <img src="assets/repo-git-images/4.jpg" alt="Dark 4" width="240" style="margin:8px;border-radius:12px;box-shadow:0 6px 18px rgba(0,0,0,0.36);" />
  <img src="assets/repo-git-images/5.jpg" alt="Dark 5" width="240" style="margin:8px;border-radius:12px;box-shadow:0 6px 18px rgba(0,0,0,0.36);" />
  <img src="assets/repo-git-images/6.jpg" alt="Dark 6" width="240" style="margin:8px;border-radius:12px;box-shadow:0 6px 18px rgba(0,0,0,0.36);" />
</p>

## Tujuan Aplikasi

Azimutree dikembangkan untuk menjawab kebutuhan peneliti kesehatan hutan dalam:

- Memvisualisasikan **titik koordinat klaster dan plot** pada peta digital.
- Mempermudah peneliti menemukan kembali **lokasi penelitian sebelumnya** di lapangan.
- Mengurangi kesalahan penentuan posisi plot akibat perubahan kondisi hutan.

Aplikasi ini berfokus pada **pencatatan dan visualisasi lokasi**, bukan pada pencatatan detail nilai kesehatan pohon atau hutan.

## Teknologi yang Digunakan

Azimutree dikembangkan menggunakan teknologi berikut:

- **Flutter** sebagai framework pengembangan aplikasi.
- **SQLite** untuk penyimpanan data lokal.
- **Mapbox** untuk pemetaan dan visualisasi lokasi.

## Manfaat

Dengan menggunakan Azimutree, peneliti dapat:

- Lebih mudah melakukan pengamatan ulang di lokasi yang sama pada periode penelitian berikutnya.
- Menghemat waktu pencarian lokasi klaster dan plot di lapangan.
- Berbagi data lokasi penelitian secara lebih praktis dan terstruktur.

## Penutup

Azimutree diharapkan dapat menjadi alat bantu yang efektif bagi peneliti kesehatan hutan dalam menjaga **konsistensi lokasi penelitian**, serta mendukung keberlanjutan pengamatan kondisi hutan dari waktu ke waktu.

<p style="font-size: 12px; color: #666;">
    Developed by Asid30 © 2026
  </p>

---

## Instalasi Untuk Pengembangan

> **Catatan:** bagian ini khusus ditujukan untuk pengembang yang ingin menjalankan atau mengembangkan aplikasi secara lokal.

Clone repositori:

```bash
git clone https://github.com/asid30/azimutree-flutter.git
```

Install dependencies:

```bash
flutter pub get
```

## Catatan Developer (Mapbox)

Akses token Mapbox diperlukan untuk fitur peta. Dapatkan token di https://www.mapbox.com/.

Gunakan `env_template` yang sudah ada — salin dan ubah namanya menjadi `.env`, lalu isi nilai `MAP_BOX_ACCESS` di file `.env`:

```bash
cp env_template .env
# lalu buka .env dan isi:
# MAP_BOX_ACCESS=pk.your_mapbox_public_token_here
```

Pastikan **tidak** meng-commit `.env` ke repo (file template tetap di-repo). Aplikasi membaca nilai ini melalui `flutter_dotenv` dan kode menggunakan variabel `MAP_BOX_ACCESS`.

Jalankan aplikasi:

```bash
flutter run
```

### Catatan

> Aplikasi ini dikembangkan untuk perangkat mobile Android.
