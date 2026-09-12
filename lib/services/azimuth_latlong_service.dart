import 'dart:math';

/// Immutable latitude and longitude coordinates expressed in degrees.
class LatLngPoint {
  final double latitude;
  final double longitude;

  const LatLngPoint({required this.latitude, required this.longitude});

  @override
  String toString() => 'LatLngPoint(lat: $latitude, lon: $longitude)';
}

/// Azimuth in degrees and distance in meters relative to an origin point.
class AzimuthDistance {
  /// Clockwise bearing where 0° is north and 90° is east.
  final double azimuthDeg;

  /// Distance from the origin in meters.
  final double distanceM;

  const AzimuthDistance({required this.azimuthDeg, required this.distanceM});

  @override
  String toString() =>
      'AzimuthDistance(azimuthDeg: $azimuthDeg, distanceM: $distanceM)';
}

/// Converts between coordinates and azimuth-distance measurements.
///
/// Calculations use great-circle geodesics on a spherical Earth model, which
/// remains stable for the short distances used by survey plots.
class AzimuthLatLongService {
  static const double _earthRadiusMeters = 6371000.0;
  static const double _degToRadFactor = pi / 180.0;
  static const double _radToDegFactor = 180.0 / pi;

  const AzimuthLatLongService._(); // Static utility; prevent instantiation.

  static double _degToRad(double deg) => deg * _degToRadFactor;

  static double _radToDeg(double rad) => rad * _radToDegFactor;

  /// Calculates target coordinates from an origin, bearing, and distance.
  ///
  /// [centerLatDeg] and [centerLonDeg] are expressed in degrees.
  /// [azimuthDeg] starts at north and increases clockwise.
  /// [distanceM] is expressed in meters.
  ///
  /// Returns the destination as a [LatLngPoint].
  static LatLngPoint fromAzimuthDistance({
    required double centerLatDeg,
    required double centerLonDeg,
    required double azimuthDeg,
    required double distanceM,
  }) {
    final bearing = _degToRad(azimuthDeg);
    final latitude = _degToRad(centerLatDeg);
    final longitude = _degToRad(centerLonDeg);
    final angularDistance = distanceM / _earthRadiusMeters;

    final targetLatitude = asin(
      sin(latitude) * cos(angularDistance) +
          cos(latitude) * sin(angularDistance) * cos(bearing),
    );
    final targetLongitude =
        longitude +
        atan2(
          sin(bearing) * sin(angularDistance) * cos(latitude),
          cos(angularDistance) - sin(latitude) * sin(targetLatitude),
        );
    final normalizedLongitude = (targetLongitude + 3 * pi) % (2 * pi) - pi;

    return LatLngPoint(
      latitude: _radToDeg(targetLatitude),
      longitude: _radToDeg(normalizedLongitude),
    );
  }

  /// Calculates bearing and distance from an origin to a target coordinate.
  ///
  /// All coordinate parameters are expressed in degrees.
  ///
  /// Returns a normalized 0–360° bearing and a distance in meters.
  static AzimuthDistance toAzimuthDistance({
    required double centerLatDeg,
    required double centerLonDeg,
    required double targetLatDeg,
    required double targetLonDeg,
  }) {
    final latitude1 = _degToRad(centerLatDeg);
    final latitude2 = _degToRad(targetLatDeg);
    final deltaLatitude = latitude2 - latitude1;
    final deltaLongitude = _degToRad(targetLonDeg - centerLonDeg);

    final haversine =
        sin(deltaLatitude / 2) * sin(deltaLatitude / 2) +
        cos(latitude1) *
            cos(latitude2) *
            sin(deltaLongitude / 2) *
            sin(deltaLongitude / 2);
    final boundedHaversine = haversine.clamp(0.0, 1.0);
    final centralAngle =
        2 * atan2(sqrt(boundedHaversine), sqrt(1 - boundedHaversine));
    final distance = _earthRadiusMeters * centralAngle;

    final y = sin(deltaLongitude) * cos(latitude2);
    final x =
        cos(latitude1) * sin(latitude2) -
        sin(latitude1) * cos(latitude2) * cos(deltaLongitude);
    final azimuth = (_radToDeg(atan2(y, x)) + 360) % 360;

    return AzimuthDistance(azimuthDeg: azimuth, distanceM: distance);
  }

  /// Calculates only the geodesic distance in meters.
  static double distanceMeters({
    required double lat1Deg,
    required double lon1Deg,
    required double lat2Deg,
    required double lon2Deg,
  }) {
    return toAzimuthDistance(
      centerLatDeg: lat1Deg,
      centerLonDeg: lon1Deg,
      targetLatDeg: lat2Deg,
      targetLonDeg: lon2Deg,
    ).distanceM;
  }
}
