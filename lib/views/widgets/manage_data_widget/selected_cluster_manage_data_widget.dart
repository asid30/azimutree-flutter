import 'package:flutter/material.dart';

class SelectedClusterManageDataWidget extends StatelessWidget {
  const SelectedClusterManageDataWidget({super.key});

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
            "Data Cluster",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Table(
            columnWidths: const {0: FlexColumnWidth(2), 1: FlexColumnWidth(3)},
            children: const [
              TableRow(children: [Text("Kode Klaster"), Text(": ABC123")]),
              TableRow(children: [Text("Pengukur"), Text(": Budi")]),
              TableRow(
                children: [Text("Tanggal Pengukuran"), Text(": 27-09-2025")],
              ),
              TableRow(children: [Text("Total Plot"), Text(": 4")]),
              TableRow(children: [Text("Total Pohon"), Text(": 100")]),
            ],
          ),
        ],
      ),
    );
  }
}
