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
      child: Theme(
        data: ThemeData().copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(
            "Data Klaster",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          tilePadding: EdgeInsets.zero,
          subtitle: Table(
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
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              spacing: 10,
              children: [
                IconButton(
                  icon: Icon(Icons.travel_explore),
                  tooltip: "Lihat di Peta",
                  onPressed: () {},
                ),
                IconButton(
                  icon: Icon(Icons.add_location_alt),
                  tooltip: "Tambah Data Baru",
                  onPressed: () {},
                ),
                IconButton(
                  icon: Icon(Icons.edit),
                  tooltip: "Edit Data Cluster",
                  onPressed: () {},
                ),
                IconButton(
                  icon: Icon(
                    Icons.delete,
                    color: Color.fromARGB(255, 131, 30, 23),
                  ),
                  tooltip: "Hapus Data Cluster",
                  onPressed: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
