import 'package:flutter/material.dart';
import 'package:azimutree/data/database/plot_dao.dart';
import 'package:azimutree/data/models/plot_model.dart';

class PlotNotifier extends ValueNotifier<List<PlotModel>> {
  PlotNotifier() : super([]);

  Future<void> loadPlots() async {
    final data = await PlotDao.getAllPlots();
    value = data;
  }

  Future<void> addPlot(PlotModel plot) async {
    await PlotDao.insertPlot(plot);
    await loadPlots(); // reload lagi setelah insert
  }

  Future<void> updatePlot(PlotModel plot) async {
    if (plot.id == null) return;
    await PlotDao.updatePlot(plot);
    await loadPlots();
  }

  Future<void> deletePlot(int id) async {
    await PlotDao.deletePlot(id);
    await loadPlots();
  }
}
