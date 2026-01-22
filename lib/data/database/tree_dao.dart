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
        -- Optional inspection workflow flag: 0/1, nullable for backward compatibility
        inspected INTEGER,
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

  /// Update only the `inspected` column for a given tree id.
  static Future<int> setInspectedForTree(int id, bool? inspected) async {
    final db = await AzimutreeDB.instance.database;
    final value = inspected == null ? null : (inspected ? 1 : 0);
    return await db.update(
      tableName,
      {'inspected': value},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Return the set of tree ids marked inspected in DB.
  static Future<Set<int>> getInspectedTreeIds() async {
    final db = await AzimutreeDB.instance.database;
    try {
      final rows = await db.query(
        tableName,
        columns: ['id'],
        where: 'inspected = 1',
      );
      return rows.map<int>((r) => r['id'] as int).toSet();
    } catch (_) {
      return {};
    }
  }

  static Future<int> deleteTree(int id) async {
    final db = await AzimutreeDB.instance.database;
    return await db.delete(tableName, where: 'id = ?', whereArgs: [id]);
  }
}
