import 'package:flutter/material.dart';

class TreePlotManageDataWidget extends StatelessWidget {
  const TreePlotManageDataWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Text("Pohon 1"),
      subtitle: Text("Pohon Akasia"),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              Table(
                columnWidths: const {
                  0: FlexColumnWidth(2),
                  1: FlexColumnWidth(3),
                },
                children: [
                  TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Image.network(
                          'https://picsum.photos/id/1/120/120',
                          fit: BoxFit.cover,
                        ),
                      ),
                      Text(""),
                    ],
                  ),
                  TableRow(children: [Text("Latitude"), Text(": -5.493510")]),
                  TableRow(children: [Text("Longitude"), Text(": 105.143400")]),
                  TableRow(children: [Text("Jarak dari pusat"), Text(": 0 m")]),
                  TableRow(children: [Text("Sudut Azimut"), Text(": 15°")]),
                  TableRow(children: [Text("Altitude"), Text(": 50 m")]),
                ],
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
              onPressed: () {
                //? TODO: Handle view on map action
              },
            ),
            IconButton(
              icon: Icon(Icons.edit),
              tooltip: "Edit Data Pohon",
              onPressed: () {
                //? TODO: Handle edit tree data action
              },
            ),
            IconButton(
              icon: Icon(Icons.delete, color: Color.fromARGB(255, 131, 30, 23)),
              tooltip: "Hapus Data Pohon",
              onPressed: () {
                //? TODO: Handle delete tree data action
              },
            ),
          ],
        ),
      ],
    );
  }
}
