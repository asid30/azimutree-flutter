import 'package:azimutree/data/database/titik_ikat_dao.dart';
import 'package:azimutree/data/models/titik_ikat_model.dart';
import 'package:flutter/material.dart';

class TitikIkatNotifier extends ValueNotifier<List<TitikIkatModel>> {
  TitikIkatNotifier() : super([]);

  Future<void> loadTitikIkat() async {
    value = await TitikIkatDao.getAllTitikIkat();
  }

  Future<void> addTitikIkat(TitikIkatModel titikIkat) async {
    await TitikIkatDao.insertTitikIkat(titikIkat);
    await loadTitikIkat();
  }

  Future<void> updateTitikIkat(TitikIkatModel titikIkat) async {
    if (titikIkat.id == null) return;
    await TitikIkatDao.updateTitikIkat(titikIkat);
    await loadTitikIkat();
  }

  Future<void> deleteTitikIkat(int id) async {
    await TitikIkatDao.deleteTitikIkat(id);
    await loadTitikIkat();
  }
}
