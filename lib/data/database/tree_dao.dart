import 'package:azimutree/data/database/azimutree_db.dart';
import 'package:azimutree/data/models/tree_model.dart';
import 'package:sqflite/sqflite.dart';

class TreeDao {
  static const String tableName = 'trees';

  static Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE $tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        kodePohon INTEGER NOT NULL,
        plotId INTEGER NOT NULL,
        namaPohon TEXT,
        namaIlmiah TEXT,
        azimut REAL,
        jarakPusatM REAL,
        latitude REAL,
        longitude REAL,
        altitude REAL,
        keterangan TEXT,
        urlFoto TEXT,
        FOREIGN KEY (plotId) REFERENCES plots(id) ON DELETE CASCADE
      )
    ''');
  }

  static Future<int> insertTree(TreeModel tree) async {
    final db = await AzimutreeDB.instance.database;
    return await db.insert(tableName, tree.toMap());
  }

  static Future<List<TreeModel>> getAllTrees() async {
    final db = await AzimutreeDB.instance.database;
    final result = await db.query(tableName);

    return result.map((map) => TreeModel.fromMap(map)).toList();
  }

  static Future<TreeModel?> getTreeById(int id) async {
    final db = await AzimutreeDB.instance.database;
    final result = await db.query(tableName, where: 'id = ?', whereArgs: [id]);

    if (result.isNotEmpty) {
      return TreeModel.fromMap(result.first);
    } else {
      return null;
    }
  }

  static Future<int> updateTree(TreeModel tree) async {
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
