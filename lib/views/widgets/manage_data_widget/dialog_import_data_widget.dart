import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:azimutree/data/notifiers/cluster_notifier.dart';
import 'package:azimutree/data/notifiers/notifiers.dart';

class DialogImportDataWidget extends StatefulWidget {
  final ClusterNotifier? clusterNotifier;

  const DialogImportDataWidget({super.key, this.clusterNotifier});

  @override
  State<DialogImportDataWidget> createState() => _DialogImportDataWidgetState();
}

class _DialogImportDataWidgetState extends State<DialogImportDataWidget> {
  late final TextEditingController _kodeController;
  late final TextEditingController _namaController;
  late final TextEditingController _tanggalController;
  final ValueNotifier<bool> _isFormValid = ValueNotifier(false);
  bool _isDuplicate = false;
  String? _pickedFilePath;

  @override
  void initState() {
    super.initState();
    _kodeController = TextEditingController();
    _namaController = TextEditingController();
    _tanggalController = TextEditingController();

    _kodeController.addListener(() {
      _syncUppercase(_kodeController);
      _validateForm();
    });
    _namaController.addListener(() {
      _syncCapitalizedWords(_namaController);
      _validateForm();
    });

    _kodeController.addListener(_validateForm);
    _namaController.addListener(_validateForm);
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
    final hasFile = (_pickedFilePath != null && _pickedFilePath!.isNotEmpty);

    final duplicate =
        widget.clusterNotifier?.value.any(
          (c) => c.kodeCluster.toUpperCase() == kode,
        ) ??
        false;

    if (_isDuplicate != duplicate) {
      setState(() {
        _isDuplicate = duplicate;
      });
    } else {
      _isDuplicate = duplicate;
    }

    final isValid = kode.isNotEmpty && nama.isNotEmpty && hasFile && !duplicate;
    if (_isFormValid.value != isValid) _isFormValid.value = isValid;
  }

  void _syncUppercase(TextEditingController controller) {
    final upper = controller.text.toUpperCase();
    if (controller.text != upper) {
      controller.value = TextEditingValue(
        text: upper,
        selection: TextSelection.collapsed(offset: upper.length),
      );
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

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _pickedFilePath = result.files.first.path;
      });
      _validateForm();
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (BuildContext context, Widget? child) {
        final isDark = !isLightModeNotifier.value;
        if (isDark) {
          return Theme(
            data: ThemeData.dark(),
            child: child ?? const SizedBox.shrink(),
          );
        }
        return Theme(
          data: Theme.of(context),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (picked != null) {
      _tanggalController.text =
          "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
    }
  }

  Future<void> _save() async {
    final kodeCluster =
        _kodeController.text.replaceAll(RegExp(r'\s+'), '').toUpperCase();
    final namaPengukur = _namaController.text.trim();
    final tanggalText = _tanggalController.text.trim();

    Navigator.of(context).pop({
      'kodeCluster': kodeCluster,
      'namaPengukur': namaPengukur,
      'tanggalPengukuran': tanggalText,
      'filePath': _pickedFilePath,
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isLightModeNotifier,
      builder: (context, isLightMode, _) {
        final isDark = !isLightMode;
        final dialogBgColor =
            isDark ? const Color.fromARGB(255, 32, 72, 43) : Colors.white;
        final dialogText = isDark ? Colors.white : Colors.black;
        final labelColor = isDark ? Colors.white70 : null;
        return AlertDialog(
          backgroundColor: dialogBgColor,
          title: Text(
            "Impor Data dari Excel",
            style: TextStyle(color: dialogText),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _kodeController,
                  style: TextStyle(color: dialogText),
                  decoration: InputDecoration(
                    labelText: "Kode Klaster (Wajib)",
                    labelStyle: TextStyle(color: labelColor),
                    border: const OutlineInputBorder(),
                    helperText: "Contoh: CL1 (otomatis huruf besar)",
                    helperStyle: TextStyle(color: labelColor),
                    errorText: _isDuplicate ? "Kode klaster sudah ada" : null,
                    errorStyle: const TextStyle(color: Colors.redAccent),
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
                  textCapitalization: TextCapitalization.characters,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _namaController,
                  style: TextStyle(color: dialogText),
                  decoration: InputDecoration(
                    labelText: "Nama Pengukur (Wajib)",
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
                        suffixIcon: Icon(
                          Icons.calendar_today,
                          color: dialogText,
                        ),
                        hintText: "YYYY-MM-DD",
                        hintStyle: TextStyle(
                          color: isDark ? Colors.white54 : null,
                        ),
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
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _pickedFilePath ?? "Belum memilih file",
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: dialogText),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: _pickFile,
                      child: Text(
                        "Pilih File Excel",
                        style: TextStyle(color: dialogText),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("Batal", style: TextStyle(color: dialogText)),
            ),
            ValueListenableBuilder<bool>(
              valueListenable: _isFormValid,
              builder: (context, isValid, _) {
                return TextButton(
                  onPressed: isValid ? _save : null,
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all(dialogBgColor),
                    foregroundColor: WidgetStateProperty.resolveWith((states) {
                      if (isDark) {
                        return states.contains(WidgetState.disabled)
                            ? Colors.grey
                            : Colors.white;
                      }
                      return states.contains(WidgetState.disabled)
                          ? Colors.grey
                          : Colors.black;
                    }),
                  ),
                  child: const Text("Impor"),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
