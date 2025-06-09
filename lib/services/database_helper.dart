import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import 'package:azimutree/data/models/cluster.dart';
import 'package:azimutree/data/models/plot.dart';
import 'package:azimutree/data/models/pohon.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'azimutree.db');
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE Clusters(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        kode_cluster TEXT UNIQUE,
        nama_pengukur TEXT,
        tanggal_pengukuran TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE Plots(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cluster_id INTEGER,
        nomor_plot INTEGER,
        latitude REAL NOT NULL, -- Wajib
        longitude REAL NOT NULL, -- Wajib
        altitude REAL, -- Opsional
        FOREIGN KEY (cluster_id) REFERENCES Clusters(id) ON DELETE CASCADE,
        UNIQUE(cluster_id, nomor_plot)
      )
    ''');
    await db.execute('''
      CREATE TABLE Pohon(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        plot_id INTEGER,
        nomor_pohon_di_plot INTEGER,
        jenis_pohon TEXT,
        nama_ilmiah TEXT,
        azimut REAL NOT NULL, -- Wajib
        jarak_pusat_m REAL NOT NULL, -- Wajib
        latitude REAL, -- Opsional
        longitude REAL, -- Opsional
        altitude REAL, -- Opsional
        FOREIGN KEY (plot_id) REFERENCES Plots(id) ON DELETE CASCADE
      )
    ''');
  }

  // --- Metode untuk Clusters ---
  Future<int> insertCluster(Cluster cluster) async {
    Database db = await database;
    return await db.insert(
      'Clusters',
      cluster.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    ); // replace jika kode_cluster sudah ada
  }

  Future<Cluster?> getClusterByKode(String kodeCluster) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'Clusters',
      where: 'kode_cluster = ?',
      whereArgs: [kodeCluster],
    );
    if (maps.isNotEmpty) {
      return Cluster.fromMap(maps.first);
    }
    return null;
  }

  Future<List<Cluster>> getAllClusters() async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query('Clusters');
    return List.generate(maps.length, (i) {
      return Cluster.fromMap(maps[i]);
    });
  }

  // --- Metode untuk Plots ---
  Future<int> insertPlot(Plot plot) async {
    Database db = await database;
    return await db.insert(
      'Plots',
      plot.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    ); // replace jika (cluster_id, nomor_plot) sudah ada
  }

  Future<Plot?> getPlotByClusterAndNomor(int clusterId, int nomorPlot) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'Plots',
      where: 'cluster_id = ? AND nomor_plot = ?',
      whereArgs: [clusterId, nomorPlot],
    );
    if (maps.isNotEmpty) {
      return Plot.fromMap(maps.first);
    }
    return null;
  }

  Future<List<Plot>> getPlotsByCluster(int clusterId) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'Plots',
      where: 'cluster_id = ?',
      whereArgs: [clusterId],
    );
    return List.generate(maps.length, (i) {
      return Plot.fromMap(maps[i]);
    });
  }

  // --- Metode untuk Pohon ---
  Future<int> insertPohon(Pohon pohon) async {
    Database db = await database;
    return await db.insert('Pohon', pohon.toMap());
  }

  Future<List<Pohon>> getPohonByPlot(int plotId) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'Pohon',
      where: 'plot_id = ?',
      whereArgs: [plotId],
      orderBy: 'nomor_pohon_di_plot ASC', // Urutkan berdasarkan nomor pohon
    );
    return List.generate(maps.length, (i) {
      return Pohon.fromMap(maps[i]);
    });
  }

  Future<List<Pohon>> getAllPohon() async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query('Pohon');
    return List.generate(maps.length, (i) {
      return Pohon.fromMap(maps[i]);
    });
  }

  Future<void> deleteCluster(int id) async {
    Database db = await database;
    await db.delete('Clusters', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deletePlot(int id) async {
    Database db = await database;
    await db.delete('Plots', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deletePohon(int id) async {
    Database db = await database;
    await db.delete('Pohon', where: 'id = ?', whereArgs: [id]);
  }

  // Metode untuk menghapus semua data (berguna untuk testing)
  Future<void> clearAllData() async {
    Database db = await database;
    await db.delete('Pohon');
    await db.delete('Plots');
    await db.delete('Clusters');
  }
}
