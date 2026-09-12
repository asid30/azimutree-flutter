import 'dart:io';

import 'package:azimutree/data/models/cluster_model.dart';
import 'package:azimutree/data/models/plot_model.dart';
import 'package:azimutree/services/search_location_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  final cluster = ClusterModel(id: 1, kodeCluster: 'CL1');
  final plot = PlotModel(
    id: 10,
    idCluster: 1,
    kodePlot: 1,
    latitude: -6.2,
    longitude: 106.8,
  );

  test('local results do not depend on or wait for Mapbox', () async {
    var remoteCalled = false;

    final results = await searchLocationService(
      'CL1',
      loadClusters: () async => [cluster],
      loadPlots: () async => [plot],
      loadTitikIkat: () async => [],
      mapboxAccessToken: 'test-token',
      httpGet: (_) async {
        remoteCalled = true;
        throw const SocketException('offline');
      },
    );

    expect(remoteCalled, isFalse);
    expect(results, isNotEmpty);
    expect(results.first['type'], 'cluster');
    expect(results.first['name'], 'Klaster CL1');
  });

  test(
    'offline Mapbox failure returns an empty result instead of throwing',
    () async {
      final results = await searchLocationService(
        'tempat yang tidak lokal',
        loadClusters: () async => [],
        loadPlots: () async => [],
        loadTitikIkat: () async => [],
        mapboxAccessToken: 'test-token',
        httpGet: (_) async => throw const SocketException('offline'),
      );

      expect(results, isEmpty);
    },
  );

  test(
    'valid Mapbox results remain available when no local data matches',
    () async {
      final results = await searchLocationService(
        'Bandung',
        loadClusters: () async => [],
        loadPlots: () async => [],
        loadTitikIkat: () async => [],
        mapboxAccessToken: 'test-token',
        httpGet:
            (_) async => http.Response(
              '{"features":[{"place_name":"Bandung, Indonesia","center":[107.61,-6.91]}]}',
              200,
            ),
      );

      expect(results, hasLength(1));
      expect(results.single['type'], 'place');
      expect(results.single['longitude'], '107.61');
      expect(results.single['latitude'], '-6.91');
    },
  );
}
