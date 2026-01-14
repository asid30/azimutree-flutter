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
  final double _maxChildSize = 0.8;
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
      // mapbox Position expects (longitude, latitude) as positional args
      try {
        userLocationNotifier.value = Position(pos.longitude, pos.latitude);
      } catch (_) {
        // ignore if Position cannot be created; map widget may handle null
      }
    });

    return true;
  }

  void _centerToMyLocation(BuildContext context) async {
    final ok = await _ensureUserLocationStreamStarted(context);
    if (!ok) return;
    isFollowingUserLocationNotifier.value = true;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      controller: _draggableController,
      initialChildSize: _minChildSize,
      minChildSize: _minChildSize,
      maxChildSize: _maxChildSize,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).canvasColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: ListView(
              controller: scrollController,
              children: [
                const SearchbarBottomsheetWidget(),
                const SizedBox(height: 8),

                ValueListenableBuilder<int>(
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
                                selectedMenuBottomSheetNotifier.value = value;
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
                                onPressed: () => _centerToMyLocation(context),
                                icon: const Icon(Icons.my_location),
                              ),
                              IconButton(
                                onPressed: () {
                                  northResetRequestNotifier.value =
                                      northResetRequestNotifier.value + 1;
                                },
                                icon: Transform.rotate(
                                  angle: -45 * math.pi / 180,
                                  child: const Icon(Icons.explore_outlined),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 8),

                ValueListenableBuilder<TreeModel?>(
                  valueListenable: selectedTreeNotifier,
                  builder: (context, tree, child) {
                    if (tree == null) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          'Tap a tree marker on the map to see details.',
                        ),
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header and controls for the selected tree are shown
                        // above the photo and details.
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              tree.namaPohon ?? 'Pohon',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Center camera to this tree's location
                                IconButton(
                                  tooltip: 'Center on tree',
                                  onPressed:
                                      (tree.latitude != null &&
                                              tree.longitude != null)
                                          ? () async {
                                            // Ensure we are not following the live user location
                                            isFollowingUserLocationNotifier
                                                .value = false;
                                            // Force a change of the selected location notifier
                                            // by briefly clearing it first, this avoids a
                                            // no-op if the same Position is already set.
                                            selectedLocationNotifier.value =
                                                null;
                                            // Small delay to ensure listeners receive the null
                                            // then the new position update.
                                            await Future.delayed(
                                              const Duration(milliseconds: 60),
                                            );
                                            selectedLocationNotifier
                                                .value = Position(
                                              tree.longitude!,
                                              tree.latitude!,
                                            );
                                            // Give quick visual feedback so user knows action ran.
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Centering map on tree...',
                                                  ),
                                                ),
                                              );
                                            }
                                          }
                                          : null,
                                  icon: const Icon(Icons.my_location_outlined),
                                ),
                                IconButton(
                                  onPressed: () {
                                    selectedTreeNotifier.value = null;
                                  },
                                  icon: const Icon(Icons.close),
                                ),
                              ],
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
                                          child: CircularProgressIndicator(
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
                              'Latitude',
                              tree.latitude?.toStringAsFixed(6) ?? '-',
                            ),
                            _row(
                              'Longitude',
                              tree.longitude?.toStringAsFixed(6) ?? '-',
                            ),
                            if (tree.keterangan != null)
                              TableRow(
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.only(top: 2, right: 4),
                                    child: Text('Keterangan'),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(tree.keterangan!),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        // header moved above
                      ],
                    );
                  },
                ),
              ],
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
