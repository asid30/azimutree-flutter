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

class LocationMapPage extends StatefulWidget {
  const LocationMapPage({super.key});

  @override
  State<LocationMapPage> createState() => _LocationMapPageState();
}

class _LocationMapPageState extends State<LocationMapPage> {
  final _tileProvider = FMTCTileProvider(
    stores: const {'mapStore': BrowseStoreStrategy.readUpdateCreate},
  );
  List<Marker> allMarkers = [];

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
    final pohons = await DatabaseHelper.instance.pohonDao.getAllPohons();

    List<Marker> markers = [];

    // Tambahkan marker untuk setiap plot
    for (var plot in plots) {
      markers.add(
        Marker(
          point: LatLng(plot.latitude, plot.longitude),
          child: const Icon(Icons.location_on, color: Colors.blue, size: 28),
        ),
      );
    }

    // Tambahkan marker untuk setiap pohon (jika punya lat & long)
    for (var pohon in pohons) {
      if (pohon.latitude != null && pohon.longitude != null) {
        markers.add(
          Marker(
            point: LatLng(pohon.latitude!, pohon.longitude!),
            child: const Icon(Icons.forest, color: Colors.green, size: 24),
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
        if (didPop) {
          return;
        }
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
              options: MapOptions(
                initialCenter: LatLng(-5.055531, 105.249231),
                initialZoom: 9.2,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.heavysnack.azimutree',
                  tileProvider: _tileProvider,
                ),
                MarkerLayer(markers: allMarkers),
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
          ],
        ),
      ),
    );
  }
}
