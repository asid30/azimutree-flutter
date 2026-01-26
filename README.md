## Tentang Aplikasi

**Azimutree** adalah aplikasi Android yang dikembangkan untuk membantu proses **pemantauan kesehatan hutan** menggunakan metode **Forest Health Monitoring (FHM)**. Aplikasi ini dirancang untuk mendukung kegiatan **penelitian lapangan**, khususnya dalam memetakan dan memvisualisasikan lokasi **cluster plot** pada peta digital.

## Latar Belakang

Dalam penelitian kesehatan hutan, kondisi lingkungan dapat berubah dari waktu ke waktu akibat faktor internal maupun eksternal. Perubahan ini sering menyebabkan **lokasi cluster plot hasil penelitian terdahulu** mengalami perbedaan kondisi vegetasi dan lingkungan, sehingga menyulitkan peneliti saat melakukan pengamatan lanjutan.

Permasalahan semakin kompleks karena pengamatan kesehatan hutan dilakukan secara **berkala** dan tidak jarang melibatkan **peneliti yang berbeda**. Meskipun data penelitian sebelumnya biasanya menyertakan koordinat lokasi, data tersebut umumnya masih disimpan dalam bentuk **file Excel**, sehingga kurang praktis untuk digunakan langsung di lapangan.

## Konsep Cluster Plot

Dalam metode Forest Health Monitoring, satu **cluster** terdiri dari beberapa **plot**, dengan ketentuan:

- Satu cluster maksimal memiliki **4 plot**.
- **Plot 1** berfungsi sebagai **sentroid (pusat cluster)**.
- Plot lainnya mengelilingi plot pusat.
- Setiap plot terdiri dari beberapa pohon terpilih yang merepresentasikan kondisi kesehatan hutan.

Struktur ini penting untuk memastikan konsistensi dan akurasi data dalam setiap periode penelitian.

## Tujuan Aplikasi

Azimutree dikembangkan untuk menjawab kebutuhan peneliti kesehatan hutan dalam:

- Memvisualisasikan **titik koordinat cluster dan plot** pada peta digital.
- Mempermudah peneliti menemukan kembali **lokasi penelitian sebelumnya** di lapangan.
- Mengurangi kesalahan penentuan posisi plot akibat perubahan kondisi hutan.

Aplikasi ini berfokus pada **pencatatan dan visualisasi lokasi**, bukan pada pencatatan detail nilai kesehatan pohon atau hutan.

## Fitur Utama

Beberapa fitur utama yang tersedia dalam aplikasi Azimutree antara lain:

- **Visualisasi peta digital** menggunakan Mapbox.
- **Penentuan posisi cluster dan plot** berdasarkan koordinat geografis.
- Informasi **sudut azimut**, **jarak dari pusat cluster**, dan **jarak dari posisi pengguna**.
- **Impor data** dalam jumlah besar (dibatasi untuk satu cluster).
- **Ekspor data ke format Excel** untuk memudahkan berbagi data antar peneliti.

## Teknologi yang Digunakan

Azimutree dikembangkan menggunakan teknologi berikut:

- **Flutter** sebagai framework pengembangan aplikasi.
- **SQLite** untuk penyimpanan data lokal.
- **Mapbox** untuk pemetaan dan visualisasi lokasi.

## Manfaat

Dengan menggunakan Azimutree, peneliti dapat:

- Lebih mudah melakukan pengamatan ulang di lokasi yang sama pada periode penelitian berikutnya.
- Menghemat waktu pencarian lokasi cluster dan plot di lapangan.
- Berbagi data lokasi penelitian secara lebih praktis dan terstruktur.

## Penutup

Azimutree diharapkan dapat menjadi alat bantu yang efektif bagi peneliti kesehatan hutan dalam menjaga **konsistensi lokasi penelitian**, serta mendukung keberlanjutan pengamatan kondisi hutan dari waktu ke waktu.

<p style="font-size: 12px; color: #666;">
    Developed by Asid30 © 2026
  </p>

---

## Instalasi Untuk Pengembangan

> **Catatan untuk Developer:** bagian ini khusus ditujukan untuk pengembang yang ingin menjalankan atau mengembangkan aplikasi secara lokal.

Clone repositori:

```bash
git clone https://github.com/asid30/azimutree-flutter.git
```

Install dependencies:

```bash
flutter pub get
```

Jalankan aplikasi:

```bash
flutter run
```

### Catatan

> Aplikasi ini dikembangkan untuk perangkat mobile Android.
