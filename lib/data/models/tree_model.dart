class TreeModel {
  int? id;
  int plotId; // Foreign key ke Plot (WAJIB)
  int kodePohon; // WAJIB
  String? namaPohon;
  String? namaIlmiah;
  double? azimut;
  double? jarakPusatM;
  double? latitude;
  double? longitude;
  double? altitude;
  String? keterangan;
  String? urlFoto;

  /// Optional flag set when a tree is inspected/done via the inspection workflow.
  /// Stored in DB as INTEGER (0/1) and may be null for older rows.
  bool? inspected;

  TreeModel({
    this.id,
    required this.plotId,
    required this.kodePohon,
    this.namaPohon,
    this.namaIlmiah,
    this.azimut,
    this.jarakPusatM,
    this.latitude,
    this.longitude,
    this.altitude,
    this.keterangan,
    this.urlFoto,
    this.inspected,
  });

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
      'inspected': inspected == null ? null : (inspected! ? 1 : 0),
    };
  }

  factory TreeModel.fromMap(Map<String, dynamic> map) {
    return TreeModel(
      id: map['id'] as int?,
      plotId: map['plotId'] as int,
      kodePohon: map['kodePohon'] as int,
      namaPohon: map['namaPohon'] as String?,
      namaIlmiah: map['namaIlmiah'] as String?,
      azimut: (map['azimut'] as num?)?.toDouble(),
      jarakPusatM: (map['jarakPusatM'] as num?)?.toDouble(),
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      altitude: (map['altitude'] as num?)?.toDouble(),
      keterangan: map['keterangan'] as String?,
      urlFoto: map['urlFoto'] as String?,
      inspected:
          (() {
            try {
              final v = map['inspected'];
              if (v == null) return null;
              if (v is int) return v == 1;
              if (v is bool) return v;
              final s = v.toString().trim();
              if (s.isEmpty) return null;
              final parsed = int.tryParse(s);
              if (parsed != null) return parsed == 1;
            } catch (_) {}
            return null;
          })(),
    );
  }
}
