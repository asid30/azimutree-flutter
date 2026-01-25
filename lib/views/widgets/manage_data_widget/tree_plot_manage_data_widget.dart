import 'package:azimutree/data/models/cluster_model.dart';
import 'package:azimutree/data/models/plot_model.dart';
import 'package:azimutree/data/models/tree_model.dart';
import 'package:azimutree/data/notifiers/notifiers.dart';
import 'package:azimutree/data/notifiers/tree_notifier.dart';
import 'package:azimutree/views/widgets/manage_data_widget/dialog_edit_tree_widget.dart';
import 'package:azimutree/views/widgets/alert_dialog_widget/alert_confirmation_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:azimutree/services/gdrive_thumbnail_service.dart';

class TreePlotManageDataWidget extends StatelessWidget {
  final int plotId;
  final List<TreeModel> treeData;
  final List<PlotModel> plots;
  final List<ClusterModel> clusters;
  final TreeNotifier treeNotifier;

  const TreePlotManageDataWidget({
    super.key,
    required this.plotId,
    required this.treeData,
    required this.plots,
    required this.clusters,
    required this.treeNotifier,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isLightModeNotifier,
      builder: (context, isLightMode, child) {
        final isDark = !isLightMode;

        final treesForPlot =
            treeData.where((tree) => tree.plotId == plotId).toList();

        if (treesForPlot.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: Text(
              "Belum ada data pohon untuk plot ini",
              style: TextStyle(color: isDark ? Colors.white : null),
            ),
          );
        }

        return Column(
          children:
              treesForPlot.map((tree) {
                String? nama = tree.namaPohon?.trim();
                String? ilmiah = tree.namaIlmiah?.trim();

                String titleText;

                if ((nama?.isNotEmpty ?? false) &&
                    (ilmiah?.isNotEmpty ?? false)) {
                  titleText = "$nama ($ilmiah)";
                } else if (nama?.isNotEmpty ?? false) {
                  titleText = nama!;
                } else if (ilmiah?.isNotEmpty ?? false) {
                  titleText = ilmiah!;
                } else {
                  titleText = "Pohon ${tree.kodePohon}";
                }

                final subtitleText = "Kode pohon: ${tree.kodePohon}";
                final hasImage =
                    tree.urlFoto != null && tree.urlFoto!.isNotEmpty;
                final hasLocation =
                    tree.latitude != null && tree.longitude != null;
                final heroTag =
                    'tree_photo_${tree.id ?? '${tree.plotId}_${tree.kodePohon}'}_${tree.urlFoto?.hashCode ?? 0}';

                final List<TableRow> tableRows = [];
                if (hasImage) {
                  tableRows.add(
                    TableRow(
                      children: [
                        SizedBox(
                          width: 120,
                          height: 120,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  _openTreePhotoPreview(context, tree, heroTag);
                                },
                                child: Hero(
                                  tag: heroTag,
                                  child: _buildTreeImage(tree),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 120),
                      ],
                    ),
                  );
                }

                tableRows.addAll([
                  _row(
                    "Azimut",
                    tree.azimut != null
                        ? "${tree.azimut!.toStringAsFixed(1)}°"
                        : "-",
                  ),
                  _row(
                    "Jarak dari pusat",
                    tree.jarakPusatM != null
                        ? "${tree.jarakPusatM!.toStringAsFixed(2)} m"
                        : "-",
                  ),
                  _row(
                    "Latitude",
                    tree.latitude != null
                        ? tree.latitude!.toStringAsFixed(6)
                        : "-",
                  ),
                  _row(
                    "Longitude",
                    tree.longitude != null
                        ? tree.longitude!.toStringAsFixed(6)
                        : "-",
                  ),
                  _row(
                    "Altitude",
                    tree.altitude != null ? "${tree.altitude} m" : "-",
                  ),
                  if (tree.keterangan != null && tree.keterangan!.isNotEmpty)
                    _row("Keterangan", tree.keterangan!),
                ]);

                return Slidable(
                  key: ValueKey("tree_${tree.id ?? tree.kodePohon}_$plotId"),
                  startActionPane: ActionPane(
                    motion: const DrawerMotion(),
                    extentRatio: 0.33,
                    children: [
                      SlidableAction(
                        onPressed: (_) => _editTree(context, tree),
                        backgroundColor: Colors.blue.shade100,
                        foregroundColor:
                            isDark
                                ? const Color.fromARGB(255, 219, 219, 219)
                                : Colors.blue.shade900,
                        icon: Icons.edit,
                        label: "Edit",
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ],
                  ),
                  endActionPane: ActionPane(
                    motion: const DrawerMotion(),
                    extentRatio: 0.33,
                    children: [
                      SlidableAction(
                        onPressed: (_) => _deleteTree(context, tree),
                        backgroundColor: Colors.red.shade100,
                        foregroundColor:
                            isDark
                                ? const Color.fromARGB(255, 215, 83, 83)
                                : Colors.red.shade900,
                        icon: Icons.delete,
                        label: "Hapus",
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ],
                  ),
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    color:
                        isDark
                            ? const Color.fromARGB(255, 36, 67, 42)
                            : const Color.fromARGB(238, 211, 236, 215),
                    child: Theme(
                      data: ThemeData().copyWith(
                        dividerColor: Colors.transparent,
                      ),
                      child: ExpansionTile(
                        tilePadding: const EdgeInsets.symmetric(horizontal: 12),
                        title: Text(
                          titleText,
                          style: TextStyle(color: isDark ? Colors.white : null),
                        ),
                        subtitle: Text(
                          subtitleText,
                          style: TextStyle(
                            color: isDark ? Colors.white70 : null,
                          ),
                        ),
                        children: [
                          const Divider(height: 1, color: Colors.transparent),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12.0,
                              vertical: 8,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Table(
                                  columnWidths: const {
                                    0: FlexColumnWidth(2),
                                    1: FlexColumnWidth(3),
                                  },
                                  defaultVerticalAlignment:
                                      TableCellVerticalAlignment.middle,
                                  children: tableRows,
                                ),
                                if (hasLocation) ...[
                                  const SizedBox(height: 10),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: OutlinedButton.icon(
                                      onPressed:
                                          () =>
                                              _trackTreeLocation(context, tree),
                                      icon: const Icon(Icons.my_location),
                                      label: Text(
                                        'Tracking Data',
                                        style: TextStyle(
                                          color: isDark ? Colors.white : null,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
        );
      },
    );
  }

  TableRow _row(String label, String value) {
    // will be rebuilt inside ValueListenableBuilder; determine current mode
    final isDark = !isLightModeNotifier.value;
    final style = TextStyle(color: isDark ? Colors.white : null);

    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2, right: 4),
          child: Text(label, style: style),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(": $value", style: style),
        ),
      ],
    );
  }

  Widget _buildTreeImage(TreeModel tree, {BoxFit fit = BoxFit.cover}) {
    final url = tree.urlFoto!;
    final resolved = GDriveThumbnailService.toThumbnailUrl(url);

    // (debug prints removed)

    return CachedNetworkImage(
      imageUrl: resolved,
      fit: fit,
      placeholder:
          (context, _) => const Center(
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ),
      errorWidget:
          (context, _, __) =>
              const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
    );
  }

  void _openTreePhotoPreview(
    BuildContext context,
    TreeModel tree,
    String heroTag,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (_) => _TreePhotoPreviewPage(
              imageUrl: GDriveThumbnailService.toThumbnailUrl(tree.urlFoto!),
              heroTag: heroTag,
            ),
      ),
    );
  }

  void _trackTreeLocation(BuildContext context, TreeModel tree) {
    if (tree.latitude == null || tree.longitude == null) return;

    selectedPageNotifier.value = 'location_map_page';
    // Navigating to the map to track a tree is not a search result selection.
    selectedLocationFromSearchNotifier.value = false;
    // Disable following the user's live location so the map centers on the tree.
    isFollowingUserLocationNotifier.value = false;
    // Preserve the current zoom level when centering (same as tapping a marker).
    preserveZoomOnNextCenterNotifier.value = true;
    // Make the tree the selected tree so the map will render it as active
    // and trigger the dashed connection to the plot center.
    selectedTreeNotifier.value = tree;
    selectedLocationNotifier.value = Position(tree.longitude!, tree.latitude!);
    Navigator.pushNamed(context, 'location_map_page');
  }

  Future<void> _editTree(BuildContext context, TreeModel tree) async {
    final updated = await showDialog<TreeModel>(
      context: context,
      builder:
          (_) => DialogEditTreeWidget(
            tree: tree,
            clusters: clusters,
            plots: plots,
            treeNotifier: treeNotifier,
          ),
    );

    if (updated != null && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Data pohon diperbarui")));
    }
  }

  Future<void> _deleteTree(BuildContext context, TreeModel tree) async {
    if (tree.id == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertConfirmationWidget(
            title: 'Hapus pohon?',
            message: 'Data pohon akan dihapus permanen.',
            confirmText: 'Hapus',
            cancelText: 'Batal',
          ),
    );
    if (confirm != true) return;
    await treeNotifier.deleteTree(tree.id!);

    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Pohon dihapus")));
    }
  }
}

class _TreePhotoPreviewPage extends StatelessWidget {
  final String imageUrl;
  final String heroTag;

  const _TreePhotoPreviewPage({required this.imageUrl, required this.heroTag});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => Navigator.of(context).pop(),
          child: Center(
            child: InteractiveViewer(
              minScale: 1.0,
              maxScale: 5.0,
              child: Hero(
                tag: heroTag,
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.contain,
                  placeholder:
                      (context, _) => const Center(
                        child: SizedBox(
                          width: 36,
                          height: 36,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        ),
                      ),
                  errorWidget:
                      (context, _, __) => const Icon(
                        Icons.broken_image,
                        color: Colors.white70,
                        size: 48,
                      ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
