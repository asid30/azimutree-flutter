//* visualization & mapping of cluster page
import 'package:azimutree/data/global_variables/api_key.dart';
import 'package:azimutree/data/notifiers/notifiers.dart';
import 'package:azimutree/views/widgets/appbar_widget.dart';
import 'package:azimutree/views/widgets/sidebar_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:azimutree/data/database/database_helper.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'dart:math';

class LocationMapPage extends StatefulWidget {
  const LocationMapPage({super.key});

  @override
  State<LocationMapPage> createState() => _LocationMapPageState();
}

class _LocationMapPageState extends State<LocationMapPage> {
  late FMTCTileProvider _tileProvider;
  final _outdoorProvider = FMTCTileProvider(
    stores: {'outdoorStore': BrowseStoreStrategy.readUpdateCreate},
  );
  final _satelliteProvider = FMTCTileProvider(
    stores: {'satelliteStore': BrowseStoreStrategy.readUpdateCreate},
  );

  final MapController _mapController = MapController();
  final String mapboxAccessToken = mapboxAccess;

  final String _outdoorsStyle = 'mapbox/outdoors-v12';
  final String _satelliteStyle =
      'mapbox/satellite-streets-v12'; // Ganti dengan style lain jika mau
  late String _currentStyle;

  List<Marker> allMarkers = [];

  // Tools state
  bool isMeasuring = false;
  bool isAddingPoint = false;
  bool isMeasuringArea = false;
  bool isMeasuringAngle = false;

  bool showLabels = true;
  bool showTools = false;
  bool showToolsLayer = true;

  // Tools data
  List<LatLng> measurePoints = [];
  List<LatLng> userPoints = [];
  List<LatLng> areaPoints = [];
  List<LatLng> anglePoints = [];

  List<List<LatLng>> finishedRulers = [];
  List<List<LatLng>> finishedAreas = [];
  List<List<LatLng>> finishedAngles = [];

  @override
  void initState() {
    super.initState();
    _currentStyle = _outdoorsStyle;
    _tileProvider = _outdoorProvider;
    loadMarkers();
  }

  void _toggleMapStyle() {
    setState(() {
      if (_currentStyle == _outdoorsStyle) {
        _currentStyle = _satelliteStyle;
        _tileProvider = _satelliteProvider;
      } else {
        _currentStyle = _outdoorsStyle;
        _tileProvider = _outdoorProvider;
      }
    });
  }

  Future<void> loadMarkers() async {
    final markers = await getMarkers();
    setState(() {
      allMarkers = markers;
    });
  }

  Future<List<Marker>> getMarkers() async {
    final plots = await DatabaseHelper.instance.plotDao.getAllPlots();
    final clusters = await DatabaseHelper.instance.clusterDao.getAllClusters();
    final pohons = await DatabaseHelper.instance.pohonDao.getAllPohons();

    // Buat map clusterId -> kodeCluster untuk lookup cepat
    final clusterMap = {for (var c in clusters) c.id: c.kodeCluster};

    List<Marker> markers = [];

    // Marker plot
    for (var plot in plots) {
      final kodeCluster = clusterMap[plot.clusterId] ?? '-';
      markers.add(
        Marker(
          point: LatLng(plot.latitude, plot.longitude),
          width: 140,
          height: 70,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              const Icon(Icons.location_on, color: Colors.blue, size: 28),
              if (showLabels)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(color: Colors.black12, blurRadius: 2),
                    ],
                  ),
                  child: Text(
                    'Plot ${plot.nomorPlot}\nCluster $kodeCluster',
                    style: const TextStyle(fontSize: 12, color: Colors.black),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      );
    }

    // Marker pohon
    for (var pohon in pohons) {
      if (pohon.latitude != null && pohon.longitude != null) {
        markers.add(
          Marker(
            point: LatLng(pohon.latitude!, pohon.longitude!),
            width: 120,
            height: 56,
            child: GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder:
                      (ctx) => AlertDialog(
                        title: Text(
                          pohon.jenisPohon ?? '-',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('ID: ${pohon.id ?? "-"}'),
                            Text(
                              'Jarak dari pusat: ${pohon.jarakPusatM.toStringAsFixed(1)} m',
                            ),
                            Text(
                              'Azimuth: ${pohon.azimut.toStringAsFixed(1)} °',
                            ),
                            Text(
                              'Koordinat: ${pohon.latitude?.toStringAsFixed(6) ?? "-"}, ${pohon.longitude?.toStringAsFixed(6) ?? "-"}',
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Tutup'),
                          ),
                        ],
                      ),
                );
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.forest, color: Colors.green, size: 24),
                  if (showLabels)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(color: Colors.black12, blurRadius: 2),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            pohon.jenisPohon ?? '-',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'ID: ${pohon.id ?? "-"}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      }
    }

    return markers;
  }

  void _finishRuler() {
    if (measurePoints.length > 1) {
      finishedRulers.add(List.from(measurePoints));
    }
    measurePoints.clear();
  }

  void _finishArea() {
    if (areaPoints.length > 2) {
      finishedAreas.add(List.from(areaPoints));
    }
    areaPoints.clear();
  }

  void _finishAngle() {
    if (anglePoints.length == 3) {
      finishedAngles.add(List.from(anglePoints));
    }
    anglePoints.clear();
  }

  void _resetAllTools() {
    measurePoints.clear();
    areaPoints.clear();
    anglePoints.clear();
    finishedRulers.clear();
    finishedAreas.clear();
    finishedAngles.clear();
    userPoints.clear();
  }

  void _deactivateAllTools() {
    isMeasuring = false;
    isMeasuringArea = false;
    isMeasuringAngle = false;
    isAddingPoint = false;
  }

  // Fungsi untuk menghitung luas poligon (hasil dalam hektar)
  double _calculatePolygonArea(List<LatLng> points) {
    if (points.length < 3) return 0.0;
    double area = 0.0;
    for (int i = 0; i < points.length; i++) {
      final j = (i + 1) % points.length;
      area += points[i].longitude * points[j].latitude;
      area -= points[j].longitude * points[i].latitude;
    }
    area = area.abs() / 2.0;
    final meterPerDegree = 111320.0;
    area = area * meterPerDegree * meterPerDegree;
    return area / 10000.0; // m2 ke hektar
  }

  // Fungsi untuk mendapatkan titik tengah poligon
  LatLng _getPolygonCenter(List<LatLng> points) {
    double lat = 0, lng = 0;
    for (var p in points) {
      lat += p.latitude;
      lng += p.longitude;
    }
    return LatLng(lat / points.length, lng / points.length);
  }

  // Fungsi untuk menghitung sudut antara tiga titik (hasil dalam derajat)
  double _calculateAngle(List<LatLng> points) {
    if (points.length != 3) return 0.0;
    final a = points[0];
    final b = points[1];
    final c = points[2];

    double abx = a.longitude - b.longitude;
    double aby = a.latitude - b.latitude;
    double cbx = c.longitude - b.longitude;
    double cby = c.latitude - b.latitude;

    double dot = (abx * cbx + aby * cby);
    double cross = (abx * cby - aby * cbx);
    double angle = (atan2(cross, dot) * 180 / pi).abs();
    return angle;
  }

  double _getTotalDistance(List<LatLng> points) {
    double total = 0.0;
    final d = Distance();
    for (int i = 0; i < points.length - 1; i++) {
      total += d.as(LengthUnit.Kilometer, points[i], points[i + 1]);
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.pushNamedAndRemoveUntil(context, 'home', (route) => false);
      },
      child: Scaffold(
        appBar: AppbarWidget(title: "Peta Lokasi Cluster Plot"),
        drawer: SidebarWidget(),
        body: Stack(
          children: [
            //* Background App
            ValueListenableBuilder(
              valueListenable: isLightModeNotifier,
              builder: (context, isLightMode, child) {
                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 800),
                  transitionBuilder: (
                    Widget child,
                    Animation<double> animation,
                  ) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                  child: Image(
                    key: ValueKey<bool>(isLightMode),
                    image: AssetImage(
                      isLightMode
                          ? "assets/images/light-bg-notitle.png"
                          : "assets/images/dark-bg-notitle.png",
                    ),
                    fit: BoxFit.cover,
                    height: double.infinity,
                    width: double.infinity,
                  ),
                );
              },
            ),
            //* Main Content
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: LatLng(-5.055531, 105.249231),
                initialZoom: 9.2,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all,
                ),
                onTap: (tapPosition, latlng) {
                  setState(() {
                    if (isMeasuring) {
                      measurePoints.add(latlng);
                    } else if (isMeasuringArea) {
                      areaPoints.add(latlng);
                    } else if (isMeasuringAngle) {
                      if (anglePoints.length >= 3) anglePoints.clear();
                      anglePoints.add(latlng);
                    } else if (isAddingPoint) {
                      userPoints.add(latlng);
                    }
                  });
                },
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://api.mapbox.com/styles/v1/{id}/tiles/{z}/{x}/{y}?access_token={accessToken}',
                  additionalOptions: {
                    'accessToken': mapboxAccessToken,
                    'id': _currentStyle,
                  },
                  userAgentPackageName: 'com.heavysnack.azimutree',
                  tileProvider: _tileProvider,
                ),
                // TOOLS LAYER
                if (showToolsLayer) ...[
                  // Semua penggaris yang sudah jadi
                  for (final ruler in finishedRulers) ...[
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: ruler,
                          color: Colors.red,
                          strokeWidth: 4,
                        ),
                      ],
                    ),
                  ],
                  // Penggaris aktif
                  if (measurePoints.length > 1)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: measurePoints,
                          color: Colors.red,
                          strokeWidth: 4,
                        ),
                      ],
                    ),
                  // Semua area yang sudah jadi
                  for (final area in finishedAreas) ...[
                    PolygonLayer(
                      polygons: [
                        Polygon(
                          points: area,
                          color: const Color.fromARGB(31, 76, 175, 79),
                          borderStrokeWidth: 3,
                          borderColor: Colors.green,
                        ),
                      ],
                    ),
                  ],
                  // Area aktif
                  if (areaPoints.length > 2)
                    PolygonLayer(
                      polygons: [
                        Polygon(
                          points: areaPoints,
                          color: const Color.fromARGB(31, 76, 175, 79),
                          borderStrokeWidth: 3,
                          borderColor: Colors.green,
                        ),
                      ],
                    ),
                  // Semua busur yang sudah jadi
                  for (final angle in finishedAngles) ...[
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: [angle[0], angle[1]],
                          color: Colors.purple,
                          strokeWidth: 4,
                        ),
                        Polyline(
                          points: [angle[2], angle[1]],
                          color: Colors.purple,
                          strokeWidth: 4,
                        ),
                      ],
                    ),
                  ],
                  // Busur aktif
                  if (anglePoints.length == 3)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: [anglePoints[0], anglePoints[1]],
                          color: Colors.purple,
                          strokeWidth: 4,
                        ),
                        Polyline(
                          points: [anglePoints[2], anglePoints[1]],
                          color: Colors.purple,
                          strokeWidth: 4,
                        ),
                      ],
                    ),
                  // Semua titik tools (ruler, area, angle, pin user)
                  MarkerLayer(
                    markers: [
                      // Titik ruler
                      ...finishedRulers.expand(
                        (ruler) => ruler.map(
                          (p) => Marker(
                            point: p,
                            width: 30,
                            height: 30,
                            child: const Icon(
                              Icons.circle,
                              color: Colors.red,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                      ...measurePoints.map(
                        (p) => Marker(
                          point: p,
                          width: 30,
                          height: 30,
                          child: const Icon(
                            Icons.circle,
                            color: Colors.red,
                            size: 18,
                          ),
                        ),
                      ),
                      // Titik area
                      ...finishedAreas.expand(
                        (area) => area.map(
                          (p) => Marker(
                            point: p,
                            width: 28,
                            height: 28,
                            child: const Icon(
                              Icons.circle,
                              color: Colors.green,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                      ...areaPoints.map(
                        (p) => Marker(
                          point: p,
                          width: 28,
                          height: 28,
                          child: const Icon(
                            Icons.circle,
                            color: Colors.green,
                            size: 18,
                          ),
                        ),
                      ),
                      // Titik busur
                      ...finishedAngles.expand(
                        (angle) => angle.map(
                          (p) => Marker(
                            point: p,
                            width: 28,
                            height: 28,
                            child: const Icon(
                              Icons.circle,
                              color: Colors.purple,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                      ...anglePoints.map(
                        (p) => Marker(
                          point: p,
                          width: 28,
                          height: 28,
                          child: const Icon(
                            Icons.circle,
                            color: Colors.purple,
                            size: 18,
                          ),
                        ),
                      ),
                      // Pin user
                      ...userPoints.map(
                        (p) => Marker(
                          point: p,
                          width: 36,
                          height: 36,
                          child: const Icon(
                            Icons.add_location_alt,
                            color: Colors.deepPurple,
                            size: 30,
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Label tools (jarak, luas, sudut)
                  // Label ruler
                  for (final ruler in finishedRulers) ...[
                    MarkerLayer(
                      markers: [
                        for (int i = 0; i < ruler.length - 1; i++)
                          Marker(
                            point: LatLng(
                              (ruler[i].latitude + ruler[i + 1].latitude) / 2,
                              (ruler[i].longitude + ruler[i + 1].longitude) / 2,
                            ),
                            width: 100,
                            height: 32,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: Text(
                                '${Distance().as(LengthUnit.Kilometer, ruler[i], ruler[i + 1]).toStringAsFixed(2)} km',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        if (ruler.length > 2)
                          Marker(
                            point: LatLng(
                              ruler
                                      .map((p) => p.latitude)
                                      .reduce((a, b) => a + b) /
                                  ruler.length,
                              ruler
                                      .map((p) => p.longitude)
                                      .reduce((a, b) => a + b) /
                                  ruler.length,
                            ),
                            width: 120,
                            height: 36,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.yellow[100],
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: Text(
                                'Total: ${_getTotalDistance(ruler).toStringAsFixed(2)} km',
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                  if (measurePoints.length > 1)
                    MarkerLayer(
                      markers: [
                        for (int i = 0; i < measurePoints.length - 1; i++)
                          Marker(
                            point: LatLng(
                              (measurePoints[i].latitude +
                                      measurePoints[i + 1].latitude) /
                                  2,
                              (measurePoints[i].longitude +
                                      measurePoints[i + 1].longitude) /
                                  2,
                            ),
                            width: 100,
                            height: 32,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: Text(
                                '${Distance().as(LengthUnit.Kilometer, measurePoints[i], measurePoints[i + 1]).toStringAsFixed(2)} km',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        if (measurePoints.length > 2)
                          Marker(
                            point: LatLng(
                              measurePoints
                                      .map((p) => p.latitude)
                                      .reduce((a, b) => a + b) /
                                  measurePoints.length,
                              measurePoints
                                      .map((p) => p.longitude)
                                      .reduce((a, b) => a + b) /
                                  measurePoints.length,
                            ),
                            width: 120,
                            height: 36,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.yellow[100],
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: Text(
                                'Total: ${_getTotalDistance(measurePoints).toStringAsFixed(2)} km',
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  // Label area
                  for (final area in finishedAreas)
                    if (area.length > 2)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _getPolygonCenter(area),
                            width: 140,
                            height: 40,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: Text(
                                '${_calculatePolygonArea(area).toStringAsFixed(2)} ha',
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                  if (areaPoints.length > 2)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _getPolygonCenter(areaPoints),
                          width: 140,
                          height: 40,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(color: Colors.black26, blurRadius: 4),
                              ],
                            ),
                            child: Text(
                              '${_calculatePolygonArea(areaPoints).toStringAsFixed(2)} ha',
                              style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  // Label sudut
                  for (final angle in finishedAngles)
                    if (angle.length == 3)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: angle[1],
                            width: 120,
                            height: 40,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: Text(
                                'Sudut: ${_calculateAngle(angle).toStringAsFixed(1)}°',
                                style: const TextStyle(
                                  color: Colors.purple,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                  if (anglePoints.length == 3)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: anglePoints[1],
                          width: 120,
                          height: 40,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(color: Colors.black26, blurRadius: 4),
                              ],
                            ),
                            child: Text(
                              'Sudut: ${_calculateAngle(anglePoints).toStringAsFixed(1)}°',
                              style: const TextStyle(
                                color: Colors.purple,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
                // MARKER CLUSTER & MARKER POHON/PLOT SELALU DI PALING ATAS
                MarkerClusterLayerWidget(
                  options: MarkerClusterLayerOptions(
                    maxClusterRadius: 45,
                    size: const Size(35, 35),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(40),
                    maxZoom: 30,
                    markers: allMarkers,
                    spiderfyCluster: false,
                    zoomToBoundsOnClick: true,
                    builder: (context, markers) {
                      return Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: Colors.blue,
                        ),
                        child: Center(
                          child: Text(
                            markers.length.toString(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                RichAttributionWidget(
                  attributions: [
                    TextSourceAttribution(
                      'OpenStreetMap contributors',
                      onTap:
                          () => launchUrl(
                            Uri.parse('https://openstreetmap.org/copyright'),
                          ),
                    ),
                  ],
                ),
              ],
            ),
            // TOOLS BUTTONS COLUMN
            Positioned(
              left: 16,
              bottom: 32,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Kompas
                  FloatingActionButton(
                    mini: true,
                    heroTag: 'toggle_mapmode',
                    backgroundColor: Colors.white,
                    onPressed: () {
                      _toggleMapStyle();
                    },
                    tooltip: 'Ganti mode peta',
                    child: const Icon(Icons.map, color: Colors.green),
                  ),
                  const SizedBox(height: 16),
                  // Kompas
                  FloatingActionButton(
                    mini: true,
                    heroTag: 'compass',
                    backgroundColor: Colors.white,
                    onPressed: () {
                      _mapController.rotate(0);
                    },
                    tooltip: 'Kembalikan ke utara',
                    child: const Icon(Icons.explore, color: Colors.blue),
                  ),
                  const SizedBox(height: 16),
                  // Toggle label
                  FloatingActionButton(
                    mini: true,
                    heroTag: 'toggle_label',
                    backgroundColor:
                        showLabels ? Colors.orange : Colors.grey[300],
                    onPressed: () async {
                      setState(() {
                        showLabels = !showLabels;
                      });
                      await loadMarkers();
                    },
                    tooltip:
                        showLabels ? 'Sembunyikan Label' : 'Tampilkan Label',
                    child: Icon(
                      showLabels ? Icons.visibility : Icons.visibility_off,
                      color: showLabels ? Colors.white : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Tools utama (expand/collapse)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FloatingActionButton(
                        mini: true,
                        heroTag: 'main_tools',
                        backgroundColor: Colors.black,
                        onPressed: () {
                          setState(() {
                            showTools = !showTools;
                          });
                        },
                        tooltip: 'Tools',
                        child: Icon(
                          showTools ? Icons.close : Icons.build,
                          color: Colors.white,
                        ),
                      ),
                      if (showTools) ...[
                        const SizedBox(height: 12),
                        // Toggle tools layer
                        FloatingActionButton(
                          mini: true,
                          heroTag: 'toggle_tools_layer',
                          backgroundColor:
                              showToolsLayer ? Colors.teal : Colors.grey[300],
                          onPressed: () {
                            setState(() {
                              showToolsLayer = !showToolsLayer;
                            });
                          },
                          tooltip:
                              showToolsLayer
                                  ? 'Sembunyikan Tools di Peta'
                                  : 'Tampilkan Tools di Peta',
                          child: Icon(
                            showToolsLayer ? Icons.layers : Icons.layers_clear,
                            color:
                                showToolsLayer ? Colors.white : Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Penggaris
                        FloatingActionButton(
                          mini: true,
                          heroTag: 'ruler',
                          backgroundColor:
                              isMeasuring ? Colors.red : Colors.white,
                          onPressed: () {
                            setState(() {
                              if (!isMeasuring) {
                                _finishArea();
                                _finishAngle();
                                isMeasuringArea = false;
                                isMeasuringAngle = false;
                                isAddingPoint = false;
                              } else {
                                _finishRuler();
                              }
                              isMeasuring = !isMeasuring;
                            });
                          },
                          tooltip: 'Ukur jarak',
                          child: Icon(
                            Icons.straighten,
                            color: isMeasuring ? Colors.white : Colors.red,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Pin
                        FloatingActionButton(
                          mini: true,
                          heroTag: 'add_point',
                          backgroundColor:
                              isAddingPoint ? Colors.deepPurple : Colors.white,
                          onPressed: () {
                            setState(() {
                              _finishRuler();
                              _finishArea();
                              _finishAngle();
                              isMeasuring = false;
                              isMeasuringArea = false;
                              isMeasuringAngle = false;
                              isAddingPoint = !isAddingPoint;
                            });
                          },
                          tooltip: 'Tambah titik di peta',
                          child: Icon(
                            Icons.add_location_alt,
                            color:
                                isAddingPoint
                                    ? Colors.white
                                    : Colors.deepPurple,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Area
                        FloatingActionButton(
                          mini: true,
                          heroTag: 'area',
                          backgroundColor:
                              isMeasuringArea ? Colors.green : Colors.white,
                          onPressed: () {
                            setState(() {
                              if (!isMeasuringArea) {
                                _finishRuler();
                                _finishAngle();
                                isMeasuring = false;
                                isMeasuringAngle = false;
                                isAddingPoint = false;
                              } else {
                                _finishArea();
                              }
                              isMeasuringArea = !isMeasuringArea;
                            });
                          },
                          tooltip: 'Ukur area',
                          child: Icon(
                            Icons.crop_square,
                            color:
                                isMeasuringArea ? Colors.white : Colors.green,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Busur sudut
                        FloatingActionButton(
                          mini: true,
                          heroTag: 'angle',
                          backgroundColor:
                              isMeasuringAngle ? Colors.purple : Colors.white,
                          onPressed: () {
                            setState(() {
                              if (!isMeasuringAngle) {
                                _finishRuler();
                                _finishArea();
                                isMeasuring = false;
                                isMeasuringArea = false;
                                isAddingPoint = false;
                              } else {
                                _finishAngle();
                              }
                              isMeasuringAngle = !isMeasuringAngle;
                            });
                          },
                          tooltip: 'Ukur sudut (busur)',
                          child: Icon(
                            Icons.architecture,
                            color:
                                isMeasuringAngle ? Colors.white : Colors.purple,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Hapus semua tools
                        FloatingActionButton(
                          mini: true,
                          heroTag: 'clear_tools',
                          backgroundColor: Colors.black,
                          onPressed: () {
                            setState(() {
                              _resetAllTools();
                              _deactivateAllTools();
                            });
                          },
                          tooltip: 'Hapus semua tools',
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
