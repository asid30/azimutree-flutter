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

  // Mengkonversi Cluster menjadi Map untuk disimpan di database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'kodeCluster': kodeCluster,
      'namaPengukur': namaPengukur,
      'tanggalPengukuran':
          tanggalPengukuran
              ?.millisecondsSinceEpoch, // Simpan DateTime sebagai Unix timestamp
    };
  }

  // Membuat objek Cluster dari Map yang diambil dari database
  factory Cluster.fromMap(Map<String, dynamic> map) {
    return Cluster(
      id: map['id'],
      kodeCluster: map['kodeCluster'],
      namaPengukur: map['namaPengukur'],
      tanggalPengukuran:
          map['tanggalPengukuran'] != null
              ? DateTime.fromMillisecondsSinceEpoch(map['tanggalPengukuran'])
              : null,
    );
  }
}
