import 'package:flutter/material.dart';
import 'package:azimutree/data/database/cluster_dao.dart';
import 'package:azimutree/data/models/cluster_model.dart';

class DialogAddClusterWidget extends StatefulWidget {
  const DialogAddClusterWidget({super.key});

  @override
  State<DialogAddClusterWidget> createState() => _DialogAddClusterWidgetState();
}

class _DialogAddClusterWidgetState extends State<DialogAddClusterWidget> {
  final TextEditingController _kodeClusterController = TextEditingController();
  final TextEditingController _namaPengukurController = TextEditingController();
  final TextEditingController _tanggalPengukuranController =
      TextEditingController();

  @override
  void dispose() {
    _kodeClusterController.dispose();
    _namaPengukurController.dispose();
    _tanggalPengukuranController.dispose();
    super.dispose();
  }

  Future<void> _saveCluster() async {
    final kodeCluster =
        _kodeClusterController.text
            .replaceAll(RegExp(r'\s+'), '')
            .toUpperCase();
    final namaPengukur = _namaPengukurController.text.trim();
    final tanggalText = _tanggalPengukuranController.text.trim();

    if (kodeCluster.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kode klaster tidak boleh kosong')),
      );
      return;
    }

    DateTime? tanggalPengukuran;
    if (tanggalText.isNotEmpty) {
      tanggalPengukuran = DateTime.parse(tanggalText);
    }

    final newCluster = ClusterModel(
      kodeCluster: kodeCluster,
      namaPengukur: namaPengukur.isEmpty ? null : namaPengukur,
      tanggalPengukuran: tanggalPengukuran,
    );

    await ClusterDao.insertCluster(newCluster);

    if (!mounted) return;

    Navigator.of(
      context,
    ).pop(true); // bisa return true kalau mau kasih info "berhasil"
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
      setState(() {
        _tanggalPengukuranController.text =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
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
            TextField(
              controller: _kodeClusterController,
              decoration: const InputDecoration(labelText: "Kode Klaster"),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _namaPengukurController,
              decoration: const InputDecoration(labelText: "Nama Pengukur"),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _selectDate,
              child: AbsorbPointer(
                child: TextField(
                  controller: _tanggalPengukuranController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: "Tanggal Pengukuran",
                    suffixIcon: const Icon(Icons.calendar_today),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          child: const Text("Batal"),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        TextButton(onPressed: _saveCluster, child: const Text("Simpan")),
      ],
    );
  }
}
