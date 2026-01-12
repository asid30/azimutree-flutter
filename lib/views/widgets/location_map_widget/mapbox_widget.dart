import 'package:azimutree/data/database/cluster_dao.dart';
import 'package:azimutree/data/database/plot_dao.dart';
import 'package:azimutree/data/database/tree_dao.dart';
import 'package:azimutree/data/models/cluster_model.dart';
import 'package:azimutree/data/models/plot_model.dart';
import 'package:azimutree/data/models/tree_model.dart';
import 'package:azimutree/data/notifiers/notifiers.dart';
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class MapboxWidget extends StatefulWidget {
  final String standardStyleUri;
  final String sateliteStyleUri;

  const MapboxWidget({
    super.key,
    this.standardStyleUri = "mapbox://styles/asid30/cmewvm2p901gv01pg9xje8up9",
    this.sateliteStyleUri = "mapbox://styles/asid30/cmewsx3my002x01sedr0a4win",
  });

  @override
  State<MapboxWidget> createState() => _MapboxWidgetState();
}

class _MapboxWidgetState extends State<MapboxWidget> {
  MapboxMap? _mapboxMap;
  CircleAnnotationManager? _circleManager;
  late final VoidCallback _styleListener;

  @override
  void initState() {
    super.initState();
    _styleListener = () {
      if (!mounted) return;
      if (_mapboxMap != null) {
        final style =
            selectedMenuBottomSheetNotifier.value == 0
                ? widget.standardStyleUri
                : widget.sateliteStyleUri;
        _applyStyleAndMarkers(style);
      }
    };

    selectedMenuBottomSheetNotifier.addListener(_styleListener);
    selectedLocationNotifier.addListener(_onLocationChanged);
  }

  @override
  void dispose() {
    selectedMenuBottomSheetNotifier.removeListener(_styleListener);
    selectedLocationNotifier.removeListener(_onLocationChanged);
    super.dispose();
  }

  void _onLocationChanged() {
    final pos = selectedLocationNotifier.value;
    if (!mounted) return;
    if (pos != null && _mapboxMap != null) {
      _mapboxMap!.easeTo(
        CameraOptions(center: Point(coordinates: pos), zoom: 14),
        MapAnimationOptions(duration: 5000),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: selectedMenuBottomSheetNotifier,
      builder: (context, selectedMenuBottomSheet, child) {
        return MapWidget(
          onMapCreated: (map) {
            _mapboxMap = map;
            final style =
                selectedMenuBottomSheetNotifier.value == 0
                    ? widget.standardStyleUri
                    : widget.sateliteStyleUri;
            _applyStyleAndMarkers(style);
            // If a target location was set before the map was created
            // (e.g., via "Tracking Data"), center the camera immediately.
            _onLocationChanged();
          },
          styleUri:
              selectedMenuBottomSheet == 0
                  ? widget.standardStyleUri
                  : widget.sateliteStyleUri,
          cameraOptions: CameraOptions(
            center: Point(
              coordinates: Position(105.09049300503469, -5.508241749086075),
            ),
            zoom: 10,
          ),
        );
      },
    );
  }

  Future<void> _applyStyleAndMarkers(String styleUri) async {
    if (_mapboxMap == null) return;
    await _mapboxMap!.loadStyleURI(styleUri);
    await _loadMarkers();
  }

  Future<void> _ensureManager() async {
    if (_mapboxMap == null) return;
    _circleManager ??=
        await _mapboxMap!.annotations.createCircleAnnotationManager();
  }

  Future<void> _loadMarkers() async {
    if (_mapboxMap == null) return;
    await _ensureManager();
    if (_circleManager == null) return;

    await _circleManager!.deleteAll();

    final clusters = await ClusterDao.getAllClusters();
    final plots = await PlotDao.getAllPlots();
    final trees = await TreeDao.getAllTrees();

    await _addClusterMarkers(clusters, plots);
    await _addPlotMarkers(plots);
    await _addTreeMarkers(trees);
  }

  Future<void> _addClusterMarkers(
    List<ClusterModel> clusters,
    List<PlotModel> plots,
  ) async {
    for (final cluster in clusters) {
      final clusterPlots =
          plots.where((p) => p.idCluster == cluster.id).toList();
      if (clusterPlots.isEmpty) continue;

      final avgLat =
          clusterPlots.map((p) => p.latitude).reduce((a, b) => a + b) /
          clusterPlots.length;
      final avgLon =
          clusterPlots.map((p) => p.longitude).reduce((a, b) => a + b) /
          clusterPlots.length;

      await _circleManager!.create(
        CircleAnnotationOptions(
          geometry: Point(coordinates: Position(avgLon, avgLat)),
          circleColor: 0xFF2E7D32,
          circleRadius: 11,
          circleStrokeColor: 0xFF1B5E20,
          circleStrokeWidth: 1.5,
          circleOpacity: 0.85,
        ),
      );
    }
  }

  Future<void> _addPlotMarkers(List<PlotModel> plots) async {
    for (final plot in plots) {
      await _circleManager!.create(
        CircleAnnotationOptions(
          geometry: Point(coordinates: Position(plot.longitude, plot.latitude)),
          circleColor: 0xFF1565C0,
          circleRadius: 9,
          circleStrokeColor: 0xFF0D47A1,
          circleStrokeWidth: 1.2,
          circleOpacity: 0.9,
        ),
      );
    }
  }

  Future<void> _addTreeMarkers(List<TreeModel> trees) async {
    for (final tree in trees) {
      if (tree.latitude == null || tree.longitude == null) continue;
      await _circleManager!.create(
        CircleAnnotationOptions(
          geometry: Point(
            coordinates: Position(tree.longitude!, tree.latitude!),
          ),
          circleColor: 0xFFF57C00,
          circleRadius: 6,
          circleStrokeColor: 0xFFE65100,
          circleStrokeWidth: 1.0,
          circleOpacity: 0.9,
        ),
      );
    }
  }
}
