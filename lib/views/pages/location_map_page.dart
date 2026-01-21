import 'package:azimutree/views/widgets/core_widget/appbar_widget.dart';
import 'package:azimutree/views/widgets/core_widget/background_app_widget.dart';
import 'package:azimutree/views/widgets/location_map_widget/bottomsheet_location_map_widget.dart';
import 'package:azimutree/views/widgets/location_map_widget/mapbox_widget.dart';
import 'package:azimutree/views/widgets/core_widget/sidebar_widget.dart';
import 'package:azimutree/views/widgets/location_map_widget/suggestion_searchbar_widget.dart';
import 'package:azimutree/views/widgets/location_map_widget/map_legend_widget.dart';
import 'package:azimutree/views/widgets/location_map_widget/marker_info_widget.dart';
import 'package:flutter/material.dart';
import 'package:azimutree/data/notifiers/notifiers.dart';

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
        appBar: AppbarWidget(
          title: "Peta Lokasi Cluster Plot",
          extraActions: [
            Builder(
              builder: (ctx) {
                return IconButton(
                  tooltip: 'Tools',
                  icon: const Icon(Icons.tune),
                  onPressed: () => Scaffold.of(ctx).openEndDrawer(),
                );
              },
            ),
          ],
        ),
        drawer: SidebarWidget(),
        endDrawerEnableOpenDragGesture: false,
        endDrawer: Drawer(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Map Tools',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Tooltip(
                    message: 'Nyalakan/Matikan klik marker',
                    child: Row(
                      children: [
                        const Icon(Icons.touch_app),
                        const SizedBox(width: 8),
                        const Expanded(child: Text('Klik marker')),
                        ValueListenableBuilder<bool>(
                          valueListenable: isMarkerActivationEnabledNotifier,
                          builder: (context, enabled, child) {
                            return Switch(
                              value: enabled,
                              onChanged:
                                  (v) =>
                                      isMarkerActivationEnabledNotifier.value =
                                          v,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Tooltip(
                    message: 'Tampilkan / Sembunyikan legenda di peta',
                    child: Row(
                      children: [
                        const Icon(Icons.list),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text('Tampilkan legenda di peta'),
                        ),
                        ValueListenableBuilder<bool>(
                          valueListenable: isMapLegendVisibleNotifier,
                          builder: (context, visible, child) {
                            return Switch(
                              value: visible,
                              onChanged:
                                  (v) => isMapLegendVisibleNotifier.value = v,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Inspection workflow toggle
                  Tooltip(
                    message: 'Aktifkan workflow inspeksi lapangan',
                    child: Row(
                      children: [
                        const Icon(Icons.checklist),
                        const SizedBox(width: 8),
                        const Expanded(child: Text('Workflow inspeksi')),
                        ValueListenableBuilder<bool>(
                          valueListenable: isInspectionWorkflowEnabledNotifier,
                          builder: (context, enabled, child) {
                            return Switch(
                              value: enabled,
                              onChanged:
                                  (v) =>
                                      isInspectionWorkflowEnabledNotifier
                                          .value = v,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        body: Stack(
          alignment: Alignment.topCenter,
          children: [
            //* Background App
            BackgroundAppWidget(
              lightBackgroundImage: "assets/images/light-bg-plain.png",
              darkBackgroundImage: "assets/images/dark-bg-plain.png",
            ),
            MapboxWidget(),
            // Top row: legend (optional) and marker info. Marker info
            // expands to fill the remaining width between the legend
            // and the right edge.
            ValueListenableBuilder<bool>(
              valueListenable: isMapLegendVisibleNotifier,
              builder: (context, visible, child) {
                return Positioned(
                  // Restore previous vertical offset so the card sits above
                  // the camera zoom indicators. Use full width between left
                  // and right margins so legend + marker info consume width.
                  top: 35,
                  left: 12,
                  right: 12,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (visible) const MapLegendWidget(),
                      if (visible) const SizedBox(width: 8),
                      // Marker info takes the remaining space
                      const Expanded(child: MarkerInfoWidget()),
                    ],
                  ),
                );
              },
            ),
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
