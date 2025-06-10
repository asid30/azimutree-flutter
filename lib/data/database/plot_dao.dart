import 'package:sqflite/sqflite.dart';
import 'package:azimutree/data/models/plot.dart';

class PlotDao {
  final Database _db;

  PlotDao(this._db);

  // Insert Plot
  Future<int> insertPlot(Plot plot) async {
    return await _db.insert(
      'plots',
      plot.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Get Plots by Cluster ID
  Future<List<Plot>> getPlotsByClusterId(int clusterId) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      'plots',
      where: 'clusterId = ?',
      whereArgs: [clusterId],
    );
    return List.generate(maps.length, (i) {
      return Plot.fromMap(maps[i]);
    });
  }

  // Get Single Plot by ID
  Future<Plot?> getPlotById(int plotId) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      'plots',
      where: 'id = ?',
      whereArgs: [plotId],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return Plot.fromMap(maps.first);
    }
    return null;
  }

  // Delete Plot (akan menghapus pohon-pohon di dalamnya karena ON DELETE CASCADE)
  Future<int> deletePlot(int id) async {
    return await _db.delete('plots', where: 'id = ?', whereArgs: [id]);
  }

  // Metode lain untuk Plot (update) dapat ditambahkan di sini
}
