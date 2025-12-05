import 'package:flutter/material.dart';
import 'package:azimutree/data/database/tree_dao.dart';
import 'package:azimutree/data/models/tree_model.dart';

class TreeNotifier extends ValueNotifier<List<TreeModel>> {
  TreeNotifier() : super([]);

  Future<void> loadTrees() async {
    final data = await TreeDao.getAllTrees();
    value = data;
  }

  Future<void> addTree(TreeModel tree) async {
    await TreeDao.insertTree(tree);
    await loadTrees(); // reload lagi setelah insert
  }

  Future<void> updateTree(TreeModel tree) async {
    if (tree.id == null) return;
    await TreeDao.updateTree(tree);
    await loadTrees();
  }

  Future<void> deleteTree(int id) async {
    await TreeDao.deleteTree(id);
    await loadTrees();
  }
}
