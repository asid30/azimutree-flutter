import 'package:sqflite/sqflite.dart';
import 'package:azimutree/data/database/azimutree_db.dart';
import 'package:azimutree/data/models/plot_model.dart';

class PlotDao {
  static const String tableName = 'plots';

  static Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE $tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        kodePlot TEXT NOT NULL,
        kodeCluster TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,    
        altitude REAL,
        FOREIGN KEY (kodeCluster) REFERENCES clusters(kodeCluster) ON DELETE CASCADE
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
    final db = await AzimutreeDB.instance.database;
    return await db.update(
      tableName,
      plot.toMap(),
      where: 'id = ?',
      whereArgs: [plot.id],
    );
  }

  static Future<int> deletePlot(int id) async {
    final db = await AzimutreeDB.instance.database;
    return await db.delete(tableName, where: 'id = ?', whereArgs: [id]);
  }
}
