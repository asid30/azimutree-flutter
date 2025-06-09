class Cluster {
  int? id;
  String kodeCluster;
  String? namaPengukur;
  DateTime? tanggalPengukuran;

  Cluster({
    this.id,
    required this.kodeCluster,
    this.namaPengukur,
    this.tanggalPengukuran,
  });

  factory Cluster.fromMap(Map<String, dynamic> map) {
    return Cluster(
      id: map['id'],
      kodeCluster: map['kode_cluster'],
      namaPengukur: map['nama_pengukur'],
      tanggalPengukuran:
          map['tanggal_pengukuran'] != null
              ? DateTime.parse(map['tanggal_pengukuran'])
              : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'kode_cluster': kodeCluster,
      'nama_pengukur': namaPengukur,
      'tanggal_pengukuran': tanggalPengukuran?.toIso8601String(),
    };
  }
}
