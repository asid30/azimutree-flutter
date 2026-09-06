import 'package:sqflite/sqflite.dart';
import 'package:azimutree/data/database/azimutree_db.dart';
import 'package:azimutree/data/models/plot_model.dart';
import 'package:azimutree/services/azimuth_latlong_service.dart';

class PlotDao {
  static const String tableName = 'plots';

  static Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE $tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        kodePlot INTEGER NOT NULL,
        idCluster INTEGER NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,    
        altitude REAL,
        FOREIGN KEY (idCluster) REFERENCES clusters(id) ON DELETE CASCADE
      )
    ''');
  }

  static Future<int> insertPlot(PlotModel plot) async {
    final db = await AzimutreeDB.instance.database;
    return await db.insert(tableName, plot.toMap());
  }

  static Future<List<PlotModel>> getAllPlots() async {
    final db = await AzimutreeDB.instance.database;
    final result = await db.query(tableName);

    return result.map((map) => PlotModel.fromMap(map)).toList();
  }

  static Future<PlotModel?> getPlotById(int id) async {
    final db = await AzimutreeDB.instance.database;
    final result = await db.query(tableName, where: 'id = ?', whereArgs: [id]);

    if (result.isNotEmpty) {
      return PlotModel.fromMap(result.first);
    } else {
      return null;
    }
  }

  static Future<int> updatePlot(PlotModel plot) async {
    if (plot.id == null) return 0;
    final db = await AzimutreeDB.instance.database;
    return db.transaction((transaction) async {
      final oldPlotRows = await transaction.query(
        tableName,
        where: 'id = ?',
        whereArgs: [plot.id],
        limit: 1,
      );
      if (oldPlotRows.isEmpty) return 0;

      final oldPlot = PlotModel.fromMap(oldPlotRows.first);
      final updated = await transaction.update(
        tableName,
        plot.toMap(),
        where: 'id = ?',
        whereArgs: [plot.id],
      );

      // Koordinat pohon adalah posisi absolut. Saat pusat plot dipindahkan,
      // posisi itu tetap dan nilai relatifnya harus dihitung ulang.
      final trees = await transaction.query(
        'trees',
        where: 'plotId = ?',
        whereArgs: [plot.id],
      );
      for (final tree in trees) {
        double? treeLatitude = (tree['latitude'] as num?)?.toDouble();
        double? treeLongitude = (tree['longitude'] as num?)?.toDouble();

        // Data lama mungkin hanya memiliki azimut dan jarak. Pulihkan dahulu
        // koordinat absolutnya dari pusat plot sebelum diedit.
        if (treeLatitude == null || treeLongitude == null) {
          final oldAzimuth = (tree['azimut'] as num?)?.toDouble();
          final oldDistance = (tree['jarakPusatM'] as num?)?.toDouble();
          if (oldAzimuth == null || oldDistance == null) continue;
          final restoredPoint = AzimuthLatLongService.fromAzimuthDistance(
            centerLatDeg: oldPlot.latitude,
            centerLonDeg: oldPlot.longitude,
            azimuthDeg: oldAzimuth,
            distanceM: oldDistance,
          );
          treeLatitude = restoredPoint.latitude;
          treeLongitude = restoredPoint.longitude;
        }

        final direction = AzimuthLatLongService.toAzimuthDistance(
          centerLatDeg: plot.latitude,
          centerLonDeg: plot.longitude,
          targetLatDeg: treeLatitude,
          targetLonDeg: treeLongitude,
        );
        await transaction.update(
          'trees',
          {
            'latitude': treeLatitude,
            'longitude': treeLongitude,
            'azimut': direction.azimuthDeg,
            'jarakPusatM': direction.distanceM,
          },
          where: 'id = ?',
          whereArgs: [tree['id']],
        );
      }
      return updated;
    });
  }

  static Future<int> deletePlot(int id) async {
    final db = await AzimutreeDB.instance.database;
    return await db.delete(tableName, where: 'id = ?', whereArgs: [id]);
  }
}
