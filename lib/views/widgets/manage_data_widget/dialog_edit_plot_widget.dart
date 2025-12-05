import 'package:flutter/material.dart';
import 'package:azimutree/data/models/plot_model.dart';
import 'package:azimutree/data/models/cluster_model.dart';
import 'package:azimutree/data/notifiers/plot_notifier.dart';

class DialogEditPlotWidget extends StatefulWidget {
  final PlotModel plot;
  final List<ClusterModel> clusters;
  final PlotNotifier plotNotifier;

  const DialogEditPlotWidget({
    super.key,
    required this.plot,
    required this.clusters,
    required this.plotNotifier,
  });

  @override
  State<DialogEditPlotWidget> createState() => _DialogEditPlotWidgetState();
}

class _DialogEditPlotWidgetState extends State<DialogEditPlotWidget> {
  late final TextEditingController _latitudeController;
  late final TextEditingController _longitudeController;
  late final TextEditingController _altitudeController;
  late int _selectedPlotCode;
  late final ClusterModel _cluster;
  bool _isDuplicateCode = false;
  final ValueNotifier<bool> _isFormValid = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    _latitudeController = TextEditingController(
      text: widget.plot.latitude.toString(),
    );
    _longitudeController = TextEditingController(
      text: widget.plot.longitude.toString(),
    );
    _altitudeController = TextEditingController(
      text: widget.plot.altitude?.toString() ?? "",
    );
    _selectedPlotCode = widget.plot.kodePlot;
    _cluster = widget.clusters.firstWhere((c) => c.id == widget.plot.idCluster);

    _latitudeController.addListener(_validateForm);
    _longitudeController.addListener(_validateForm);
    _validateForm();
  }

  @override
  void dispose() {
    _latitudeController.dispose();
    _longitudeController.dispose();
    _altitudeController.dispose();
    _isFormValid.dispose();
    super.dispose();
  }

  List<int> get _availableCodes {
    final existing =
        widget.plotNotifier.value
            .where(
              (plot) =>
                  plot.idCluster == widget.plot.idCluster &&
                  plot.id != widget.plot.id,
            )
            .map((plot) => plot.kodePlot)
            .toSet();
    return List<int>.generate(
      4,
      (index) => index + 1,
    ).where((code) => !existing.contains(code)).toList();
  }

  void _validateForm() {
    final latValid = double.tryParse(_latitudeController.text.trim()) != null;
    final lonValid = double.tryParse(_longitudeController.text.trim()) != null;

    final duplicate = widget.plotNotifier.value.any(
      (plot) =>
          plot.idCluster == widget.plot.idCluster &&
          plot.id != widget.plot.id &&
          plot.kodePlot == _selectedPlotCode,
    );

    if (_isDuplicateCode != duplicate) {
      setState(() {
        _isDuplicateCode = duplicate;
      });
    } else {
      _isDuplicateCode = duplicate;
    }

    final isValid = latValid && lonValid && !_isDuplicateCode;
    if (_isFormValid.value != isValid) {
      _isFormValid.value = isValid;
    }
  }

  Future<void> _save() async {
    final latitude = double.tryParse(_latitudeController.text.trim());
    final longitude = double.tryParse(_longitudeController.text.trim());
    final altitude =
        _altitudeController.text.trim().isNotEmpty
            ? double.tryParse(_altitudeController.text.trim())
            : null;

    if (latitude == null || longitude == null) return;

    final updated = PlotModel(
      id: widget.plot.id,
      idCluster: widget.plot.idCluster,
      kodePlot: _selectedPlotCode,
      latitude: latitude,
      longitude: longitude,
      altitude: altitude,
    );

    await widget.plotNotifier.updatePlot(updated);
    if (!mounted) return;
    Navigator.of(context).pop(updated);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Edit Plot"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              initialValue: _cluster.kodeCluster,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: "Klaster",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              initialValue: _selectedPlotCode,
              decoration: InputDecoration(
                labelText: "Kode Plot",
                border: const OutlineInputBorder(),
                errorText: _isDuplicateCode ? "Kode plot sudah dipakai" : null,
              ),
              items: [
                DropdownMenuItem(
                  value: widget.plot.kodePlot,
                  child: Text("Plot ${widget.plot.kodePlot} (saat ini)"),
                ),
                ..._availableCodes
                    .where((code) => code != widget.plot.kodePlot)
                    .map(
                      (code) => DropdownMenuItem(
                        value: code,
                        child: Text("Plot $code"),
                      ),
                    ),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _selectedPlotCode = value;
                });
                _validateForm();
              },
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
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("Batal"),
        ),
        ValueListenableBuilder<bool>(
          valueListenable: _isFormValid,
          builder: (context, isValid, _) {
            return TextButton(
              onPressed: isValid ? _save : null,
              child: const Text("Simpan"),
            );
          },
        ),
      ],
    );
  }
}
