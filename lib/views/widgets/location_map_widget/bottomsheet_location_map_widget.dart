import 'package:azimutree/data/notifiers/notifiers.dart';
import 'package:azimutree/views/widgets/location_map_widget/searchbar_bottomsheet_widget.dart';
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

  final double _maxChildSize = 0.32;
  final double _minChildSize = 0.10;

  @override
  void dispose() {
    _positionSub?.cancel();
    super.dispose();
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
      initialChildSize: _minChildSize,
      minChildSize: _minChildSize,
      maxChildSize: _maxChildSize,
      builder: (context, scrollController) {
        return SafeArea(
          child: Material(
            color: Colors.transparent,
            child: Container(
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 205, 237, 211),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: ListView(
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
                  SearchbarBottomsheetWidget(),
                  const SizedBox(height: 8),
                  ValueListenableBuilder(
                    valueListenable: selectedMenuBottomSheetNotifier,
                    builder: (context, selectedMenuBottomSheet, child) {
                      return NavigationBar(
                        selectedIndex: selectedMenuBottomSheet,
                        onDestinationSelected: (value) {
                          selectedMenuBottomSheetNotifier.value = value;
                        },
                        destinations: [
                          const NavigationDestination(
                            icon: Icon(Icons.map_outlined),
                            selectedIcon: Icon(Icons.map),
                            label: 'Medan',
                          ),
                          const NavigationDestination(
                            icon: Icon(Icons.terrain_outlined),
                            selectedIcon: Icon(Icons.terrain),
                            label: 'Satelit',
                          ),
                          Row(
                            children: [
                              IconButton(
                                onPressed: () => _centerToMyLocation(context),
                                icon: const Icon(Icons.my_location),
                              ),
                              IconButton(
                                onPressed: () {
                                  // Request the map to reset bearing to north.
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
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
