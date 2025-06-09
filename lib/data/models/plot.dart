class Plot {
  int? id;
  int clusterId;
  int nomorPlot;
  double latitude; // Wajib: koordinat titik pusat plot
  double longitude; // Wajib: koordinat titik pusat plot
  double? altitude; // Opsional

  Plot({
    this.id,
    required this.clusterId,
    required this.nomorPlot,
    required this.latitude,
    required this.longitude,
    this.altitude,
  });

  factory Plot.fromMap(Map<String, dynamic> map) {
    return Plot(
      id: map['id'],
      clusterId: map['cluster_id'],
      nomorPlot: map['nomor_plot'],
      latitude:
          map['latitude']?.toDouble() ??
          0.0, // Default 0.0 jika null, atau tangani error
      longitude:
          map['longitude']?.toDouble() ??
          0.0, // Default 0.0 jika null, atau tangani error
      altitude: map['altitude']?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cluster_id': clusterId,
      'nomor_plot': nomorPlot,
      'latitude': latitude,
      'longitude': longitude,
      'altitude': altitude,
    };
  }
}
