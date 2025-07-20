//* visualization & mapping of cluster page
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

class LocationMapPage extends StatefulWidget {
  const LocationMapPage({super.key});

  @override
  State<LocationMapPage> createState() => _LocationMapPageState();
}

class _LocationMapPageState extends State<LocationMapPage> {
  final _tileProvider = FMTCTileProvider(
    stores: const {'mapStore': BrowseStoreStrategy.readUpdateCreate},
  );
  final MapController _mapController = MapController();
  List<Marker> allMarkers = [];

  bool isMeasuring = false;
  List<LatLng> measurePoints = [];

  bool isAddingPoint = false;
  List<LatLng> userPoints = [];

  bool isMeasuringArea = false;
  List<LatLng> areaPoints = [];

  bool showLabels = true;

  @override
  void initState() {
    super.initState();
    loadMarkers();
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

    // add marker for each plot
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

    // add marker for each tree (if has lat & long)
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
                  if (isMeasuring) {
                    setState(() {
                      if (measurePoints.length >= 2) {
                        measurePoints.clear();
                      }
                      measurePoints.add(latlng);
                    });
                  } else if (isMeasuringArea) {
                    setState(() {
                      areaPoints.add(latlng);
                    });
                  } else if (isAddingPoint) {
                    setState(() {
                      userPoints.add(latlng);
                    });
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.heavysnack.azimutree',
                  tileProvider: _tileProvider,
                ),
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
                          color: Color(0xFF1F4226),
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
                // Garis pengukuran
                if (measurePoints.length == 2)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: measurePoints,
                        color: Colors.red,
                        strokeWidth: 4,
                      ),
                    ],
                  ),
                // Marker titik pengukuran
                MarkerLayer(
                  markers:
                      measurePoints
                          .map(
                            (point) => Marker(
                              point: point,
                              width: 30,
                              height: 30,
                              child: const Icon(
                                Icons.circle,
                                color: Colors.red,
                                size: 18,
                              ),
                            ),
                          )
                          .toList(),
                ),
                // Marker titik custom user
                MarkerLayer(
                  markers:
                      userPoints
                          .map(
                            (point) => Marker(
                              point: point,
                              width: 36,
                              height: 36,
                              child: const Icon(
                                Icons.add_location_alt,
                                color: Colors.deepPurple,
                                size: 30,
                              ),
                            ),
                          )
                          .toList(),
                ),
                // Tampilkan jarak jika dua titik
                if (measurePoints.length == 2)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(
                          (measurePoints[0].latitude +
                                  measurePoints[1].latitude) /
                              2,
                          (measurePoints[0].longitude +
                                  measurePoints[1].longitude) /
                              2,
                        ),
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
                            '${Distance().as(LengthUnit.Kilometer, measurePoints[0], measurePoints[1]).toStringAsFixed(2)} km',
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                // Polygon area measurement
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
                // Marker titik area
                if (isMeasuringArea)
                  MarkerLayer(
                    markers:
                        areaPoints
                            .map(
                              (point) => Marker(
                                point: point,
                                width: 28,
                                height: 28,
                                child: const Icon(
                                  Icons.circle,
                                  color: Colors.green,
                                  size: 18,
                                ),
                              ),
                            )
                            .toList(),
                  ),
                // Tampilkan luas area jika lebih dari 2 titik
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
            // Button kompas
            Positioned(
              bottom: 48,
              right: 16,
              child: FloatingActionButton(
                mini: true,
                heroTag: 'compass',
                backgroundColor: Colors.white,
                onPressed: () {
                  _mapController.rotate(0);
                },
                tooltip: 'Kembalikan ke utara',
                child: const Icon(Icons.explore, color: Colors.blue),
              ),
            ),
            // Button penggaris
            Positioned(
              bottom: 112,
              right: 16,
              child: FloatingActionButton(
                mini: true,
                heroTag: 'ruler',
                backgroundColor: isMeasuring ? Colors.red : Colors.white,
                onPressed: () {
                  setState(() {
                    isMeasuring = !isMeasuring;
                    if (isMeasuring) isAddingPoint = false;
                    measurePoints.clear();
                  });
                },
                tooltip: 'Ukur jarak',
                child: Icon(
                  Icons.straighten,
                  color: isMeasuring ? Colors.white : Colors.red,
                ),
              ),
            ),
            // Button tambah titik
            Positioned(
              bottom: 176,
              right: 16,
              child: FloatingActionButton(
                mini: true,
                heroTag: 'add_point',
                backgroundColor:
                    isAddingPoint ? Colors.deepPurple : Colors.white,
                onPressed: () {
                  setState(() {
                    isAddingPoint = !isAddingPoint;
                    if (isAddingPoint) isMeasuring = false;
                  });
                },
                tooltip: 'Tambah titik di peta',
                child: Icon(
                  Icons.add_location_alt,
                  color: isAddingPoint ? Colors.white : Colors.deepPurple,
                ),
              ),
            ),
            // Button area
            Positioned(
              bottom: 240,
              right: 16,
              child: FloatingActionButton(
                mini: true,
                heroTag: 'area',
                backgroundColor: isMeasuringArea ? Colors.green : Colors.white,
                onPressed: () {
                  setState(() {
                    isMeasuringArea = !isMeasuringArea;
                    if (isMeasuringArea) {
                      isMeasuring = false;
                      isAddingPoint = false;
                    }
                    areaPoints.clear();
                  });
                },
                tooltip: 'Ukur area',
                child: Icon(
                  Icons.crop_square,
                  color: isMeasuringArea ? Colors.white : Colors.green,
                ),
              ),
            ),
            // Tombol toggle label di pojok kanan atas
            Positioned(
              bottom: 304,
              right: 16,
              child: FloatingActionButton(
                mini: true,
                heroTag: 'toggle_label',
                backgroundColor: showLabels ? Colors.orange : Colors.grey[300],
                onPressed: () async {
                  setState(() {
                    showLabels = !showLabels;
                  });
                  await loadMarkers();
                },
                tooltip: showLabels ? 'Sembunyikan Label' : 'Tampilkan Label',
                child: Icon(
                  showLabels ? Icons.visibility : Icons.visibility_off,
                  color: showLabels ? Colors.white : Colors.black54,
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
    // Konversi derajat ke meter persegi (approx, untuk area kecil)
    // 1 derajat lat ~ 111.32 km, 1 derajat lon ~ 111.32*cos(lat) km
    // Untuk hasil lebih akurat gunakan library geodesic, ini cukup untuk visualisasi
    final lat = points[0].latitude * (3.141592653589793 / 180.0);
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
}
