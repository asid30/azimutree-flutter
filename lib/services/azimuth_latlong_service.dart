import 'dart:math';

/// Titik koordinat sederhana (latitude, longitude) dalam derajat.
class LatLngPoint {
  final double latitude;
  final double longitude;

  const LatLngPoint({required this.latitude, required this.longitude});

  @override
  String toString() => 'LatLngPoint(lat: $latitude, lon: $longitude)';
}

/// Representasi azimut (derajat) dan jarak (meter) dari titik pusat.
class AzimuthDistance {
  /// Azimut dalam derajat, 0° = utara, 90° = timur, searah jarum jam.
  final double azimuthDeg;

  /// Jarak dari pusat dalam meter.
  final double distanceM;

  const AzimuthDistance({required this.azimuthDeg, required this.distanceM});

  @override
  String toString() =>
      'AzimuthDistance(azimuthDeg: $azimuthDeg, distanceM: $distanceM)';
}

/// Service helper untuk konversi azimut <-> koordinat.
/// Catatan:
/// Menggunakan rumus geodesik great-circle pada bumi berbentuk bola. Rumus ini
/// tetap stabil untuk jarak plot yang pendek dan tidak bergantung pada arah.
class AzimuthLatLongService {
  static const double _earthRadiusMeters = 6371000.0;
  static const double _degToRadFactor = pi / 180.0;
  static const double _radToDegFactor = 180.0 / pi;

  const AzimuthLatLongService._(); // private constructor, ga perlu di-instantiate

  static double _degToRad(double deg) => deg * _degToRadFactor;

  static double _radToDeg(double rad) => rad * _radToDegFactor;

  /// Hitung koordinat target berdasarkan titik pusat, azimut, dan jarak.
  ///
  /// [centerLatDeg], [centerLonDeg] dalam derajat.
  /// [azimuthDeg] dalam derajat, 0° = utara, meningkat searah jarum jam.
  /// [distanceM] dalam meter.
  ///
  /// Return: koordinat pohon (LatLngPoint).
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

  /// Hitung azimut (derajat) dan jarak (meter) dari titik pusat ke target.
  ///
  /// [centerLatDeg], [centerLonDeg], [targetLatDeg], [targetLonDeg] dalam derajat.
  ///
  /// Return: [AzimuthDistance] dengan azimut 0–360° dan jarak meter.
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

  /// Hitung hanya jarak geodesik (meter).
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
