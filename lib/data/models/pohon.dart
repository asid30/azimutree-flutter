class Pohon {
  int? id;
  int plotId;
  int nomorPohonDiPlot;
  String? jenisPohon;
  String? namaIlmiah;
  double azimut; // Wajib
  double jarakPusatM; // Wajib
  double? latitude; // Opsional, akan dihitung
  double? longitude; // Opsional, akan dihitung
  double? altitude; // Opsional, akan dihitung

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

  factory Pohon.fromMap(Map<String, dynamic> map) {
    return Pohon(
      id: map['id'],
      plotId: map['plot_id'],
      nomorPohonDiPlot: map['nomor_pohon_di_plot'],
      jenisPohon: map['jenis_pohon'],
      namaIlmiah: map['nama_ilmiah'],
      azimut: map['azimut']?.toDouble() ?? 0.0, // Wajib, set default jika null
      jarakPusatM:
          map['jarak_pusat_m']?.toDouble() ??
          0.0, // Wajib, set default jika null
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
      altitude: map['altitude']?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'plot_id': plotId,
      'nomor_pohon_di_plot': nomorPohonDiPlot,
      'jenis_pohon': jenisPohon,
      'nama_ilmiah': namaIlmiah,
      'azimut': azimut,
      'jarak_pusat_m': jarakPusatM,
      'latitude': latitude,
      'longitude': longitude,
      'altitude': altitude,
    };
  }
}
