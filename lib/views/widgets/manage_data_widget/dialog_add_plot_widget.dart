import 'package:flutter/material.dart';
import 'package:azimutree/data/notifiers/plot_notifier.dart';
import 'package:azimutree/data/models/plot_model.dart';

class DialogAddPlotWidget extends StatefulWidget {
  final PlotNotifier plotNotifier;
  const DialogAddPlotWidget({super.key, required this.plotNotifier});

  @override
  State<DialogAddPlotWidget> createState() => _DialogAddPlotWidgetState();
}

class _DialogAddPlotWidgetState extends State<DialogAddPlotWidget> {
  final TextEditingController _kodePlotController = TextEditingController();
  final TextEditingController _clusterId = TextEditingController();
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();
  final TextEditingController _altitudeController = TextEditingController();

  @override
  void dispose() {
    _kodePlotController.dispose();
    _clusterId.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _altitudeController.dispose();
    super.dispose();
  }

  Future<void> _savePlot() async {
    final clusterId = int.tryParse(_clusterId.text.trim());
    final kodePlot = int.tryParse(_kodePlotController.text.trim());
    final latitude = double.tryParse(_latitudeController.text.trim());
    final longitude = double.tryParse(_longitudeController.text.trim());
    final altitude = double.tryParse(_altitudeController.text.trim());

    if (clusterId == null ||
        kodePlot == null ||
        latitude == null ||
        longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mohon isi semua field dengan benar')),
      );
      return;
    }

    final newPlot = PlotModel(
      clusterId: clusterId,
      kodePlot: kodePlot,
      latitude: latitude,
      longitude: longitude,
      altitude: altitude,
    );

    await widget.plotNotifier.addPlot(newPlot);

    if (!mounted) return;

    Navigator.of(context).pop();
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
              controller: _clusterId,
              decoration: const InputDecoration(labelText: "Kode Klaster"),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _kodePlotController,
              decoration: const InputDecoration(labelText: "Kode Plot"),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _latitudeController,
              decoration: const InputDecoration(labelText: "Latitude"),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _longitudeController,
              decoration: const InputDecoration(labelText: "Longitude"),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _altitudeController,
              decoration: const InputDecoration(labelText: "Altitude"),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          child: const Text("Batal"),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        TextButton(onPressed: _savePlot, child: const Text("Simpan")),
      ],
    );
  }
}
