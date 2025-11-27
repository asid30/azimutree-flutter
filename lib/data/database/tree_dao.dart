import 'package:sqflite/sqflite.dart';
import 'package:azimutree/data/database/azimutree_db.dart';
import 'package:azimutree/data/models/tree_model.dart';

class TreeDao {
  static const String tableName = 'trees';

  static Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE $tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        kodeTree TEXT NOT NULL,
        kodePlot TEXT NOT NULL,
        namaPohon TEXT,
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

  static Future<int> insertTree(Pohon tree) async {
    final db = await AzimutreeDB.instance.database;
    return await db.insert(tableName, tree.toMap());
  }

  static Future<List<Pohon>> getAllTrees() async {
    final db = await AzimutreeDB.instance.database;
    final result = await db.query(tableName);

    return result.map((map) => Pohon.fromMap(map)).toList();
  }

  static Future<Pohon?> getTreeById(int id) async {
    final db = await AzimutreeDB.instance.database;
    final result = await db.query(tableName, where: 'id = ?', whereArgs: [id]);

    if (result.isNotEmpty) {
      return Pohon.fromMap(result.first);
    } else {
      return null;
    }
  }

  static Future<int> updateTree(Pohon tree) async {
    final db = await AzimutreeDB.instance.database;
    return await db.update(
      tableName,
      tree.toMap(),
      where: 'id = ?',
      whereArgs: [tree.id],
    );
  }

  static Future<int> deleteTree(int id) async {
    final db = await AzimutreeDB.instance.database;
    return await db.delete(tableName, where: 'id = ?', whereArgs: [id]);
  }
}
