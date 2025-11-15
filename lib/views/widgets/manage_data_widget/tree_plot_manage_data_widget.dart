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
                          width: 120,
                          height: 120,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) {
                              return child;
                            }
                            return Center(
                              child: CircularProgressIndicator(
                                value:
                                    loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress
                                                .cumulativeBytesLoaded /
                                            (loadingProgress
                                                    .expectedTotalBytes ??
                                                1)
                                        : null,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 120,
                              height: 120,
                              color: Colors.grey.shade300,
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.broken_image,
                                color: Colors.grey,
                              ),
                            );
                          },
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
      ],
    );
  }
}
