import 'package:flutter/material.dart';
import 'package:azimutree/data/notifiers/cluster_notifier.dart';
import 'package:azimutree/data/models/cluster_model.dart';

class DialogAddClusterWidget extends StatefulWidget {
  final ClusterNotifier clusterNotifier;

  const DialogAddClusterWidget({super.key, required this.clusterNotifier});

  @override
  State<DialogAddClusterWidget> createState() => _DialogAddClusterWidgetState();
}

class _DialogAddClusterWidgetState extends State<DialogAddClusterWidget> {
  final TextEditingController _kodeClusterController = TextEditingController();
  final TextEditingController _namaPengukurController = TextEditingController();
  final TextEditingController _tanggalPengukuranController =
      TextEditingController();

  // Notifier: apakah form valid?
  final ValueNotifier<bool> _isFormValid = ValueNotifier(false);
  bool _isDuplicateCode = false;

  @override
  void initState() {
    super.initState();

    // Listener setiap kali user mengetik → normalisasi & validasi ulang
    _kodeClusterController.addListener(() {
      _syncUppercase(_kodeClusterController);
      _validateForm();
    });
    _namaPengukurController.addListener(() {
      _syncCapitalizedWords(_namaPengukurController);
      _validateForm();
    });
  }

  @override
  void dispose() {
    _kodeClusterController.dispose();
    _namaPengukurController.dispose();
    _tanggalPengukuranController.dispose();
    _isFormValid.dispose();
    super.dispose();
  }

  void _validateForm() {
    final kode =
        _kodeClusterController.text
            .replaceAll(RegExp(r'\s+'), '')
            .toUpperCase();
    final nama = _namaPengukurController.text.trim();

    final isDuplicate = widget.clusterNotifier.value.any(
      (cluster) => cluster.kodeCluster.toUpperCase() == kode,
    );

    if (_isDuplicateCode != isDuplicate) {
      setState(() {
        _isDuplicateCode = isDuplicate;
      });
    } else {
      _isDuplicateCode = isDuplicate;
    }

    final isValid = kode.isNotEmpty && nama.isNotEmpty && !isDuplicate;

    if (_isFormValid.value != isValid) {
      _isFormValid.value = isValid;
    }
  }

  Future<void> _saveCluster() async {
    final kodeCluster =
        _kodeClusterController.text
            .replaceAll(RegExp(r'\s+'), '')
            .toUpperCase();

    final hasDuplicate = widget.clusterNotifier.value.any(
      (cluster) => cluster.kodeCluster.toUpperCase() == kodeCluster,
    );

    if (hasDuplicate) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kode klaster sudah ada. Gunakan kode lain.'),
        ),
      );
      return;
    }

    final namaPengukur = _capitalizeWords(_namaPengukurController.text.trim());
    final tanggalText = _tanggalPengukuranController.text.trim();

    DateTime? tanggalPengukuran;
    if (tanggalText.isNotEmpty) {
      tanggalPengukuran = DateTime.tryParse(tanggalText);
    }

    final newCluster = ClusterModel(
      kodeCluster: kodeCluster,
      namaPengukur: namaPengukur,
      tanggalPengukuran: tanggalPengukuran,
    );

    await widget.clusterNotifier.addCluster(newCluster);

    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  Future<void> _selectDate() async {
    final DateTime now = DateTime.now();

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (picked != null) {
      _tanggalPengukuranController.text =
          "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
    }
  }

  void _syncUppercase(TextEditingController controller) {
    final sanitized = controller.text.toUpperCase();
    if (controller.text != sanitized) {
      controller.value = TextEditingValue(
        text: sanitized,
        selection: TextSelection.collapsed(offset: sanitized.length),
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
    return value
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .map(
          (word) =>
              word[0].toUpperCase() +
              (word.length > 1 ? word.substring(1).toLowerCase() : ''),
        )
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      title: const Text("Tambah Klaster Baru"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Kode Klaster
            TextField(
              controller: _kodeClusterController,
              decoration: InputDecoration(
                labelText: "Kode Klaster (wajib)",
                border: const OutlineInputBorder(),
                helperText: "Contoh: CL01 (otomatis huruf besar)",
                helperMaxLines: 2,
                errorText:
                    _isDuplicateCode
                        ? 'Kode klaster sudah ada, gunakan kode lain.'
                        : null,
                errorMaxLines: 2,
              ),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 8),

            // Nama Pengukur
            TextField(
              controller: _namaPengukurController,
              decoration: const InputDecoration(
                labelText: "Nama Pengukur (wajib)",
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 8),

            // Tanggal opsional
            GestureDetector(
              onTap: _selectDate,
              child: AbsorbPointer(
                child: TextField(
                  controller: _tanggalPengukuranController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: "Tanggal Pengukuran (opsional)",
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                    hintText: "YYYY-MM-DD",
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      // Tombol aksi
      actions: [
        TextButton(
          child: const Text("Batal"),
          onPressed: () => Navigator.of(context).pop(false),
        ),

        // Tombol Simpan pakai ValueListenableBuilder
        ValueListenableBuilder<bool>(
          valueListenable: _isFormValid,
          builder: (context, isValid, _) {
            return TextButton(
              onPressed: isValid ? _saveCluster : null,
              child: Text(
                "Simpan",
                style: TextStyle(color: isValid ? Colors.blue : Colors.grey),
              ),
            );
          },
        ),
      ],
    );
  }
}
