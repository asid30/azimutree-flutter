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

        final dropdown = ValueListenableBuilder<bool>(
          valueListenable: isLightModeNotifier,
          builder: (context, isLightMode, child) {
            final isDark = !isLightMode;
            final textColor = isDark ? Colors.white : Colors.black87;
            final dropdownBg =
                isDark
                    ? const Color.fromARGB(255, 36, 67, 42)
                    : defaultDropdownColor;

            return DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value:
                    clusterOptions.contains(selectedValue)
                        ? selectedValue
                        : null,
                hint: Text(
                  isEmpty ? "Tidak ada Klaster" : "Pilih Klaster",
                  style: TextStyle(color: textColor),
                ),
                isExpanded: true,
                dropdownColor: dropdownBg,
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                items:
                    clusterOptions.map((e) {
                      return DropdownMenuItem<String>(
                        value: e,
                        child: Text(e, style: TextStyle(color: textColor)),
                      );
                    }).toList(),
                onChanged: (newValue) {
                  if (newValue != null) {
                    selectedDropdownClusterNotifier.value = newValue;
                  }
                },
              ),
            );
          },
        );

        if (embedded) return dropdown;

        return ValueListenableBuilder<bool>(
          valueListenable: isLightModeNotifier,
          builder: (context, isLightMode, _) {
            final isDark = !isLightMode;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color:
                    isDark
                        ? const Color.fromARGB(255, 36, 67, 42)
                        : defaultBackgroundColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: dropdown,
            );
          },
        );
      },
    );
  }
}
