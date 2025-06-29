class Pohon {
  int? id;
  int plotId; // Foreign key ke Plot
  int nomorPohonDiPlot;
  String? jenisPohon;
  String? namaIlmiah;
  double azimut;
  double jarakPusatM;
  double? latitude;
  double? longitude;
  double? altitude;

  Pohon({
    this.id,
    required this.plotId,
    required this.nomorPohonDiPlot,
    this.jenisPohon,
    this.namaIlmiah,
    required this.azimut,
    required this.jarakPusatM,
    this.latitude,
    this.longitude,
    this.altitude,
  });

  // Converting Pohon to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'plotId': plotId,
      'nomorPohonDiPlot': nomorPohonDiPlot,
      'jenisPohon': jenisPohon,
      'namaIlmiah': namaIlmiah,
      'azimut': azimut,
      'jarakPusatM': jarakPusatM,
      'latitude': latitude,
      'longitude': longitude,
      'altitude': altitude,
    };
  }

  // Factory constructor to create Pohon from Map
  factory Pohon.fromMap(Map<String, dynamic> map) {
    return Pohon(
      id: map['id'],
      plotId: map['plotId'],
      nomorPohonDiPlot: map['nomorPohonDiPlot'],
      jenisPohon: map['jenisPohon'],
      namaIlmiah: map['namaIlmiah'],
      azimut: map['azimut'],
      jarakPusatM: map['jarakPusatM'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      altitude: map['altitude'],
    );
  }
}
