import 'package:azimutree/data/models/cluster_model.dart';
import 'package:azimutree/data/models/plot_model.dart';
import 'package:azimutree/data/models/tree_model.dart';
import 'package:azimutree/data/notifiers/tree_notifier.dart';
import 'package:azimutree/views/widgets/manage_data_widget/dialog_edit_tree_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

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
    final treesForPlot =
        treeData.where((tree) => tree.plotId == plotId).toList();

    if (treesForPlot.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
        child: Text("Belum ada data pohon untuk plot ini"),
      );
    }

    return Column(
      children: treesForPlot.map((tree) {
        String? nama = tree.namaPohon?.trim();
        String? ilmiah = tree.namaIlmiah?.trim();

        String titleText;

        if ((nama?.isNotEmpty ?? false) && (ilmiah?.isNotEmpty ?? false)) {
          titleText = "$nama ($ilmiah)";
        } else if (nama?.isNotEmpty ?? false) {
          titleText = nama!;
        } else if (ilmiah?.isNotEmpty ?? false) {
          titleText = ilmiah!;
        } else {
          titleText = "Pohon ${tree.kodePohon}";
        }

        final subtitleText = "Kode pohon: ${tree.kodePohon}";
        final hasImage = tree.urlFoto != null && tree.urlFoto!.isNotEmpty;

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
                    child: _buildTreeImage(tree),
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
            tree.azimut != null ? "${tree.azimut!.toStringAsFixed(1)}°" : "-",
          ),
          _row(
            "Jarak dari pusat",
            tree.jarakPusatM != null ? "${tree.jarakPusatM!.toStringAsFixed(2)} m" : "-",
          ),
          _row(
            "Latitude",
            tree.latitude != null ? tree.latitude!.toStringAsFixed(6) : "-",
          ),
          _row(
            "Longitude",
            tree.longitude != null ? tree.longitude!.toStringAsFixed(6) : "-",
          ),
          _row(
            "Altitude",
            tree.altitude != null ? "${tree.altitude} m" : "-",
          ),
          if (tree.keterangan != null && tree.keterangan!.isNotEmpty)
            _row("Keterangan", tree.keterangan!),
        ]);

        return Dismissible(
          key: ValueKey("tree_${tree.id ?? tree.kodePohon}_$plotId"),
          background: _swipeBackground(
            alignment: Alignment.centerLeft,
            color: Colors.blue.shade100,
            icon: Icons.edit,
            text: "Edit",
          ),
          secondaryBackground: _swipeBackground(
            alignment: Alignment.centerRight,
            color: Colors.red.shade100,
            icon: Icons.delete,
            text: "Hapus",
          ),
          confirmDismiss: (direction) async {
            if (direction == DismissDirection.startToEnd) {
              await _editTree(context, tree);
              return false;
            } else {
              await _deleteTree(context, tree);
              return false;
            }
          },
          child: Card(
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            color: const Color.fromARGB(240, 180, 216, 187),
            child: Theme(
              data: ThemeData().copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 12),
                title: Text(titleText),
                subtitle: Text(subtitleText),
                children: [
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
                    child: Table(
                      columnWidths: const {
                        0: FlexColumnWidth(2),
                        1: FlexColumnWidth(3),
                      },
                      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                      children: tableRows,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  TableRow _row(String label, String value) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2, right: 4),
          child: Text(label),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(": $value"),
        ),
      ],
    );
  }

  Widget _buildTreeImage(TreeModel tree) {
    final url = tree.urlFoto!;

    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (context, _) => const Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      ),
      errorWidget: (context, _, __) => const Center(
        child: Icon(Icons.broken_image, color: Colors.grey),
      ),
    );
  }

  Future<void> _editTree(BuildContext context, TreeModel tree) async {
    final updated = await showDialog<TreeModel>(
      context: context,
      builder: (_) => DialogEditTreeWidget(
        tree: tree,
        clusters: clusters,
        plots: plots,
        treeNotifier: treeNotifier,
      ),
    );

    if (updated != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Data pohon diperbarui")),
      );
    }
  }

  Future<void> _deleteTree(BuildContext context, TreeModel tree) async {
    if (tree.id == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Hapus pohon?"),
        content: const Text("Data pohon akan dihapus permanen."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Hapus"),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await treeNotifier.deleteTree(tree.id!);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pohon dihapus")),
      );
    }
  }

  Widget _swipeBackground({
    required Alignment alignment,
    required Color color,
    required IconData icon,
    required String text,
  }) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: color,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.black54),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
