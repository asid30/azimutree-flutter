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
import 'package:azimutree/views/widgets/alert_dialog_widget/alert_confirmation_widget.dart';

// Marker style constants
const int kClusterColor = 0xFF2E7D32;
const int kClusterStrokeColor = 0xFF1B5E20;
const double kClusterRadius = 11.0;
const double kClusterStrokeWidth = 1.5;
const double kClusterOpacity = 0.85;

const int kPlotColor = 0xFF1565C0;
const int kPlotStrokeColor = 0xFF0D47A1;
const double kPlotRadius = 9.0;
const double kPlotStrokeWidth = 1.2;
const double kPlotOpacity = 0.9;
const int kPlotSelectedStrokeColor = 0xFFFFFFFF;
const double kPlotSelectedStrokeWidth = 1.6;

const int kTreeColor = 0xFFF57C00;
const int kTreeStrokeColor = 0xFFE65100;
const int kTreeSelectedStrokeColor = 0xFFFFFFFF;
const double kTreeRadius = 6.0;
const double kTreeSelectedStrokeWidth = 1.6;
const double kTreeStrokeWidth = 1.0;
const double kTreeOpacity = 0.95;

const int kConnectionColor = 0xFFB71C1C;
const double kConnectionRadius = 2.0;
const int kConnectionSegments = 120;
// Light green for inspected trees (visually distinct from normal tree color)
const int kTreeInspectedColor = 0xFF8BC34A;
// Light blue for plot-to-plot cluster connection lines
const int kPlotConnectionColor = 0xFF81D4FA;

// Centroid generated marker color
const int kCentroidColor = 0xFF6A1B9A;

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
  // Cache of generated centroid markers for hit-testing and metadata.
  final List<Map<String, dynamic>> _centroidCache = [];
  // Use dynamic so we can support line annotation manager when available
  // while avoiding static analyzer errors on plugin API mismatches.
  dynamic _connectionManager;
  // Track current zoom locally so zoom buttons can apply relative changes.
  double _currentZoom = 10.0;
  late final VoidCallback _styleListener;
  late final VoidCallback _northResetListener;
  late final VoidCallback _selectedTreeListener;
  late final VoidCallback _inspectedListener;
  late final VoidCallback _inspectionToggleListener;
  late final VoidCallback _userLocationListener;
  late final VoidCallback _selectedCentroidListener;
  late final VoidCallback _treeToPlotToggleListener;
  late final VoidCallback _plotToPlotToggleListener;
  // Cache of tree models currently displayed on the map.
  final List<TreeModel> _treesCache = [];
  // Cache of plot models currently displayed on the map.
  final List<PlotModel> _plotsCache = [];
  // Timer used to differentiate single-tap from double-tap (double-tap = zoom).
  // Timer used to detect a short hold (long-press) before activating markers.
  Timer? _holdTimer;
  // Whether a long-press was recognized for the current pointer sequence.
  bool _longPressRecognized = false;

  @override
  void initState() {
    super.initState();
    _styleListener = () {
      if (!mounted) return;
      if (_mapboxMap != null) {
        final style =
            // Use satellite as the default for menu index 0
            selectedMenuBottomSheetNotifier.value == 0
                ? widget.sateliteStyleUri
                : widget.standardStyleUri;
        _applyStyleAndMarkers(style);
      }
    };

    selectedMenuBottomSheetNotifier.addListener(_styleListener);
    selectedLocationNotifier.addListener(_onLocationChanged);
    _userLocationListener = () {
      final pos = userLocationNotifier.value;
      if (!mounted) return;
      if (pos != null &&
          _mapboxMap != null &&
          isFollowingUserLocationNotifier.value) {
        _mapboxMap!.easeTo(
          CameraOptions(center: Point(coordinates: pos), zoom: 14),
          MapAnimationOptions(duration: 800),
        );
        _currentZoom = 14.0;
        // Keep selectedLocationNotifier in sync so other UI can react
        selectedLocationNotifier.value = pos;
        // Ensure any search result marker does not conflict with the user puck
        _removeSearchResultMarker();
      }
    };
    userLocationNotifier.addListener(_userLocationListener);
    _treeToPlotToggleListener = () {
      // If tree->plot lines were turned off, remove any existing connection
      // visuals. If turned on, refresh current selection.
      if (!isTreeToPlotLineVisibleNotifier.value) {
        Future.microtask(() async => await _removeConnectionMarkers());
      } else {
        if (selectedTreeNotifier.value != null) {
          Future.microtask(
            () async => await _updateConnectionForSelectedTree(),
          );
        } else if (selectedPlotNotifier.value != null) {
          Future.microtask(
            () async => await _updateConnectionForSelectedPlot(),
          );
        }
      }
    };
    isTreeToPlotLineVisibleNotifier.addListener(_treeToPlotToggleListener);

    _plotToPlotToggleListener = () {
      if (!isPlotToPlotLineVisibleNotifier.value) {
        Future.microtask(() async => await _removeConnectionMarkers());
      } else {
        if (selectedPlotNotifier.value != null) {
          Future.microtask(
            () async => await _updateConnectionForSelectedPlot(),
          );
        }
      }
    };
    isPlotToPlotLineVisibleNotifier.addListener(_plotToPlotToggleListener);
    _selectedTreeListener = () {
      if (!mounted) return;
      // Recreate markers so the selected tree is rendered with the
      // "active" style (no separate highlight annotation required).
      if (_mapboxMap != null) _loadMarkers();
      // Also show a dashed connection line to the plot center.
      _updateConnectionForSelectedTree();
    };
    selectedTreeNotifier.addListener(_selectedTreeListener);

    _selectedCentroidListener = () {
      if (!mounted) return;
      // Reload markers first. If a centroid is selected, draw connections
      // to it. If centroid is cleared, avoid removing connection visuals
      // if another selection (plot/tree) is active — let their listeners
      // manage connections.
      Future.microtask(() async {
        try {
          if (_mapboxMap != null) await _loadMarkers();
          final cluster = selectedCentroidNotifier.value;
          if (cluster != null) {
            await _updateConnectionForSelectedCentroid();
          } else {
            // If a plot or tree is selected, they will redraw connections.
            if (selectedPlotNotifier.value == null &&
                selectedTreeNotifier.value == null) {
              await _removeConnectionMarkers();
            }
          }
        } catch (_) {}
      });
    };
    selectedCentroidNotifier.addListener(_selectedCentroidListener);

    _inspectedListener = () {
      if (!mounted) return;
      // Run asynchronously so the notifier call doesn't block the UI.
      Future.microtask(() async {
        try {
          if (_mapboxMap == null) return;
          // If we have a circle manager and cached trees, update only tree
          // annotations for a faster, more reliable visual update.
          if (_circleManager != null && _treesCache.isNotEmpty) {
            try {
              await _circleManager!.deleteAll();
            } catch (_) {}
            await _addClusterMarkers(
              await ClusterDao.getAllClusters(),
              await PlotDao.getAllPlots(),
            );
            await _addPlotMarkers(_plotsCache);
            await _addTreeMarkers(_treesCache);
          } else {
            // Fallback: reload everything.
            await _loadMarkers();
          }
        } catch (_) {}
      });
    };
    inspectedTreeIdsNotifier.addListener(_inspectedListener);
    // Reload markers when the inspection workflow toggle changes so marker
    // colors reflect the current workflow state (show/hide inspected color).
    _inspectionToggleListener = () {
      if (!mounted) return;
      Future.microtask(() async {
        try {
          if (_mapboxMap == null) return;
          // Refresh markers so tree colors update according to the toggle.
          await _loadMarkers();
        } catch (_) {}
      });
    };
    isInspectionWorkflowEnabledNotifier.addListener(_inspectionToggleListener);

    // React to plot selection (marker taps).
    selectedPlotNotifier.addListener(() {
      if (!mounted) return;
      if (_mapboxMap != null) _loadMarkers();
      _updateConnectionForSelectedPlot();
    });

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
    userLocationNotifier.removeListener(_userLocationListener);
    selectedTreeNotifier.removeListener(_selectedTreeListener);
    inspectedTreeIdsNotifier.removeListener(_inspectedListener);
    isInspectionWorkflowEnabledNotifier.removeListener(
      _inspectionToggleListener,
    );
    isTreeToPlotLineVisibleNotifier.removeListener(_treeToPlotToggleListener);
    isPlotToPlotLineVisibleNotifier.removeListener(_plotToPlotToggleListener);
    selectedCentroidNotifier.removeListener(_selectedCentroidListener);
    super.dispose();
  }

  void _onLocationChanged() {
    final pos = selectedLocationNotifier.value;
    if (!mounted) return;
    if (pos != null && _mapboxMap != null) {
      final follow = isFollowingUserLocationNotifier.value;
      // If the UI requested preserving zoom for this center action,
      // don't supply a zoom value so the map keeps its current zoom level.
      if (preserveZoomOnNextCenterNotifier.value) {
        _mapboxMap!.easeTo(
          CameraOptions(center: Point(coordinates: pos)),
          MapAnimationOptions(duration: follow ? 800 : 1500),
        );
        // Reset the flag after applying
        preserveZoomOnNextCenterNotifier.value = false;
      } else {
        _mapboxMap!.easeTo(
          CameraOptions(center: Point(coordinates: pos), zoom: 14),
          MapAnimationOptions(duration: follow ? 800 : 1500),
        );
        _currentZoom = 14.0;
      }
      // Show a search result pin only when the selected location was set
      // as a search result. Other actions that set `selectedLocationNotifier`
      // (map marker taps, center actions, tracking) should set
      // `selectedLocationFromSearchNotifier` to false so no duplicate pin
      // appears on top of the map markers.
      if (!isFollowingUserLocationNotifier.value &&
          selectedLocationFromSearchNotifier.value) {
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
                // Initial zoom matches the MapWidget cameraOptions below.
                _currentZoom = 10.0;
                final style =
                    // Use satellite as the default for menu index 0
                    selectedMenuBottomSheetNotifier.value == 0
                        ? widget.sateliteStyleUri
                        : widget.standardStyleUri;
                _applyStyleAndMarkers(style);
                _enableUserLocationPuck();
                // Hide the native Mapbox compass so it won't overlap marker
                // info on some devices (we keep a small right gap too).
                try {
                  final dyn = _mapboxMap as dynamic;
                  try {
                    dyn.uiSettings?.setCompassEnabled(false);
                  } catch (_) {
                    dyn.setCompassEnabled?.call(false);
                  }
                } catch (_) {}
                // Keep the Mapbox built-in compass enabled (use default UI).
                // If a target location was set before the map was created
                // (e.g., via "Tracking Data"), center the camera immediately.
                _onLocationChanged();
              },
              styleUri:
                  // Show satellite by default when bottom sheet menu index is 0
                  selectedMenuBottomSheet == 0
                      ? widget.sateliteStyleUri
                      : widget.standardStyleUri,
              cameraOptions: CameraOptions(
                // Center the initial camera on Bandar Lampung (Lampung province)
                center: Point(
                  // Longitude, Latitude for Bandar Lampung
                  coordinates: Position(105.2626, -5.4297),
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
                onPointerDown: (event) {
                  // Start a short hold timer; only if this fires do we
                  // consider the subsequent pointer up as an activation.
                  _holdTimer?.cancel();
                  _longPressRecognized = false;
                  _holdTimer = Timer(const Duration(milliseconds: 200), () {
                    _longPressRecognized = true;
                  });
                },
                onPointerUp: (event) async {
                  // Cancel any pending hold timer.
                  if (_holdTimer != null) {
                    _holdTimer!.cancel();
                    _holdTimer = null;
                  }

                  if (_longPressRecognized) {
                    // A long-press was recognized: activate marker selection.
                    _longPressRecognized = false;
                    // Respect the global toggle: if marker activation is
                    // disabled, skip handling the tap.
                    if (!isMarkerActivationEnabledNotifier.value) return;
                    final local = event.localPosition;
                    await _handleMapSingleTap(local);
                  }
                  // Quick taps (including double-tap) are ignored here so the
                  // native map gestures (zoom, etc.) continue to work.
                },
                onPointerCancel: (event) {
                  _holdTimer?.cancel();
                  _holdTimer = null;
                  _longPressRecognized = false;
                },
              ),
            ),
            // Zoom controls (inset on top of the map).
            Positioned(
              right: 12,
              // Compute a dynamic bottom offset so the controls sit above
              // the bottomsheet on most device sizes rather than being
              // occluded. This uses a fraction of the screen height.
              bottom: MediaQuery.of(context).size.height * 0.28,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // (Using built-in Mapbox compass; no custom compass here.)
                  // Remove-search-marker button at top so it's visually first.
                  ValueListenableBuilder<bool>(
                    valueListenable: selectedLocationFromSearchNotifier,
                    builder: (context, hasSearchMarker, child) {
                      if (!hasSearchMarker) return const SizedBox.shrink();
                      return Tooltip(
                        message: 'Hapus marker pencarian',
                        child: FloatingActionButton.small(
                          heroTag: 'remove_search_marker_btn',
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder:
                                  (_) => const AlertConfirmationWidget(
                                    message:
                                        'Hapus marker pencarian dari peta?',
                                    confirmText: 'Hapus',
                                    cancelText: 'Batal',
                                  ),
                            );
                            if (confirm != true) return;
                            // Prevent the bottomsheet from regaining focus or
                            // expanding after the dialog dismisses by explicitly
                            // unfocusing and clearing the focus notifier.
                            try {
                              FocusManager.instance.primaryFocus?.unfocus();
                            } catch (_) {}
                            try {
                              isSearchFieldFocusedNotifier.value = false;
                            } catch (_) {}
                            try {
                              await _removeSearchResultMarker();
                            } catch (_) {}
                            try {
                              selectedLocationFromSearchNotifier.value = false;
                              selectedLocationNotifier.value = null;
                            } catch (_) {}
                          },
                          backgroundColor: const Color.fromARGB(
                            255,
                            205,
                            237,
                            211,
                          ),
                          child: const Icon(
                            Icons.clear,
                            color: Color(0xFF1F4226),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  ValueListenableBuilder<bool>(
                    valueListenable: isMarkerActivationEnabledNotifier,
                    builder: (context, enabled, child) {
                      return Tooltip(
                        message:
                            enabled
                                ? 'Klik marker: Aktif'
                                : 'Klik marker: Nonaktif',
                        child: FloatingActionButton.small(
                          heroTag: 'toggle_marker_activation',
                          onPressed:
                              () =>
                                  isMarkerActivationEnabledNotifier.value =
                                      !enabled,
                          backgroundColor: const Color.fromARGB(
                            255,
                            205,
                            237,
                            211,
                          ),
                          child: Icon(
                            enabled ? Icons.touch_app : Icons.block,
                            color: const Color(0xFF1F4226),
                          ),
                        ),
                      );
                    },
                  ),
                  FloatingActionButton.small(
                    heroTag: 'zoom_in_btn',
                    onPressed: () async => _zoomBy(1.0),
                    backgroundColor: Color.fromARGB(255, 205, 237, 211),
                    child: const Icon(Icons.add, color: Color(0xFF1F4226)),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton.small(
                    heroTag: 'zoom_out_btn',
                    onPressed: () async => _zoomBy(-1.0),
                    backgroundColor: Color.fromARGB(255, 205, 237, 211),
                    child: const Icon(Icons.remove, color: Color(0xFF1F4226)),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleMapSingleTap(Offset localPosition) async {
    if (_mapboxMap == null) return;
    if (_treesCache.isEmpty && _plotsCache.isEmpty) return;

    // Convert tree and plot coordinates to screen pixels and find nearest.
    double minDist = double.infinity;
    TreeModel? nearestTree;
    PlotModel? nearestPlot;

    // Track nearest centroid candidate entry (contains cluster, lat, lon)
    Map<String, dynamic>? nearestCentroidEntry;

    // Helper to process a coordinate and update nearest candidates.
    Future<void> processCoordinate(
      double lon,
      double lat, {
      TreeModel? tree,
      PlotModel? plot,
      Map<String, dynamic>? centroidEntry,
    }) async {
      try {
        final scr = await _mapboxMap!.pixelForCoordinate(
          Point(coordinates: Position(lon, lat)),
        );
        final off = _extractScreenOffset(scr);
        if (off == null) return;
        final dx = off.dx - localPosition.dx;
        final dy = off.dy - localPosition.dy;
        final dist = math.sqrt(dx * dx + dy * dy);
        if (dist < minDist) {
          minDist = dist;
          nearestTree = tree;
          nearestPlot = plot;
          if (centroidEntry != null) {
            nearestCentroidEntry = centroidEntry;
          }
        }
      } catch (_) {
        // ignore conversion errors per point
      }
    }

    // Check trees first
    for (final tree in _treesCache) {
      if (tree.latitude == null || tree.longitude == null) continue;
      await processCoordinate(tree.longitude!, tree.latitude!, tree: tree);
    }

    // Then check plots
    for (final plot in _plotsCache) {
      // PlotModel latitude/longitude are non-nullable.
      await processCoordinate(plot.longitude, plot.latitude, plot: plot);
    }

    // Then check generated centroids
    if (_centroidCache.isNotEmpty) {
      for (final c in _centroidCache) {
        final lon = c['lon'] as double?;
        final lat = c['lat'] as double?;
        if (lon == null || lat == null) continue;
        await processCoordinate(lon, lat, centroidEntry: c);
      }
    }

    const threshold = 28.0; // pixels
    if (minDist <= threshold && mounted) {
      isSearchFieldFocusedNotifier.value = false;

      // Prefer tree over plot if both are equally close.
      if (nearestTree != null) {
        final selTree = nearestTree;
        // Clear centroid selection when selecting a tree so its marker
        // style deactivates immediately.
        selectedCentroidNotifier.value = null;
        selectedPlotNotifier.value = null;
        selectedTreeNotifier.value = selTree;
        // Resolve plot and cluster for UI consumption
        try {
          final plot = await PlotDao.getPlotById(selTree!.plotId);
          selectedTreePlotNotifier.value = plot;
          if (plot != null) {
            final cluster = await ClusterDao.getClusterById(plot.idCluster);
            selectedTreeClusterNotifier.value = cluster;
          } else {
            selectedTreeClusterNotifier.value = null;
          }
        } catch (_) {
          selectedTreePlotNotifier.value = null;
          selectedTreeClusterNotifier.value = null;
        }
        // Position the floating info near the pointer (slightly above)
        selectedMarkerScreenOffsetNotifier.value = Offset(
          localPosition.dx,
          localPosition.dy - 48,
        );
        try {
          isFollowingUserLocationNotifier.value = false;
          preserveZoomOnNextCenterNotifier.value = true;
          selectedLocationFromSearchNotifier.value = false;
          selectedLocationNotifier.value = Position(
            selTree!.longitude!,
            selTree.latitude!,
          );
        } catch (_) {}
        return;
      }

      if (nearestPlot != null) {
        final selPlot = nearestPlot;
        // Clear centroid selection when selecting a plot so centroid
        // loses the active style immediately.
        selectedCentroidNotifier.value = null;
        selectedTreeNotifier.value = null;
        selectedTreePlotNotifier.value = null;
        selectedTreeClusterNotifier.value = null;
        selectedPlotNotifier.value = selPlot;
        // Resolve cluster for selected plot to allow showing kodeCluster
        try {
          final cluster = await ClusterDao.getClusterById(selPlot!.idCluster);
          selectedPlotClusterNotifier.value = cluster;
        } catch (_) {
          selectedPlotClusterNotifier.value = null;
        }
        selectedMarkerScreenOffsetNotifier.value = Offset(
          localPosition.dx,
          localPosition.dy - 48,
        );
        try {
          isFollowingUserLocationNotifier.value = false;
          preserveZoomOnNextCenterNotifier.value = true;
          selectedLocationFromSearchNotifier.value = false;
          selectedLocationNotifier.value = Position(
            selPlot!.longitude,
            selPlot.latitude,
          );
        } catch (_) {}
      }
      // If no plot/tree selected but a centroid was nearest, select centroid
      if (nearestPlot == null && nearestCentroidEntry != null) {
        final selEntry = nearestCentroidEntry!;
        final selCluster = selEntry['cluster'] as ClusterModel?;
        final selLat = selEntry['lat'] as double?;
        final selLon = selEntry['lon'] as double?;
        selectedTreeNotifier.value = null;
        selectedPlotNotifier.value = null;
        selectedCentroidNotifier.value = selCluster;
        selectedPlotClusterNotifier.value = selCluster;
        selectedMarkerScreenOffsetNotifier.value = Offset(
          localPosition.dx,
          localPosition.dy - 48,
        );
        try {
          isFollowingUserLocationNotifier.value = false;
          preserveZoomOnNextCenterNotifier.value = true;
          selectedLocationFromSearchNotifier.value = false;
          if (selLon != null && selLat != null) {
            selectedLocationNotifier.value = Position(selLon, selLat);
          }
        } catch (_) {}
      }
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

  Future<void> _removeConnectionMarkers() async {
    try {
      // Remove any native annotation-based connections
      if (_connectionManager != null) {
        try {
          await (_connectionManager as dynamic).deleteAll();
        } catch (_) {}
      }
      // Also remove any style-based GeoJSON source/layer we may have added
      try {
        final style = (_mapboxMap as dynamic).style;
        await style.removeLayer('connection-line-layer');
      } catch (_) {}
      try {
        final style = (_mapboxMap as dynamic).style;
        await style.removeSource('connection-line-source');
      } catch (_) {}
    } catch (_) {}
  }

  Future<void> _showConnectionLine(
    double lonA,
    double latA,
    double lonB,
    double latB,
  ) async {
    if (_mapboxMap == null) return;
    // Do not pre-create managers here; prefer creating a native polyline
    // manager below. Remove any previous connection visuals first.
    await _removeConnectionMarkers();

    // Build list of coordinates for the line (both as raw pairs for GeoJSON
    // and as Position objects for potential fallback annotation creation).
    final segments = math.max(8, (kConnectionSegments / 6).round());
    final coordsPairs = <List<double>>[];
    final coordsPositions = <Position>[];
    for (int i = 0; i <= segments; i++) {
      final t = i / segments;
      final lon = lonA + (lonB - lonA) * t;
      final lat = latA + (latB - latA) * t;
      coordsPairs.add([lon, lat]);
      coordsPositions.add(Position(lon, lat));
    }

    // Preferred approach: add a GeoJSON source + LineLayer to the map style
    // so a single vector line is rendered (best performance). We use the
    // map's style API via dynamic calls to avoid static type issues.
    // First try native PolylineAnnotationManager (best - single native polyline)
    try {
      _connectionManager ??=
          await (_mapboxMap!.annotations as dynamic)
              .createPolylineAnnotationManager();
      if (_connectionManager != null) {
        final polylineOptions = PolylineAnnotationOptions(
          geometry: LineString(coordinates: coordsPositions),
          lineColor: kConnectionColor,
          lineWidth: 2.0,
          lineOpacity: 1.0,
        );
        await (_connectionManager as dynamic).create(polylineOptions);
        return;
      }
    } catch (_) {}

    try {
      final style = (_mapboxMap as dynamic).style;
      // Remove existing layer/source if present.
      try {
        await style.removeLayer('connection-line-layer');
      } catch (_) {}
      try {
        await style.removeSource('connection-line-source');
      } catch (_) {}

      final coordinates = coordsPairs;

      final geojson = {
        'type': 'geojson',
        'data': {
          'type': 'Feature',
          'geometry': {'type': 'LineString', 'coordinates': coordinates},
        },
      };

      await style.addSource('connection-line-source', geojson);

      final colorHex =
          '#${(kConnectionColor & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

      final layer = {
        'id': 'connection-line-layer',
        'type': 'line',
        'source': 'connection-line-source',
        'paint': {'line-color': colorHex, 'line-width': 2, 'line-opacity': 1.0},
      };

      await style.addLayer(layer);
      return;
    } catch (_) {}

    // No circle-annotation fallback: prefer native polyline or style layer only.
  }

  Future<void> _zoomBy(double delta) async {
    if (_mapboxMap == null) return;
    final newZoom = (_currentZoom + delta).clamp(1.0, 22.0);
    try {
      await _mapboxMap!.easeTo(
        CameraOptions(zoom: newZoom),
        MapAnimationOptions(duration: 300),
      );
      _currentZoom = newZoom;
    } catch (_) {}
  }

  Future<void> _updateConnectionForSelectedTree() async {
    final tree = selectedTreeNotifier.value;
    if (_mapboxMap == null) return;
    if (tree == null) {
      await _removeConnectionMarkers();
      return;
    }
    // Respect user preference: do not draw tree->plot lines if disabled.
    if (!isTreeToPlotLineVisibleNotifier.value) {
      await _removeConnectionMarkers();
      return;
    }
    if (tree.latitude == null || tree.longitude == null) return;

    // Find the plot center for this tree and draw connection.
    try {
      final plot = await PlotDao.getPlotById(tree.plotId);
      if (plot == null) {
        await _removeConnectionMarkers();
        return;
      }
      await _showConnectionLine(
        tree.longitude!,
        tree.latitude!,
        plot.longitude,
        plot.latitude,
      );
    } catch (_) {
      // ensure we clear markers on error
      await _removeConnectionMarkers();
    }
  }

  Future<void> _updateConnectionForSelectedPlot() async {
    final plot = selectedPlotNotifier.value;
    if (_mapboxMap == null) return;
    if (plot == null) {
      await _removeConnectionMarkers();
      return;
    }

    try {
      // Find cluster for this plot
      final cluster = await ClusterDao.getClusterById(plot.idCluster);
      if (cluster == null) {
        await _removeConnectionMarkers();
        return;
      }

      // Find representative cluster coordinates: prefer plot 1 if exists
      final clusterPlots = await PlotDao.getAllPlots();
      final plotsForCluster =
          clusterPlots.where((p) => p.idCluster == cluster.id).toList();
      if (plotsForCluster.isEmpty) {
        await _removeConnectionMarkers();
        return;
      }

      double clusterLat;
      double clusterLon;
      final plot1 = plotsForCluster.firstWhere(
        (p) => p.kodePlot == 1,
        orElse: () => plotsForCluster.first,
      );
      clusterLat = plot1.latitude;
      clusterLon = plot1.longitude;

      if (plot1.kodePlot != 1 && plotsForCluster.length > 1) {
        clusterLat =
            plotsForCluster.map((p) => p.latitude).reduce((a, b) => a + b) /
            plotsForCluster.length;
        clusterLon =
            plotsForCluster.map((p) => p.longitude).reduce((a, b) => a + b) /
            plotsForCluster.length;
      }

      // Build lines from every plot in the cluster to the representative
      // cluster center (plot 1 preferred). This draws multiple straight
      // connections from each plot marker (blue) to plot1.
      final plotSegments = <List<double>>[];
      for (final p in plotsForCluster) {
        plotSegments.add([p.longitude, p.latitude, clusterLon, clusterLat]);
      }
      // Draw plot->plot lines in light-blue only if enabled by the user.
      if (plotSegments.isNotEmpty && isPlotToPlotLineVisibleNotifier.value) {
        await _showConnectionLines(
          plotSegments,
          color: kPlotConnectionColor,
          removeExisting: true,
        );
      }

      // Additionally, draw connections from the selected plot to each of its
      // child trees (plot -> tree). These should use the original
      // connection color (red).
      final allTrees = await TreeDao.getAllTrees();
      final treesForPlot =
          allTrees
              .where(
                (t) =>
                    t.plotId == plot.id &&
                    t.latitude != null &&
                    t.longitude != null,
              )
              .toList();
      final treeSegments = <List<double>>[];
      for (final t in treesForPlot) {
        treeSegments.add([
          plot.longitude,
          plot.latitude,
          t.longitude!,
          t.latitude!,
        ]);
      }
      if (treeSegments.isNotEmpty && isTreeToPlotLineVisibleNotifier.value) {
        // Add tree connection lines without removing the plot->plot lines.
        await _showConnectionLines(
          treeSegments,
          color: kConnectionColor,
          removeExisting: false,
        );
      }
    } catch (_) {
      await _removeConnectionMarkers();
    }
  }

  Future<void> _updateConnectionForSelectedCentroid() async {
    final cluster = selectedCentroidNotifier.value;
    if (_mapboxMap == null) return;
    if (cluster == null) {
      await _removeConnectionMarkers();
      return;
    }

    try {
      // Find plots for this cluster
      final allPlots = await PlotDao.getAllPlots();
      final plotsForCluster =
          allPlots.where((p) => p.idCluster == cluster.id).toList();
      if (plotsForCluster.isEmpty) {
        await _removeConnectionMarkers();
        return;
      }

      // Compute centroid (average) of available plot coordinates
      final latSum = plotsForCluster
          .map((p) => p.latitude)
          .reduce((a, b) => a + b);
      final lonSum = plotsForCluster
          .map((p) => p.longitude)
          .reduce((a, b) => a + b);
      final centroidLat = latSum / plotsForCluster.length;
      final centroidLon = lonSum / plotsForCluster.length;

      // Build lines from every plot in the cluster to the centroid
      final plotSegments = <List<double>>[];
      for (final p in plotsForCluster) {
        plotSegments.add([p.longitude, p.latitude, centroidLon, centroidLat]);
      }

      if (plotSegments.isNotEmpty && isPlotToPlotLineVisibleNotifier.value) {
        await _showConnectionLines(
          plotSegments,
          color: kPlotConnectionColor,
          removeExisting: true,
        );
      } else {
        // If plotting is disabled, ensure connections are removed.
        await _removeConnectionMarkers();
      }
    } catch (_) {
      await _removeConnectionMarkers();
    }
  }

  Future<void> _showConnectionLines(
    List<List<double>> segments, {
    int color = kPlotConnectionColor,
    bool removeExisting = true,
  }) async {
    if (_mapboxMap == null) return;
    // Optionally remove previous visuals
    if (removeExisting) await _removeConnectionMarkers();

    // Try native polyline manager: create one polyline per segment
    try {
      _connectionManager ??=
          await (_mapboxMap!.annotations as dynamic)
              .createPolylineAnnotationManager();
      if (_connectionManager != null) {
        for (final seg in segments) {
          final lonA = seg[0];
          final latA = seg[1];
          final lonB = seg[2];
          final latB = seg[3];
          final options = PolylineAnnotationOptions(
            geometry: LineString(
              coordinates: [Position(lonA, latA), Position(lonB, latB)],
            ),
            lineColor: color,
            lineWidth: 2.0,
            lineOpacity: 1.0,
          );
          await (_connectionManager as dynamic).create(options);
        }
        return;
      }
    } catch (_) {}

    // Fallback to a GeoJSON feature collection containing multiple LineString
    // features so the style layer can render all segments at once.
    try {
      final features =
          segments.map((seg) {
            return {
              'type': 'Feature',
              'geometry': {
                'type': 'LineString',
                'coordinates': [
                  [seg[0], seg[1]],
                  [seg[2], seg[3]],
                ],
              },
            };
          }).toList();

      final geojson = {
        'type': 'geojson',
        'data': {'type': 'FeatureCollection', 'features': features},
      };

      final style = (_mapboxMap as dynamic).style;
      final colorHex =
          '#${(color & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

      // Use unique source/layer ids per color so multiple calls can coexist.
      final sourceId = 'connection-line-source-$colorHex';
      final layerId = 'connection-line-layer-$colorHex';

      try {
        await style.removeLayer(layerId);
      } catch (_) {}
      try {
        await style.removeSource(sourceId);
      } catch (_) {}

      await style.addSource(sourceId, geojson);

      final layer = {
        'id': layerId,
        'type': 'line',
        'source': sourceId,
        'paint': {'line-color': colorHex, 'line-width': 2, 'line-opacity': 1.0},
      };

      await style.addLayer(layer);
      return;
    } catch (_) {}
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
    _plotsCache.clear();
    _plotsCache.addAll(plots);

    await _addClusterMarkers(clusters, plots);
    await _addPlotMarkers(plots);
    await _addTreeMarkers(trees);
    // If there's an active selected location that originated from a search,
    // show its pin. Other flows that set `selectedLocationNotifier` (e.g.
    // tracking, map marker taps) should set
    // `selectedLocationFromSearchNotifier.value = false` so no duplicate
    // search pin appears on top of the map markers.
    final sel = selectedLocationNotifier.value;
    if (sel != null && selectedLocationFromSearchNotifier.value) {
      await _showSearchResultMarker(sel);
    }
    // Ensure that if a tree or plot was selected before the map was created
    // (for example when navigating from Manage Data's Tracking action),
    // we draw the appropriate connection now that markers are loaded and
    // the connection manager is available. Prefer tree over plot.
    if (selectedTreeNotifier.value != null) {
      await _updateConnectionForSelectedTree();
    } else if (selectedPlotNotifier.value != null) {
      await _updateConnectionForSelectedPlot();
    } else {
      // No selection: ensure no stale connection remains.
      await _removeConnectionMarkers();
    }
  }

  Future<void> _addClusterMarkers(
    List<ClusterModel> clusters,
    List<PlotModel> plots,
  ) async {
    // Add generated-centroid markers for clusters that do NOT have a Plot 1
    // and that contain more than one plot. The marker uses the same size
    // as plot markers but a distinct purple color.
    if (_circleManager == null) return;
    _centroidCache.clear();
    final futures = <Future>[];
    for (final cluster in clusters) {
      try {
        final clusterPlots =
            plots.where((p) => p.idCluster == cluster.id).toList();
        if (clusterPlots.length <= 1) {
          continue; // do not show for single-plot clusters
        }
        final hasPlot1 = clusterPlots.any((p) => p.kodePlot == 1);
        if (hasPlot1) {
          continue; // skip if Plot 1 exists
        }

        // Compute centroid (average) of plot coordinates
        final latSum = clusterPlots.fold<double>(0.0, (s, p) => s + p.latitude);
        final lonSum = clusterPlots.fold<double>(
          0.0,
          (s, p) => s + p.longitude,
        );
        final centroidLat = latSum / clusterPlots.length;
        final centroidLon = lonSum / clusterPlots.length;

        // remember for hit-testing
        _centroidCache.add({
          'cluster': cluster,
          'lat': centroidLat,
          'lon': centroidLon,
        });

        final isSelectedCentroid =
            selectedCentroidNotifier.value?.id == cluster.id;
        futures.add(
          _circleManager!.create(
            _buildCircleOptions(
              Position(centroidLon, centroidLat),
              circleColor: kCentroidColor,
              circleRadius: kPlotRadius,
              circleStrokeColor:
                  isSelectedCentroid
                      ? kPlotSelectedStrokeColor
                      : kPlotStrokeColor,
              circleStrokeWidth:
                  isSelectedCentroid
                      ? kPlotSelectedStrokeWidth
                      : kPlotStrokeWidth,
              circleOpacity: 1.0,
            ),
          ),
        );
      } catch (_) {
        // ignore per-cluster errors
      }
    }

    if (futures.isNotEmpty) await Future.wait(futures);
  }

  Future<void> _addPlotMarkers(List<PlotModel> plots) async {
    final futures = <Future>[];
    for (final plot in plots) {
      final selected = selectedPlotNotifier.value?.id == plot.id;
      futures.add(
        _circleManager!.create(
          _buildCircleOptions(
            Position(plot.longitude, plot.latitude),
            circleColor: kPlotColor,
            circleRadius: kPlotRadius,
            circleStrokeColor:
                selected ? kPlotSelectedStrokeColor : kPlotStrokeColor,
            circleStrokeWidth:
                selected ? kPlotSelectedStrokeWidth : kPlotStrokeWidth,
            circleOpacity: kPlotOpacity,
          ),
        ),
      );
    }

    if (futures.isNotEmpty) await Future.wait(futures);
  }

  Future<void> _addTreeMarkers(List<TreeModel> trees) async {
    final futures = <Future>[];
    final selTree = selectedTreeNotifier.value;
    int? selPlotId = selTree?.plotId;
    int? selClusterId;
    if (selTree != null) {
      try {
        final selPlot = _plotsCache.firstWhere((p) => p.id == selTree.plotId);
        selClusterId = selPlot.idCluster;
      } catch (_) {
        selClusterId = null;
      }
    }
    // Also consider selected plot context: when a plot is selected, all trees
    // in the same cluster should be muted (gray) except trees belonging to
    // the selected plot.
    final selPlotModel = selectedPlotNotifier.value;
    int? selPlotSelectedId = selPlotModel?.id;
    int? selPlotClusterId;
    if (selPlotModel != null) {
      try {
        final sp = _plotsCache.firstWhere((p) => p.id == selPlotModel.id);
        selPlotClusterId = sp.idCluster;
      } catch (_) {
        selPlotClusterId = null;
      }
    }

    for (final tree in trees) {
      if (tree.latitude == null || tree.longitude == null) continue;
      final selected = selTree?.id == tree.id;

      // If the tree is marked as inspected and the inspection workflow is
      // currently enabled, show it with the inspected color. When the
      // workflow toggle is off, treat trees as not inspected for visual
      // purposes so they render the normal color.
      final inspected =
          isInspectionWorkflowEnabledNotifier.value &&
          tree.id != null &&
          inspectedTreeIdsNotifier.value.contains(tree.id);

      // Determine cluster for this tree via its plot.
      int? treeClusterId;
      try {
        final treePlot = _plotsCache.firstWhere((p) => p.id == tree.plotId);
        treeClusterId = treePlot.idCluster;
      } catch (_) {
        treeClusterId = null;
      }

      // Coloring rules (priority):
      // - If a tree is selected: other trees in the same cluster but different
      //   plot are muted (gray).
      // - Else if a plot is selected: trees in the same cluster but not in the
      //   selected plot are muted (gray).
      // - Otherwise, inspected trees show inspected color; else normal color.
      int circleColor = kTreeColor;
      if (selTree != null && !selected) {
        if (selClusterId != null &&
            treeClusterId == selClusterId &&
            tree.plotId != selPlotId) {
          circleColor =
              0xFFBDBDBD; // neutral gray (different plot in same cluster)
        } else if (inspected) {
          circleColor = kTreeInspectedColor;
        } else {
          circleColor = kTreeColor;
        }
      } else if (selPlotModel != null) {
        // Plot selection context
        if (selPlotClusterId != null &&
            treeClusterId == selPlotClusterId &&
            tree.plotId != selPlotSelectedId) {
          circleColor = 0xFFBDBDBD; // neutral gray for other plots in cluster
        } else if (inspected) {
          circleColor = kTreeInspectedColor;
        } else {
          circleColor = kTreeColor;
        }
      } else {
        // No selection context: inspected still shows inspected color.
        if (inspected) circleColor = kTreeInspectedColor;
      }

      futures.add(
        _circleManager!.create(
          _buildCircleOptions(
            Position(tree.longitude!, tree.latitude!),
            circleColor: circleColor,
            circleRadius: kTreeRadius,
            circleStrokeColor:
                selected ? kTreeSelectedStrokeColor : kTreeStrokeColor,
            circleStrokeWidth:
                selected ? kTreeSelectedStrokeWidth : kTreeStrokeWidth,
            circleOpacity: kTreeOpacity,
          ),
        ),
      );
    }

    if (futures.isNotEmpty) await Future.wait(futures);
  }

  CircleAnnotationOptions _buildCircleOptions(
    Position pos, {
    required int circleColor,
    required double circleRadius,
    int? circleStrokeColor,
    double? circleStrokeWidth,
    double circleOpacity = 1.0,
  }) {
    return CircleAnnotationOptions(
      geometry: Point(coordinates: pos),
      circleColor: circleColor,
      circleRadius: circleRadius,
      circleStrokeColor: circleStrokeColor,
      circleStrokeWidth: circleStrokeWidth,
      circleOpacity: circleOpacity,
    );
  }
}
