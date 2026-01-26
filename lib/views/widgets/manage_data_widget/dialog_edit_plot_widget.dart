import 'package:flutter/material.dart';
import 'package:azimutree/data/models/plot_model.dart';
import 'package:azimutree/data/models/cluster_model.dart';
import 'package:azimutree/data/notifiers/plot_notifier.dart';
import 'package:azimutree/data/notifiers/notifiers.dart';

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
          title: Text("Edit Plot", style: TextStyle(color: dialogText)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  initialValue: _cluster.kodeCluster,
                  readOnly: true,
                  style: TextStyle(color: dialogText),
                  decoration: InputDecoration(
                    labelText: "Klaster",
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
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  initialValue: _selectedPlotCode,
                  style: TextStyle(color: dialogText),
                  dropdownColor: dialogBgColor,
                  decoration: InputDecoration(
                    labelText: "Kode Plot",
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
                    errorText:
                        _isDuplicateCode ? "Kode plot sudah dipakai" : null,
                  ),
                  items: [
                    DropdownMenuItem(
                      value: widget.plot.kodePlot,
                      child: Text(
                        "Plot ${widget.plot.kodePlot} (saat ini)",
                        style: TextStyle(color: dialogText),
                      ),
                    ),
                    ..._availableCodes
                        .where((code) => code != widget.plot.kodePlot)
                        .map(
                          (code) => DropdownMenuItem(
                            value: code,
                            child: Text(
                              "Plot $code",
                              style: TextStyle(color: dialogText),
                            ),
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
                  style: TextStyle(color: dialogText),
                  decoration: InputDecoration(
                    labelText: "Latitude",
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
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _longitudeController,
                  style: TextStyle(color: dialogText),
                  decoration: InputDecoration(
                    labelText: "Longitude",
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
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _altitudeController,
                  style: TextStyle(color: dialogText),
                  decoration: InputDecoration(
                    labelText: "Altitude (opsional)",
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
