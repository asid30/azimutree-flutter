class Pohon {
  int? id;
  int plotId; // Foreign key ke Plot
  int kodePohon;
  String? namaPohon;
  String? namaIlmiah;
  double azimut;
  double jarakPusatM;
  double? latitude;
  double? longitude;
  double? altitude;
  String? keterangan;
  String? urlFoto;

  Pohon({
    this.id,
    required this.plotId,
    required this.kodePohon,
    this.namaPohon,
    this.namaIlmiah,
    required this.azimut,
    required this.jarakPusatM,
    this.latitude,
    this.longitude,
    this.altitude,
    this.keterangan,
    this.urlFoto,
  });

  // Converting Pohon to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'plotId': plotId,
      'kodePohon': kodePohon,
      'namaPohon': namaPohon,
      'namaIlmiah': namaIlmiah,
      'azimut': azimut,
      'jarakPusatM': jarakPusatM,
      'latitude': latitude,
      'longitude': longitude,
      'altitude': altitude,
      'keterangan': keterangan,
      'urlFoto': urlFoto,
    };
  }

  // Factory constructor to create Pohon from Map
  factory Pohon.fromMap(Map<String, dynamic> map) {
    return Pohon(
      id: map['id'],
      plotId: map['plotId'],
      kodePohon: map['kodePohon'],
      namaPohon: map['namaPohon'],
      namaIlmiah: map['namaIlmiah'],
      azimut: map['azimut'],
      jarakPusatM: map['jarakPusatM'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      altitude: map['altitude'],
      keterangan: map['keterangan'],
      urlFoto: map['urlFoto'],
    );
  }
}
