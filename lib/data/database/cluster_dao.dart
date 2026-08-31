import 'package:sqflite/sqflite.dart';
import 'package:azimutree/data/database/azimutree_db.dart';
import 'package:azimutree/data/models/cluster_model.dart';
import 'package:azimutree/data/models/titik_ikat_model.dart';
import 'package:azimutree/data/database/titik_ikat_dao.dart';

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

  static Future<int> insertClusterWithTitikIkat(
    ClusterModel cluster,
    TitikIkatModel titikIkat,
  ) async {
    final db = await AzimutreeDB.instance.database;
    return db.transaction((txn) async {
      final clusterId = await txn.insert(tableName, cluster.toMap());
      titikIkat.idCluster = clusterId;
      titikIkat.validate();
      await txn.insert(TitikIkatDao.tableName, titikIkat.toMap());
      return clusterId;
    });
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
    return db.transaction((txn) async {
      final updated = await txn.update(
        tableName,
        cluster.toMap(),
        where: 'id = ?',
        whereArgs: [cluster.id],
      );
      await txn.update(
        TitikIkatDao.tableName,
        {'nama': 'Titik Ikat ${cluster.kodeCluster}'},
        where: 'idCluster = ?',
        whereArgs: [cluster.id],
      );
      return updated;
    });
  }

  static Future<int> deleteCluster(int id) async {
    final db = await AzimutreeDB.instance.database;
    return await db.delete(tableName, where: 'id = ?', whereArgs: [id]);
  }
}
