class PlotModel {
  int? id;
  int clusterId; // Foreign key ke Cluster
  int kodePlot;
  double latitude;
  double longitude;
  double? altitude;

  PlotModel({
    this.id,
    required this.clusterId,
    required this.kodePlot,
    required this.latitude,
    required this.longitude,
    this.altitude,
  });

  // Converting Plot to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'clusterId': clusterId,
      'kodePlot': kodePlot,
      'latitude': latitude,
      'longitude': longitude,
      'altitude': altitude,
    };
  }

  // Factory constructor untuk membuat Plot dari Map
  factory PlotModel.fromMap(Map<String, dynamic> map) {
    return PlotModel(
      id: map['id'],
      clusterId: map['clusterId'],
      kodePlot: map['kodePlot'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      altitude: map['altitude'],
    );
  }
}
