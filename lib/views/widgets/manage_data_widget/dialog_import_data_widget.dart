import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:azimutree/data/notifiers/cluster_notifier.dart';

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
    return AlertDialog(
      title: const Text("Impor Data dari Excel"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _kodeController,
              decoration: InputDecoration(
                labelText: "Kode Klaster (Wajib)",
                border: const OutlineInputBorder(),
                helperText: "Contoh: CL1 (otomatis huruf besar)",
                errorText: _isDuplicate ? "Kode klaster sudah ada" : null,
              ),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _namaController,
              decoration: const InputDecoration(
                labelText: "Nama Pengukur (Wajib)",
                border: OutlineInputBorder(),
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
                  decoration: const InputDecoration(
                    labelText: "Tanggal Pengukuran",
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                    hintText: "YYYY-MM-DD",
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
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _pickFile,
                  child: const Text("Pilih File Excel"),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("Batal"),
        ),
        ValueListenableBuilder<bool>(
          valueListenable: _isFormValid,
          builder: (context, isValid, _) {
            return TextButton(
              onPressed: isValid ? _save : null,
              child: const Text("Impor"),
            );
          },
        ),
      ],
    );
  }
}
