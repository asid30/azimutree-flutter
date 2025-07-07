import 'dart:math';

class RandomDataGenerator {
  static final Random _random = Random();

  //* Generates a random latitude in the Lampung region (-5.55687 to -5.39351 degrees)
  static double generateRandomLatitude() {
    double minLat = -5.55687;
    double maxLat = -5.39351;
    return minLat + _random.nextDouble() * (maxLat - minLat);
  }

  //* Generates a random longitude in the Lampung region (105.0434 to 105.2295 degrees)
  static double generateRandomLongitude() {
    double minLng = 105.0434;
    double maxLng = 105.2295;
    return minLng + _random.nextDouble() * (maxLng - minLng);
  }

  //* Generates a random altitude in meters (10m to 100m)
  static double generateRandomAltitude() {
    // Generates random altitude between 10m and 100m
    return 10.0 + (_random.nextDouble() * 90.0);
  }

  //* Generates a random azimuth in degrees (0 to 360)
  static double generateRandomAzimuth() {
    // 0 to 360 degrees, with one decimal place
    return double.parse((_random.nextDouble() * 360.0).toStringAsFixed(1));
  }

  //* Generates a random distance from the center in meters
  static double generateRandomJarakPusatM() {
    // 1 to 10 meters
    return double.parse(
      (1.0 + (_random.nextDouble() * 9.0)).toStringAsFixed(1),
    );
  }

  //* Generates a name for the tree based on its type
  static String generateRandomJenisPohon() {
    final List<String> jenisPohon = [
      'Meranti',
      'Jati',
      'Mahoni',
      'Sengon',
      'Akasia',
      'Ulin',
      'Damar',
      'Cempaka',
      'Kenari',
      'Sungkay',
      'Rasamala',
      'Beringin',
      'Eboni',
      'Cendana',
      'Kayu Besi',
    ];
    return jenisPohon[_random.nextInt(jenisPohon.length)];
  }

  //* Generates a random scientific name based on the type of tree
  static String generateRandomNamaIlmiah(String jenisPohon) {
    // A simplified mapping for scientific names
    switch (jenisPohon) {
      case 'Meranti':
        return 'Shorea sp.';
      case 'Jati':
        return 'Tectona grandis';
      case 'Mahoni':
        return 'Swietenia macrophylla';
      case 'Sengon':
        return 'Paraserianthes falcataria';
      case 'Akasia':
        return 'Acacia mangium';
      case 'Ulin':
        return 'Eusideroxylon zwageri';
      case 'Damar':
        return 'Agathis dammara';
      case 'Cempaka':
        return 'Magnolia champaca';
      case 'Kenari':
        return 'Canarium vulgare';
      case 'Sungkay':
        return 'Peronema canescens';
      case 'Rasamala':
        return 'Altingia excelsa';
      case 'Beringin':
        return 'Ficus benjamina';
      case 'Eboni':
        return 'Diospybyros celebica';
      case 'Cendana':
        return 'Santalum album';
      case 'Kayu Besi':
        return 'Lagerstroemia loudonii';
      default:
        return 'Spesies tidak diketahui';
    }
  }

  //* Generates a random cluster code in the format "CL-XXX"
  static String generateRandomKodeCluster() {
    const chars = '0123456789';
    return 'CL-${String.fromCharCodes(Iterable.generate(3, (_) => chars.codeUnitAt(_random.nextInt(chars.length))))}';
  }

  //* Generates a random name for the measurer
  static String generateRandomNamaPengukur() {
    final List<String> pengukurNames = [
      'Budi Santoso',
      'Siti Nuraini',
      'Abdillah Asyidiqi',
      'Fikri Pratama',
      'Fikri Al-hafidz',
      'Rudi Wijaya',
      'Dewi Lestari',
      'Joko Susilo',
      'Indah Permata',
      'Candra Kirana',
      'Bayu Pratama',
      'Eko Saputro',
      'Fika Nuraini',
    ];
    return pengukurNames[_random.nextInt(pengukurNames.length)];
  }
}
