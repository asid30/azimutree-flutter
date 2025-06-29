import 'package:azimutree/data/global_variables/logger_global.dart';
import 'package:sqflite/sqflite.dart';
import 'package:azimutree/data/models/cluster.dart';
import 'package:azimutree/data/models/plot.dart';
import 'package:azimutree/data/models/pohon.dart';
import 'package:azimutree/services/location_utils.dart'; // Import utility baru kita

class DatabaseSeeder {
  static Future<void> seedInitialData(Database db) async {
    // Cek apakah database sudah ada datanya (misal: cek jumlah cluster)
    final List<Map<String, dynamic>> existingClusters = await db.query(
      'clusters',
      limit: 1,
    );
    if (existingClusters.isNotEmpty) {
      logger.w('Database sudah berisi data, tidak perlu seeding.');
      return; // Jika sudah ada, jangan seeding lagi
    }

    logger.i('Melakukan seeding database...');

    // 1. Insert Cluster Dummy
    final Cluster dummyCluster = Cluster(
      kodeCluster: 'CL-001',
      namaPengukur: 'Dr. Ahmad',
      tanggalPengukuran: DateTime(2024, 5, 20),
    );
    final int clusterId = await db.insert('clusters', dummyCluster.toMap());
    logger.i('Cluster inserted with ID: $clusterId');

    // 2. Insert Plots Dummy
    final Plot dummyPlot1 = Plot(
      clusterId: clusterId,
      nomorPlot: 1,
      latitude: -5.452654, // Contoh koordinat Lampung
      longitude: 105.266710, // Contoh koordinat Lampung
      altitude: 50.0,
    );
    final int plot1Id = await db.insert('plots', dummyPlot1.toMap());
    logger.i('Plot 1 inserted with ID: $plot1Id');

    final Plot dummyPlot2 = Plot(
      clusterId: clusterId,
      nomorPlot: 2,
      latitude: -5.453000, // Koordinat berbeda untuk Plot 2
      longitude: 105.267000, // Koordinat berbeda untuk Plot 2
      altitude: 52.0,
    );
    final int plot2Id = await db.insert('plots', dummyPlot2.toMap());
    logger.i('Plot 2 inserted with ID: $plot2Id');

    // 3. Insert Pohon Dummy untuk Plot 1
    List<Pohon> pohonForPlot1 = [
      Pohon(
        plotId: plot1Id,
        nomorPohonDiPlot: 1,
        jenisPohon: 'Meranti',
        namaIlmiah: 'Shorea sp.',
        azimut: 45.0,
        jarakPusatM: 5.2,
      ),
      Pohon(
        plotId: plot1Id,
        nomorPohonDiPlot: 2,
        jenisPohon: 'Ulin',
        namaIlmiah: 'Eusideroxylon zwageri',
        azimut: 90.0,
        jarakPusatM: 7.8,
      ),
      Pohon(
        plotId: plot1Id,
        nomorPohonDiPlot: 3,
        jenisPohon: 'Jati',
        namaIlmiah: 'Tectona grandis',
        azimut: 135.0,
        jarakPusatM: 6.5,
      ),
      Pohon(
        plotId: plot1Id,
        nomorPohonDiPlot: 4,
        jenisPohon: 'Mahoni',
        namaIlmiah: 'Swietenia macrophylla',
        azimut: 180.0,
        jarakPusatM: 4.1,
      ),
      Pohon(
        plotId: plot1Id,
        nomorPohonDiPlot: 5,
        jenisPohon: 'Sengon',
        namaIlmiah: 'Paraserianthes falcataria',
        azimut: 225.0,
        jarakPusatM: 9.0,
      ),
      Pohon(
        plotId: plot1Id,
        nomorPohonDiPlot: 6,
        jenisPohon: 'Akasia',
        namaIlmiah: 'Acacia mangium',
        azimut: 270.0,
        jarakPusatM: 3.7,
      ),
      Pohon(
        plotId: plot1Id,
        nomorPohonDiPlot: 7,
        jenisPohon: 'Rasamala',
        namaIlmiah: 'Altingia excelsa',
        azimut: 315.0,
        jarakPusatM: 8.4,
      ),
      Pohon(
        plotId: plot1Id,
        nomorPohonDiPlot: 8,
        jenisPohon: 'Beringin',
        namaIlmiah: 'Ficus benjamina',
        azimut: 360.0,
        jarakPusatM: 6.0,
      ),
      Pohon(
        plotId: plot1Id,
        nomorPohonDiPlot: 9,
        jenisPohon: 'Eboni',
        namaIlmiah: 'Diospyros celebica',
        azimut: 20.0,
        jarakPusatM: 5.5,
      ),
      Pohon(
        plotId: plot1Id,
        nomorPohonDiPlot: 10,
        jenisPohon: 'Cendana',
        namaIlmiah: 'Santalum album',
        azimut: 70.0,
        jarakPusatM: 4.8,
      ),
    ];

    for (var pohon in pohonForPlot1) {
      final Map<String, double> coords =
          LocationUtils.calculatePohonCoordinates(
            dummyPlot1.latitude,
            dummyPlot1.longitude,
            pohon.azimut,
            pohon.jarakPusatM,
          );
      pohon.latitude = coords['latitude'];
      pohon.longitude = coords['longitude'];
      pohon.altitude =
          dummyPlot1.altitude; // Ketinggian pohon = ketinggian plot
      await db.insert('pohons', pohon.toMap());
    }
    logger.i('Pohons for Plot 1 inserted.');

    // 4. Insert Pohon Dummy untuk Plot 2
    List<Pohon> pohonForPlot2 = [
      Pohon(
        plotId: plot2Id,
        nomorPohonDiPlot: 1,
        jenisPohon: 'Meranti Putih',
        namaIlmiah: 'Shorea assamica',
        azimut: 10.0,
        jarakPusatM: 3.0,
      ),
      Pohon(
        plotId: plot2Id,
        nomorPohonDiPlot: 2,
        jenisPohon: 'Damar',
        namaIlmiah: 'Agathis dammara',
        azimut: 120.0,
        jarakPusatM: 6.5,
      ),
      Pohon(
        plotId: plot2Id,
        nomorPohonDiPlot: 3,
        jenisPohon: 'Cempaka',
        namaIlmiah: 'Magnolia champaca',
        azimut: 210.0,
        jarakPusatM: 4.0,
      ),
      Pohon(
        plotId: plot2Id,
        nomorPohonDiPlot: 4,
        jenisPohon: 'Kenari',
        namaIlmiah: 'Canarium vulgare',
        azimut: 300.0,
        jarakPusatM: 7.2,
      ),
      Pohon(
        plotId: plot2Id,
        nomorPohonDiPlot: 5,
        jenisPohon: 'Sungkay',
        namaIlmiah: 'Peronema canescens',
        azimut: 45.0,
        jarakPusatM: 5.0,
      ),
    ];

    for (var pohon in pohonForPlot2) {
      final Map<String, double> coords =
          LocationUtils.calculatePohonCoordinates(
            dummyPlot2.latitude,
            dummyPlot2.longitude,
            pohon.azimut,
            pohon.jarakPusatM,
          );
      pohon.latitude = coords['latitude'];
      pohon.longitude = coords['longitude'];
      pohon.altitude =
          dummyPlot2.altitude; // Ketinggian pohon = ketinggian plot
      await db.insert('pohons', pohon.toMap());
    }
    logger.i('Pohons for Plot 2 inserted.');
    logger.i('Seeding lengkap!');
  }
}
