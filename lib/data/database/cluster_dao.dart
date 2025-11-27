import 'package:sqflite/sqflite.dart';
import 'package:azimutree/data/database/azimutree_db.dart';
import 'package:azimutree/data/models/cluster_model.dart';

class ClusterDao {
  static const String tableName = 'clusters';

  static Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE $tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        kodeCluster TEXT NOT NULL,
        namaPengukur TEXT,
        tanggalPengukuran INTEGER
      )
    ''');
  }

  static Future<int> insertCluster(ClusterModel cluster) async {
    final db = await AzimutreeDB.instance.database;
    return await db.insert(tableName, cluster.toMap());
  }

  static Future<List<ClusterModel>> getAllClusters() async {
    final db = await AzimutreeDB.instance.database;
    final result = await db.query(tableName);

    return result.map((map) => ClusterModel.fromMap(map)).toList();
  }

  static Future<ClusterModel?> getClusterById(int id) async {
    final db = await AzimutreeDB.instance.database;
    final result = await db.query(tableName, where: 'id = ?', whereArgs: [id]);

    if (result.isNotEmpty) {
      return ClusterModel.fromMap(result.first);
    } else {
      return null;
    }
  }

  static Future<int> updateCluster(ClusterModel cluster) async {
    final db = await AzimutreeDB.instance.database;
    return await db.update(
      tableName,
      cluster.toMap(),
      where: 'id = ?',
      whereArgs: [cluster.id],
    );
  }

  static Future<int> deleteCluster(int id) async {
    final db = await AzimutreeDB.instance.database;
    return await db.delete(tableName, where: 'id = ?', whereArgs: [id]);
  }
}
