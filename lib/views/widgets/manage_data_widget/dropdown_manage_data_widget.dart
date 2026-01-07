import 'package:azimutree/data/notifiers/notifiers.dart';
import 'package:flutter/material.dart';

class DropdownManageDataWidget extends StatelessWidget {
  static const Color defaultBackgroundColor = Color.fromARGB(
    240,
    180,
    216,
    187,
  );
  static const Color defaultDropdownColor = Color(0xFFb4d8bb);

  final List<String> clusterOptions;
  final bool isEmpty;
  final bool embedded;

  const DropdownManageDataWidget({
    super.key,
    this.clusterOptions = const [],
    this.isEmpty = false,
    this.embedded = false,
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

        final dropdown = DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value:
                clusterOptions.contains(selectedValue) ? selectedValue : null,
            hint: Text(isEmpty ? "Tidak ada Klaster" : "Pilih Klaster"),
            isExpanded: true,
            dropdownColor: defaultDropdownColor,
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
        );

        if (embedded) return dropdown;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: defaultBackgroundColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: dropdown,
        );
      },
    );
  }
}
