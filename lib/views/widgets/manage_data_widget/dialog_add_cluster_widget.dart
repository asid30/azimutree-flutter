import 'package:flutter/material.dart';
import 'package:azimutree/data/database/cluster_dao.dart';
import 'package:azimutree/data/models/cluster_model.dart';

class DialogAddClusterWidget extends StatefulWidget {
  const DialogAddClusterWidget({super.key});

  @override
  State<DialogAddClusterWidget> createState() => _DialogAddClusterWidgetState();
}

class _DialogAddClusterWidgetState extends State<DialogAddClusterWidget> {
  // Controller untuk input teks
  final TextEditingController _kodeClusterController = TextEditingController();
  final TextEditingController _namaPengukurController = TextEditingController();
  final TextEditingController _tanggalPengukuranController =
      TextEditingController();

  @override
  void dispose() {
    // Wajib di-dispose biar nggak bocor memory
    _kodeClusterController.dispose();
    _namaPengukurController.dispose();
    _tanggalPengukuranController.dispose();
    super.dispose();
  }

  // Dibikin async biar bisa pakai await, lebih rapi daripada .then()
  Future<void> _saveCluster() async {
    final kodeCluster = _kodeClusterController.text.trim();
    final namaPengukur = _namaPengukurController.text.trim();
    final tanggalText = _tanggalPengukuranController.text.trim();

    // Validasi sederhana: kode wajib diisi
    if (kodeCluster.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kode klaster tidak boleh kosong')),
      );
      return;
    }

    DateTime? tanggalPengukuran;
    if (tanggalText.isNotEmpty) {
      // Karena kamu formatnya "YYYY-M-D", DateTime.parse masih bisa baca
      // Kalau mau lebih aman nanti bisa pakai intl (DateFormat)
      tanggalPengukuran = DateTime.parse(tanggalText);
    }

    final newCluster = ClusterModel(
      kodeCluster: kodeCluster,
      namaPengukur: namaPengukur.isEmpty ? null : namaPengukur,
      tanggalPengukuran: tanggalPengukuran,
    );

    // Operasi async ke database
    await ClusterDao.insertCluster(newCluster);

    // Setelah await, SELALU cek mounted dulu sebelum pakai context
    if (!mounted) return;

    // Tutup dialog
    Navigator.of(
      context,
    ).pop(true); // bisa return true kalau mau kasih info "berhasil"
  }

  // Ga usah passing BuildContext sebagai parameter, langsung pakai context dari State
  Future<void> _selectDate() async {
    final DateTime now = DateTime.now();

    final DateTime? picked = await showDatePicker(
      context: context, // aman, dipakai sebelum await
      initialDate: now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (picked != null) {
      setState(() {
        // Format sederhana: yyyy-mm-dd
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
            TextField(
              controller: _tanggalPengukuranController,
              readOnly:
                  true, // user ga boleh ketik manual, cuma lewat date picker
              decoration: InputDecoration(
                labelText: "Tanggal Pengukuran",
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: _selectDate, // ga perlu kirim context
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
