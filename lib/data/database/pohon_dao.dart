import 'package:sqflite/sqflite.dart';
import 'package:azimutree/data/models/pohon.dart';

class PohonDao {
  final Database _db;

  PohonDao(this._db);

  // Insert Pohon
  Future<int> insertPohon(Pohon pohon) async {
    return await _db.insert(
      'pohons',
      pohon.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Get All Pohon by Plot ID
  Future<List<Pohon>> getAllPohonsByPlotId(int plotId) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      'pohons',
      where: 'plotId = ?',
      whereArgs: [plotId],
    );
    return List.generate(maps.length, (i) {
      return Pohon.fromMap(maps[i]);
    });
  }

  // Get Single Pohon by ID
  Future<Pohon?> getPohonById(int pohonId) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      'pohons',
      where: 'id = ?',
      whereArgs: [pohonId],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return Pohon.fromMap(maps.first);
    }
    return null;
  }

  // Delete Pohon
  Future<int> deletePohon(int id) async {
    return await _db.delete('pohons', where: 'id = ?', whereArgs: [id]);
  }
}
