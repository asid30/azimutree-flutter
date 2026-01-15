import 'package:azimutree/data/global_variables/logger_global.dart';
import 'package:azimutree/data/notifiers/notifiers.dart';
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

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
              onTap: () {
                logger.i(
                  "Selected place: $place\n${place["longitude"]} ${place["latitude"]}",
                );
                // Mark this selection as originating from a search so the
                // map shows the search-result marker.
                selectedLocationFromSearchNotifier.value = true;
                selectedLocationNotifier.value = Position(
                  double.parse(place["longitude"]),
                  double.parse(place["latitude"]),
                );
                userInputSearchBarNotifier.value = "";
              },
            );
          },
        ),
      );
    }
  }
}
