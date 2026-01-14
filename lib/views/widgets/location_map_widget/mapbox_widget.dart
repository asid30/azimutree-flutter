import 'package:azimutree/data/database/cluster_dao.dart';
import 'package:azimutree/data/database/plot_dao.dart';
import 'package:azimutree/data/database/tree_dao.dart';
import 'package:azimutree/data/models/cluster_model.dart';
import 'package:azimutree/data/models/plot_model.dart';
import 'package:azimutree/data/models/tree_model.dart';
import 'package:azimutree/data/notifiers/notifiers.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
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
  CircleAnnotationManager? _searchResultManager;
  late final VoidCallback _styleListener;
  late final VoidCallback _northResetListener;
  // Cache of tree models currently displayed on the map.
  final List<TreeModel> _treesCache = [];
  // Timer used to differentiate single-tap from double-tap (double-tap = zoom).
  Timer? _singleTapTimer;

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

    _northResetListener = () {
      _resetBearingToNorth();
    };
    northResetRequestNotifier.addListener(_northResetListener);
  }

  @override
  void dispose() {
    selectedMenuBottomSheetNotifier.removeListener(_styleListener);
    selectedLocationNotifier.removeListener(_onLocationChanged);
    northResetRequestNotifier.removeListener(_northResetListener);
    super.dispose();
  }

  void _onLocationChanged() {
    final pos = selectedLocationNotifier.value;
    if (!mounted) return;
    if (pos != null && _mapboxMap != null) {
      final follow = isFollowingUserLocationNotifier.value;
      _mapboxMap!.easeTo(
        CameraOptions(center: Point(coordinates: pos), zoom: 14),
        MapAnimationOptions(duration: follow ? 800 : 1500),
      );
      // Show a search result pin so user can see selected location.
      // Do not show the search pin when the map is following the user's live
      // location (it would overlap the user puck).
      if (!isFollowingUserLocationNotifier.value) {
        _showSearchResultMarker(pos);
      } else {
        // Ensure any previous search result marker is removed.
        _removeSearchResultMarker();
      }
    }
  }

  void _resetBearingToNorth() {
    if (!mounted) return;
    if (_mapboxMap == null) return;

    _mapboxMap!.easeTo(
      CameraOptions(bearing: 0),
      MapAnimationOptions(duration: 500),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: selectedMenuBottomSheetNotifier,
      builder: (context, selectedMenuBottomSheet, child) {
        // Wrap the MapWidget in a Stack so we can listen for pointer ups and
        // detect taps on tree markers without blocking the map's native
        // gesture handling (we use a delayed single-tap handler to avoid
        // interfering with double-tap-to-zoom).
        return Stack(
          children: [
            MapWidget(
              onMapCreated: (map) {
                _mapboxMap = map;
                final style =
                    selectedMenuBottomSheetNotifier.value == 0
                        ? widget.standardStyleUri
                        : widget.sateliteStyleUri;
                _applyStyleAndMarkers(style);
                _enableUserLocationPuck();
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
            ),
            // Fullscreen listener that captures pointer ups. We purposely do
            // not block gestures; instead we use a short-delay single-tap
            // recognition so double-tap (zoom) is allowed by the map.
            Positioned.fill(
              child: Listener(
                behavior: HitTestBehavior.translucent,
                onPointerUp: (event) {
                  // If there's an existing timer, this is the second tap
                  // (double-tap). Cancel the pending single-tap action and
                  // let the map handle the gesture (zoom).
                  if (_singleTapTimer != null) {
                    _singleTapTimer!.cancel();
                    _singleTapTimer = null;
                    return;
                  }

                  // Start a short timer; if no second tap comes, treat as
                  // single tap and handle it.
                  _singleTapTimer = Timer(
                    const Duration(milliseconds: 250),
                    () async {
                      _singleTapTimer = null;
                      final local = event.localPosition;
                      await _handleMapSingleTap(local);
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleMapSingleTap(Offset localPosition) async {
    if (_mapboxMap == null) return;
    if (_treesCache.isEmpty) return;

    // Convert each tree coordinate to screen pixel and find nearest to tap.
    double minDist = double.infinity;
    TreeModel? nearest;

    for (final tree in _treesCache) {
      if (tree.latitude == null || tree.longitude == null) continue;
      try {
        final scr = await _mapboxMap!.pixelForCoordinate(
          Point(coordinates: Position(tree.longitude!, tree.latitude!)),
        );
        final off = _extractScreenOffset(scr);
        if (off == null) continue;
        final dx = off.dx - localPosition.dx;
        final dy = off.dy - localPosition.dy;
        final dist = math.sqrt(dx * dx + dy * dy);
        if (dist < minDist) {
          minDist = dist;
          nearest = tree;
        }
      } catch (_) {
        // ignore
      }
    }

    // If nearest marker within threshold (pixels), set selected tree so the
    // existing bottomsheet will display its information.
    const threshold = 28.0; // pixels
    if (nearest != null && minDist <= threshold && mounted) {
      // Clear any search focus to avoid conflicting sheet animations.
      isSearchFieldFocusedNotifier.value = false;
      selectedTreeNotifier.value = nearest;
    }
  }

  Offset? _extractScreenOffset(dynamic scr) {
    if (scr == null) return null;
    try {
      if (scr is Map) {
        final x = scr['x'] ?? scr['X'];
        final y = scr['y'] ?? scr['Y'];
        if (x is num && y is num) return Offset(x.toDouble(), y.toDouble());
      }
    } catch (_) {}
    try {
      final dyn = scr as dynamic;
      final x = dyn.x;
      final y = dyn.y;
      if (x is num && y is num) return Offset(x.toDouble(), y.toDouble());
    } catch (_) {}
    try {
      final json = (scr as dynamic).toJson();
      final x = json['x'];
      final y = json['y'];
      if (x is num && y is num) return Offset(x.toDouble(), y.toDouble());
    } catch (_) {}
    return null;
  }

  Future<void> _enableUserLocationPuck() async {
    if (_mapboxMap == null) return;
    // Shows the user's location indicator (puck/pin) on the map.
    // Permission is handled by geolocator; if not granted, it simply won't show.
    await _mapboxMap!.location.updateSettings(
      LocationComponentSettings(enabled: true, pulsingEnabled: true),
    );
  }

  Future<void> _applyStyleAndMarkers(String styleUri) async {
    if (_mapboxMap == null) return;
    await _mapboxMap!.loadStyleURI(styleUri);
    await _loadMarkers();
  }

  // The bottomsheet now listens to `selectedTreeNotifier` and
  // will display the tree info there. We keep the original
  // full-screen modal helper above for backward compatibility.
  Future<void> _ensureManager() async {
    if (_mapboxMap == null) return;
    _circleManager ??=
        await _mapboxMap!.annotations.createCircleAnnotationManager();
  }

  Future<void> _ensureSearchManager() async {
    if (_mapboxMap == null) return;
    // Create a separate manager for the search result so it can be
    // manipulated independently from the database markers.
    _searchResultManager ??=
        await _mapboxMap!.annotations.createCircleAnnotationManager();
  }

  Future<void> _removeSearchResultMarker() async {
    // Remove any search result markers (circle manager)
    try {
      if (_searchResultManager != null) {
        await _searchResultManager!.deleteAll();
      }
    } catch (_) {}
    // (no symbol manager supported in this plugin version)
  }

  Future<void> _showSearchResultMarker(Position pos) async {
    if (_mapboxMap == null) return;
    // If the app is currently following the user's live location, do not
    // show a search result marker (it would overlap the user location puck).
    if (isFollowingUserLocationNotifier.value) {
      await _removeSearchResultMarker();
      return;
    }

    // Create a circle-style search result marker. We avoid showing this
    // when the map is following user's live location (handled above).
    await _ensureSearchManager();
    if (_searchResultManager == null) return;
    try {
      await _searchResultManager!.deleteAll();
    } catch (_) {}
    await _searchResultManager!.create(
      CircleAnnotationOptions(
        geometry: Point(coordinates: pos),
        circleColor: 0xFFFF5252,
        // Slightly smaller so it doesn't obscure nearby objects or the
        // user location puck.
        circleRadius: 8,
        circleStrokeColor: 0xFFFFFFFF,
        circleStrokeWidth: 1.5,
        circleOpacity: 1.0,
      ),
    );
  }

  Future<void> _loadMarkers() async {
    if (_mapboxMap == null) return;
    await _ensureManager();
    if (_circleManager == null) return;

    await _circleManager!.deleteAll();

    final clusters = await ClusterDao.getAllClusters();
    final plots = await PlotDao.getAllPlots();
    final trees = await TreeDao.getAllTrees();

    // Populate cache for quick access during tap hit-testing.
    _treesCache.clear();
    _treesCache.addAll(trees);

    await _addClusterMarkers(clusters, plots);
    await _addPlotMarkers(plots);
    await _addTreeMarkers(trees);
    // If there's an active selected location (from search), show its pin.
    final sel = selectedLocationNotifier.value;
    if (sel != null) {
      await _showSearchResultMarker(sel);
    }
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
