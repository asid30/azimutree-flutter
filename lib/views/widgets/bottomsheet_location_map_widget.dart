import 'package:azimutree/data/notifiers/notifiers.dart';
import 'package:azimutree/views/widgets/searchbar_bottomsheet_widget.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

class BottomsheetLocationMapWidget extends StatelessWidget {
  const BottomsheetLocationMapWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 8),
          SearchbarBottomsheetWidget(),
          ValueListenableBuilder(
            valueListenable: selectedMenuBottomSheetNotifier,
            builder: (context, selectedMenuBottomSheet, child) {
              return NavigationBar(
                selectedIndex: selectedMenuBottomSheet,
                onDestinationSelected: (value) {
                  selectedMenuBottomSheetNotifier.value = value;
                },
                destinations: [
                  NavigationDestination(
                    icon: Icon(Icons.map_outlined),
                    selectedIcon: Icon(Icons.map),
                    label: 'Medan',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.terrain_outlined),
                    selectedIcon: Icon(Icons.terrain),
                    label: 'Satelit',
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {},
                        icon: Icon(Icons.my_location),
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: Transform.rotate(
                          angle:
                              -45 *
                              math.pi /
                              180, // rotasi -45 derajat biar ke utara
                          child: Icon(Icons.explore_outlined),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
