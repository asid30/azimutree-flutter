//* Homepages
import 'package:azimutree/data/notifiers/notifiers.dart';
import 'package:azimutree/views/widgets/appbar_widget.dart';
import 'package:azimutree/views/widgets/background_app_widget.dart';
import 'package:azimutree/views/widgets/menu_button_widget.dart';
import 'package:azimutree/views/widgets/sidebar_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          final shouldExit = await showDialog<bool>(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: Text("Keluar Aplikasi"),
                  content: Text("Apa kamu yakin mau keluar?"),
                  backgroundColor: Colors.lightGreen.shade200,
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text("Cancel"),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text("Exit"),
                    ),
                  ],
                ),
          );
          if (shouldExit == true && context.mounted) {
            SystemNavigator.pop();
          }
        }
      },
      child: Scaffold(
        appBar: AppbarWidget(title: "Home"),
        drawer: SidebarWidget(),
        body: Stack(
          alignment: Alignment.topCenter,
          children: [
            //* Background App
            BackgroundAppWidget(),
            //* Content
            Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ValueListenableBuilder(
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
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        MenuButtonWidget(
                          label: "Scan\nKode Label",
                          icon: Icons.photo_camera,
                          onPressed: () {
                            Navigator.popAndPushNamed(
                              context,
                              "scan_label_page",
                            );
                          },
                        ),
                        MenuButtonWidget(
                          label: "Kelola Data\nCluster Plot",
                          icon: Icons.storage,
                          onPressed: () {
                            Navigator.popAndPushNamed(
                              context,
                              "manage_data_page",
                            );
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
                            Navigator.popAndPushNamed(
                              context,
                              "location_map_page",
                            );
                          },
                        ),
                        MenuButtonWidget(
                          label: "Panduan\nAplikasi",
                          icon: Icons.book,
                          onPressed: () {
                            Navigator.popAndPushNamed(context, "tutorial_page");
                          },
                        ),
                      ],
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
