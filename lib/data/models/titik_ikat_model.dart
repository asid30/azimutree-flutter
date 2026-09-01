class TitikIkatModel {
  int? id;
  int idCluster;
  String nama;
  String? jenis;
  double? latitude;
  double? longitude;
  double? altitude;
  double? azimutKePlot1;
  double? jarakKePlot1M;
  String? keterangan;

  TitikIkatModel({
    this.id,
    required this.idCluster,
    required this.nama,
    this.jenis,
    this.latitude,
    this.longitude,
    this.altitude,
    this.azimutKePlot1,
    this.jarakKePlot1M,
    this.keterangan,
  });

  void validate() {
    if (idCluster <= 0) {
      throw ArgumentError.value(idCluster, 'idCluster', 'Klaster tidak valid');
    }
    if (nama.trim().isEmpty) {
      throw ArgumentError.value(nama, 'nama', 'Nama wajib diisi');
    }
    if ((azimutKePlot1 == null) != (jarakKePlot1M == null)) {
      throw ArgumentError('Azimut dan jarak harus diisi bersama-sama');
    }
    if (azimutKePlot1 != null &&
        (!azimutKePlot1!.isFinite ||
            azimutKePlot1! < 0 ||
            azimutKePlot1! >= 360)) {
      throw ArgumentError.value(
        azimutKePlot1,
        'azimutKePlot1',
        'Azimut harus berada pada rentang 0 sampai kurang dari 360',
      );
    }
    if (jarakKePlot1M != null &&
        (!jarakKePlot1M!.isFinite || jarakKePlot1M! < 0)) {
      throw ArgumentError.value(
        jarakKePlot1M,
        'jarakKePlot1M',
        'Jarak tidak boleh negatif',
      );
    }
    if ((latitude == null) != (longitude == null)) {
      throw ArgumentError(
        'Lintang dan bujur harus diisi bersama-sama atau dikosongkan',
      );
    }
    if (latitude != null &&
        (!latitude!.isFinite || latitude! < -90 || latitude! > 90)) {
      throw ArgumentError.value(latitude, 'latitude', 'Lintang tidak valid');
    }
    if (longitude != null &&
        (!longitude!.isFinite || longitude! < -180 || longitude! > 180)) {
      throw ArgumentError.value(longitude, 'longitude', 'Bujur tidak valid');
    }
    if (altitude != null && !altitude!.isFinite) {
      throw ArgumentError.value(altitude, 'altitude', 'Altitude tidak valid');
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'idCluster': idCluster,
      'nama': nama,
      'jenis': jenis,
      'latitude': latitude,
      'longitude': longitude,
      'altitude': altitude,
      'azimutKePlot1': azimutKePlot1,
      'jarakKePlot1M': jarakKePlot1M,
      'keterangan': keterangan,
    };
  }

  factory TitikIkatModel.fromMap(Map<String, dynamic> map) {
    return TitikIkatModel(
      id: map['id'] as int?,
      idCluster: map['idCluster'] as int,
      nama: map['nama'] as String,
      jenis: map['jenis'] as String?,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      altitude: (map['altitude'] as num?)?.toDouble(),
      azimutKePlot1: (map['azimutKePlot1'] as num?)?.toDouble(),
      jarakKePlot1M: (map['jarakKePlot1M'] as num?)?.toDouble(),
      keterangan: map['keterangan'] as String?,
    );
  }
}
