import 'package:azimutree/data/global_variables/logger_global.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:azimutree/data/database/cluster_dao.dart';
import 'package:azimutree/data/database/plot_dao.dart';
import 'package:azimutree/data/database/pohon_dao.dart';
import 'package:azimutree/data/database/database_seeder.dart';

class DatabaseHelper {
  static Database? _database;
  static const String dbName = 'azimutree_db.db';
  static const int dbVersion = 1;

  // Singleton Pattern: memastikan hanya ada satu instance DatabaseHelper
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  // DAO Instances
  late final ClusterDao clusterDao;
  late final PlotDao plotDao;
  late final PohonDao pohonDao;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    // Inisialisasi DAO setelah database siap
    clusterDao = ClusterDao(_database!);
    plotDao = PlotDao(_database!);
    pohonDao = PohonDao(_database!);
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), dbName);
    return await openDatabase(
      path,
      version: dbVersion,
      onCreate: _onCreate,
      onConfigure: _onConfigure, // Penting untuk foreign keys
    );
  }

  // Mengaktifkan Foreign Key Constraints
  Future _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  // Membuat tabel saat database pertama kali dibuat
  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE clusters(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        kodeCluster TEXT NOT NULL UNIQUE,
        namaPengukur TEXT,
        tanggalPengukuran INTEGER
      )
    ''');
    await db.execute('''
      CREATE TABLE plots(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        clusterId INTEGER NOT NULL,
        nomorPlot INTEGER NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        altitude REAL,
        FOREIGN KEY (clusterId) REFERENCES clusters (id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE pohons(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        plotId INTEGER NOT NULL,
        nomorPohonDiPlot INTEGER NOT NULL,
        azimut REAL NOT NULL,
        jarakPusatM REAL NOT NULL,
        jenisPohon TEXT,
        namaIlmiah TEXT,
        latitude REAL,
        longitude REAL,
        altitude REAL,
        FOREIGN KEY (plotId) REFERENCES plots (id) ON DELETE CASCADE
      )
    ''');

    // Panggil fungsi seeding setelah tabel dibuat
    await DatabaseSeeder.seedInitialData(db);
  }

  // Metode untuk menghapus semua data (untuk debugging)
  Future<void> deleteAllData() async {
    final db = await database; // Pastikan database sudah terinisialisasi
    await db.delete('pohons');
    await db.delete('plots');
    await db.delete('clusters');
    logger.i('All data deleted from database.');
  }
}
