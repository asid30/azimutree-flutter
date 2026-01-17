//* Homepages
import 'package:azimutree/data/notifiers/notifiers.dart';
import 'package:azimutree/views/widgets/core_widget/appbar_widget.dart';
import 'package:azimutree/views/widgets/core_widget/background_app_widget.dart';
import 'package:azimutree/views/widgets/core_widget/menu_button_widget.dart';
import 'package:azimutree/views/widgets/core_widget/sidebar_widget.dart';
import 'package:azimutree/views/widgets/core_widget/small_menu_button_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:azimutree/views/widgets/alert_dialog_widget/alert_confirmation_widget.dart';

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
                (context) => AlertConfirmationWidget(
                  title: 'Keluar Aplikasi',
                  message: 'Apa kamu yakin mau keluar?',
                  confirmText: 'Exit',
                  cancelText: 'Cancel',
                  // keep default background color from the widget
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 10),
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
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.625,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.max,
                    children: [
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
                      const SizedBox(height: 10),
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
                      const SizedBox(height: 10),
                      MenuButtonWidget(
                        label: "Panduan\nAplikasi",
                        icon: Icons.book,
                        onPressed: () {
                          Navigator.popAndPushNamed(context, "tutorial_page");
                        },
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SmallMenuButtonWidget(
                            icon: Icons.settings,
                            onPressed: () {
                              Navigator.pushNamed(context, 'settings_page');
                            },
                          ),
                          SmallMenuButtonWidget(
                            icon: Icons.info,
                            onPressed: () {
                              Navigator.pushNamed(context, 'about_page');
                            },
                          ),
                          SmallMenuButtonWidget(
                            icon: Icons.exit_to_app,
                            onPressed: () {
                              showDialog<bool>(
                                context: context,
                                builder:
                                    (context) => AlertConfirmationWidget(
                                      title: 'Keluar Aplikasi',
                                      message: 'Apa kamu yakin mau keluar?',
                                      confirmText: 'Exit',
                                      cancelText: 'Cancel',
                                    ),
                              ).then((shouldExit) {
                                if (shouldExit == true && context.mounted) {
                                  SystemNavigator.pop();
                                }
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
