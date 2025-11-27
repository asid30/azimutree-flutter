import 'package:azimutree/data/models/cluster_model.dart';
import 'package:azimutree/data/notifiers/notifiers.dart';
import 'package:flutter/material.dart';

class SelectedClusterManageDataWidget extends StatelessWidget {
  final List<ClusterModel> clustersData;

  const SelectedClusterManageDataWidget({
    super.key,
    this.clustersData = const [],
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: selectedDropdownClusterNotifier,
      builder: (context, selectedClusterCode, child) {
        ClusterModel? selectedCluster;
        if (selectedClusterCode != null && clustersData.isNotEmpty) {
          try {
            selectedCluster = clustersData.firstWhere(
              (c) => c.kodeCluster == selectedClusterCode,
            );
          } catch (_) {
            selectedCluster = null; // kalau tidak ketemu
          }
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color.fromARGB(240, 180, 216, 187),
            borderRadius: BorderRadius.circular(8),
          ),
          child:
              selectedCluster == null
                  ? const Text(
                    "Tidak ada data / belum ada klaster dipilih",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  )
                  : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Data Cluster",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Table(
                        columnWidths: const {
                          0: FlexColumnWidth(2),
                          1: FlexColumnWidth(3),
                        },
                        children: [
                          _row("Kode Klaster", selectedCluster.kodeCluster),
                          _row("Pengukur", selectedCluster.namaPengukur ?? "-"),
                          _row(
                            "Tanggal Pengukuran",
                            selectedCluster.tanggalPengukuran != null
                                ? _formatDate(
                                  selectedCluster.tanggalPengukuran!,
                                )
                                : "-",
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
        );
      },
    );
  }

  /// Row helper biar kodenya ga berantakan
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

  /// Format tanggal jadi dd-mm-yyyy
  String _formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final y = date.year.toString();
    return "$d-$m-$y";
  }
}
