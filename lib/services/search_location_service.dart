import 'dart:convert';
import 'package:azimutree/data/global_variables/logger_global.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:azimutree/data/database/cluster_dao.dart';
import 'package:azimutree/data/database/plot_dao.dart';
import 'package:azimutree/data/models/plot_model.dart';
import 'package:azimutree/data/models/cluster_model.dart';

Future<List<Map<String, dynamic>>> searchLocationService(String query) async {
  // Normalize query to avoid accidental mismatches from leading/trailing
  // whitespace (e.g., "jakarta " vs "jakarta").
  final normalized = query.trim();
  final token = dotenv.env['MAP_BOX_ACCESS']!;
  final encodedQuery = Uri.encodeComponent(normalized);
  final url =
      'https://api.mapbox.com/geocoding/v5/mapbox.places/$encodedQuery.json?access_token=$token&limit=5';

  final response = await http.get(Uri.parse(url));
  if (response.statusCode != 200) {
    logger.e('failed to fetch location: Status ${response.statusCode}');
    throw Exception('failed to fetch location: Status ${response.statusCode}');
  }

  final data = json.decode(response.body);
  final features = data['features'] as List;

  final mapboxResults =
      features.map((f) {
        logger.i(
          'success to fetch location: Status ${response.statusCode} - ${f['place_name']}',
        );
        return {
          'type': 'place',
          'name': f['place_name'] as String,
          'longitude': f['center'][0].toString(),
          'latitude': f['center'][1].toString(),
        };
      }).toList();

  // Also include local clusters and plots in search results (clusters first,
  // then plots). Do not include individual trees to avoid noisy results.
  final localResults = <Map<String, dynamic>>[];
  try {
    final clusters = await ClusterDao.getAllClusters();
    final plots = await PlotDao.getAllPlots();

    final q = normalized.toLowerCase();

    // Cluster matches
    for (final c in clusters) {
      final name = c.kodeCluster.toString();
      final nama = (c.namaPengukur ?? '').toLowerCase();
      if (name.toLowerCase().contains(q) || nama.contains(q)) {
        // find plot 1 for this cluster, otherwise any plot
        final clusterPlots = plots.where((p) => p.idCluster == c.id).toList();
        PlotModel? targetPlot;
        try {
          targetPlot = clusterPlots.firstWhere((p) => p.kodePlot == 1);
        } catch (_) {
          if (clusterPlots.isNotEmpty) targetPlot = clusterPlots.first;
        }

        if (targetPlot != null) {
          localResults.add({
            'type': 'cluster',
            'name': 'Cluster ${c.kodeCluster}',
            'clusterId': c.id,
            'plotId': targetPlot.id,
            'longitude': targetPlot.longitude.toString(),
            'latitude': targetPlot.latitude.toString(),
          });
        }
      }
    }

    // Plot matches
    for (final p in plots) {
      // Find the cluster for display
      final cl = clusters.firstWhere(
        (c) => c.id == p.idCluster,
        orElse: () => ClusterModel(id: null, kodeCluster: ''),
      );
      final display = 'Plot ${p.kodePlot} (Cluster ${cl.kodeCluster})';
      if (display.toLowerCase().contains(q) ||
          p.kodePlot.toString() == normalized) {
        localResults.add({
          'type': 'plot',
          'name': display,
          'clusterId': p.idCluster,
          'plotId': p.id,
          'longitude': p.longitude.toString(),
          'latitude': p.latitude.toString(),
        });
      }
    }
  } catch (e) {
    logger.w('searchLocationService: local search failed: $e');
  }

  // Prefer local results (clusters then plots) before remote Mapbox places.
  return [...localResults, ...mapboxResults];
}
