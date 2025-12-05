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
/// - Menggunakan pendekatan lokal (equirectangular approximation).
/// - Cukup akurat untuk jarak pendek (skala plot hutan).
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
    final azRad = _degToRad(azimuthDeg);
    final lat0Rad = _degToRad(centerLatDeg);

    // Komponen jarak relatif terhadap utara & timur
    final dNorth = distanceM * cos(azRad); // +Y
    final dEast = distanceM * sin(azRad); // +X

    // Konversi ke derajat
    final dLatDeg = (dNorth / _earthRadiusMeters) * _radToDegFactor;
    final dLonDeg =
        (dEast / (_earthRadiusMeters * cos(lat0Rad))) * _radToDegFactor;

    final newLat = centerLatDeg + dLatDeg;
    final newLon = centerLonDeg + dLonDeg;

    return LatLngPoint(latitude: newLat, longitude: newLon);
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
    final lat0Rad = _degToRad(centerLatDeg);

    // Selisih derajat
    final dLatDeg = targetLatDeg - centerLatDeg;
    final dLonDeg = targetLonDeg - centerLonDeg;

    // Konversi selisih ke meter dengan pendekatan lokal
    final dNorth =
        dLatDeg * _degToRadFactor * _earthRadiusMeters; // delta Y (m)
    final dEast =
        dLonDeg *
        _degToRadFactor *
        _earthRadiusMeters *
        cos(lat0Rad); // delta X (m)

    final distance = sqrt(dNorth * dNorth + dEast * dEast);

    // Azimut: 0° = utara, searah jarum jam.
    // atan2(X, Y) karena:
    // - dEast (X) sepanjang timur (+X)
    // - dNorth (Y) sepanjang utara (+Y)
    var azRad = atan2(dEast, dNorth);
    var azDeg = _radToDeg(azRad);

    if (azDeg < 0) {
      azDeg += 360.0;
    }

    return AzimuthDistance(azimuthDeg: azDeg, distanceM: distance);
  }

  /// Hitung hanya jarak (meter) menggunakan pendekatan lokal yang sama.
  static double distanceMeters({
    required double lat1Deg,
    required double lon1Deg,
    required double lat2Deg,
    required double lon2Deg,
  }) {
    final latMidRad = _degToRad((lat1Deg + lat2Deg) / 2.0);
    final dLat = (lat2Deg - lat1Deg) * _degToRadFactor;
    final dLon = (lon2Deg - lon1Deg) * _degToRadFactor;

    final dNorth = dLat * _earthRadiusMeters;
    final dEast = dLon * _earthRadiusMeters * cos(latMidRad);

    return sqrt(dNorth * dNorth + dEast * dEast);
  }
}
