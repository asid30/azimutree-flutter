import 'package:azimutree/data/global_variables/logger_global.dart';
import 'package:azimutree/data/notifiers/notifiers.dart';
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:azimutree/data/database/plot_dao.dart';
import 'package:azimutree/data/database/cluster_dao.dart';

class SuggestionBodyWidget extends StatelessWidget {
  final bool isSearching;
  final List<Map<String, dynamic>> results;

  const SuggestionBodyWidget({
    super.key,
    required this.isSearching,
    required this.results,
  });

  @override
  Widget build(BuildContext context) {
    if (isSearching) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(),
        ),
      );
    } else if (results.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text("Tidak ada hasil ditemukan."),
        ),
      );
    } else {
      return Expanded(
        child: ListView.builder(
          itemCount: results.length,
          itemBuilder: (context, index) {
            final place = results[index];
            return ListTile(
              title: Text(place["name"] ?? ""),
              subtitle: Text("${place["longitude"]} ${place["latitude"]}"),
              onTap: () async {
                logger.i(
                  "Selected place: $place\n${place["longitude"]} ${place["latitude"]}",
                );
                // Clear any existing marker selection so the search action
                // starts from a clean state (previous plot/tree selection
                // should not linger after user searches).
                selectedTreeNotifier.value = null;
                selectedPlotNotifier.value = null;
                // If this is a cluster/plot local result, resolve DB models
                // and set selectedPlotNotifier so the UI shows the plot
                // details. Otherwise fallback to generic map location.
                final type = place['type'] as String?;
                selectedLocationFromSearchNotifier.value = true;
                try {
                  if (type == 'plot' || type == 'cluster') {
                    final plotId = place['plotId'] as int?;
                    if (plotId != null) {
                      final plot = await PlotDao.getPlotById(plotId);
                      if (plot != null) {
                        selectedPlotNotifier.value = plot;
                        try {
                          final cl = await ClusterDao.getClusterById(
                            plot.idCluster,
                          );
                          selectedPlotClusterNotifier.value = cl;
                        } catch (_) {
                          selectedPlotClusterNotifier.value = null;
                        }
                        // Ensure we stop following live location so the
                        // search result marker can be displayed (the map
                        // hides the search marker while following user).
                        isFollowingUserLocationNotifier.value = false;
                        // Center map on the plot
                        selectedLocationNotifier.value = Position(
                          plot.longitude,
                          plot.latitude,
                        );
                        userInputSearchBarNotifier.value = "";
                        return;
                      }
                    }
                  }
                } catch (e) {
                  logger.w('Suggestion selection DB resolve failed: $e');
                }

                // Fallback: generic place coordinate (Mapbox).
                // Also disable follow-to-user so the search marker can show.
                try {
                  isFollowingUserLocationNotifier.value = false;
                  selectedLocationNotifier.value = Position(
                    double.parse(place["longitude"].toString()),
                    double.parse(place["latitude"].toString()),
                  );
                } catch (_) {}
                userInputSearchBarNotifier.value = "";
              },
            );
          },
        ),
      );
    }
  }
}
