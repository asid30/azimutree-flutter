import 'package:azimutree/data/notifiers/notifiers.dart';
import 'package:azimutree/views/widgets/location_map_widget/searchbar_bottomsheet_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:azimutree/data/models/tree_model.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:async';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class BottomsheetLocationMapWidget extends StatefulWidget {
  const BottomsheetLocationMapWidget({super.key});

  @override
  State<BottomsheetLocationMapWidget> createState() =>
      _BottomsheetLocationMapWidgetState();
}

class _BottomsheetLocationMapWidgetState
    extends State<BottomsheetLocationMapWidget> {
  StreamSubscription<geo.Position>? _positionSub;
  final double _maxChildSize = 0.7;
  final double _minChildSize = 0.25;
  final DraggableScrollableController _draggableController =
      DraggableScrollableController();

  @override
  void dispose() {
    _positionSub?.cancel();
    _draggableController.dispose();
    super.dispose();
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
    }

    if (permission == geo.LocationPermission.denied ||
        permission == geo.LocationPermission.deniedForever) {
      if (!context.mounted) return false;
      await showDialog(
        context: context,
        builder:
            (_) => const AlertDialog(
              title: Text('Izin lokasi ditolak'),
              content: Text(
                'Berikan izin lokasi agar aplikasi bisa menampilkan posisi kamu.',
              ),
            ),
      );
      return false;
    }

    // Start live stream (always on after permission granted).
    isFollowingUserLocationNotifier.value = true;

    // Emit one immediate position so we have a value right away.
    final current = await geo.Geolocator.getCurrentPosition(
      desiredAccuracy: geo.LocationAccuracy.high,
    );
    userLocationNotifier.value = Position(current.longitude, current.latitude);

    _positionSub = geo.Geolocator.getPositionStream(
      locationSettings: const geo.LocationSettings(
        accuracy: geo.LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((p) {
      userLocationNotifier.value = Position(p.longitude, p.latitude);
    });

    return true;
  }

  Future<void> _centerToMyLocation(BuildContext context) async {
    final ok = await _ensureUserLocationStreamStarted(context);
    if (!ok) return;

    // Center map camera to the latest known user location.
    final pos = userLocationNotifier.value;
    if (pos == null) return;
    selectedLocationNotifier.value = pos;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      controller: _draggableController,
      initialChildSize: _minChildSize,
      minChildSize: _minChildSize,
      maxChildSize: _maxChildSize,
      builder: (context, scrollController) {
        // Disable bottom SafeArea so the draggable sheet can reach the
        // physical bottom edge (no gap above system navigation bar).
        // Keep top safe area so content doesn't clash with notches/status bar
        // when the sheet is expanded.
        return SafeArea(
          bottom: false,
          child: Material(
            color: Colors.transparent,
            child: Container(
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 205, 237, 211),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: ValueListenableBuilder<bool>(
                valueListenable: isSearchFieldFocusedNotifier,
                builder: (context, focused, child) {
                  // When the search field gains focus, animate the sheet so it
                  // rises above the keyboard. We compute a target extent based
                  // on current keyboard inset.
                  // When search field focused, expand sheet to a fixed extent
                  // (0.4). When unfocused, collapse back to minimal size (0.25).
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    final double target = focused ? 0.4 : _minChildSize;
                    final t = target.clamp(_minChildSize, _maxChildSize);
                    try {
                      _draggableController.animateTo(
                        t,
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOut,
                      );
                    } catch (_) {}
                  });

                  return ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    children: [
                      Center(
                        child: Container(
                          width: 48,
                          height: 6,
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade400,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                      ValueListenableBuilder<TreeModel?>(
                        valueListenable: selectedTreeNotifier,
                        builder: (context, tree, child) {
                          if (tree == null) {
                            return const SearchbarBottomsheetWidget();
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
                                  IconButton(
                                    onPressed: () {
                                      selectedTreeNotifier.value = null;
                                    },
                                    icon: const Icon(Icons.close),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              if (tree.urlFoto != null)
                                GestureDetector(
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder:
                                            (_) => _TreePhotoPreviewPage(
                                              imageUrl: tree.urlFoto!,
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
                                      child: CachedNetworkImage(
                                        imageUrl: tree.urlFoto!,
                                        fit: BoxFit.cover,
                                        placeholder:
                                            (context, _) => const Center(
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
                                            (context, _, __) => const Center(
                                              child: Icon(
                                                Icons.broken_image,
                                                color: Colors.grey,
                                              ),
                                            ),
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
                                    tree.jarakPusatM?.toStringAsFixed(2) ?? '-',
                                  ),
                                  _row(
                                    'Koordinat',
                                    '${tree.longitude ?? '-'}, ${tree.latitude ?? '-'}',
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
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      ValueListenableBuilder(
                        valueListenable: selectedMenuBottomSheetNotifier,
                        builder: (context, selectedMenuBottomSheet, child) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 205, 237, 211),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: NavigationBar(
                                    backgroundColor: Colors.transparent,
                                    elevation: 0,
                                    selectedIndex: selectedMenuBottomSheet,
                                    onDestinationSelected: (value) {
                                      selectedMenuBottomSheetNotifier.value =
                                          value;
                                    },
                                    destinations: const [
                                      NavigationDestination(
                                        icon: Icon(Icons.map_outlined),
                                        selectedIcon: Icon(Icons.map),
                                        label: 'Medan',
                                      ),
                                      NavigationDestination(
                                        icon: Icon(Icons.terrain_outlined),
                                        selectedIcon: Icon(Icons.terrain),
                                        label: 'Satelit',
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      onPressed:
                                          () => _centerToMyLocation(context),
                                      icon: const Icon(Icons.my_location),
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        northResetRequestNotifier.value =
                                            northResetRequestNotifier.value + 1;
                                      },
                                      icon: Transform.rotate(
                                        angle: -45 * math.pi / 180,
                                        child: const Icon(
                                          Icons.explore_outlined,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ); // end ListView
                }, // end ValueListenableBuilder.builder
              ), // end ValueListenableBuilder
            ),
          ),
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
