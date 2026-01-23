import "package:sqflite/sqflite.dart";
import "package:path/path.dart";
import "package:azimutree/data/database/cluster_dao.dart";
import 'package:azimutree/data/database/plot_dao.dart';
import "package:azimutree/data/database/tree_dao.dart";

class AzimutreeDB {
  static final AzimutreeDB instance = AzimutreeDB._init();

  static Database? _database;

  AzimutreeDB._init();

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDB("azimutree.db");
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onCreate(Database db, int version) async {
    await ClusterDao.createTable(db);
    await PlotDao.createTable(db);
    await TreeDao.createTable(db);
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Add migration path to introduce optional 'inspected' column on trees
    if (oldVersion < 2 && newVersion >= 2) {
      try {
        await db.execute(
          'ALTER TABLE ${TreeDao.tableName} ADD COLUMN inspected INTEGER',
        );
      } catch (_) {
        // ignore if column already exists or other issues; safe to continue
      }
    }
  }

  Future close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
