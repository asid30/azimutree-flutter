import 'dart:math' as math;

import 'package:azimutree/views/widgets/location_map_widget/map_marker_style.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class AnchorMiniMapWidget extends StatefulWidget {
  const AnchorMiniMapWidget({
    super.key,
    required this.anchorLatitude,
    required this.anchorLongitude,
    required this.userLatitude,
    required this.userLongitude,
    required this.standardStyleUri,
    required this.satelliteStyleUri,
  });

  final double anchorLatitude;
  final double anchorLongitude;
  final double? userLatitude;
  final double? userLongitude;
  final String standardStyleUri;
  final String satelliteStyleUri;

  @override
  State<AnchorMiniMapWidget> createState() => _AnchorMiniMapWidgetState();
}

class _AnchorMiniMapWidgetState extends State<AnchorMiniMapWidget> {
  bool _satellite = true;

  @override
  Widget build(BuildContext context) {
    final hasUser = widget.userLatitude != null && widget.userLongitude != null;
    final center =
        hasUser
            ? Position(
              (widget.anchorLongitude + widget.userLongitude!) / 2,
              (widget.anchorLatitude + widget.userLatitude!) / 2,
            )
            : Position(widget.anchorLongitude, widget.anchorLatitude);
    final distance =
        hasUser
            ? _distanceMeters(
              widget.anchorLatitude,
              widget.anchorLongitude,
              widget.userLatitude!,
              widget.userLongitude!,
            )
            : 0.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 210,
        child: Stack(
          children: [
            MapWidget(
              key: ValueKey(
                'anchor-mini-map-${widget.anchorLatitude}-${widget.anchorLongitude}-$_satellite',
              ),
              styleUri:
                  _satellite
                      ? widget.satelliteStyleUri
                      : widget.standardStyleUri,
              gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                Factory<OneSequenceGestureRecognizer>(
                  EagerGestureRecognizer.new,
                ),
              },
              viewport: CameraViewportState(
                center: Point(coordinates: center),
                zoom: _zoomFor(distance),
              ),
              onMapCreated: (map) async {
                await map.location.updateSettings(
                  LocationComponentSettings(
                    enabled: true,
                    pulsingEnabled: true,
                  ),
                );
                final manager =
                    await map.annotations.createPointAnnotationManager();
                await manager.create(
                  PointAnnotationOptions(
                    geometry: Point(
                      coordinates: Position(
                        widget.anchorLongitude,
                        widget.anchorLatitude,
                      ),
                    ),
                    image: await TitikIkatMarkerIconFactory.create(
                      selected: true,
                    ),
                    iconAnchor: IconAnchor.BOTTOM,
                    iconSize: 1,
                  ),
                );
              },
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Material(
                color: const Color(0xE61F4226),
                borderRadius: BorderRadius.circular(8),
                child: SegmentedButton<bool>(
                  showSelectedIcon: false,
                  style: ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: const WidgetStatePropertyAll(Colors.white),
                    backgroundColor: WidgetStateProperty.resolveWith(
                      (states) =>
                          states.contains(WidgetState.selected)
                              ? const Color(0xFF176E26)
                              : Colors.transparent,
                    ),
                  ),
                  segments: const [
                    ButtonSegment(
                      value: false,
                      icon: Icon(Icons.map_outlined, size: 18),
                      label: Text('Medan'),
                    ),
                    ButtonSegment(
                      value: true,
                      icon: Icon(Icons.satellite_alt, size: 18),
                      label: Text('Satelit'),
                    ),
                  ],
                  selected: {_satellite},
                  onSelectionChanged: (value) {
                    setState(() => _satellite = value.first);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static double _zoomFor(double meters) {
    if (meters <= 60) return 18;
    if (meters <= 250) return 16.5;
    if (meters <= 1000) return 14.5;
    if (meters <= 5000) return 12.5;
    return 10.5;
  }

  static double _distanceMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadius = 6371000.0;
    final dLat = (lat2 - lat1) * math.pi / 180;
    final dLon = (lon2 - lon1) * math.pi / 180;
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * math.pi / 180) *
            math.cos(lat2 * math.pi / 180) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return earthRadius * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }
}
