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
        _mapboxMap!.loadStyleURI(style);
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
            _mapboxMap!.loadStyleURI(style);
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
}
