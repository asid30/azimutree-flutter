import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:azimutree/data/database/cluster_dao.dart';
import 'package:azimutree/data/database/plot_dao.dart';
import 'package:azimutree/data/database/titik_ikat_dao.dart';
import 'package:azimutree/data/global_variables/logger_global.dart';
import 'package:azimutree/data/models/cluster_model.dart';
import 'package:azimutree/data/models/plot_model.dart';
import 'package:azimutree/data/models/titik_ikat_model.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

typedef ClusterLoader = Future<List<ClusterModel>> Function();
typedef PlotLoader = Future<List<PlotModel>> Function();
typedef TitikIkatLoader = Future<List<TitikIkatModel>> Function();
typedef LocationHttpGet = Future<http.Response> Function(Uri uri);

/// Searches local survey data first, with Mapbox as an optional fallback.
///
/// The injectable dependencies are primarily useful for deterministic tests.
Future<List<Map<String, dynamic>>> searchLocationService(
  String query, {
  ClusterLoader? loadClusters,
  PlotLoader? loadPlots,
  TitikIkatLoader? loadTitikIkat,
  LocationHttpGet? httpGet,
  String? mapboxAccessToken,
  Duration requestTimeout = const Duration(seconds: 6),
}) async {
  final normalized = query.trim();
  if (normalized.isEmpty) return const [];

  final localResults = await _searchLocal(
    normalized,
    loadClusters ?? ClusterDao.getAllClusters,
    loadPlots ?? PlotDao.getAllPlots,
    loadTitikIkat ?? TitikIkatDao.getAllTitikIkat,
  );

  // A local match should be usable instantly and must never wait for internet.
  if (localResults.isNotEmpty) return localResults;

  final mapboxResults = await _searchMapbox(
    normalized,
    httpGet: httpGet ?? http.get,
    accessToken: mapboxAccessToken ?? _readMapboxAccessToken(),
    timeout: requestTimeout,
  );
  return [...localResults, ...mapboxResults];
}

Future<List<Map<String, dynamic>>> _searchLocal(
  String query,
  ClusterLoader loadClusters,
  PlotLoader loadPlots,
  TitikIkatLoader loadTitikIkat,
) async {
  try {
    final values = await Future.wait<dynamic>([
      loadClusters(),
      loadPlots(),
      loadTitikIkat(),
    ]);
    final clusters = values[0] as List<ClusterModel>;
    final plots = values[1] as List<PlotModel>;
    final anchors = values[2] as List<TitikIkatModel>;
    final clustersById = <int, ClusterModel>{
      for (final cluster in clusters)
        if (cluster.id != null) cluster.id!: cluster,
    };
    final q = query.toLowerCase();
    final results = <Map<String, dynamic>>[];

    for (final cluster in clusters) {
      final matchesCode = cluster.kodeCluster.toLowerCase().contains(q);
      final matchesSurveyor = (cluster.namaPengukur ?? '')
          .toLowerCase()
          .contains(q);
      if (!matchesCode && !matchesSurveyor) continue;

      final clusterPlots =
          plots.where((plot) => plot.idCluster == cluster.id).toList();
      PlotModel? targetPlot;
      for (final plot in clusterPlots) {
        if (plot.kodePlot == 1) {
          targetPlot = plot;
          break;
        }
      }
      targetPlot ??= clusterPlots.isEmpty ? null : clusterPlots.first;
      if (targetPlot == null) continue;

      results.add({
        'type': 'cluster',
        'name': 'Klaster ${cluster.kodeCluster}',
        'clusterId': cluster.id,
        'plotId': targetPlot.id,
        'longitude': targetPlot.longitude.toString(),
        'latitude': targetPlot.latitude.toString(),
      });
    }

    for (final anchor in anchors) {
      if (anchor.latitude == null || anchor.longitude == null) continue;
      final clusterCode = clustersById[anchor.idCluster]?.kodeCluster ?? '';
      final display = 'Titik Ikat $clusterCode'.trim();
      if (!display.toLowerCase().contains(q) &&
          !anchor.nama.toLowerCase().contains(q)) {
        continue;
      }
      results.add({
        'type': 'anchor',
        'name': display,
        'clusterId': anchor.idCluster,
        'anchorId': anchor.id,
        'longitude': anchor.longitude.toString(),
        'latitude': anchor.latitude.toString(),
      });
    }

    for (final plot in plots) {
      final clusterCode = clustersById[plot.idCluster]?.kodeCluster ?? '';
      final display = 'Plot ${plot.kodePlot} (Klaster $clusterCode)';
      if (!display.toLowerCase().contains(q) &&
          plot.kodePlot.toString() != query) {
        continue;
      }
      results.add({
        'type': 'plot',
        'name': display,
        'clusterId': plot.idCluster,
        'plotId': plot.id,
        'longitude': plot.longitude.toString(),
        'latitude': plot.latitude.toString(),
      });
    }

    return results;
  } catch (error, stackTrace) {
    logger.w(
      'searchLocationService: local search failed',
      error: error,
      stackTrace: stackTrace,
    );
    return const [];
  }
}

Future<List<Map<String, dynamic>>> _searchMapbox(
  String query, {
  required LocationHttpGet httpGet,
  required String? accessToken,
  required Duration timeout,
}) async {
  final token = accessToken?.trim();
  if (token == null || token.isEmpty) {
    logger.w('searchLocationService: Mapbox access token is unavailable');
    return const [];
  }

  final uri = Uri.https(
    'api.mapbox.com',
    '/geocoding/v5/mapbox.places/${Uri.encodeComponent(query)}.json',
    {'access_token': token, 'limit': '5'},
  );

  try {
    final response = await httpGet(uri).timeout(timeout);
    if (response.statusCode != 200) {
      logger.w('searchLocationService: Mapbox returned ${response.statusCode}');
      return const [];
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic> || decoded['features'] is! List) {
      logger.w('searchLocationService: invalid Mapbox response');
      return const [];
    }

    final results = <Map<String, dynamic>>[];
    for (final rawFeature in decoded['features'] as List) {
      if (rawFeature is! Map) continue;
      final name = rawFeature['place_name'];
      final center = rawFeature['center'];
      if (name is! String ||
          center is! List ||
          center.length < 2 ||
          center[0] is! num ||
          center[1] is! num) {
        continue;
      }
      results.add({
        'type': 'place',
        'name': name,
        'longitude': (center[0] as num).toString(),
        'latitude': (center[1] as num).toString(),
      });
    }
    return results;
  } on TimeoutException catch (error) {
    logger.w('searchLocationService: Mapbox request timed out: $error');
  } on SocketException catch (error) {
    logger.w('searchLocationService: device is offline: $error');
  } on http.ClientException catch (error) {
    logger.w('searchLocationService: Mapbox request failed: $error');
  } on FormatException catch (error) {
    logger.w('searchLocationService: invalid Mapbox JSON: $error');
  } catch (error, stackTrace) {
    logger.w(
      'searchLocationService: unexpected Mapbox error',
      error: error,
      stackTrace: stackTrace,
    );
  }
  return const [];
}

String? _readMapboxAccessToken() {
  try {
    return dotenv.env['MAP_BOX_ACCESS'];
  } catch (error) {
    logger.w('searchLocationService: dotenv is not initialized: $error');
    return null;
  }
}
