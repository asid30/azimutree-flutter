import 'package:azimutree/data/models/plot_model.dart';
import 'package:azimutree/views/widgets/manage_data_widget/tree_plot_manage_data_widget.dart';
import 'package:flutter/material.dart';

class PlotClusterManageDataWidget extends StatelessWidget {
  final List<PlotModel> plotData;

  const PlotClusterManageDataWidget({super.key, required this.plotData});

  @override
  Widget build(BuildContext context) {
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

          if (plotData.isEmpty)
            const Text("Tidak ada data plot untuk klaster ini"),
          // kalau ada isi → generate ExpansionTile per plot
          for (final plot in plotData) ...[
            Theme(
              data: ThemeData().copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                title: Text(
                  "Plot ${plot.kodePlot}", // atau "Plot ${plot.id}" terserah kamu
                ),
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
                  ],
                ),
                tilePadding: EdgeInsets.zero,
                children: [
                  // ⬇️ kirim identitas plot ke widget pohon
                  if (plot.id != null)
                    TreePlotManageDataWidget(plotId: plot.id!)
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
