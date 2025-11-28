import 'package:flutter/material.dart';

class TreePlotManageDataWidget extends StatelessWidget {
  final int plotId;
  const TreePlotManageDataWidget({super.key, required this.plotId});

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: const Text("Pohon 1"),
      subtitle: const Text("Pohon Akasia"),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
          child: Column(
            children: [
              Table(
                columnWidths: const {
                  0: FlexColumnWidth(2),
                  1: FlexColumnWidth(3),
                },
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                children: [
                  TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: SizedBox(
                          width: 120,
                          height: 120,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              'https://picsum.photos/id/1/120/120',
                              fit: BoxFit.cover,
                              // >>> INI BAGIAN PENTING
                              frameBuilder: (
                                context,
                                child,
                                frame,
                                wasSynchronouslyLoaded,
                              ) {
                                // Kalau langsung ke-load (misal dari cache)
                                if (wasSynchronouslyLoaded) return child;

                                if (frame == null) {
                                  // BELUM ADA FRAME → tampilkan loader + bg abu
                                  return Container(
                                    color: Colors.grey.shade200,
                                    alignment: Alignment.center,
                                    child: const SizedBox(
                                      width: 28,
                                      height: 28,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                      ),
                                    ),
                                  );
                                }

                                // Sudah ada frame → animasi pelan masuk
                                return AnimatedOpacity(
                                  opacity: 1,
                                  duration: const Duration(milliseconds: 250),
                                  child: child,
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
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
                        ),
                      ),
                      const SizedBox(
                        height: 120,
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: Text(
                            "",
                          ), // slot kosong buat info lain kalau perlu
                        ),
                      ),
                    ],
                  ),
                  const TableRow(
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 0),
                        child: Text("Latitude"),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 0),
                        child: Text(": -5.493510"),
                      ),
                    ],
                  ),
                  const TableRow(
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 0),
                        child: Text("Longitude"),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 0),
                        child: Text(": 105.143400"),
                      ),
                    ],
                  ),
                  const TableRow(
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 0),
                        child: Text("Jarak dari pusat"),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 0),
                        child: Text(": 0 m"),
                      ),
                    ],
                  ),
                  const TableRow(
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 0),
                        child: Text("Sudut Azimut"),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 0),
                        child: Text(": 15°"),
                      ),
                    ],
                  ),
                  const TableRow(
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 0),
                        child: Text("Altitude"),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 0),
                        child: Text(": 50 m"),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
