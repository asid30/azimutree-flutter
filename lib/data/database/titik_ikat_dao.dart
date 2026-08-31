import 'package:azimutree/data/database/azimutree_db.dart';
import 'package:azimutree/data/models/titik_ikat_model.dart';
import 'package:sqflite/sqflite.dart';

class TitikIkatDao {
  static const String tableName = 'titik_ikat';

  static Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        idCluster INTEGER NOT NULL,
        nama TEXT NOT NULL,
        jenis TEXT,
        latitude REAL,
        longitude REAL,
        altitude REAL,
        azimutKePlot1 REAL NOT NULL,
        jarakKePlot1M REAL NOT NULL,
        keterangan TEXT,
        FOREIGN KEY (idCluster) REFERENCES clusters(id) ON DELETE CASCADE
      )
    ''');
  }

  static Future<int> insertTitikIkat(TitikIkatModel titikIkat) async {
    titikIkat.validate();
    final db = await AzimutreeDB.instance.database;
    return db.insert(tableName, titikIkat.toMap());
  }

  static Future<List<TitikIkatModel>> getAllTitikIkat() async {
    final db = await AzimutreeDB.instance.database;
    final result = await db.query(tableName, orderBy: 'nama COLLATE NOCASE');
    return result.map(TitikIkatModel.fromMap).toList();
  }

  static Future<List<TitikIkatModel>> getTitikIkatByCluster(
    int idCluster,
  ) async {
    final db = await AzimutreeDB.instance.database;
    final result = await db.query(
      tableName,
      where: 'idCluster = ?',
      whereArgs: [idCluster],
      orderBy: 'nama COLLATE NOCASE',
    );
    return result.map(TitikIkatModel.fromMap).toList();
  }

  static Future<TitikIkatModel?> getTitikIkatById(int id) async {
    final db = await AzimutreeDB.instance.database;
    final result = await db.query(tableName, where: 'id = ?', whereArgs: [id]);
    return result.isEmpty ? null : TitikIkatModel.fromMap(result.first);
  }

  static Future<int> updateTitikIkat(TitikIkatModel titikIkat) async {
    if (titikIkat.id == null) return 0;
    titikIkat.validate();
    final db = await AzimutreeDB.instance.database;
    return db.update(
      tableName,
      titikIkat.toMap(),
      where: 'id = ?',
      whereArgs: [titikIkat.id],
    );
  }

  static Future<int> deleteTitikIkat(int id) async {
    final db = await AzimutreeDB.instance.database;
    return db.delete(tableName, where: 'id = ?', whereArgs: [id]);
  }
}
