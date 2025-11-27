import 'package:azimutree/data/notifiers/notifiers.dart';
import 'package:flutter/material.dart';

class DropdownManageDataWidget extends StatelessWidget {
  final List<String> clusterOptions;
  final bool isEmpty;

  const DropdownManageDataWidget({
    super.key,
    this.clusterOptions = const [],
    this.isEmpty = false,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: selectedDropdownClusterNotifier,
      builder: (context, selectedValue, child) {
        if (clusterOptions.isNotEmpty &&
            (selectedValue == null ||
                !clusterOptions.contains(selectedValue))) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            // Set default value ke item pertama
            selectedDropdownClusterNotifier.value = clusterOptions.first;
          });
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: const Color.fromARGB(240, 180, 216, 187),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value:
                  clusterOptions.contains(selectedValue) ? selectedValue : null,
              hint: Text(isEmpty ? "Tidak ada Klaster" : "Pilih Klaster"),
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
