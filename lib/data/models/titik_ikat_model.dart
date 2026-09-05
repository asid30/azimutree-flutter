class TitikIkatModel {
  int? id;
  int idCluster;
  String nama;
  double? latitude;
  double? longitude;
  double? altitude;
  String? keterangan;
  String? urlFoto;

  TitikIkatModel({
    this.id,
    required this.idCluster,
    required this.nama,
    this.latitude,
    this.longitude,
    this.altitude,
    this.keterangan,
    this.urlFoto,
  });

  void validate() {
    if (idCluster <= 0) {
      throw ArgumentError.value(idCluster, 'idCluster', 'Klaster tidak valid');
    }
    if (nama.trim().isEmpty) {
      throw ArgumentError.value(nama, 'nama', 'Nama wajib diisi');
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
      'latitude': latitude,
      'longitude': longitude,
      'altitude': altitude,
      'keterangan': keterangan,
      'urlFoto': urlFoto,
    };
  }

  factory TitikIkatModel.fromMap(Map<String, dynamic> map) {
    return TitikIkatModel(
      id: map['id'] as int?,
      idCluster: map['idCluster'] as int,
      nama: map['nama'] as String,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      altitude: (map['altitude'] as num?)?.toDouble(),
      keterangan: map['keterangan'] as String?,
      urlFoto: map['urlFoto'] as String?,
    );
  }
}
