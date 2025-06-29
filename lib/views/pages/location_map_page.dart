import 'package:azimutree/data/notifiers/notifiers.dart';
import 'package:azimutree/views/widgets/appbar_widget.dart';
import 'package:azimutree/views/widgets/sidebar_widget.dart';
import 'package:flutter/material.dart';

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

class LocationMapPage extends StatefulWidget {
  const LocationMapPage({super.key});

  @override
  State<LocationMapPage> createState() => _LocationMapPageState();
}

class _LocationMapPageState extends State<LocationMapPage> {
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
            SingleChildScrollView(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      BackButton(
                        onPressed: () {
                          Navigator.popAndPushNamed(context, "home");
                        },
                      ),
                      const Text("Kembali", style: TextStyle(fontSize: 18)),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black54, width: 1.0),
                      ),
                      width: double.infinity,
                      height: 450,
                      child: FlutterMap(
                        options: MapOptions(
                          initialCenter: LatLng(
                            -5.055531,
                            105.249231,
                          ), // Center the map over Bandar Lampung
                          initialZoom: 9.2,
                        ),
                        children: [
                          TileLayer(
                            // Bring your own tiles
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png', // For demonstration only
                            userAgentPackageName:
                                'com.heavysnack.azimutree', // Add your app identifier
                            // And many more recommended properties!
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: LatLng(-5.055531, 105.249231),
                                child: Icon(
                                  Icons.location_on,
                                  color: Colors.black,
                                  size: 25.0,
                                ),
                              ),
                            ],
                          ),
                          RichAttributionWidget(
                            // Include a stylish prebuilt attribution widget that meets all requirments
                            attributions: [
                              TextSourceAttribution(
                                'OpenStreetMap contributors',
                                onTap:
                                    () => launchUrl(
                                      Uri.parse(
                                        'https://openstreetmap.org/copyright',
                                      ),
                                    ), // (external)
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Color(0xFF1F4226),
                            minimumSize: Size(120, 75),
                            maximumSize: Size(175, 120),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.refresh, size: 30),
                              Text("Refresh", textAlign: TextAlign.center),
                            ],
                          ),
                        ),
                      ],
                    ),
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
