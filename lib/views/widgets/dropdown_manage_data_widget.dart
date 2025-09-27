import 'package:azimutree/data/notifiers/notifiers.dart';
import 'package:flutter/material.dart';

class DropdownManageDataWidget extends StatelessWidget {
  final List<String> clusterOptions;
  const DropdownManageDataWidget({super.key, this.clusterOptions = const []});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: selectedDropdownClusterNotifier,
      builder: (context, selectedDropdownCluster, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFb4d8bb),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value:
                  clusterOptions.contains(selectedDropdownCluster)
                      ? selectedDropdownCluster
                      : null,
              hint: const Text("Pilih Cluster"),
              isExpanded: true,
              dropdownColor: const Color(0xFFb4d8bb),
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              items:
                  clusterOptions.map((e) {
                    return DropdownMenuItem<String>(value: e, child: Text(e));
                  }).toList(),
              onChanged: (newValue) {
                if (newValue != null) {
                  selectedDropdownClusterNotifier.value = newValue;
                }
              },
            ),
          ),
        );
      },
    );
  }
}
