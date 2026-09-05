import 'dart:math' as math;

import 'package:azimutree/data/database/plot_dao.dart';
import 'package:azimutree/data/database/titik_ikat_dao.dart';
import 'package:azimutree/data/database/tree_dao.dart';
import 'package:azimutree/data/models/tree_model.dart';
import 'package:azimutree/data/notifiers/notifiers.dart';
import 'package:azimutree/views/widgets/location_map_widget/map_marker_style.dart';
import 'package:azimutree/views/widgets/location_map_widget/map_legend_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class PickedCoordinate {
  final double latitude;
  final double longitude;

  const PickedCoordinate({required this.latitude, required this.longitude});
}

Future<PickedCoordinate?> pickCoordinateFromMap(
  BuildContext context, {
  double? initialLatitude,
  double? initialLongitude,
}) {
  final userPosition = userLocationNotifier.value;
  final latitude = initialLatitude ?? userPosition?.lat.toDouble() ?? -5.4297;
  final longitude =
      initialLongitude ?? userPosition?.lng.toDouble() ?? 105.2626;
  return Navigator.of(context).push<PickedCoordinate>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder:
          (_) => CoordinatePickerPage(
            initialLatitude: latitude,
            initialLongitude: longitude,
          ),
    ),
  );
}

class CoordinatePickerPage extends StatefulWidget {
  final double initialLatitude;
  final double initialLongitude;

  const CoordinatePickerPage({
    super.key,
    required this.initialLatitude,
    required this.initialLongitude,
  });

  @override
  State<CoordinatePickerPage> createState() => _CoordinatePickerPageState();
}

class _CoordinatePickerPageState extends State<CoordinatePickerPage> {
  MapboxMap? _map;
  CircleAnnotationManager? _markerManager;
  PolygonAnnotationManager? _areaManager;
  PointAnnotationManager? _treeManager;
  late double _latitude;
  late double _longitude;
  late final ValueNotifier<PickedCoordinate> _displayedCoordinate;
  bool _updatingCenter = false;

  @override
  void initState() {
    super.initState();
    _latitude = widget.initialLatitude;
    _longitude = widget.initialLongitude;
    _displayedCoordinate = ValueNotifier(
      PickedCoordinate(latitude: _latitude, longitude: _longitude),
    );
  }

  @override
  void dispose() {
    _displayedCoordinate.dispose();
    super.dispose();
  }

  Future<void> _updateCenter() async {
    final map = _map;
    if (map == null || _updatingCenter) return;
    _updatingCenter = true;
    try {
      final camera = await map.getCameraState();
      if (!mounted) return;
      final latitude = camera.center.coordinates.lat.toDouble();
      final longitude = camera.center.coordinates.lng.toDouble();
      if (latitude != _latitude || longitude != _longitude) {
        _latitude = latitude;
        _longitude = longitude;
        _displayedCoordinate.value = PickedCoordinate(
          latitude: latitude,
          longitude: longitude,
        );
      }
    } finally {
      _updatingCenter = false;
    }
  }

  Future<void> _loadContextMarkers() async {
    final map = _map;
    if (map == null) return;
    _markerManager ??= await map.annotations.createCircleAnnotationManager();
    _areaManager ??= await map.annotations.createPolygonAnnotationManager(
      below: _markerManager!.id,
    );
    _treeManager ??= await map.annotations.createPointAnnotationManager();
    await _markerManager!.deleteAll();
    await _areaManager!.deleteAll();
    await _treeManager!.deleteAll();

    final plots = await PlotDao.getAllPlots();
    final trees = await TreeDao.getAllTrees();
    final anchors = await TitikIkatDao.getAllTitikIkat();
    final markers = <CircleAnnotationOptions>[];
    final treeMarkers = <PointAnnotationOptions>[];

    final titikIkatIcon = await TitikIkatMarkerIconFactory.create();
    for (final anchor in anchors) {
      if (anchor.latitude == null || anchor.longitude == null) continue;
      treeMarkers.add(
        PointAnnotationOptions(
          geometry: Point(
            coordinates: Position(anchor.longitude!, anchor.latitude!),
          ),
          image: titikIkatIcon,
          iconAnchor: IconAnchor.BOTTOM,
          iconSize: kTitikIkatIconSize * titikIkatMarkerScaleNotifier.value,
          iconOpacity: 1,
        ),
      );
    }
    for (final plot in plots) {
      markers.add(
        _circleMarker(
          plot.longitude,
          plot.latitude,
          color: kPlotColor,
          radius: kPlotRadius * plotMarkerScaleNotifier.value,
          strokeColor: kPlotStrokeColor,
          strokeWidth: kPlotStrokeWidth,
          opacity: kPlotOpacity,
        ),
      );
    }
    for (final tree in trees) {
      if (tree.latitude == null || tree.longitude == null) continue;
      final inspected =
          isInspectionWorkflowEnabledNotifier.value && tree.inspected == true;
      treeMarkers.add(
        PointAnnotationOptions(
          geometry: Point(
            coordinates: Position(tree.longitude!, tree.latitude!),
          ),
          image: await TreeMarkerIconFactory.create(
            inspected ? kTreeInspectedColor : kTreeColor,
          ),
          iconAnchor: IconAnchor.BOTTOM,
          iconSize: kTreeIconSize * treeMarkerScaleNotifier.value,
          iconOpacity: kTreeOpacity,
        ),
      );
    }

    final clusterIds = plots.map((plot) => plot.idCluster).toSet();
    for (final clusterId in clusterIds) {
      final clusterPlots =
          plots.where((plot) => plot.idCluster == clusterId).toList();
      final hasPlotOne = clusterPlots.any((plot) => plot.kodePlot == 1);
      if (hasPlotOne || clusterPlots.length < 2) continue;
      final latitude =
          clusterPlots.fold<double>(0, (sum, plot) => sum + plot.latitude) /
          clusterPlots.length;
      final longitude =
          clusterPlots.fold<double>(0, (sum, plot) => sum + plot.longitude) /
          clusterPlots.length;
      markers.add(
        _circleMarker(
          longitude,
          latitude,
          color: kCentroidColor,
          radius: kPlotRadius * centroidMarkerScaleNotifier.value,
          strokeColor: kPlotStrokeColor,
          strokeWidth: kPlotStrokeWidth,
        ),
      );
    }

    final treesByPlot = <int, List<TreeModel>>{};
    for (final tree in trees) {
      treesByPlot.putIfAbsent(tree.plotId, () => []).add(tree);
    }
    final areas = <PolygonAnnotationOptions>[];
    for (final plot in plots) {
      var farthestMeters = 0.0;
      for (final tree in treesByPlot[plot.id] ?? const <TreeModel>[]) {
        final distance =
            tree.latitude != null && tree.longitude != null
                ? _distanceMeters(
                  plot.latitude,
                  plot.longitude,
                  tree.latitude!,
                  tree.longitude!,
                )
                : (tree.jarakPusatM ?? 0);
        farthestMeters = math.max(farthestMeters, distance);
      }
      final radius =
          farthestMeters > 0
              ? farthestMeters + kPlotAreaMarginMeters
              : kEmptyPlotAreaRadiusMeters;
      areas.add(
        PolygonAnnotationOptions(
          geometry: Polygon(
            coordinates: [
              _circleCoordinates(plot.latitude, plot.longitude, radius),
            ],
          ),
          fillColor: kPlotAreaColor,
          fillOutlineColor: kPlotAreaOutlineColor,
          fillOpacity: kPlotAreaOpacity,
        ),
      );
    }

    if (areas.isNotEmpty) await _areaManager!.createMulti(areas);
    if (markers.isNotEmpty) await _markerManager!.createMulti(markers);
    if (treeMarkers.isNotEmpty) await _treeManager!.createMulti(treeMarkers);
  }

  CircleAnnotationOptions _circleMarker(
    double longitude,
    double latitude, {
    required int color,
    required double radius,
    int strokeColor = 0xFFFFFFFF,
    double strokeWidth = 1,
    double opacity = 0.92,
  }) => CircleAnnotationOptions(
    geometry: Point(coordinates: Position(longitude, latitude)),
    circleColor: color,
    circleRadius: radius,
    circleStrokeColor: strokeColor,
    circleStrokeWidth: strokeWidth,
    circleOpacity: opacity,
  );

  double _distanceMeters(
    double fromLat,
    double fromLon,
    double toLat,
    double toLon,
  ) {
    const earthRadius = 6371008.8;
    final lat1 = fromLat * math.pi / 180;
    final lat2 = toLat * math.pi / 180;
    final deltaLat = (toLat - fromLat) * math.pi / 180;
    final deltaLon = (toLon - fromLon) * math.pi / 180;
    final value =
        math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(deltaLon / 2) *
            math.sin(deltaLon / 2);
    final boundedValue = value.clamp(0.0, 1.0);
    return earthRadius *
        2 *
        math.atan2(math.sqrt(boundedValue), math.sqrt(1 - boundedValue));
  }

  List<Position> _circleCoordinates(
    double centerLat,
    double centerLon,
    double radiusMeters,
  ) {
    const earthRadius = 6371008.8;
    final angularDistance = radiusMeters / earthRadius;
    final lat = centerLat * math.pi / 180;
    final lon = centerLon * math.pi / 180;
    final result = <Position>[];
    for (var index = 0; index <= kPlotAreaSegments; index++) {
      final bearing = 2 * math.pi * index / kPlotAreaSegments;
      final targetLat = math.asin(
        math.sin(lat) * math.cos(angularDistance) +
            math.cos(lat) * math.sin(angularDistance) * math.cos(bearing),
      );
      final targetLon =
          lon +
          math.atan2(
            math.sin(bearing) * math.sin(angularDistance) * math.cos(lat),
            math.cos(angularDistance) - math.sin(lat) * math.sin(targetLat),
          );
      result.add(
        Position(targetLon * 180 / math.pi, targetLat * 180 / math.pi),
      );
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = !isLightModeNotifier.value;
    final style = dotenv.env['MAPBOX_STYLE_SATELLITE']?.trim();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih Koordinat'),
        backgroundColor: const Color(0xFF1F4226),
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          MapWidget(
            styleUri:
                style != null && style.isNotEmpty
                    ? style
                    : MapboxStyles.SATELLITE_STREETS,
            viewport: CameraViewportState(
              center: Point(
                coordinates: Position(
                  widget.initialLongitude,
                  widget.initialLatitude,
                ),
              ),
              zoom: 18,
            ),
            onMapCreated: (map) {
              _map = map;
              map.location.updateSettings(
                LocationComponentSettings(enabled: true, pulsingEnabled: true),
              );
              _loadContextMarkers();
            },
            onCameraChangeListener: (_) => _updateCenter(),
            onMapIdleListener: (_) => _updateCenter(),
          ),
          IgnorePointer(
            child: Center(
              child: Transform.translate(
                offset: const Offset(0, -27),
                child: const Icon(
                  Icons.location_pin,
                  size: 54,
                  color: Color(0xFFE53935),
                  shadows: [Shadow(color: Colors.white, blurRadius: 4)],
                ),
              ),
            ),
          ),
          const Positioned(
            left: 12,
            bottom: 190,
            child: MapLegendWidget(
              showConnections: false,
              showSearchResult: false,
              showCloseButton: false,
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF14351D) : Colors.white,
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 10),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Koordinat Saat Ini',
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Geser peta hingga pin tepat di lokasi tujuan',
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ValueListenableBuilder<PickedCoordinate>(
                      valueListenable: _displayedCoordinate,
                      builder:
                          (_, coordinate, __) => Text(
                            'Lintang ${coordinate.latitude.toStringAsFixed(7)}  •  '
                            'Bujur ${coordinate.longitude.toStringAsFixed(7)}',
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1F4226),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                        ),
                        onPressed: () async {
                          final camera = await _map?.getCameraState();
                          if (!context.mounted) return;
                          final latitude =
                              camera?.center.coordinates.lat.toDouble() ??
                              _latitude;
                          final longitude =
                              camera?.center.coordinates.lng.toDouble() ??
                              _longitude;
                          Navigator.of(context).pop(
                            PickedCoordinate(
                              latitude: latitude,
                              longitude: longitude,
                            ),
                          );
                        },
                        icon: const Icon(Icons.check),
                        label: const Text('Gunakan Lokasi Ini'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
