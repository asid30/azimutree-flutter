import 'package:azimutree/data/notifiers.dart';
import 'package:azimutree/views/widgets/menu_button_widget.dart';
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Center(
          heightFactor: 3,
          child: ValueListenableBuilder(
            valueListenable: isLightModeNotifier,
            builder: (context, isLightMode, child) {
              return Image(
                image: AssetImage(
                  isLightMode
                      ? "assets/images/light-title.png"
                      : "assets/images/dark-title.png",
                ),
                fit: BoxFit.cover,
                width: 250,
              );
            },
          ),
        ),
        ValueListenableBuilder(
          valueListenable: selectedPageNotifier,
          builder: (context, selectedPage, child) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: 220),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      MenuButtonWidget(
                        label: "Scan\nKode Label",
                        icon: Icons.photo_camera,
                        onPressed: () {
                          selectedPageNotifier.value = "scan_label_page";
                        },
                      ),
                      MenuButtonWidget(
                        label: "Kelola\nData Sampel",
                        icon: Icons.storage,
                        onPressed: () {
                          selectedPageNotifier.value = "manage_data_page";
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      MenuButtonWidget(
                        label: "Peta Lokasi\nCluster Plot",
                        icon: Icons.map,
                        onPressed: () {
                          selectedPageNotifier.value = "location_map_page";
                        },
                      ),
                      MenuButtonWidget(
                        label: "Panduan\nAplikasi",
                        icon: Icons.book,
                        onPressed: () {
                          selectedPageNotifier.value = "tutorial_page";
                        },
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
