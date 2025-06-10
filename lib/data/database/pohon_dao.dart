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

  // Get Pohon by Plot ID
  Future<List<Pohon>> getPohonsByPlotId(int plotId) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      'pohons',
      where: 'plotId = ?',
      whereArgs: [plotId],
    );
    return List.generate(maps.length, (i) {
      return Pohon.fromMap(maps[i]);
    });
  }

  // Delete Pohon
  Future<int> deletePohon(int id) async {
    return await _db.delete('pohons', where: 'id = ?', whereArgs: [id]);
  }

  // Metode lain untuk Pohon (update, get single pohon) dapat ditambahkan di sini
}
