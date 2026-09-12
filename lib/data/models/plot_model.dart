class PlotModel {
  int? id;
  int idCluster; // Foreign key ke Cluster
  int kodePlot;
  double latitude;
  double longitude;
  double? altitude;

  PlotModel({
    this.id,
    required this.idCluster,
    required this.kodePlot,
    required this.latitude,
    required this.longitude,
    this.altitude,
  });

  // Converting Plot to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'idCluster': idCluster,
      'kodePlot': kodePlot,
      'latitude': latitude,
      'longitude': longitude,
      'altitude': altitude,
    };
  }

  // Creates a plot from a database row.
  factory PlotModel.fromMap(Map<String, dynamic> map) {
    return PlotModel(
      id: map['id'],
      idCluster: map['idCluster'],
      kodePlot: map['kodePlot'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      altitude: map['altitude'],
    );
  }
}
