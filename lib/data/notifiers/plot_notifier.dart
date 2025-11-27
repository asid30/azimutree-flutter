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

  Future<void> deletePlot(int id) async {
    await PlotDao.deletePlot(id);
    await loadPlots();
  }
}
