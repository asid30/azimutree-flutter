import 'package:azimutree/data/notifiers/notifiers.dart';
import 'package:azimutree/views/widgets/location_map_widget/searchbar_bottomsheet_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:azimutree/data/models/tree_model.dart';
import 'package:azimutree/data/database/plot_dao.dart';
import 'package:azimutree/data/database/cluster_dao.dart';
import 'package:azimutree/data/database/tree_dao.dart';
import 'package:azimutree/data/models/plot_model.dart';
import 'package:azimutree/data/models/cluster_model.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:async';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:azimutree/services/gdrive_thumbnail_service.dart';

class BottomsheetLocationMapWidget extends StatefulWidget {
  const BottomsheetLocationMapWidget({super.key});
  @override
  State<BottomsheetLocationMapWidget> createState() =>
      _BottomsheetLocationMapWidgetState();
}

class _BottomsheetLocationMapWidgetState
    extends State<BottomsheetLocationMapWidget> {
  StreamSubscription<geo.Position>? _positionSub;
  final double _maxChildSize = 0.9;
  final double _minChildSize = 0.25;
  final DraggableScrollableController _draggableController =
      DraggableScrollableController();
  late final VoidCallback _searchFocusListener;
  late final VoidCallback _searchCenterListener;
  late final VoidCallback _minimizeRequestListener;

  // Cached plot/cluster info for the currently-selected tree.
  PlotModel? _selectedPlot;
  ClusterModel? _selectedCluster;
  List<TreeModel> _treesForSelectedPlot = [];
  late final VoidCallback _selectedPlotListener;
  late final VoidCallback _selectedTreeListener;
  // Whether the local database contains any cluster/plot/tree data.
  bool _hasAnyData = false;

  @override
  void initState() {
    super.initState();
    _searchFocusListener = () {
      if (isSearchFieldFocusedNotifier.value) {
        _draggableController.animateTo(
          (_maxChildSize * 0.75).clamp(_minChildSize, _maxChildSize),
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
        );
      } else {
        _draggableController.animateTo(
          _minChildSize,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
        );
      }
    };
    isSearchFieldFocusedNotifier.addListener(_searchFocusListener);

    _minimizeRequestListener = () {
      try {
        _draggableController.animateTo(
          _minChildSize,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
        );
      } catch (_) {}
    };
    bottomsheetMinimizeRequestNotifier.addListener(_minimizeRequestListener);

    _searchCenterListener = () {
      // When a search result set `selectedLocationFromSearchNotifier`,
      // center will occur on the map. After a short delay (to let the
      // camera animation run), minimize the bottomsheet, unfocus the
      // search field (hide keyboard), and ensure any previous marker
      // selection is cleared.
      if (!selectedLocationFromSearchNotifier.value) return;
      Future.microtask(() async {
        await Future.delayed(const Duration(milliseconds: 600));
        if (!mounted) return;
        try {
          // Minimize bottomsheet
          bottomsheetMinimizeRequestNotifier.value =
              bottomsheetMinimizeRequestNotifier.value + 1;
        } catch (_) {}
        try {
          // Unfocus keyboard/search field
          if (context.mounted) FocusScope.of(context).unfocus();
          isSearchFieldFocusedNotifier.value = false;
        } catch (_) {}
        try {
          // Clear any existing marker selection (previous marker)
          selectedTreeNotifier.value = null;
          selectedPlotNotifier.value = null;
        } catch (_) {}
      });
    };
    selectedLocationFromSearchNotifier.addListener(_searchCenterListener);

    _selectedTreeListener = () {
      final tree = selectedTreeNotifier.value;
      if (tree == null) {
        setState(() {
          _selectedPlot = null;
          _selectedCluster = null;
        });
        // Ensure global selected tree plot/cluster notifiers are cleared
        selectedTreePlotNotifier.value = null;
        selectedTreeClusterNotifier.value = null;
        return;
      }
      // Fetch plot and cluster for the selected tree asynchronously.
      PlotDao.getPlotById(tree.plotId)
          .then((plot) async {
            if (!mounted) return;
            if (plot == null) {
              setState(() {
                _selectedPlot = null;
                _selectedCluster = null;
              });
              // clear global notifiers as well
              selectedTreePlotNotifier.value = null;
              selectedTreeClusterNotifier.value = null;
              return;
            }
            try {
              final cluster = await ClusterDao.getClusterById(plot.idCluster);
              if (!mounted) return;
              setState(() {
                _selectedPlot = plot;
                _selectedCluster = cluster;
              });
              // update global notifiers so other widgets (map overlay) can consume
              selectedTreePlotNotifier.value = plot;
              selectedTreeClusterNotifier.value = cluster;
              // Populate trees for this plot so Prev/Next can navigate
              TreeDao.getAllTrees()
                  .then((allTrees) {
                    if (!mounted) return;
                    final trees =
                        allTrees.where((t) => t.plotId == plot.id).toList();
                    setState(() {
                      _treesForSelectedPlot = trees;
                    });
                  })
                  .catchError((_) {
                    if (!mounted) return;
                    setState(() {
                      _treesForSelectedPlot = [];
                    });
                  });
            } catch (_) {
              if (!mounted) return;
              setState(() {
                _selectedPlot = plot;
                _selectedCluster = null;
              });
              selectedTreePlotNotifier.value = plot;
              selectedTreeClusterNotifier.value = null;
              // Populate trees even if cluster lookup failed
              TreeDao.getAllTrees()
                  .then((allTrees) {
                    if (!mounted) return;
                    final trees =
                        allTrees.where((t) => t.plotId == plot.id).toList();
                    setState(() {
                      _treesForSelectedPlot = trees;
                    });
                  })
                  .catchError((_) {
                    if (!mounted) return;
                    setState(() {
                      _treesForSelectedPlot = [];
                    });
                  });
            }
          })
          .catchError((_) {
            if (!mounted) return;
            setState(() {
              _selectedPlot = null;
              _selectedCluster = null;
            });
            selectedTreePlotNotifier.value = null;
            selectedTreeClusterNotifier.value = null;
          });
    };
    selectedTreeNotifier.addListener(_selectedTreeListener);
    // If a tree was selected before this sheet was created (e.g., via
    // Manage Data -> Tracking), immediately run the listener so the
    // cached plot/cluster info is loaded for display.
    if (selectedTreeNotifier.value != null) {
      _selectedTreeListener();
    }

    _selectedPlotListener = () {
      final plot = selectedPlotNotifier.value;
      if (plot == null) {
        setState(() {
          _selectedPlot = null;
          _selectedCluster = null;
          _treesForSelectedPlot = [];
        });
        return;
      }

      // Fetch cluster and trees for the selected plot asynchronously.
      ClusterDao.getClusterById(plot.idCluster)
          .then((cluster) {
            if (!mounted) return;
            TreeDao.getAllTrees()
                .then((allTrees) {
                  if (!mounted) return;
                  final trees =
                      allTrees.where((t) => t.plotId == plot.id).toList();
                  setState(() {
                    _selectedPlot = plot;
                    _selectedCluster = cluster;
                    _treesForSelectedPlot = trees;
                  });
                })
                .catchError((_) {
                  if (!mounted) return;
                  setState(() {
                    _selectedPlot = plot;
                    _selectedCluster = cluster;
                    _treesForSelectedPlot = [];
                  });
                });
          })
          .catchError((_) {
            if (!mounted) return;
            setState(() {
              _selectedPlot = plot;
              _selectedCluster = null;
              _treesForSelectedPlot = [];
            });
          });
    };
    selectedPlotNotifier.addListener(_selectedPlotListener);
    if (selectedPlotNotifier.value != null) _selectedPlotListener();

    // No separate listener needed for centroid; UI reads notifier directly.

    // Check whether the DB has any data so we can show contextual help text.
    _checkDatabaseHasData();
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    isSearchFieldFocusedNotifier.removeListener(_searchFocusListener);
    selectedLocationFromSearchNotifier.removeListener(_searchCenterListener);
    bottomsheetMinimizeRequestNotifier.removeListener(_minimizeRequestListener);
    _draggableController.dispose();
    selectedTreeNotifier.removeListener(_selectedTreeListener);
    selectedPlotNotifier.removeListener(_selectedPlotListener);
    super.dispose();
  }

  Future<void> _checkDatabaseHasData() async {
    try {
      final clusters = await ClusterDao.getAllClusters();
      final plots = await PlotDao.getAllPlots();
      final trees = await TreeDao.getAllTrees();
      final has = (clusters.isNotEmpty || plots.isNotEmpty || trees.isNotEmpty);
      if (!mounted) return;
      setState(() {
        _hasAnyData = has;
      });
    } catch (_) {
      // If any error occurs, keep _hasAnyData as false.
    }
  }

  Future<void> _selectAndCenterTree(TreeModel t) async {
    if (t.latitude == null || t.longitude == null) return;
    selectedTreeNotifier.value = t;
    selectedLocationNotifier.value = null;
    await Future.delayed(const Duration(milliseconds: 60));
    isFollowingUserLocationNotifier.value = false;
    preserveZoomOnNextCenterNotifier.value = true;
    selectedLocationFromSearchNotifier.value = false;
    selectedLocationNotifier.value = Position(t.longitude!, t.latitude!);
  }

  void _goToNextTree() {
    if (_treesForSelectedPlot.isEmpty) return;
    final sorted = List<TreeModel>.from(
      _treesForSelectedPlot,
    )..sort((a, b) => a.kodePohon.toString().compareTo(b.kodePohon.toString()));
    final current = selectedTreeNotifier.value;
    int idx = 0;
    if (current != null) {
      idx = sorted.indexWhere((t) => t.id == current.id);
      if (idx < 0) idx = 0;
      idx = (idx + 1) % sorted.length;
    }
    final next = sorted[idx];
    _selectAndCenterTree(next);
  }

  void _goToPreviousTree() {
    if (_treesForSelectedPlot.isEmpty) return;
    final sorted = List<TreeModel>.from(
      _treesForSelectedPlot,
    )..sort((a, b) => a.kodePohon.toString().compareTo(b.kodePohon.toString()));
    final current = selectedTreeNotifier.value;
    int idx = 0;
    if (current != null) {
      idx = sorted.indexWhere((t) => t.id == current.id);
      if (idx < 0) idx = 0;
      idx = (idx - 1) < 0 ? sorted.length - 1 : (idx - 1);
    } else {
      idx = sorted.length - 1;
    }
    final prev = sorted[idx];
    _selectAndCenterTree(prev);
  }

  Future<void> _selectAndCenterPlot(PlotModel p) async {
    selectedPlotNotifier.value = p;
    // center flow: clear then set selectedLocation so map centers
    selectedLocationNotifier.value = null;
    await Future.delayed(const Duration(milliseconds: 60));
    isFollowingUserLocationNotifier.value = false;
    preserveZoomOnNextCenterNotifier.value = true;
    selectedLocationFromSearchNotifier.value = false;
    selectedLocationNotifier.value = Position(p.longitude, p.latitude);
  }

  Future<void> _centerToCentroid(ClusterModel cluster) async {
    try {
      final allPlots = await PlotDao.getAllPlots();
      final plotsForCluster =
          allPlots.where((p) => p.idCluster == cluster.id).toList();
      if (plotsForCluster.isEmpty) return;
      final latSum = plotsForCluster
          .map((p) => p.latitude)
          .reduce((a, b) => a + b);
      final lonSum = plotsForCluster
          .map((p) => p.longitude)
          .reduce((a, b) => a + b);
      final centroidLat = latSum / plotsForCluster.length;
      final centroidLon = lonSum / plotsForCluster.length;
      // center flow
      selectedLocationNotifier.value = null;
      await Future.delayed(const Duration(milliseconds: 60));
      isFollowingUserLocationNotifier.value = false;
      preserveZoomOnNextCenterNotifier.value = true;
      selectedLocationFromSearchNotifier.value = false;
      selectedLocationNotifier.value = Position(centroidLon, centroidLat);
    } catch (_) {}
  }

  Future<void> _goToNextPlotFromCentroid(ClusterModel cluster) async {
    try {
      final all = await PlotDao.getAllPlots();
      final sameCluster =
          all.where((pl) => pl.idCluster == cluster.id).toList()..sort(
            (a, b) => a.kodePlot.toString().compareTo(b.kodePlot.toString()),
          );
      if (sameCluster.isEmpty) return;
      // if a plot is currently selected, move to next; otherwise go to first
      final cur = selectedPlotNotifier.value;
      int idx = 0;
      if (cur != null && cur.idCluster == cluster.id) {
        idx = sameCluster.indexWhere((pl) => pl.id == cur.id);
        if (idx < 0) idx = 0;
        idx = (idx + 1) % sameCluster.length;
      }
      final next = sameCluster[idx];
      // Deselect centroid when moving to a concrete plot
      selectedCentroidNotifier.value = null;
      await _selectAndCenterPlot(next);
    } catch (_) {}
  }

  Future<void> _goToPreviousPlotFromCentroid(ClusterModel cluster) async {
    try {
      final all = await PlotDao.getAllPlots();
      final sameCluster =
          all.where((pl) => pl.idCluster == cluster.id).toList()..sort(
            (a, b) => a.kodePlot.toString().compareTo(b.kodePlot.toString()),
          );
      if (sameCluster.isEmpty) return;
      final cur = selectedPlotNotifier.value;
      int idx = 0;
      if (cur != null && cur.idCluster == cluster.id) {
        idx = sameCluster.indexWhere((pl) => pl.id == cur.id);
        if (idx < 0) idx = 0;
        idx = (idx - 1) < 0 ? sameCluster.length - 1 : (idx - 1);
      } else {
        idx = sameCluster.length - 1;
      }
      final prev = sameCluster[idx];
      // Deselect centroid when moving to a concrete plot
      selectedCentroidNotifier.value = null;
      await _selectAndCenterPlot(prev);
    } catch (_) {}
  }

  Future<void> _goToNextPlot() async {
    final cur = _selectedPlot;
    if (cur == null) return;
    try {
      final all = await PlotDao.getAllPlots();
      final sameCluster =
          all.where((pl) => pl.idCluster == cur.idCluster).toList()..sort(
            (a, b) => a.kodePlot.toString().compareTo(b.kodePlot.toString()),
          );
      if (sameCluster.isEmpty) return;
      // Determine if this cluster has a generated centroid
      final hasPlot1 = sameCluster.any((p) => p.kodePlot == 1);
      final includeCentroid = !hasPlot1 && sameCluster.length > 1;

      // Build navigation sequence: [plot1, plot2, ..., (centroid)]
      final seq = <dynamic>[];
      seq.addAll(sameCluster);
      if (includeCentroid) {
        seq.add({'centroid': true, 'clusterId': cur.idCluster});
      }

      // Find current index
      int idx = seq.indexWhere((e) => e is PlotModel && e.id == cur.id);
      if (idx < 0) idx = 0;
      final next = seq[(idx + 1) % seq.length];
      if (next is PlotModel) {
        // Clear centroid selection if any and move to plot
        selectedCentroidNotifier.value = null;
        await _selectAndCenterPlot(next);
      } else {
        // Centroid selected
        try {
          final cluster = await ClusterDao.getClusterById(cur.idCluster);
          if (cluster != null) {
            selectedPlotNotifier.value = null;
            selectedCentroidNotifier.value = cluster;
            await _centerToCentroid(cluster);
          }
        } catch (_) {}
      }
    } catch (_) {}
  }

  Future<void> _goToPreviousPlot() async {
    final cur = _selectedPlot;
    if (cur == null) return;
    try {
      final all = await PlotDao.getAllPlots();
      final sameCluster =
          all.where((pl) => pl.idCluster == cur.idCluster).toList()..sort(
            (a, b) => a.kodePlot.toString().compareTo(b.kodePlot.toString()),
          );
      if (sameCluster.isEmpty) return;
      // Determine if this cluster has a generated centroid
      final hasPlot1 = sameCluster.any((p) => p.kodePlot == 1);
      final includeCentroid = !hasPlot1 && sameCluster.length > 1;

      final seq = <dynamic>[];
      seq.addAll(sameCluster);
      if (includeCentroid) {
        seq.add({'centroid': true, 'clusterId': cur.idCluster});
      }

      int idx = seq.indexWhere((e) => e is PlotModel && e.id == cur.id);
      if (idx < 0) idx = 0;
      final prev = seq[(idx - 1) < 0 ? (seq.length - 1) : (idx - 1)];
      if (prev is PlotModel) {
        selectedCentroidNotifier.value = null;
        await _selectAndCenterPlot(prev);
      } else {
        try {
          final cluster = await ClusterDao.getClusterById(cur.idCluster);
          if (cluster != null) {
            selectedPlotNotifier.value = null;
            selectedCentroidNotifier.value = cluster;
            await _centerToCentroid(cluster);
          }
        } catch (_) {}
      }
    } catch (_) {}
  }

  TableRow _row(String label, String value) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2, right: 4),
          child: Text(label),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(": $value"),
        ),
      ],
    );
  }

  Future<bool> _ensureUserLocationStreamStarted(BuildContext context) async {
    if (_positionSub != null) return true;

    final enabled = await geo.Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      if (!context.mounted) return false;
      await showDialog(
        context: context,
        builder:
            (_) => const AlertDialog(
              title: Text('Lokasi tidak aktif'),
              content: Text('Aktifkan layanan lokasi (GPS) untuk melanjutkan.'),
            ),
      );
      return false;
    }

    var permission = await geo.Geolocator.checkPermission();
    if (permission == geo.LocationPermission.denied) {
      permission = await geo.Geolocator.requestPermission();
      if (permission == geo.LocationPermission.denied) return false;
    }

    if (permission == geo.LocationPermission.deniedForever) {
      if (!context.mounted) return false;
      await showDialog(
        context: context,
        builder:
            (_) => const AlertDialog(
              title: Text('Izin lokasi ditolak'),
              content: Text(
                'Perbolehkan akses lokasi pada pengaturan aplikasi.',
              ),
            ),
      );
      return false;
    }

    _positionSub = geo.Geolocator.getPositionStream(
      locationSettings: const geo.LocationSettings(
        accuracy: geo.LocationAccuracy.best,
        distanceFilter: 5,
      ),
    ).listen((pos) {
      try {
        userLocationNotifier.value = Position(pos.longitude, pos.latitude);
      } catch (_) {}
    });

    return true;
  }

  void _centerToMyLocation(BuildContext context) async {
    final ok = await _ensureUserLocationStreamStarted(context);
    if (!ok) return;
    isFollowingUserLocationNotifier.value = true;
    final pos = userLocationNotifier.value;
    if (pos != null) {
      selectedLocationFromSearchNotifier.value = false;
      selectedLocationNotifier.value = pos;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      controller: _draggableController,
      initialChildSize: _minChildSize,
      minChildSize: _minChildSize,
      maxChildSize: _maxChildSize,
      builder: (context, scrollController) {
        return ValueListenableBuilder<bool>(
          valueListenable: isLightModeNotifier,
          builder: (context, isLightMode, child) {
            final isDark = !isLightMode;
            return Container(
              decoration: BoxDecoration(
                color:
                    isDark
                        ? const Color.fromARGB(255, 34, 66, 40)
                        : const Color.fromARGB(255, 205, 237, 211),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 8),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: ValueListenableBuilder<bool>(
                  valueListenable: isLightModeNotifier,
                  builder: (context, isLightMode, _) {
                    final isDark = !isLightMode;
                    return DefaultTextStyle(
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      child: ListView(
                        controller: scrollController,
                        children: [
                          const SearchbarBottomsheetWidget(),
                          const SizedBox(height: 8),

                          ValueListenableBuilder<int>(
                            valueListenable: selectedMenuBottomSheetNotifier,
                            builder: (context, selectedMenuBottomSheet, child) {
                              return ValueListenableBuilder(
                                valueListenable: isLightModeNotifier,
                                builder: (context, isLightMode, _) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          isLightMode
                                              ? const Color.fromARGB(
                                                255,
                                                205,
                                                237,
                                                211,
                                              )
                                              : const Color.fromARGB(
                                                255,
                                                34,
                                                66,
                                                40,
                                              ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: ValueListenableBuilder<bool>(
                                            valueListenable:
                                                isLightModeNotifier,
                                            builder: (context, isLightMode, _) {
                                              final isDark = !isLightMode;
                                              return NavigationBarTheme(
                                                data: NavigationBarThemeData(
                                                  indicatorColor:
                                                      isDark
                                                          ? const Color.fromARGB(
                                                            255,
                                                            23,
                                                            110,
                                                            38,
                                                          )
                                                          : const Color.fromARGB(
                                                            255,
                                                            195,
                                                            208,
                                                            197,
                                                          ),
                                                  backgroundColor:
                                                      Colors.transparent,
                                                  elevation: 0,
                                                  labelTextStyle:
                                                      WidgetStateProperty.resolveWith(
                                                        (states) => TextStyle(
                                                          color:
                                                              isDark
                                                                  ? Colors.white
                                                                  : Colors
                                                                      .black87,
                                                        ),
                                                      ),
                                                ),
                                                child: NavigationBar(
                                                  backgroundColor:
                                                      Colors.transparent,
                                                  elevation: 0,
                                                  selectedIndex:
                                                      selectedMenuBottomSheet,
                                                  onDestinationSelected: (
                                                    value,
                                                  ) {
                                                    selectedMenuBottomSheetNotifier
                                                        .value = value;
                                                  },
                                                  destinations: [
                                                    NavigationDestination(
                                                      icon: Icon(
                                                        Icons.satellite,
                                                        color:
                                                            isDark
                                                                ? Colors.white
                                                                : Colors
                                                                    .black87,
                                                      ),
                                                      selectedIcon: Icon(
                                                        Icons.satellite,
                                                        color:
                                                            isDark
                                                                ? Colors.white
                                                                : Colors
                                                                    .black87,
                                                      ),
                                                      label: 'Satelit',
                                                    ),
                                                    NavigationDestination(
                                                      icon: Icon(
                                                        Icons.map_outlined,
                                                        color:
                                                            isDark
                                                                ? Colors.white
                                                                : Colors
                                                                    .black87,
                                                      ),
                                                      selectedIcon: Icon(
                                                        Icons.map,
                                                        color:
                                                            isDark
                                                                ? Colors.white
                                                                : Colors
                                                                    .black87,
                                                      ),
                                                      label: 'Medan',
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        ValueListenableBuilder<bool>(
                                          valueListenable: isLightModeNotifier,
                                          builder: (context, isLightMode, _) {
                                            final isDark = !isLightMode;
                                            return Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                IconButton(
                                                  onPressed:
                                                      () => _centerToMyLocation(
                                                        context,
                                                      ),
                                                  icon: ValueListenableBuilder<
                                                    dynamic
                                                  >(
                                                    valueListenable:
                                                        userLocationNotifier,
                                                    builder: (
                                                      context,
                                                      pos,
                                                      child,
                                                    ) {
                                                      return Icon(
                                                        pos == null
                                                            ? Icons
                                                                .location_on_outlined
                                                            : Icons.location_on,
                                                        color:
                                                            isDark
                                                                ? Colors.white
                                                                : null,
                                                      );
                                                    },
                                                  ),
                                                  style: ButtonStyle(
                                                    foregroundColor:
                                                        WidgetStateProperty.resolveWith(
                                                          (states) =>
                                                              states.contains(
                                                                    WidgetState
                                                                        .pressed,
                                                                  )
                                                                  ? Colors
                                                                      .lightGreen
                                                                      .shade200
                                                                  : null,
                                                        ),
                                                    overlayColor: WidgetStateProperty.resolveWith(
                                                      (states) =>
                                                          states.contains(
                                                                WidgetState
                                                                    .pressed,
                                                              )
                                                              ? Colors
                                                                  .lightGreen
                                                                  .shade100
                                                                  .withAlpha(
                                                                    (0.4 * 255)
                                                                        .round(),
                                                                  )
                                                              : null,
                                                    ),
                                                  ),
                                                ),
                                                IconButton(
                                                  onPressed: () {
                                                    northResetRequestNotifier
                                                            .value =
                                                        northResetRequestNotifier
                                                            .value +
                                                        1;
                                                  },
                                                  icon: Transform.rotate(
                                                    angle: -45 * math.pi / 180,
                                                    child: Icon(
                                                      Icons.explore_outlined,
                                                      color:
                                                          isDark
                                                              ? Colors.white
                                                              : null,
                                                    ),
                                                  ),
                                                  style: ButtonStyle(
                                                    foregroundColor:
                                                        WidgetStateProperty.resolveWith(
                                                          (states) =>
                                                              states.contains(
                                                                    WidgetState
                                                                        .pressed,
                                                                  )
                                                                  ? const Color.fromARGB(
                                                                    255,
                                                                    197,
                                                                    225,
                                                                    165,
                                                                  )
                                                                  : null,
                                                        ),
                                                    overlayColor: WidgetStateProperty.resolveWith(
                                                      (states) =>
                                                          states.contains(
                                                                WidgetState
                                                                    .pressed,
                                                              )
                                                              ? Colors
                                                                  .lightGreen
                                                                  .shade100
                                                                  .withAlpha(
                                                                    (0.4 * 255)
                                                                        .round(),
                                                                  )
                                                              : null,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                          ),

                          const SizedBox(height: 8),
                          const Divider(),
                          const SizedBox(height: 8),

                          ValueListenableBuilder<TreeModel?>(
                            valueListenable: selectedTreeNotifier,
                            builder: (context, tree, child) {
                              // If a tree is selected, show tree detail UI (existing behavior).
                              if (tree == null) {
                                // If no tree selected but a plot is selected, show plot summary
                                if (_selectedPlot != null) {
                                  final plot = _selectedPlot!;
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Plot ${plot.kodePlot}',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          ValueListenableBuilder<bool>(
                                            valueListenable:
                                                isLightModeNotifier,
                                            builder: (context, isLightMode, _) {
                                              final isDark = !isLightMode;
                                              return Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  IconButton(
                                                    tooltip: 'Plot sebelumnya',
                                                    onPressed: () async {
                                                      await _goToPreviousPlot();
                                                    },
                                                    icon: Icon(
                                                      Icons.arrow_back,
                                                      color:
                                                          isDark
                                                              ? Colors.white
                                                              : null,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  IconButton(
                                                    tooltip: 'Center on plot',
                                                    onPressed: () async {
                                                      isFollowingUserLocationNotifier
                                                          .value = false;
                                                      selectedLocationNotifier
                                                          .value = null;
                                                      await Future.delayed(
                                                        const Duration(
                                                          milliseconds: 60,
                                                        ),
                                                      );
                                                      preserveZoomOnNextCenterNotifier
                                                          .value = true;
                                                      selectedLocationFromSearchNotifier
                                                          .value = false;
                                                      selectedLocationNotifier
                                                          .value = Position(
                                                        plot.longitude,
                                                        plot.latitude,
                                                      );
                                                      // center applied; no snackbar
                                                    },
                                                    icon: Icon(
                                                      Icons
                                                          .my_location_outlined,
                                                      color:
                                                          isDark
                                                              ? Colors.white
                                                              : null,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  IconButton(
                                                    tooltip: 'Plot berikutnya',
                                                    onPressed: () async {
                                                      await _goToNextPlot();
                                                    },
                                                    icon: Icon(
                                                      Icons.arrow_forward,
                                                      color:
                                                          isDark
                                                              ? Colors.white
                                                              : null,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  IconButton(
                                                    onPressed: () {
                                                      selectedPlotNotifier
                                                          .value = null;
                                                    },
                                                    icon: Icon(
                                                      Icons.close,
                                                      color:
                                                          isDark
                                                              ? Colors.white
                                                              : null,
                                                    ),
                                                  ),
                                                ],
                                              );
                                            },
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 8),

                                      // Plot and Cluster summary
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 8.0,
                                        ),
                                        child: Row(
                                          children: [
                                            Text(
                                              'Klaster: ${_selectedCluster?.kodeCluster ?? '-'}',
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              'Plot: ${_selectedPlot?.kodePlot ?? '-'}',
                                            ),
                                          ],
                                        ),
                                      ),

                                      const SizedBox(height: 8),

                                      ValueListenableBuilder<bool>(
                                        valueListenable: isLightModeNotifier,
                                        builder: (context, isLightMode, _) {
                                          final isDark = !isLightMode;
                                          return Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Pohon dalam plot ini:',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color:
                                                      isDark
                                                          ? Colors.white
                                                          : null,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              if (_treesForSelectedPlot.isEmpty)
                                                Text(
                                                  'Tidak ada pohon di plot ini',
                                                  style: TextStyle(
                                                    color:
                                                        isDark
                                                            ? Colors.white
                                                            : null,
                                                  ),
                                                )
                                              else
                                                Column(
                                                  children:
                                                      _treesForSelectedPlot.map((
                                                        t,
                                                      ) {
                                                        final title =
                                                            (t.namaPohon
                                                                        ?.trim()
                                                                        .isNotEmpty ??
                                                                    false)
                                                                ? (t.namaPohon ??
                                                                    'Pohon')
                                                                : (t.namaIlmiah
                                                                        ?.trim()
                                                                        .isNotEmpty ??
                                                                    false)
                                                                ? t.namaIlmiah!
                                                                : 'Pohon ${t.kodePohon}';

                                                        return ListTile(
                                                          contentPadding:
                                                              EdgeInsets.zero,
                                                          title: Text(
                                                            title,
                                                            style: TextStyle(
                                                              color:
                                                                  isDark
                                                                      ? Colors
                                                                          .white
                                                                      : null,
                                                            ),
                                                          ),
                                                          subtitle: Text(
                                                            'Kode: ${t.kodePohon}',
                                                            style: TextStyle(
                                                              color:
                                                                  isDark
                                                                      ? Colors
                                                                          .white70
                                                                      : null,
                                                            ),
                                                          ),
                                                          trailing: ValueListenableBuilder<
                                                            bool
                                                          >(
                                                            valueListenable:
                                                                isLightModeNotifier,
                                                            builder: (
                                                              context,
                                                              isLightMode2,
                                                              _,
                                                            ) {
                                                              final isDark2 =
                                                                  !isLightMode2;
                                                              return IconButton(
                                                                tooltip:
                                                                    'Center to this tree',
                                                                icon: Icon(
                                                                  Icons
                                                                      .my_location,
                                                                  color:
                                                                      isDark2
                                                                          ? Colors
                                                                              .white
                                                                          : null,
                                                                ),
                                                                onPressed:
                                                                    (t.latitude !=
                                                                                null &&
                                                                            t.longitude !=
                                                                                null)
                                                                        ? () async {
                                                                          // Select the tree and center
                                                                          selectedTreeNotifier.value =
                                                                              t;
                                                                          await Future.delayed(
                                                                            const Duration(
                                                                              milliseconds:
                                                                                  40,
                                                                            ),
                                                                          );
                                                                          isFollowingUserLocationNotifier.value =
                                                                              false;
                                                                          preserveZoomOnNextCenterNotifier.value =
                                                                              true;
                                                                          selectedLocationFromSearchNotifier.value =
                                                                              false;
                                                                          selectedLocationNotifier
                                                                              .value = Position(
                                                                            t.longitude!,
                                                                            t.latitude!,
                                                                          );
                                                                        }
                                                                        : null,
                                                              );
                                                            },
                                                          ),
                                                          onTap: () {
                                                            // Show tree details in bottomsheet
                                                            selectedTreeNotifier
                                                                .value = t;
                                                          },
                                                        );
                                                      }).toList(),
                                                ),
                                            ],
                                          );
                                        },
                                      ),
                                    ],
                                  );
                                }

                                // If no plot selected but a centroid is selected, show centroid UI
                                return ValueListenableBuilder<ClusterModel?>(
                                  valueListenable: selectedCentroidNotifier,
                                  builder: (context, cluster, child) {
                                    if (cluster != null) {
                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              const Text(
                                                'Centroid',
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  ValueListenableBuilder<bool>(
                                                    valueListenable:
                                                        isLightModeNotifier,
                                                    builder: (
                                                      context,
                                                      isLightMode,
                                                      _,
                                                    ) {
                                                      final isDark =
                                                          !isLightMode;
                                                      return Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          IconButton(
                                                            tooltip:
                                                                'Plot sebelumnya',
                                                            onPressed: () async {
                                                              await _goToPreviousPlotFromCentroid(
                                                                cluster,
                                                              );
                                                            },
                                                            icon: Icon(
                                                              Icons.arrow_back,
                                                              color:
                                                                  isDark
                                                                      ? Colors
                                                                          .white
                                                                      : null,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            width: 8,
                                                          ),
                                                          IconButton(
                                                            tooltip:
                                                                'Center on centroid',
                                                            onPressed: () async {
                                                              await _centerToCentroid(
                                                                cluster,
                                                              );
                                                            },
                                                            icon: Icon(
                                                              Icons
                                                                  .my_location_outlined,
                                                              color:
                                                                  isDark
                                                                      ? Colors
                                                                          .white
                                                                      : null,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            width: 8,
                                                          ),
                                                          IconButton(
                                                            tooltip:
                                                                'Plot berikutnya',
                                                            onPressed: () async {
                                                              await _goToNextPlotFromCentroid(
                                                                cluster,
                                                              );
                                                            },
                                                            icon: Icon(
                                                              Icons
                                                                  .arrow_forward,
                                                              color:
                                                                  isDark
                                                                      ? Colors
                                                                          .white
                                                                      : null,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            width: 8,
                                                          ),
                                                          IconButton(
                                                            onPressed: () {
                                                              selectedCentroidNotifier
                                                                  .value = null;
                                                            },
                                                            icon: Icon(
                                                              Icons.close,
                                                              color:
                                                                  isDark
                                                                      ? Colors
                                                                          .white
                                                                      : null,
                                                            ),
                                                          ),
                                                        ],
                                                      );
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 8.0,
                                            ),
                                            child: Row(
                                              children: [
                                                Text(
                                                  'Klaster: ${cluster.kodeCluster}',
                                                ),
                                                const SizedBox(width: 12),
                                                const Text('Centroid'),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          const Text(
                                            'Centroid ini dihasilkan dari plot di klaster ini.',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                        ],
                                      );
                                    }
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      child: Text(
                                        _hasAnyData
                                            ? 'Pilih marker di peta untuk menampilkan informasi.'
                                            : 'Kamu tidak memiliki data, silahkan tambah data terlebih dahulu.',
                                      ),
                                    );
                                  },
                                );
                              }

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        tree.namaPohon ?? 'Pohon',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      ValueListenableBuilder<bool>(
                                        valueListenable: isLightModeNotifier,
                                        builder: (context, isLightMode, _) {
                                          final isDark = !isLightMode;
                                          return Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                tooltip: 'Pohon sebelumnya',
                                                onPressed: _goToPreviousTree,
                                                icon: Icon(
                                                  Icons.arrow_back,
                                                  color:
                                                      isDark
                                                          ? Colors.white
                                                          : null,
                                                ),
                                              ),
                                              IconButton(
                                                tooltip: 'Center on tree',
                                                onPressed:
                                                    (tree.latitude != null &&
                                                            tree.longitude !=
                                                                null)
                                                        ? () async {
                                                          isFollowingUserLocationNotifier
                                                              .value = false;
                                                          selectedLocationNotifier
                                                              .value = null;
                                                          await Future.delayed(
                                                            const Duration(
                                                              milliseconds: 60,
                                                            ),
                                                          );
                                                          preserveZoomOnNextCenterNotifier
                                                              .value = true;
                                                          selectedLocationFromSearchNotifier
                                                              .value = false;
                                                          selectedLocationNotifier
                                                              .value = Position(
                                                            tree.longitude!,
                                                            tree.latitude!,
                                                          );
                                                          // center applied; no snackbar
                                                        }
                                                        : null,
                                                icon: Icon(
                                                  Icons.my_location_outlined,
                                                  color:
                                                      isDark
                                                          ? Colors.white
                                                          : null,
                                                ),
                                              ),
                                              IconButton(
                                                tooltip: 'Pohon berikutnya',
                                                onPressed: _goToNextTree,
                                                icon: Icon(
                                                  Icons.arrow_forward,
                                                  color:
                                                      isDark
                                                          ? Colors.white
                                                          : null,
                                                ),
                                              ),
                                              IconButton(
                                                onPressed: () {
                                                  selectedTreeNotifier.value =
                                                      null;
                                                },
                                                icon: Icon(
                                                  Icons.close,
                                                  color:
                                                      isDark
                                                          ? Colors.white
                                                          : null,
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 8),

                                  // Plot and Cluster summary (loaded asynchronously in initState listener)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: Row(
                                      children: [
                                        Text(
                                          'Klaster: ${_selectedCluster?.kodeCluster ?? '-'}',
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          'Plot: ${_selectedPlot?.kodePlot ?? '-'}',
                                        ),
                                      ],
                                    ),
                                  ),

                                  if (tree.urlFoto != null)
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder:
                                                (_) => _TreePhotoPreviewPage(
                                                  imageUrl:
                                                      GDriveThumbnailService.toThumbnailUrl(
                                                        tree.urlFoto!,
                                                      ),
                                                  heroTag:
                                                      'tree-photo-${tree.id ?? DateTime.now().millisecondsSinceEpoch}',
                                                ),
                                          ),
                                        );
                                      },
                                      child: Hero(
                                        tag:
                                            'tree-photo-${tree.id ?? DateTime.now().millisecondsSinceEpoch}',
                                        child: SizedBox(
                                          height: 160,
                                          width: double.infinity,
                                          child: Builder(
                                            builder: (ctx) {
                                              final url = tree.urlFoto!;
                                              final resolved =
                                                  GDriveThumbnailService.toThumbnailUrl(
                                                    url,
                                                  );
                                              return CachedNetworkImage(
                                                imageUrl: resolved,
                                                fit: BoxFit.cover,
                                                placeholder:
                                                    (
                                                      context,
                                                      _,
                                                    ) => const Center(
                                                      child: SizedBox(
                                                        width: 28,
                                                        height: 28,
                                                        child:
                                                            CircularProgressIndicator(
                                                              strokeWidth: 2.5,
                                                            ),
                                                      ),
                                                    ),
                                                errorWidget:
                                                    (context, _, __) =>
                                                        const Center(
                                                          child: Icon(
                                                            Icons.broken_image,
                                                            color: Colors.grey,
                                                          ),
                                                        ),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                    ),

                                  const SizedBox(height: 8),
                                  Table(
                                    columnWidths: const {
                                      0: IntrinsicColumnWidth(),
                                      1: FlexColumnWidth(),
                                    },
                                    defaultVerticalAlignment:
                                        TableCellVerticalAlignment.top,
                                    children: [
                                      _row('Ilmiah', tree.namaIlmiah ?? '-'),
                                      _row(
                                        'Azimut',
                                        tree.azimut?.toStringAsFixed(1) ?? '-',
                                      ),
                                      _row(
                                        'Jarak (m)',
                                        tree.jarakPusatM?.toStringAsFixed(2) ??
                                            '-',
                                      ),
                                      _row(
                                        'Latitude',
                                        tree.latitude?.toStringAsFixed(6) ??
                                            '-',
                                      ),
                                      _row(
                                        'Longitude',
                                        tree.longitude?.toStringAsFixed(6) ??
                                            '-',
                                      ),
                                      if (tree.keterangan != null)
                                        TableRow(
                                          children: [
                                            const Padding(
                                              padding: EdgeInsets.only(
                                                top: 2,
                                                right: 4,
                                              ),
                                              child: Text('Keterangan'),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                top: 2,
                                              ),
                                              child: Text(tree.keterangan!),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  // Mark/Done button for inspection workflow (bottomsheet)
                                  Row(
                                    children: [
                                      const Spacer(),
                                      ValueListenableBuilder<bool>(
                                        valueListenable:
                                            isInspectionWorkflowEnabledNotifier,
                                        builder: (
                                          context,
                                          workflowEnabled,
                                          child,
                                        ) {
                                          if (!workflowEnabled) {
                                            return const SizedBox.shrink();
                                          }
                                          return ValueListenableBuilder<
                                            Set<int>
                                          >(
                                            valueListenable:
                                                inspectedTreeIdsNotifier,
                                            builder: (
                                              context,
                                              inspectedSet,
                                              child,
                                            ) {
                                              final inspected =
                                                  (tree.id != null &&
                                                      inspectedSet.contains(
                                                        tree.id,
                                                      ));
                                              return ConstrainedBox(
                                                constraints:
                                                    const BoxConstraints(
                                                      minWidth: 72,
                                                    ),
                                                child: ElevatedButton.icon(
                                                  style: ElevatedButton.styleFrom(
                                                    elevation: 0,
                                                    backgroundColor:
                                                        inspected
                                                            ? Colors.green
                                                            : Colors.orange,
                                                    foregroundColor:
                                                        const Color(0xFF1F4226),
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 8,
                                                        ),
                                                  ),
                                                  onPressed: () async {
                                                    final setCopy =
                                                        Set<int>.from(
                                                          inspectedSet,
                                                        );
                                                    if (inspected) {
                                                      setCopy.remove(tree.id);
                                                    } else {
                                                      if (tree.id != null) {
                                                        setCopy.add(tree.id!);
                                                      }
                                                    }
                                                    inspectedTreeIdsNotifier
                                                        .value = setCopy;
                                                    try {
                                                      if (tree.id != null) {
                                                        await TreeDao.setInspectedForTree(
                                                          tree.id!,
                                                          setCopy.contains(
                                                            tree.id,
                                                          ),
                                                        );
                                                      }
                                                    } catch (_) {}
                                                  },
                                                  icon: Icon(
                                                    inspected
                                                        ? Icons.check
                                                        : Icons.checklist,
                                                    size: 16,
                                                  ),
                                                  label: FittedBox(
                                                    fit: BoxFit.scaleDown,
                                                    child: Text(
                                                      inspected
                                                          ? 'Done'
                                                          : 'Mark',
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _TreePhotoPreviewPage extends StatelessWidget {
  final String imageUrl;
  final String heroTag;

  const _TreePhotoPreviewPage({required this.imageUrl, required this.heroTag});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => Navigator.of(context).pop(),
          child: Center(
            child: InteractiveViewer(
              minScale: 1.0,
              maxScale: 5.0,
              child: Hero(
                tag: heroTag,
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.contain,
                  placeholder:
                      (context, _) => const Center(
                        child: SizedBox(
                          width: 36,
                          height: 36,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        ),
                      ),
                  errorWidget:
                      (context, _, __) => const Icon(
                        Icons.broken_image,
                        color: Color.fromARGB(255, 205, 237, 211),
                        size: 48,
                      ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
