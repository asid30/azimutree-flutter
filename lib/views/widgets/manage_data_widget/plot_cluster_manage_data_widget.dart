import 'package:azimutree/data/models/plot_model.dart';
import 'package:azimutree/data/models/tree_model.dart';
import 'package:azimutree/views/widgets/manage_data_widget/tree_plot_manage_data_widget.dart';
import 'package:flutter/material.dart';

class PlotClusterManageDataWidget extends StatelessWidget {
  final List<PlotModel> plotData;
  final List<TreeModel> treeData;
  final bool isEmpty; // true = klaster ini tidak punya plot

  const PlotClusterManageDataWidget({
    super.key,
    required this.plotData,
    required this.treeData,
    this.isEmpty = false,
  });

  @override
  Widget build(BuildContext context) {
    // Kalau dari parent sudah dibilang klaster ini tidak punya plot,
    // langsung tampilkan pesan dan jangan render list plot sama sekali.
    if (isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: const Color.fromARGB(240, 180, 216, 187),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Data Plot",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text("Tidak ada data plot untuk klaster ini"),
          ],
        ),
      );
    }

    // Fallback: kalau isEmpty == false tapi plotData kosong (just in case)
    if (plotData.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: const Color.fromARGB(240, 180, 216, 187),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Data Plot",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text("Tidak ada data plot untuk klaster ini"),
          ],
        ),
      );
    }

    // Normal case: ada plot untuk klaster ini
    final sortedPlotData = [...plotData]
      ..sort((a, b) => a.kodePlot.compareTo(b.kodePlot));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: const Color.fromARGB(240, 180, 216, 187),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Data Plot",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          for (final plot in sortedPlotData) ...[
            Theme(
              data: ThemeData().copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                title: Text("Plot ${plot.kodePlot}"),
                subtitle: Table(
                  columnWidths: const {
                    0: FlexColumnWidth(2),
                    1: FlexColumnWidth(3),
                  },
                  children: [
                    _row("Latitude", plot.latitude.toStringAsFixed(6)),
                    _row("Longitude", plot.longitude.toStringAsFixed(6)),
                    _row(
                      "Altitude",
                      plot.altitude != null ? "${plot.altitude} m" : "-",
                    ),
                    _row(
                      "Jumlah Pohon",
                      plot.id != null
                          ? treeData
                              .where((tree) => tree.plotId == plot.id)
                              .length
                              .toString()
                          : "0",
                    ),
                  ],
                ),
                tilePadding: EdgeInsets.zero,
                children: [
                  if (plot.id != null)
                    TreePlotManageDataWidget(
                      plotId: plot.id!,
                      treeData: treeData,
                    )
                  else
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text("ID plot tidak tersedia"),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  TableRow _row(String label, String value) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 0),
          child: Text(label),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 0),
          child: Text(": $value"),
        ),
      ],
    );
  }
}
