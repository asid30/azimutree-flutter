import 'package:azimutree/data/notifiers/notifiers.dart';
import 'package:azimutree/views/widgets/appbar_widget.dart';
import 'package:azimutree/views/widgets/background_app_widget.dart';
import 'package:azimutree/views/widgets/dropdown_manage_data_widget.dart';
import 'package:azimutree/views/widgets/sidebar_widget.dart';
import 'package:flutter/material.dart';

class ManageDataPage extends StatefulWidget {
  const ManageDataPage({super.key});

  @override
  State<ManageDataPage> createState() => _ManageDataPageState();
}

class _ManageDataPageState extends State<ManageDataPage> {
  final List<String> clusterOptions = [
    "Cluster A",
    "Cluster B",
    "Cluster C",
    "Cluster D",
  ];

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
        appBar: AppbarWidget(title: "Kelola Data Cluster Plot"),
        drawer: SidebarWidget(),
        body: Stack(
          alignment: Alignment.topCenter,
          children: [
            //* Background App
            BackgroundAppWidget(
              lightBackgroundImage: "assets/images/light-bg-notitle.png",
              darkBackgroundImage: "assets/images/dark-bg-notitle.png",
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      BackButton(
                        onPressed: () {
                          Navigator.popAndPushNamed(context, "home");
                        },
                      ),
                      const Text("Kembali", style: TextStyle(fontSize: 18)),
                    ],
                  ),
                  DropdownManageDataWidget(clusterOptions: clusterOptions),
                  ValueListenableBuilder(
                    valueListenable: selectedDropdownClusterNotifier,
                    builder: (context, value, child) {
                      return Row(
                        children: [
                          Text(
                            "(Debug) Cluster terpilih: $value",
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
