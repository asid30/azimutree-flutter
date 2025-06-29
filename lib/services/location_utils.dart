import 'dart:math' as math;

class LocationUtils {
  // Konstanta untuk perhitungan koordinat (rata-rata radius bumi)
  static const double earthRadiusMeters = 6371000;

  // Fungsi untuk mengkonversi derajat ke radian
  static double toRadians(double degrees) {
    return degrees * math.pi / 180.0;
  }

  // Fungsi untuk mengkonversi radian ke derajat
  static double toDegrees(double radians) {
    return radians * 180.0 / math.pi;
  }

  // Fungsi utama untuk menghitung koordinat pohon
  static Map<String, double> calculatePohonCoordinates(
    double plotLat,
    double plotLon,
    double azimut, // dalam derajat
    double distanceMeters, // dalam meter
  ) {
    // Konversi latitude plot dan azimut ke radian
    double latRad = toRadians(plotLat);
    double lonRad = toRadians(plotLon);
    double azimutRad = toRadians(azimut);

    // Hitung perubahan angular distance (delta sigma)
    double angularDistance = distanceMeters / earthRadiusMeters;

    // Hitung latitude baru
    double newLatRad = math.asin(
      math.sin(latRad) * math.cos(angularDistance) +
          math.cos(latRad) * math.sin(angularDistance) * math.cos(azimutRad),
    );

    // Hitung longitude baru
    double newLonRad =
        lonRad +
        math.atan2(
          math.sin(azimutRad) * math.sin(angularDistance) * math.cos(latRad),
          math.cos(angularDistance) - math.sin(latRad) * math.sin(newLatRad),
        );

    return {
      'latitude': toDegrees(newLatRad),
      'longitude': toDegrees(newLonRad),
    };
  }
}
