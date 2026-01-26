import 'package:flutter/material.dart';
import 'package:azimutree/data/models/cluster_model.dart';
import 'package:azimutree/data/notifiers/cluster_notifier.dart';
import 'package:azimutree/data/notifiers/notifiers.dart';

class DialogEditClusterWidget extends StatefulWidget {
  final ClusterModel cluster;
  final ClusterNotifier clusterNotifier;

  const DialogEditClusterWidget({
    super.key,
    required this.cluster,
    required this.clusterNotifier,
  });

  @override
  State<DialogEditClusterWidget> createState() =>
      _DialogEditClusterWidgetState();
}

class _DialogEditClusterWidgetState extends State<DialogEditClusterWidget> {
  late final TextEditingController _kodeController;
  late final TextEditingController _namaController;
  late final TextEditingController _tanggalController;
  final ValueNotifier<bool> _isFormValid = ValueNotifier(false);
  bool _isDuplicate = false;

  @override
  void initState() {
    super.initState();
    _kodeController = TextEditingController(text: widget.cluster.kodeCluster);
    _namaController = TextEditingController(
      text: widget.cluster.namaPengukur ?? "",
    );
    _tanggalController = TextEditingController(
      text:
          widget.cluster.tanggalPengukuran != null
              ? widget.cluster.tanggalPengukuran!
                  .toIso8601String()
                  .split('T')
                  .first
              : "",
    );

    _kodeController.addListener(_validateForm);
    _namaController.addListener(() {
      _syncCapitalizedWords(_namaController);
      _validateForm();
    });
  }

  @override
  void dispose() {
    _kodeController.dispose();
    _namaController.dispose();
    _tanggalController.dispose();
    _isFormValid.dispose();
    super.dispose();
  }

  void _validateForm() {
    final kode =
        _kodeController.text.replaceAll(RegExp(r'\s+'), '').toUpperCase();
    final nama = _namaController.text.trim();

    final duplicate = widget.clusterNotifier.value.any(
      (c) => c.id != widget.cluster.id && c.kodeCluster.toUpperCase() == kode,
    );

    if (_isDuplicate != duplicate) {
      setState(() {
        _isDuplicate = duplicate;
      });
    } else {
      _isDuplicate = duplicate;
    }

    final isValid = kode.isNotEmpty && nama.isNotEmpty && !duplicate;
    if (_isFormValid.value != isValid) {
      _isFormValid.value = isValid;
    }
  }

  Future<void> _save() async {
    final kodeCluster =
        _kodeController.text.replaceAll(RegExp(r'\s+'), '').toUpperCase();
    final namaPengukur = _capitalizeWords(_namaController.text.trim());
    final tanggalText = _tanggalController.text.trim();
    DateTime? tanggalPengukuran;
    if (tanggalText.isNotEmpty) {
      tanggalPengukuran = DateTime.tryParse(tanggalText);
    }

    final updated = ClusterModel(
      id: widget.cluster.id,
      kodeCluster: kodeCluster,
      namaPengukur: namaPengukur,
      tanggalPengukuran: tanggalPengukuran,
    );

    await widget.clusterNotifier.updateCluster(updated);
    if (!mounted) return;
    Navigator.of(context).pop(updated);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: widget.cluster.tanggalPengukuran ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (picked != null) {
      _tanggalController.text =
          "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
    }
  }

  void _syncCapitalizedWords(TextEditingController controller) {
    final sanitized = _capitalizeWords(controller.text);
    if (controller.text != sanitized) {
      controller.value = TextEditingValue(
        text: sanitized,
        selection: TextSelection.collapsed(offset: sanitized.length),
      );
    }
  }

  String _capitalizeWords(String value) {
    final buffer = StringBuffer();
    var capitalizeNext = true;
    for (final rune in value.runes) {
      final char = String.fromCharCode(rune);
      if (char.trim().isEmpty) {
        buffer.write(char);
        capitalizeNext = true;
      } else {
        buffer.write(capitalizeNext ? char.toUpperCase() : char.toLowerCase());
        capitalizeNext = false;
      }
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isLightModeNotifier,
      builder: (context, isLightMode, _) {
        final isDark = !isLightMode;
        final dialogBgColor =
            isDark ? const Color.fromARGB(255, 36, 67, 42) : null;
        final dialogText = isDark ? Colors.white : Colors.black;
        final labelColor = isDark ? Colors.white70 : null;

        return AlertDialog(
          backgroundColor: dialogBgColor,
          title: Text("Edit Klaster", style: TextStyle(color: dialogText)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _kodeController,
                  style: TextStyle(color: dialogText),
                  decoration: InputDecoration(
                    labelText: "Kode Klaster",
                    labelStyle: TextStyle(color: labelColor),
                    border: const OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: isDark ? Colors.white54 : Colors.grey,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color:
                            isDark
                                ? Colors.white
                                : Theme.of(context).colorScheme.primary,
                        width: 2.0,
                      ),
                    ),
                    errorText: _isDuplicate ? "Kode klaster sudah ada" : null,
                  ),
                  textCapitalization: TextCapitalization.characters,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _namaController,
                  style: TextStyle(color: dialogText),
                  decoration: InputDecoration(
                    labelText: "Nama Pengukur",
                    labelStyle: TextStyle(color: labelColor),
                    border: const OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: isDark ? Colors.white54 : Colors.grey,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color:
                            isDark
                                ? Colors.white
                                : Theme.of(context).colorScheme.primary,
                        width: 2.0,
                      ),
                    ),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _pickDate,
                  child: AbsorbPointer(
                    child: TextField(
                      controller: _tanggalController,
                      readOnly: true,
                      style: TextStyle(color: dialogText),
                      decoration: InputDecoration(
                        labelText: "Tanggal Pengukuran",
                        labelStyle: TextStyle(color: labelColor),
                        border: const OutlineInputBorder(),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: isDark ? Colors.white54 : Colors.grey,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color:
                                isDark
                                    ? Colors.white
                                    : Theme.of(context).colorScheme.primary,
                            width: 2.0,
                          ),
                        ),
                        suffixIcon: Icon(
                          Icons.calendar_today,
                          color: isDark ? Colors.white70 : null,
                        ),
                        hintText: "YYYY-MM-DD",
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                "Batal",
                style: TextStyle(color: isDark ? Colors.white : null),
              ),
            ),
            ValueListenableBuilder<bool>(
              valueListenable: _isFormValid,
              builder: (context, isValid, _) {
                return TextButton(
                  onPressed: isValid ? _save : null,
                  child: Text(
                    "Simpan",
                    style: TextStyle(color: isDark ? Colors.white : null),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
