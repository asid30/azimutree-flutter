import 'package:azimutree/services/compass_navigation_service.dart';
import 'package:flutter_compass/flutter_compass.dart';

/// Exposes normalized, smoothed device headings without owning UI state.
class CompassService {
  const CompassService({this.smoothingWindowSize = 8});

  final int smoothingWindowSize;

  Stream<double?> get headingStream {
    final events = FlutterCompass.events;
    if (events == null) return Stream<double?>.value(null);

    final smoother = CircularHeadingSmoother(windowSize: smoothingWindowSize);

    return events.map((event) {
      final heading = event.heading;
      if (heading == null || !heading.isFinite) return null;
      return smoother.add(heading);
    });
  }
}
