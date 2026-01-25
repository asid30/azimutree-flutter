import 'package:azimutree/data/notifiers/cluster_notifier.dart';
import 'package:azimutree/data/notifiers/notifiers.dart';
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
  late final DraggableScrollableController _draggableController;

  @override
  void initState() {
    super.initState();
    clusterNotifier = ClusterNotifier();
    plotNotifier = PlotNotifier();
    treeNotifier = TreeNotifier();
    _draggableController = DraggableScrollableController();
    clusterNotifier.loadClusters();
    plotNotifier.loadPlots();
    treeNotifier.loadTrees();
  }

  @override
  void dispose() {
    clusterNotifier.dispose();
    plotNotifier.dispose();
    treeNotifier.dispose();
    _draggableController.dispose();
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
              child: ValueListenableBuilder<bool>(
                valueListenable: isLightModeNotifier,
                builder: (context, isLight, child) {
                  final content = Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          ValueListenableBuilder<bool>(
                            valueListenable: isLightModeNotifier,
                            builder: (context, isLight, child) {
                              return BackButton(
                                color: isLight ? null : Colors.white,
                                onPressed: () {
                                  Navigator.popAndPushNamed(context, "home");
                                },
                              );
                            },
                          ),
                          ValueListenableBuilder<bool>(
                            valueListenable: isLightModeNotifier,
                            builder: (context, isLight, child) {
                              return Text(
                                "Kembali",
                                style: TextStyle(
                                  fontSize: 18,
                                  color: isLight ? null : Colors.white,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      ValueListenableBuilder(
                        valueListenable: clusterNotifier,
                        builder: (context, clusterData, child) {
                          final clusters = clusterData; // List<ClusterModel>
                          final hasCluster = clusters.isNotEmpty;
                          final clusterOptions =
                              clusters
                                  .map((cluster) => cluster.kodeCluster)
                                  .toList();

                          return Column(
                            children: [
                              // Dropdown tetap sama, karena sudah pakai selectedDropdownClusterNotifier
                              ValueListenableBuilder<bool>(
                                valueListenable: isLightModeNotifier,
                                builder: (context, isLightMode, _) {
                                  final isDark = !isLightMode;
                                  return Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.fromLTRB(
                                      12,
                                      10,
                                      12,
                                      6,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          isDark
                                              ? const Color.fromARGB(
                                                255,
                                                36,
                                                67,
                                                42,
                                              )
                                              : DropdownManageDataWidget
                                                  .defaultBackgroundColor,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Pilih Klaster",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color:
                                                isDark
                                                    ? Colors.white
                                                    : Colors.black,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        DropdownManageDataWidget(
                                          clusterOptions: clusterOptions,
                                          isEmpty: clusterOptions.isEmpty,
                                          embedded: true,
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 8),

                              ValueListenableBuilder(
                                valueListenable: plotNotifier,
                                builder: (context, plotData, _) {
                                  return ValueListenableBuilder(
                                    valueListenable: treeNotifier,
                                    builder: (context, treeData, __) {
                                      return SelectedClusterManageDataWidget(
                                        clustersData: clusters,
                                        plotData: plotData,
                                        treeData: treeData,
                                        clusterNotifier: clusterNotifier,
                                        plotNotifier: plotNotifier,
                                        treeNotifier: treeNotifier,
                                      );
                                    },
                                  );
                                },
                              ),
                              const SizedBox(height: 8),

                              if (hasCluster)
                                // 🔥 Dengarkan dropdown pilihan klaster
                                ValueListenableBuilder<String?>(
                                  valueListenable:
                                      selectedDropdownClusterNotifier,
                                  builder: (context, selectedKodeCluster, _) {
                                    // Cari cluster yang cocok dengan kode yang dipilih
                                    final selectedCluster = clusters.firstWhere(
                                      (c) =>
                                          c.kodeCluster == selectedKodeCluster,
                                      orElse: () => clusters.first,
                                    );

                                    return ValueListenableBuilder(
                                      valueListenable: plotNotifier,
                                      builder: (context, plotData, child) {
                                        final plots =
                                            plotData; // List<PlotModel>

                                        // 💡 Filter plot berdasarkan idCluster dari cluster terpilih
                                        final plotsForSelectedCluster =
                                            plots
                                                .where(
                                                  (plot) =>
                                                      plot.idCluster ==
                                                      selectedCluster.id,
                                                )
                                                .toList();

                                        return ValueListenableBuilder(
                                          valueListenable: treeNotifier,
                                          builder: (context, treeData, child) {
                                            return PlotClusterManageDataWidget(
                                              plotData: plotsForSelectedCluster,
                                              treeData: treeData,
                                              clustersData: clusters,
                                              plotNotifier: plotNotifier,
                                              treeNotifier: treeNotifier,
                                              isEmpty:
                                                  plotsForSelectedCluster
                                                      .isEmpty,
                                            );
                                          },
                                        );
                                      },
                                    );
                                  },
                                ),
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: 8),
                      const SizedBox(height: 70),
                    ],
                  );

                  if (isLight) return content;

                  // Dark mode: force text to white for this page's content (icons unchanged)
                  return DefaultTextStyle(
                    style: const TextStyle(color: Colors.white),
                    child: content,
                  );
                },
              ),
            ),

            BottomsheetManageDataWidget(
              clusterNotifier: clusterNotifier,
              plotNotifier: plotNotifier,
              treeNotifier: treeNotifier,
              draggableController: _draggableController,
            ),
          ],
        ),
        floatingActionButton: ValueListenableBuilder<bool>(
          valueListenable: isLightModeNotifier,
          builder: (context, isLight, _) {
            final isDark = !isLight;
            return FloatingActionButton(
              backgroundColor:
                  isDark
                      ? const Color.fromARGB(255, 19, 41, 23)
                      : const Color(0xFF1F4226),
              foregroundColor: Colors.white,
              onPressed: () {
                // expand bottom sheet to near-fullscreen
                _draggableController.animateTo(
                  0.9,
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutCubic,
                );
              },
              child: const Icon(Icons.menu_open),
            );
          },
        ),
      ),
    );
  }
}
