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
          ExpansionTile(
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
                    icon: Icon(Icons.delete, color: Colors.red),
                    tooltip: "Hapus Data Plot",
                    onPressed: () {},
                  ),
                ],
              ),
              ExpansionTile(
                title: Text("Pohon 1"),
                subtitle: Table(
                  columnWidths: const {
                    0: FlexColumnWidth(2),
                    1: FlexColumnWidth(3),
                  },
                  children: const [
                    TableRow(
                      children: [Text("Jenis Pohon"), Text(": Pohon Akasia")],
                    ),
                    TableRow(children: [Text("Latitude"), Text(": -5.493510")]),
                    TableRow(
                      children: [Text("Longitude"), Text(": 105.143400")],
                    ),
                    TableRow(
                      children: [Text("Jarak dari pusat"), Text(": 0 m")],
                    ),
                    TableRow(children: [Text("Altitude"), Text(": 50 m")]),
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
                        icon: Icon(Icons.edit),
                        tooltip: "Edit Data Pohon",
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        tooltip: "Hapus Data Pohon",
                        onPressed: () {},
                      ),
                    ],
                  ),
                ],
              ),
              ListTile(title: Text("Pohon 2"), subtitle: Text("Pohon Pale")),
              ListTile(title: Text("Pohon 3"), subtitle: Text("Pohon Jengkol")),
              ListTile(title: Text("Pohon 4"), subtitle: Text("Pohon Kelapa")),
              ListTile(title: Text("Pohon 5"), subtitle: Text("Pohon Jati")),
            ],
          ),
          SizedBox(height: 8),
          ExpansionTile(
            title: Text("Plot 2"),
            subtitle: Table(
              columnWidths: const {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(3),
              },
              children: const [
                TableRow(children: [Text("Latitude"), Text(": -5.493510")]),
                TableRow(children: [Text("Longitude"), Text(": 105.143410")]),
                TableRow(children: [Text("Altitude"), Text(": 50 m")]),
                TableRow(children: [Text("Total Pohon"), Text(": 25")]),
              ],
            ),
            tilePadding: EdgeInsets.zero,
            children: [
              ListTile(title: Text("Pohon 1"), subtitle: Text("Pohon Akasia")),
              ListTile(title: Text("Pohon 2"), subtitle: Text("Pohon Pale")),
              ListTile(title: Text("Pohon 3"), subtitle: Text("Pohon Jengkol")),
              ListTile(title: Text("Pohon 4"), subtitle: Text("Pohon Kelapa")),
              ListTile(title: Text("Pohon 5"), subtitle: Text("Pohon Jati")),
            ],
          ),
          SizedBox(height: 8),
          ExpansionTile(
            title: Text("Plot 3"),
            subtitle: Table(
              columnWidths: const {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(3),
              },
              children: const [
                TableRow(children: [Text("Latitude"), Text(": -5.493510")]),
                TableRow(children: [Text("Longitude"), Text(": 105.143420")]),
                TableRow(children: [Text("Altitude"), Text(": 50 m")]),
                TableRow(children: [Text("Total Pohon"), Text(": 25")]),
              ],
            ),
            tilePadding: EdgeInsets.zero,
            children: [
              ListTile(title: Text("Pohon 1"), subtitle: Text("Pohon Akasia")),
              ListTile(title: Text("Pohon 2"), subtitle: Text("Pohon Pale")),
              ListTile(title: Text("Pohon 3"), subtitle: Text("Pohon Jengkol")),
              ListTile(title: Text("Pohon 4"), subtitle: Text("Pohon Kelapa")),
              ListTile(title: Text("Pohon 5"), subtitle: Text("Pohon Jati")),
            ],
          ),
          SizedBox(height: 8),
          ExpansionTile(
            title: Text("Plot 4"),
            subtitle: Table(
              columnWidths: const {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(3),
              },
              children: const [
                TableRow(children: [Text("Latitude"), Text(": -5.493510")]),
                TableRow(children: [Text("Longitude"), Text(": 105.143430")]),
                TableRow(children: [Text("Altitude"), Text(": 50 m")]),
                TableRow(children: [Text("Total Pohon"), Text(": 25")]),
              ],
            ),
            tilePadding: EdgeInsets.zero,
            children: [
              ListTile(title: Text("Pohon 1"), subtitle: Text("Pohon Akasia")),
              ListTile(title: Text("Pohon 2"), subtitle: Text("Pohon Pale")),
              ListTile(title: Text("Pohon 3"), subtitle: Text("Pohon Jengkol")),
              ListTile(title: Text("Pohon 4"), subtitle: Text("Pohon Kelapa")),
              ListTile(title: Text("Pohon 5"), subtitle: Text("Pohon Jati")),
            ],
          ),
        ],
      ),
    );
  }
}
