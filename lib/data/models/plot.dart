class Plot {
  int? id;
  int clusterId; // Foreign key ke Cluster
  int nomorPlot;
  double latitude;
  double longitude;
  double? altitude;

  Plot({
    this.id,
    required this.clusterId,
    required this.nomorPlot,
    required this.latitude,
    required this.longitude,
    this.altitude,
  });

  // Converting Plot to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'clusterId': clusterId,
      'nomorPlot': nomorPlot,
      'latitude': latitude,
      'longitude': longitude,
      'altitude': altitude,
    };
  }

  // Factory constructor untuk membuat Plot dari Map
  factory Plot.fromMap(Map<String, dynamic> map) {
    return Plot(
      id: map['id'],
      clusterId: map['clusterId'],
      nomorPlot: map['nomorPlot'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      altitude: map['altitude'],
    );
  }
}
