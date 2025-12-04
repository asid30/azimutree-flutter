import 'package:flutter/material.dart';
import 'package:azimutree/data/notifiers/plot_notifier.dart';
import 'package:azimutree/data/models/plot_model.dart';
import 'package:azimutree/data/models/cluster_model.dart';

class DialogAddPlotWidget extends StatefulWidget {
  final PlotNotifier plotNotifier;
  final List<ClusterModel> clusters; // daftar klaster dari DB

  const DialogAddPlotWidget({
    super.key,
    required this.plotNotifier,
    required this.clusters,
  });

  @override
  State<DialogAddPlotWidget> createState() => _DialogAddPlotWidgetState();
}

class _DialogAddPlotWidgetState extends State<DialogAddPlotWidget> {
  final TextEditingController _kodePlotController = TextEditingController();
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();
  final TextEditingController _altitudeController = TextEditingController();

  int? _selectedClusterId; // id klaster terpilih (FK)

  // Notifier untuk status valid form
  final ValueNotifier<bool> _isFormValid = ValueNotifier(false);

  @override
  void initState() {
    super.initState();

    // optional: auto pilih klaster pertama kalau ada datanya
    if (widget.clusters.isNotEmpty) {
      _selectedClusterId = widget.clusters.first.id;
    }

    // Dengarkan perubahan input buat validasi real-time
    _kodePlotController.addListener(_validateForm);
    _latitudeController.addListener(_validateForm);
    _longitudeController.addListener(_validateForm);

    // trigger awal
    _validateForm();
  }

  @override
  void dispose() {
    _kodePlotController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _altitudeController.dispose();
    _isFormValid.dispose();
    super.dispose();
  }

  void _validateForm() {
    final hasCluster = _selectedClusterId != null;

    final kodeText = _kodePlotController.text.trim();
    final latText = _latitudeController.text.trim();
    final lonText = _longitudeController.text.trim();

    final kodeValid = int.tryParse(kodeText) != null;
    final latValid = double.tryParse(latText) != null;
    final lonValid = double.tryParse(lonText) != null;

    final isValid = hasCluster && kodeValid && latValid && lonValid;

    if (_isFormValid.value != isValid) {
      _isFormValid.value = isValid;
    }
  }

  Future<void> _savePlot() async {
    // idCluster dari dropdown, bukan dari textfield
    final idCluster = _selectedClusterId;
    if (idCluster == null) return; // harusnya nggak kejadian kalau tombol aktif

    final kodePlot = int.tryParse(_kodePlotController.text.trim());
    final latitude = double.tryParse(_latitudeController.text.trim());
    final longitude = double.tryParse(_longitudeController.text.trim());
    final altitude =
        _altitudeController.text.trim().isNotEmpty
            ? double.tryParse(_altitudeController.text.trim())
            : null; // altitude boleh kosong

    // Safety guard, normalnya ini sudah valid karena tombol cuma aktif kalau valid
    if (kodePlot == null || latitude == null || longitude == null) {
      return;
    }

    final newPlot = PlotModel(
      idCluster: idCluster,
      kodePlot: kodePlot,
      latitude: latitude,
      longitude: longitude,
      altitude: altitude,
    );

    await widget.plotNotifier.addPlot(newPlot);

    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      title: const Text("Tambah Plot Baru"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 🔽 DROPDOWN KODE KLASTER
            DropdownButtonFormField<int>(
              initialValue: _selectedClusterId,
              decoration: const InputDecoration(
                labelText: "Klaster",
                border: OutlineInputBorder(),
              ),
              isExpanded: true,
              items:
                  widget.clusters.map((cluster) {
                    return DropdownMenuItem<int>(
                      value: cluster.id,
                      child: Text(cluster.kodeCluster),
                    );
                  }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedClusterId = value;
                });
                _validateForm();
              },
            ),
            const SizedBox(height: 8),

            TextField(
              controller: _kodePlotController,
              decoration: const InputDecoration(
                labelText: "Kode Plot",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),

            TextField(
              controller: _latitudeController,
              decoration: const InputDecoration(
                labelText: "Latitude",
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
            ),
            const SizedBox(height: 8),

            TextField(
              controller: _longitudeController,
              decoration: const InputDecoration(
                labelText: "Longitude",
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
            ),
            const SizedBox(height: 8),

            TextField(
              controller: _altitudeController,
              decoration: const InputDecoration(
                labelText: "Altitude (opsional)",
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
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
        ValueListenableBuilder<bool>(
          valueListenable: _isFormValid,
          builder: (context, isValid, _) {
            return TextButton(
              onPressed: isValid ? _savePlot : null,
              child: const Text("Simpan"),
            );
          },
        ),
      ],
    );
  }
}
