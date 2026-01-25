import 'package:azimutree/views/widgets/core_widget/appbar_widget.dart';
import 'package:azimutree/views/widgets/core_widget/background_app_widget.dart';
import 'package:azimutree/views/widgets/location_map_widget/bottomsheet_location_map_widget.dart';
import 'package:azimutree/views/widgets/location_map_widget/mapbox_widget.dart';
import 'package:azimutree/views/widgets/core_widget/sidebar_widget.dart';
import 'package:azimutree/views/widgets/location_map_widget/suggestion_searchbar_widget.dart';
import 'package:azimutree/views/widgets/location_map_widget/map_legend_widget.dart';
import 'package:azimutree/views/widgets/location_map_widget/marker_info_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:azimutree/data/notifiers/notifiers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationMapPage extends StatefulWidget {
  const LocationMapPage({super.key});

  @override
  State<LocationMapPage> createState() => _LocationMapPageState();
}

class _LocationMapPageState extends State<LocationMapPage> {
  bool defaultStyleMap = true;
  final GlobalKey _legendKey = GlobalKey();
  double? _legendWidth;

  // Helper widget: persistent toggle row for the end-drawer that
  // shows a Tooltip until the user dismisses it. Dismissal is
  // persisted via SharedPreferences under the provided key.
  // This is defined as an inner class to keep usage local.

  Widget _endDrawerToggleRow({
    required String prefKey,
    required String tooltipMessage,
    required Icon icon,
    required String title,
    required String subtitle,
    required ValueListenable<bool> valueListenable,
    required ValueChanged<bool> onChanged,
  }) {
    return _EndDrawerToggleRow(
      prefKey: prefKey,
      tooltipMessage: tooltipMessage,
      icon: icon,
      title: title,
      subtitle: subtitle,
      valueListenable: valueListenable,
      onChanged: onChanged,
    );
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
        appBar: AppbarWidget(
          title: "Peta Lokasi Cluster Plot",
          extraActions: [
            Builder(
              builder: (ctx) {
                return IconButton(
                  tooltip: 'Tools',
                  icon: const Icon(Icons.tune),
                  onPressed: () {
                    try {
                      FocusManager.instance.primaryFocus?.unfocus();
                    } catch (_) {}
                    try {
                      isSearchFieldFocusedNotifier.value = false;
                    } catch (_) {}
                    Scaffold.of(ctx).openEndDrawer();
                  },
                );
              },
            ),
          ],
        ),
        drawer: SidebarWidget(),
        endDrawerEnableOpenDragGesture: false,
        endDrawer: ValueListenableBuilder<bool>(
          valueListenable: isLightModeNotifier,
          builder: (context, isLightMode, _) {
            final isDark = !isLightMode;
            return Drawer(
              backgroundColor:
                  isDark
                      ? const Color(0xFF1F4226)
                      : Color.fromARGB(255, 205, 237, 211),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Map Tools',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color:
                                  isDark
                                      ? const Color(0xFFC1FF72)
                                      : Colors.black,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _endDrawerToggleRow(
                        prefKey: 'enddrawer_tooltip_marker_click_dismissed',
                        tooltipMessage: 'Nyalakan/Matikan klik marker',
                        icon: const Icon(Icons.touch_app),
                        title: 'Klik marker',
                        subtitle:
                            'Aktifkan untuk memilih marker dengan menahan sebentar',
                        valueListenable: isMarkerActivationEnabledNotifier,
                        onChanged:
                            (v) => isMarkerActivationEnabledNotifier.value = v,
                      ),
                      const SizedBox(height: 12),
                      _endDrawerToggleRow(
                        prefKey: 'enddrawer_tooltip_legend_dismissed',
                        tooltipMessage:
                            'Tampilkan / Sembunyikan legenda di peta',
                        icon: const Icon(Icons.list),
                        title: 'Tampilkan legenda di peta',
                        subtitle:
                            'Menampilkan keterangan warna marker di pojok kiri atas',
                        valueListenable: isMapLegendVisibleNotifier,
                        onChanged: (v) => isMapLegendVisibleNotifier.value = v,
                      ),
                      const SizedBox(height: 12),
                      _endDrawerToggleRow(
                        prefKey: 'enddrawer_tooltip_marker_info_dismissed',
                        tooltipMessage:
                            'Tampilkan kartu info saat marker dipilih',
                        icon: const Icon(Icons.info_outline),
                        title: 'Tampilkan info marker',
                        subtitle:
                            'Tampilkan kartu informasi saat marker dipilih di peta',
                        valueListenable: isMarkerInfoOnSelectNotifier,
                        onChanged:
                            (v) => isMarkerInfoOnSelectNotifier.value = v,
                      ),
                      const SizedBox(height: 12),
                      _endDrawerToggleRow(
                        prefKey: 'enddrawer_tooltip_inspection_dismissed',
                        tooltipMessage: 'Aktifkan workflow inspeksi lapangan',
                        icon: const Icon(Icons.checklist),
                        title: 'Workflow inspeksi',
                        subtitle:
                            'Aktifkan untuk menandai pohon sebagai "Done" saat inspeksi',
                        valueListenable: isInspectionWorkflowEnabledNotifier,
                        onChanged:
                            (v) =>
                                isInspectionWorkflowEnabledNotifier.value = v,
                      ),
                      const SizedBox(height: 12),
                      const SizedBox(height: 12),
                      _endDrawerToggleRow(
                        prefKey:
                            'enddrawer_tooltip_tree_to_plot_lines_dismissed',
                        tooltipMessage:
                            'Tampilkan garis dari pohon ke pusat plot',
                        icon: const Icon(Icons.show_chart),
                        title: 'Tampilkan garis pohon → plot',
                        subtitle:
                            'Garis bantu dari tiap pohon menuju pusat plot',
                        valueListenable: isTreeToPlotLineVisibleNotifier,
                        onChanged:
                            (v) => isTreeToPlotLineVisibleNotifier.value = v,
                      ),
                      const SizedBox(height: 12),
                      _endDrawerToggleRow(
                        prefKey:
                            'enddrawer_tooltip_plot_to_plot_lines_dismissed',
                        tooltipMessage: 'Tampilkan garis penghubung antar plot',
                        icon: const Icon(Icons.linear_scale),
                        title: 'Tampilkan garis plot → plot',
                        subtitle: 'Tampilkan koneksi antar plot jika tersedia',
                        valueListenable: isPlotToPlotLineVisibleNotifier,
                        onChanged:
                            (v) => isPlotToPlotLineVisibleNotifier.value = v,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
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
                if (visible) {
                  // Measure legend width after layout and store it in state.
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    final ctx = _legendKey.currentContext;
                    final w = ctx?.size?.width;
                    if (w != null && w != _legendWidth) {
                      setState(() {
                        _legendWidth = w;
                      });
                    }
                  });

                  // Provide the measured legend width to MarkerInfoWidget so
                  // it uses the same width without relying on intrinsics.
                  final markerWidth =
                      _legendWidth ??
                      (MediaQuery.of(context).size.width * 0.45).clamp(
                        200.0,
                        MediaQuery.of(context).size.width,
                      );

                  return Positioned(
                    top: 35,
                    left: 12,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Attach key to legend so we can measure it.
                        Container(
                          key: _legendKey,
                          child: const MapLegendWidget(),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: markerWidth,
                          child: const MarkerInfoWidget(),
                        ),
                      ],
                    ),
                  );
                }

                // Legend hidden: give MarkerInfo a reasonable finite width.
                final defaultWidth = (MediaQuery.of(context).size.width * 0.45)
                    .clamp(200.0, MediaQuery.of(context).size.width);
                return Positioned(
                  top: 35,
                  left: 12,
                  child: SizedBox(
                    width: defaultWidth,
                    child: const MarkerInfoWidget(),
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

class _EndDrawerToggleRow extends StatefulWidget {
  final String prefKey;
  final String tooltipMessage;
  final Icon icon;
  final String title;
  final String subtitle;
  final ValueListenable<bool> valueListenable;
  final ValueChanged<bool> onChanged;

  const _EndDrawerToggleRow({
    required this.prefKey,
    required this.tooltipMessage,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.valueListenable,
    required this.onChanged,
  });

  @override
  State<_EndDrawerToggleRow> createState() => _EndDrawerToggleRowState();
}

class _EndDrawerToggleRowState extends State<_EndDrawerToggleRow> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPref();
  }

  Future<void> _loadPref() async {
    final prefs = await SharedPreferences.getInstance();
    final valueKey = '${widget.prefKey}_value';
    final persistedValue = prefs.getBool(valueKey);
    if (!mounted) return;
    setState(() {
      _loading = false;
    });
    // If a persisted toggle value exists, apply it to the provided
    // ValueListenable by calling the onChanged callback so the global
    // notifier is updated accordingly.
    if (persistedValue != null) {
      widget.onChanged(persistedValue);
    }
  }

  Future<void> _persistValue(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    final valueKey = '${widget.prefKey}_value';
    await prefs.setBool(valueKey, v);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox.shrink();
    return ValueListenableBuilder<bool>(
      valueListenable: isLightModeNotifier,
      builder: (context, isLightMode, _) {
        final isDark = !isLightMode;

        final row = Row(
          children: [
            Icon(
              widget.icon.icon,
              color: isDark ? Colors.white : const Color(0xFF1F4226),
              size: widget.icon.size,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.title,
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF1F4226),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            ValueListenableBuilder<bool>(
              valueListenable: widget.valueListenable,
              builder: (context, enabled, child) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Switch(
                      activeTrackColor:
                          isDark
                              ? const Color(0xFFC1FF72)
                              : const Color(0xFF1F4226),
                      activeThumbColor:
                          isDark
                              ? const Color(0xFF1F4226)
                              : Color.fromARGB(255, 205, 237, 211),
                      value: enabled,
                      onChanged: (v) {
                        // Persist and propagate the change
                        _persistValue(v);
                        widget.onChanged(v);
                      },
                    ),
                  ],
                );
              },
            ),
          ],
        );

        return Tooltip(message: widget.tooltipMessage, child: row);
      },
    );
  }
}
