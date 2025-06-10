import 'package:sqflite/sqflite.dart';
import 'package:azimutree/data/models/cluster.dart';

class ClusterDao {
  final Database _db;

  ClusterDao(this._db);

  // Insert Cluster
  Future<int> insertCluster(Cluster cluster) async {
    return await _db.insert(
      'clusters',
      cluster.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Get All Clusters
  Future<List<Cluster>> getAllClusters() async {
    final List<Map<String, dynamic>> maps = await _db.query('clusters');
    return List.generate(maps.length, (i) {
      return Cluster.fromMap(maps[i]);
    });
  }

  // Get Single Cluster by ID
  Future<Cluster?> getClusterById(int clusterId) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      'clusters',
      where: 'id = ?',
      whereArgs: [clusterId],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return Cluster.fromMap(maps.first);
    }
    return null;
  }

  // Metode lain untuk Cluster (update, delete) dapat ditambahkan di sini
}
