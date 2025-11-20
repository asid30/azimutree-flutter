import 'package:sqflite/sqflite.dart';
import 'package:azimutree/data/database/azimutree_db.dart';

class TreeDao {
  static const String tableName = 'trees';

  static Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE $tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        kodeTree TEXT NOT NULL,
        kodePlot TEXT NOT NULL,
        namaIlmiah TEXT,
        azimut REAL NOT NULL,
        jarakPusatM REAL NOT NULL,
        latitude REAL,
        longitude REAL,
        altitude REAL,
        keterangan TEXT,
        urlFoto TEXT,
        FOREIGN KEY (kodePlot) REFERENCES plots(kodePlot) ON DELETE CASCADE
      )
    ''');
  }
}
