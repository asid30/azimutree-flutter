import 'package:sqflite/sqflite.dart';
import 'package:azimutree/data/database/azimutree_db.dart';

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
}
