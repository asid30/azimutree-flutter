import 'package:azimutree/views/widgets/manage_data_widget/tree_plot_manage_data_widget.dart';
import 'package:flutter/material.dart';

class PlotClusterManageDataWidget extends StatelessWidget {
  const PlotClusterManageDataWidget({super.key});

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
          Text(
            "Data Plot",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Theme(
            data: ThemeData().copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              title: Text("Plot 1"),
              subtitle: Table(
                columnWidths: const {
                  0: FlexColumnWidth(2),
                  1: FlexColumnWidth(3),
                },
                children: [
                  TableRow(children: [Text("Latitude"), Text(": -5.493510")]),
                  TableRow(children: [Text("Longitude"), Text(": 105.143400")]),
                  TableRow(children: [Text("Altitude"), Text(": 50 m")]),
                  TableRow(children: [Text("Total Pohon"), Text(": 25")]),
                ],
              ),
              tilePadding: EdgeInsets.zero,
              children: [TreePlotManageDataWidget()],
            ),
          ),
          SizedBox(height: 8),
        ],
      ),
    );
  }
}
