import 'package:azimutree/data/database/cluster_dao.dart';
import 'package:flutter/material.dart';
import 'package:azimutree/data/models/cluster_model.dart';

class ClusterNotifier extends ValueNotifier<List<ClusterModel>> {
  ClusterNotifier() : super([]);

  Future<void> loadClusters() async {
    final data = await ClusterDao.getAllClusters();
    value = data;
  }

  Future<void> addCluster(ClusterModel cluster) async {
    await ClusterDao.insertCluster(cluster);
    await loadClusters(); // reload lagi setelah insert
  }

  Future<void> deleteCluster(int id) async {
    await ClusterDao.deleteCluster(id);
    await loadClusters();
  }
}
