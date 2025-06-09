import 'package:azimutree/data/notifiers/notifiers.dart';
import 'package:azimutree/views/widgets/appbar_widget.dart';
import 'package:azimutree/views/widgets/sidebar_widget.dart';
import 'package:flutter/material.dart';

import 'dart:math' as math; // Import math library untuk sin, cos, dll.

import 'package:azimutree/data/models/cluster.dart';
import 'package:azimutree/data/models/plot.dart';
import 'package:azimutree/data/models/pohon.dart';
import 'package:intl/intl.dart';

class ManageDataPage extends StatefulWidget {
  const ManageDataPage({super.key});

  @override
  State<ManageDataPage> createState() => _ManageDataPageState();
}

class _ManageDataPageState extends State<ManageDataPage> {
  // --- DATA DUMMY ---
  // Satu Cluster
  final Cluster dummyCluster = Cluster(
    id: 1,
    kodeCluster: 'CL-001',
    namaPengukur: 'Dr. Ahmad',
    tanggalPengukuran: DateTime(2024, 5, 20),
  );

  // List untuk menyimpan semua plot (Plot 1 sebagai titik pusat)
  late final List<Plot> _dummyPlots;

  // Map untuk menyimpan pohon berdasarkan plotId
  late final Map<int, List<Pohon>> _dummyPohonMap;

  // Konstanta untuk perhitungan koordinat (rata-rata radius bumi)
  static const double earthRadiusMeters =
      6371000; // Radius bumi rata-rata dalam meter

  @override
  void initState() {
    super.initState();

    // Inisialisasi Plot 1 (titik pusat klaster)
    final Plot dummyPlot1 = Plot(
      id: 101,
      clusterId: dummyCluster.id!,
      nomorPlot: 1,
      latitude: -5.452654, // Contoh koordinat Lampung
      longitude: 105.266710, // Contoh koordinat Lampung
      altitude: 50.0, // Contoh ketinggian
    );

    // Inisialisasi Plot 2
    final Plot dummyPlot2 = Plot(
      id: 102,
      clusterId: dummyCluster.id!, // Masih dalam klaster yang sama
      nomorPlot: 2,
      latitude: -5.453000, // Koordinat berbeda untuk Plot 2
      longitude: 105.267000, // Koordinat berbeda untuk Plot 2
      altitude: 52.0, // Ketinggian berbeda untuk Plot 2
    );

    _dummyPlots = [dummyPlot1, dummyPlot2];
    _dummyPohonMap = {};

    // --- Inisialisasi Pohon untuk Plot 1 (10 pohon) ---
    List<Pohon> pohonForPlot1 =
        [
          Pohon(
            id: 1001,
            plotId: dummyPlot1.id!,
            nomorPohonDiPlot: 1,
            jenisPohon: 'Meranti',
            namaIlmiah: 'Shorea sp.',
            azimut: 45.0,
            jarakPusatM: 5.2,
          ),
          Pohon(
            id: 1002,
            plotId: dummyPlot1.id!,
            nomorPohonDiPlot: 2,
            jenisPohon: 'Ulin',
            namaIlmiah: 'Eusideroxylon zwageri',
            azimut: 90.0,
            jarakPusatM: 7.8,
          ),
          Pohon(
            id: 1003,
            plotId: dummyPlot1.id!,
            nomorPohonDiPlot: 3,
            jenisPohon: 'Jati',
            namaIlmiah: 'Tectona grandis',
            azimut: 135.0,
            jarakPusatM: 6.5,
          ),
          Pohon(
            id: 1004,
            plotId: dummyPlot1.id!,
            nomorPohonDiPlot: 4,
            jenisPohon: 'Mahoni',
            namaIlmiah: 'Swietenia macrophylla',
            azimut: 180.0,
            jarakPusatM: 4.1,
          ),
          Pohon(
            id: 1005,
            plotId: dummyPlot1.id!,
            nomorPohonDiPlot: 5,
            jenisPohon: 'Sengon',
            namaIlmiah: 'Paraserianthes falcataria',
            azimut: 225.0,
            jarakPusatM: 9.0,
          ),
          Pohon(
            id: 1006,
            plotId: dummyPlot1.id!,
            nomorPohonDiPlot: 6,
            jenisPohon: 'Akasia',
            namaIlmiah: 'Acacia mangium',
            azimut: 270.0,
            jarakPusatM: 3.7,
          ),
          Pohon(
            id: 1007,
            plotId: dummyPlot1.id!,
            nomorPohonDiPlot: 7,
            jenisPohon: 'Rasamala',
            namaIlmiah: 'Altingia excelsa',
            azimut: 315.0,
            jarakPusatM: 8.4,
          ),
          Pohon(
            id: 1008,
            plotId: dummyPlot1.id!,
            nomorPohonDiPlot: 8,
            jenisPohon: 'Beringin',
            namaIlmiah: 'Ficus benjamina',
            azimut: 360.0,
            jarakPusatM: 6.0,
          ),
          Pohon(
            id: 1009,
            plotId: dummyPlot1.id!,
            nomorPohonDiPlot: 9,
            jenisPohon: 'Eboni',
            namaIlmiah: 'Diospyros celebica',
            azimut: 20.0,
            jarakPusatM: 5.5,
          ),
          Pohon(
            id: 1010,
            plotId: dummyPlot1.id!,
            nomorPohonDiPlot: 10,
            jenisPohon: 'Cendana',
            namaIlmiah: 'Santalum album',
            azimut: 70.0,
            jarakPusatM: 4.8,
          ),
        ].map((pohon) {
          final Map<String, double> coords = calculatePohonCoordinates(
            dummyPlot1.latitude,
            dummyPlot1.longitude,
            pohon.azimut,
            pohon.jarakPusatM,
          );
          return Pohon(
            id: pohon.id,
            plotId: pohon.plotId,
            nomorPohonDiPlot: pohon.nomorPohonDiPlot,
            jenisPohon: pohon.jenisPohon,
            namaIlmiah: pohon.namaIlmiah,
            azimut: pohon.azimut,
            jarakPusatM: pohon.jarakPusatM,
            latitude: coords['latitude'],
            longitude: coords['longitude'],
            altitude: dummyPlot1.altitude, // Ketinggian pohon = ketinggian plot
          );
        }).toList();
    _dummyPohonMap[dummyPlot1.id!] = pohonForPlot1;

    // --- Inisialisasi Pohon untuk Plot 2 (5 pohon) ---
    List<Pohon> pohonForPlot2 =
        [
          Pohon(
            id: 2001,
            plotId: dummyPlot2.id!,
            nomorPohonDiPlot: 1,
            jenisPohon: 'Meranti Putih',
            namaIlmiah: 'Shorea assamica',
            azimut: 10.0,
            jarakPusatM: 3.0,
          ),
          Pohon(
            id: 2002,
            plotId: dummyPlot2.id!,
            nomorPohonDiPlot: 2,
            jenisPohon: 'Damar',
            namaIlmiah: 'Agathis dammara',
            azimut: 120.0,
            jarakPusatM: 6.5,
          ),
          Pohon(
            id: 2003,
            plotId: dummyPlot2.id!,
            nomorPohonDiPlot: 3,
            jenisPohon: 'Cempaka',
            namaIlmiah: 'Magnolia champaca',
            azimut: 210.0,
            jarakPusatM: 4.0,
          ),
          Pohon(
            id: 2004,
            plotId: dummyPlot2.id!,
            nomorPohonDiPlot: 4,
            jenisPohon: 'Kenari',
            namaIlmiah: 'Canarium vulgare',
            azimut: 300.0,
            jarakPusatM: 7.2,
          ),
          Pohon(
            id: 2005,
            plotId: dummyPlot2.id!,
            nomorPohonDiPlot: 5,
            jenisPohon: 'Sungkay',
            namaIlmiah: 'Peronema canescens',
            azimut: 45.0,
            jarakPusatM: 5.0,
          ),
        ].map((pohon) {
          final Map<String, double> coords = calculatePohonCoordinates(
            dummyPlot2.latitude,
            dummyPlot2.longitude,
            pohon.azimut,
            pohon.jarakPusatM,
          );
          return Pohon(
            id: pohon.id,
            plotId: pohon.plotId,
            nomorPohonDiPlot: pohon.nomorPohonDiPlot,
            jenisPohon: pohon.jenisPohon,
            namaIlmiah: pohon.namaIlmiah,
            azimut: pohon.azimut,
            jarakPusatM: pohon.jarakPusatM,
            latitude: coords['latitude'],
            longitude: coords['longitude'],
            altitude: dummyPlot2.altitude, // Ketinggian pohon = ketinggian plot
          );
        }).toList();
    _dummyPohonMap[dummyPlot2.id!] = pohonForPlot2;
  }

  // Fungsi untuk mengkonversi derajat ke radian
  double _toRadians(double degrees) {
    return degrees * math.pi / 180.0;
  }

  // Fungsi untuk mengkonversi radian ke derajat
  double _toDegrees(double radians) {
    return radians * 180.0 / math.pi;
  }

  // Fungsi utama untuk menghitung koordinat pohon
  Map<String, double> calculatePohonCoordinates(
    double plotLat,
    double plotLon,
    double azimut, // dalam derajat
    double distanceMeters, // dalam meter
  ) {
    // Konversi latitude plot dan azimut ke radian
    double latRad = _toRadians(plotLat);
    double lonRad = _toRadians(plotLon);
    double azimutRad = _toRadians(azimut);

    // Hitung perubahan angular distance (delta sigma)
    double angularDistance = distanceMeters / earthRadiusMeters;

    // Hitung latitude baru
    double newLatRad = math.asin(
      math.sin(latRad) * math.cos(angularDistance) +
          math.cos(latRad) * math.sin(angularDistance) * math.cos(azimutRad),
    );

    // Hitung longitude baru
    double newLonRad =
        lonRad +
        math.atan2(
          math.sin(azimutRad) * math.sin(angularDistance) * math.cos(latRad),
          math.cos(angularDistance) - math.sin(latRad) * math.sin(newLatRad),
        );

    return {
      'latitude': _toDegrees(newLatRad),
      'longitude': _toDegrees(newLonRad),
    };
  }

  // Fungsi untuk mendapatkan jumlah total pohon dari semua plot
  int _getTotalPohonCount() {
    return _dummyPohonMap.values.fold(0, (sum, list) => sum + list.length);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppbarWidget(title: "Kelola Data Cluster Plot"),
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
          //* Konten Utama
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Data Klaster:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kode Klaster: ${dummyCluster.kodeCluster}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text('Pengukur: ${dummyCluster.namaPengukur ?? '-'}'),
                        Text(
                          'Tanggal Pengukuran: ${dummyCluster.tanggalPengukuran != null ? DateFormat('dd-MM-yyyy').format(dummyCluster.tanggalPengukuran!) : '-'}',
                        ),
                        Text(
                          'Jumlah Plot: ${_dummyPlots.length}',
                        ), // Jumlah plot dinamis
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Data Plot:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                // Gunakan ListView.builder untuk menampilkan semua plot
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _dummyPlots.length,
                  itemBuilder: (context, plotIndex) {
                    final plot = _dummyPlots[plotIndex];
                    final pohonListForPlot = _dummyPohonMap[plot.id!] ?? [];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Nomor Plot: ${plot.nomorPlot}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text('Latitude: ${plot.latitude}'),
                            Text('Longitude: ${plot.longitude}'),
                            Text('Altitude: ${plot.altitude ?? '-'}'),
                            const SizedBox(height: 10),
                            Text(
                              'Pohon di Plot ini (${pohonListForPlot.length} pohon):',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            // Nested ListView.builder untuk pohon-pohon di dalam plot ini
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: pohonListForPlot.length,
                              itemBuilder: (context, pohonIndex) {
                                final pohon = pohonListForPlot[pohonIndex];
                                return Padding(
                                  padding: const EdgeInsets.only(
                                    left: 16.0,
                                    top: 4.0,
                                    bottom: 4.0,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'No. Pohon: ${pohon.nomorPohonDiPlot}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        'Jenis: ${pohon.jenisPohon ?? '-'} (${pohon.namaIlmiah ?? '-'})',
                                      ),
                                      Text('Azimuth: ${pohon.azimut}°'),
                                      Text(
                                        'Jarak Pusat: ${pohon.jarakPusatM} m',
                                      ),
                                      Text(
                                        'Koordinat: ${pohon.latitude?.toStringAsFixed(6) ?? '-'} Lat, ${pohon.longitude?.toStringAsFixed(6) ?? '-'} Lon, ${pohon.altitude?.toStringAsFixed(2) ?? '-'} Alt',
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                Text(
                  'Total Pohon di Semua Plot: ${_getTotalPohonCount()}', // Jumlah total pohon
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
