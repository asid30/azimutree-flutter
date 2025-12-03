import 'package:azimutree/data/models/tree_model.dart';
import 'package:flutter/material.dart';

class TreePlotManageDataWidget extends StatelessWidget {
  final int plotId;
  final List<TreeModel> treeData;

  const TreePlotManageDataWidget({
    super.key,
    required this.plotId,
    required this.treeData,
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
      children:
          treesForPlot.map((tree) {
            // TITLE: Nama Pohon (Nama Ilmiah)
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

            // SUBTITLE: Kode pohon
            final subtitleText = "Kode pohon: ${tree.kodePohon}";

            final hasImage = tree.urlFoto != null && tree.urlFoto!.isNotEmpty;

            // Table Rows
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
                tree.latitude != null ? tree.latitude!.toStringAsFixed(6) : "-",
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

            return ExpansionTile(
              title: Text(titleText),
              subtitle: Text(subtitleText),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
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

    return Image.network(
      url,
      fit: BoxFit.cover,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) return child;

        if (frame == null) {
          return const Center(
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          );
        }
        return AnimatedOpacity(
          opacity: 1,
          duration: const Duration(milliseconds: 250),
          child: child,
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return const Center(
          child: Icon(Icons.broken_image, color: Colors.grey),
        );
      },
    );
  }
}
