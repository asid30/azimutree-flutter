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
                  subtitle: Text("Pohon Akasia"),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Table(
                        columnWidths: const {
                          0: FlexColumnWidth(2),
                          1: FlexColumnWidth(3),
                        },
                        children: const [
                          TableRow(
                            children: [Text("Latitude"), Text(": -5.493510")],
                          ),
                          TableRow(
                            children: [Text("Longitude"), Text(": 105.143400")],
                          ),
                          TableRow(
                            children: [Text("Jarak dari pusat"), Text(": 0 m")],
                          ),
                          TableRow(
                            children: [Text("Sudut Azimut"), Text(": 15°")],
                          ),
                          TableRow(
                            children: [Text("Altitude"), Text(": 50 m")],
                          ),
                        ],
                      ),
                    ),
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
              ],
            ),
          ),
          SizedBox(height: 8),
        ],
      ),
    );
  }
}
