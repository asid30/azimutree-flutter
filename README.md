<!DOCTYPE html>
<html lang="id">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
</head>
<body>

  <h1>Azimutree - Forest Health Monitoring Scanner</h1>

  <p><strong>Azimutree</strong> adalah aplikasi Android yang dikembangkan untuk membantu proses pemantauan kesehatan hutan menggunakan metode <strong>Forest Health Monitoring (FHM)</strong>. Aplikasi ini dirancang untuk mendukung kegiatan penelitian lapangan dengan fitur pemindaian dan pemetaan digital yang efisien dan akurat.</p>

  <h2>Fitur Utama</h2>
  <ul>
    <li><strong>Pemindaian Kode Pohon & Plot</strong><br>
      Menggunakan kamera ponsel dan teknologi OCR (Google ML Kit / Google Vision API) untuk membaca label ID pohon secara real-time.</li>
    <li><strong>Mapping Lokasi Pohon</strong><br>
      Menampilkan posisi pohon dalam satu klaster menggunakan data azimut dan jarak dari titik pusat klaster.</li>
    <li><strong>Pencocokan Data Pohon</strong><br>
      Setelah pemindaian, aplikasi akan mencocokkan kode ID dengan data pohon yang telah direkam dalam database.</li>
    <li><strong>Manajemen Data Klaster</strong><br>
      Menyimpan dan menampilkan informasi lengkap tentang plot, klaster, dan pohon-pohon yang berada dalam area monitoring.</li>
  </ul>

  <h2>Teknologi yang Digunakan</h2>
  <ul>
    <li><strong>Flutter</strong> (Frontend App Development)</li>
    <li><strong>Google ML Kit / Google Vision API</strong> (OCR)</li>
    <li><strong>Tesseract OCR</strong> (Alternatif OCR)</li>
    <li><strong>OpenCV</strong> (Pra-pemrosesan gambar)</li>
    <li><strong>Hive</strong> (Local NoSQL database untuk penyimpanan data offline)</li>
    <li><strong>GeoLocation & Kompas</strong> (untuk orientasi arah dan posisi)</li>
  </ul>

  <h2>Tujuan Proyek</h2>
  <p>Proyek ini dikembangkan sebagai bagian dari penelitian akademik untuk mempercepat dan mempermudah pengumpulan data lapangan dalam studi kesehatan hutan tropis.</p>

  <h2>Instalasi</h2>
  <ol>
    <li>Clone repositori:
      <pre><code>git clone https://github.com/username/azimutree.git</code></pre>
    </li>
    <li>Install dependencies:
      <pre><code>flutter pub get</code></pre>
    </li>
    <li>Jalankan aplikasi:
      <pre><code>flutter run</code></pre>
    </li>
  </ol>

  <h2>Catatan</h2>
  <ul>
    <li>Beberapa fitur OCR memerlukan koneksi internet dan kunci API (jika menggunakan Google Vision API).</li>
    <li>Versi offline akan dikembangkan sepenuhnya menggunakan Tesseract dan OpenCV.</li>
  </ul>

  <h2>Kontribusi</h2>
  <p>Kontribusi sangat terbuka! Silakan buka <em>issue</em> atau kirim <em>pull request</em> jika ingin berkontribusi dalam pengembangan aplikasi ini.</p>

</body>
</html>