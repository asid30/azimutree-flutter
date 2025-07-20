import 'dart:math' as math;

class LocationUtils {
  //* Earth's radius in meters
  static const double earthRadiusMeters = 6371000;

  //* Function to convert degrees to radians
  static double toRadians(double degrees) {
    return degrees * math.pi / 180.0;
  }

  //* Function to convert radians to degrees
  static double toDegrees(double radians) {
    return radians * 180.0 / math.pi;
  }

  //* Calculates the coordinates of a tree based on the plot's coordinates, azimuth, and distance
  static Map<String, double> calculatePohonCoordinates(
    double plotLat,
    double plotLon,
    double azimut, // degrees
    double distanceMeters, // meter
  ) {
    // Convert latitude, longitude, and azimuth to radians
    double latRad = toRadians(plotLat);
    double lonRad = toRadians(plotLon);
    double azimutRad = toRadians(azimut);

    // Calculate the angular distance in radians
    double angularDistance = distanceMeters / earthRadiusMeters;

    // Calculate the new latitude
    double newLatRad = math.asin(
      math.sin(latRad) * math.cos(angularDistance) +
          math.cos(latRad) * math.sin(angularDistance) * math.cos(azimutRad),
    );

    // Calculate the new longitude
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
