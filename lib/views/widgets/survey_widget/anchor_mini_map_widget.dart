import 'dart:math' as math;

import 'package:azimutree/data/notifiers/notifiers.dart';
import 'package:azimutree/services/survey_ui_constants.dart';
import 'package:azimutree/views/widgets/location_map_widget/map_marker_style.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

/// Interactive mini map showing the user's route toward an anchor point.
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
  MapboxMap? _map;
  PolylineAnnotationManager? _connectionManager;

  @override
  void didUpdateWidget(covariant AnchorMiniMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userLatitude != widget.userLatitude ||
        oldWidget.userLongitude != widget.userLongitude ||
        oldWidget.anchorLatitude != widget.anchorLatitude ||
        oldWidget.anchorLongitude != widget.anchorLongitude) {
      _drawGpsToAnchorLine();
    }
  }

  Future<void> _drawGpsToAnchorLine() async {
    final map = _map;
    if (map == null) return;
    _connectionManager ??=
        await map.annotations.createPolylineAnnotationManager();
    await _connectionManager!.deleteAll();
    final userLatitude = widget.userLatitude;
    final userLongitude = widget.userLongitude;
    if (userLatitude == null || userLongitude == null) return;
    await _connectionManager!.create(
      PolylineAnnotationOptions(
        geometry: LineString(
          coordinates: [
            Position(userLongitude, userLatitude),
            Position(widget.anchorLongitude, widget.anchorLatitude),
          ],
        ),
        lineColor: Colors.red.toARGB32(),
        lineWidth: 3,
        lineOpacity: 0.9,
      ),
    );
  }

  Future<void> _centerOnAnchor() async {
    final map = _map;
    if (map == null) return;
    await map.easeTo(
      CameraOptions(
        center: Point(
          coordinates: Position(widget.anchorLongitude, widget.anchorLatitude),
        ),
        zoom: 17.5,
      ),
      MapAnimationOptions(duration: 700),
    );
  }

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

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 210,
            child: MapWidget(
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
                _map = map;
                _connectionManager = null;
                await map.location.updateSettings(
                  LocationComponentSettings(
                    enabled: true,
                    pulsingEnabled: true,
                  ),
                );
                await _drawGpsToAnchorLine();
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
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: SegmentedButton<bool>(
                showSelectedIcon: false,
                style: ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  foregroundColor: const WidgetStatePropertyAll(Colors.white),
                  backgroundColor: WidgetStateProperty.resolveWith(
                    (states) =>
                        states.contains(WidgetState.selected)
                            ? const Color(0xFF176E26)
                            : const Color(0xFF1F4226),
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
            const SizedBox(width: 8),
            ValueListenableBuilder<bool>(
              valueListenable: isLightModeNotifier,
              builder: (context, isLightMode, _) {
                return Material(
                  color:
                      isLightMode
                          ? SurveyUiConstants.primaryButtonLight
                          : SurveyUiConstants.primaryButtonDark,
                  shape: const CircleBorder(),
                  child: SizedBox.square(
                    dimension: 36,
                    child: IconButton(
                      tooltip: 'Pusatkan ke titik ikat',
                      color: Colors.white,
                      iconSize: 19,
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      constraints: const BoxConstraints.tightFor(
                        width: 36,
                        height: 36,
                      ),
                      style: IconButton.styleFrom(
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: const Icon(Icons.location_pin),
                      onPressed: _centerOnAnchor,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ],
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
