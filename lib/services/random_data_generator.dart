import 'dart:math';

class RandomDataGenerator {
  static final Random _random = Random();

  static double generateRandomLatitude() {
    // Generates a random latitude near Lampung region (-6 to -5 degrees)
    return -6.0 + (_random.nextDouble() * 1.0); // Example range: -6.0 to -5.0
  }

  static double generateRandomLongitude() {
    // Generates a random longitude near Lampung region (105 to 106 degrees)
    return 105.0 +
        (_random.nextDouble() * 1.0); // Example range: 105.0 to 106.0
  }

  static double generateRandomAltitude() {
    // Generates random altitude between 10m and 100m
    return 10.0 + (_random.nextDouble() * 90.0);
  }

  static double generateRandomAzimuth() {
    // 0 to 360 degrees, with one decimal place
    return double.parse((_random.nextDouble() * 360.0).toStringAsFixed(1));
  }

  static double generateRandomJarakPusatM() {
    // 1 to 10 meters
    return double.parse(
      (1.0 + (_random.nextDouble() * 9.0)).toStringAsFixed(1),
    );
  }

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

  // BARU: Generate Random Kode Cluster
  static String generateRandomKodeCluster() {
    const chars = '0123456789';
    return 'CL-${String.fromCharCodes(Iterable.generate(3, (_) => chars.codeUnitAt(_random.nextInt(chars.length))))}';
  }

  // BARU: Generate Random Nama Pengukur
  static String generateRandomNamaPengukur() {
    final List<String> pengukurNames = [
      'Budi Santoso',
      'Siti Aminah',
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
