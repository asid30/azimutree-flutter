import 'package:azimutree/data/notifiers/cluster_notifier.dart';
import 'package:azimutree/data/notifiers/plot_notifier.dart';
import 'package:azimutree/data/notifiers/tree_notifier.dart';
import 'package:azimutree/views/widgets/core_widget/appbar_widget.dart';
import 'package:azimutree/views/widgets/core_widget/background_app_widget.dart';
import 'package:azimutree/views/widgets/manage_data_widget/bottomsheet_manage_data_widget.dart';
import 'package:azimutree/views/widgets/manage_data_widget/plot_cluster_manage_data_widget.dart';
import 'package:azimutree/views/widgets/manage_data_widget/selected_cluster_manage_data_widget.dart';
import 'package:azimutree/views/widgets/manage_data_widget/dropdown_manage_data_widget.dart';
import 'package:azimutree/views/widgets/core_widget/sidebar_widget.dart';
import 'package:flutter/material.dart';

class ManageDataPage extends StatefulWidget {
  const ManageDataPage({super.key});

  @override
  State<ManageDataPage> createState() => _ManageDataPageState();
}

class _ManageDataPageState extends State<ManageDataPage> {
  late final ClusterNotifier clusterNotifier;
  late final PlotNotifier plotNotifier;
  late final TreeNotifier treeNotifier;

  @override
  void initState() {
    super.initState();
    clusterNotifier = ClusterNotifier();
    plotNotifier = PlotNotifier();
    treeNotifier = TreeNotifier();
    clusterNotifier.loadClusters();
    plotNotifier.loadPlots();
    treeNotifier.loadTrees();
  }

  @override
  void dispose() {
    clusterNotifier.dispose();
    plotNotifier.dispose();
    treeNotifier.dispose();
    super.dispose();
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
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 0,
                ),
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
                    ValueListenableBuilder(
                      valueListenable: clusterNotifier,
                      builder: (context, clusterData, child) {
                        final clusterOptions =
                            clusterData
                                .map((cluster) => cluster.kodeCluster)
                                .toList();
                        return Column(
                          children: [
                            DropdownManageDataWidget(
                              clusterOptions: clusterOptions,
                              isEmpty: clusterOptions.isEmpty,
                            ),
                            SizedBox(height: 12),
                            SelectedClusterManageDataWidget(
                              clustersData: clusterData,
                            ),
                          ],
                        );
                      },
                    ),
                    SizedBox(height: 12),
                    ValueListenableBuilder(
                      valueListenable: plotNotifier,
                      builder: (context, plotData, child) {
                        return PlotClusterManageDataWidget();
                      },
                    ),
                    SizedBox(height: 80),
                  ],
                ),
              ),
            ),
            BottomsheetManageDataWidget(
              clusterNotifier: clusterNotifier,
              plotNotifier: plotNotifier,
              treeNotifier: treeNotifier,
            ),
          ],
        ),
      ),
    );
  }
}
