import 'package:azimutree/views/widgets/core_widget/appbar_widget.dart';
import 'package:azimutree/views/widgets/core_widget/background_app_widget.dart';
import 'package:azimutree/views/widgets/location_map_widget/bottomsheet_location_map_widget.dart';
import 'package:azimutree/views/widgets/location_map_widget/mapbox_widget.dart';
import 'package:azimutree/views/widgets/core_widget/sidebar_widget.dart';
import 'package:azimutree/views/widgets/location_map_widget/suggestion_searchbar_widget.dart';
import 'package:azimutree/views/widgets/location_map_widget/map_legend_widget.dart';
import 'package:flutter/material.dart';

class LocationMapPage extends StatefulWidget {
  const LocationMapPage({super.key});

  @override
  State<LocationMapPage> createState() => _LocationMapPageState();
}

class _LocationMapPageState extends State<LocationMapPage> {
  bool defaultStyleMap = true;

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
          alignment: Alignment.topCenter,
          children: [
            //* Background App
            BackgroundAppWidget(
              lightBackgroundImage: "assets/images/light-bg-plain.png",
              darkBackgroundImage: "assets/images/dark-bg-plain.png",
            ),
            MapboxWidget(),
            Positioned(top: 35, left: 12, child: MapLegendWidget()),
            SuggestionSearchbarWidget(),
            Align(
              alignment: Alignment.bottomCenter,
              child: BottomsheetLocationMapWidget(),
            ),
          ],
        ),
      ),
    );
  }
}
