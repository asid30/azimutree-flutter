import 'package:azimutree/data/global_variables/logger_global.dart';
import 'package:flutter/material.dart';
import 'package:azimutree/data/notifiers/notifiers.dart';

class SuggestionSearchbarWidget extends StatelessWidget {
  SuggestionSearchbarWidget({super.key});

  // Dummy list of cities for demonstration
  final List<Map<String, String>> _cities = [
    {"id": "1", "name": "Jakarta"},
    {"id": "2", "name": "Bandung"},
    {"id": "3", "name": "Surabaya"},
    {"id": "4", "name": "Medan"},
    {"id": "5", "name": "Lampung"},
    {"id": "6", "name": "Palembang"},
    {"id": "7", "name": "Gorontalo"},
    {"id": "8", "name": "Makasar"},
    {"id": "9", "name": "Banten"},
    {"id": "10", "name": "Aceh"},
    {"id": "11", "name": "Papua"},
    {"id": "12", "name": "Maluku"},
    {"id": "13", "name": "Metro"},
    {"id": "14", "name": "Kemiling"},
  ];

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: userInputSearchBarNotifier,
      builder: (context, userInputSearchBar, child) {
        if (userInputSearchBar.isEmpty) {
          return const SizedBox();
        }
        final filteredCities =
            _cities
                .where(
                  (city) => city["name"]!.toLowerCase().contains(
                    userInputSearchBar.toLowerCase(),
                  ),
                )
                .toList();
        if (filteredCities.isEmpty) {
          return Container(
            color: Colors.white,
            width: double.infinity,
            height: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  title: Text(
                    "Hasil Pencarian: ",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text("\"$userInputSearchBar\""),
                ),
                Divider(),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text("Tidak ada hasil ditemukan."),
                ),
                SizedBox(height: 150),
              ],
            ),
          );
        }
        return Container(
          color: Colors.white,
          width: double.infinity,
          height: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                title: Text(
                  "Hasil Pencarian: ",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text("\"$userInputSearchBar\""),
              ),
              Divider(),
              Expanded(
                child: ListView.builder(
                  itemCount: filteredCities.length,
                  shrinkWrap: true,
                  itemBuilder: (context, index) {
                    final city = filteredCities[index];
                    return ListTile(
                      title: Text(city["name"]!),
                      onTap: () {
                        logger.i("Kamu pilih: ${city["name"]}");
                      },
                    );
                  },
                ),
              ),
              SizedBox(height: 150),
            ],
          ),
        );
      },
    );
  }
}
