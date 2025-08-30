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

  @override
  void initState() {
    super.initState();
    selectedMenuBottomSheetNotifier.addListener(() {
      if (_mapboxMap != null) {
        final style =
            selectedMenuBottomSheetNotifier.value == 0
                ? widget.standardStyleUri
                : widget.sateliteStyleUri;
        _mapboxMap!.loadStyleURI(style);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: selectedMenuBottomSheetNotifier,
      builder: (context, selectedMenuBottomSheet, child) {
        return MapWidget(
          onMapCreated: (map) {
            _mapboxMap = map;
          },
          styleUri:
              selectedMenuBottomSheet == 0
                  ? widget.standardStyleUri
                  : widget.sateliteStyleUri,
          cameraOptions: CameraOptions(
            center: Point(
              coordinates: Position(105.09049300503469, -5.508241749086075),
            ), // Koordinat Jakarta
            zoom: 10,
          ),
        );
      },
    );
  }
}
