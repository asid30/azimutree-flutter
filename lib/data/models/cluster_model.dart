class ClusterModel {
  int? id;
  String kodeCluster;
  String? namaPengukur;
  DateTime? tanggalPengukuran;

  ClusterModel({
    this.id,
    required this.kodeCluster,
    this.namaPengukur,
    this.tanggalPengukuran,
  });

  // Converting Cluster to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'kodeCluster': kodeCluster,
      'namaPengukur': namaPengukur,
      'tanggalPengukuran': tanggalPengukuran?.millisecondsSinceEpoch,
    };
  }

  // Factory constructor to create Cluster from Map
  factory ClusterModel.fromMap(Map<String, dynamic> map) {
    return ClusterModel(
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
