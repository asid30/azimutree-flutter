import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:azimutree/data/notifiers/plot_notifier.dart';
import 'package:azimutree/data/models/plot_model.dart';
import 'package:azimutree/data/models/cluster_model.dart';
import 'package:azimutree/data/notifiers/notifiers.dart';

class _CommaToDotNoSpaceFormatter extends TextInputFormatter {
  _CommaToDotNoSpaceFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final sanitized = newValue.text.replaceAll(',', '.').replaceAll(' ', '');
    if (sanitized == newValue.text) return newValue;

    final baseOffset = newValue.selection.baseOffset;
    final safeOffset = baseOffset < 0 ? 0 : baseOffset;
    final beforeCursor = newValue.text.substring(
      0,
      safeOffset.clamp(0, newValue.text.length),
    );
    final beforeCursorSanitized = beforeCursor
        .replaceAll(',', '.')
        .replaceAll(' ', '');

    return TextEditingValue(
      text: sanitized,
      selection: TextSelection.collapsed(offset: beforeCursorSanitized.length),
    );
  }
}

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
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();
  final TextEditingController _altitudeController = TextEditingController();

  int? _selectedClusterId; // id klaster terpilih (FK)
  int? _selectedPlotCode;

  // Notifier untuk status valid form
  final ValueNotifier<bool> _isFormValid = ValueNotifier(false);
  bool _isDuplicateCode = false;

  @override
  void initState() {
    super.initState();

    // Pilih klaster aktif sesuai dropdown global jika ada
    if (widget.clusters.isNotEmpty) {
      final activeCode = selectedDropdownClusterNotifier.value;
      ClusterModel? activeCluster;
      if (activeCode != null) {
        try {
          activeCluster = widget.clusters.firstWhere(
            (cluster) => cluster.kodeCluster == activeCode,
          );
        } catch (_) {
          activeCluster = null;
        }
      }

      _selectedClusterId = activeCluster?.id ?? widget.clusters.first.id;
      final availableCodes = _availablePlotCodesForSelectedCluster;
      _selectedPlotCode =
          availableCodes.isNotEmpty ? availableCodes.first : null;
    }

    // Dengarkan perubahan input buat validasi real-time
    _latitudeController.addListener(_validateForm);
    _longitudeController.addListener(_validateForm);

    // trigger awal
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

  void _validateForm() {
    final hasCluster = _selectedClusterId != null;

    final latText = _latitudeController.text.trim();
    final lonText = _longitudeController.text.trim();

    final latValid = double.tryParse(latText) != null;
    final lonValid = double.tryParse(lonText) != null;

    final hasDuplicate =
        hasCluster && _selectedPlotCode != null
            ? widget.plotNotifier.value.any(
              (plot) =>
                  plot.idCluster == _selectedClusterId &&
                  plot.kodePlot == _selectedPlotCode,
            )
            : false;

    if (_isDuplicateCode != hasDuplicate) {
      setState(() {
        _isDuplicateCode = hasDuplicate;
      });
    } else {
      _isDuplicateCode = hasDuplicate;
    }

    final isValid =
        hasCluster &&
        _selectedPlotCode != null &&
        latValid &&
        lonValid &&
        !hasDuplicate;

    if (_isFormValid.value != isValid) {
      _isFormValid.value = isValid;
    }
  }

  List<int> get _availablePlotCodesForSelectedCluster {
    if (_selectedClusterId == null) return [];

    final existingCodes =
        widget.plotNotifier.value
            .where((plot) => plot.idCluster == _selectedClusterId)
            .map((plot) => plot.kodePlot)
            .toSet();

    return List<int>.generate(
      4,
      (index) => index + 1,
    ).where((code) => !existingCodes.contains(code)).toList();
  }

  Future<void> _savePlot() async {
    // idCluster dari dropdown, bukan dari textfield
    final idCluster = _selectedClusterId;
    if (idCluster == null) return; // harusnya nggak kejadian kalau tombol aktif

    final kodePlot = _selectedPlotCode;
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

    final hasDuplicate = widget.plotNotifier.value.any(
      (plot) => plot.idCluster == idCluster && plot.kodePlot == kodePlot,
    );

    if (hasDuplicate) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Kode plot sudah ada pada klaster ini. Gunakan kode plot lain.',
          ),
        ),
      );
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
    return ValueListenableBuilder<bool>(
      valueListenable: isLightModeNotifier,
      builder: (context, isLightMode, _) {
        final isDark = !isLightMode;
        final dialogBgColor = isDark ? const Color.fromARGB(255, 32, 72, 43) : Colors.white;
        final dialogText = isDark ? Colors.white : Colors.black;
        return AlertDialog(
          backgroundColor: dialogBgColor,
          title: Text(
            "Tambah Plot Baru",
            style: TextStyle(color: dialogText),
          ),
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
                      final availableCodes =
                          _availablePlotCodesForSelectedCluster;
                      _selectedPlotCode =
                          availableCodes.isNotEmpty
                              ? availableCodes.first
                              : null;
                    });
                    _validateForm();
                  },
                ),
                const SizedBox(height: 8),

                DropdownButtonFormField<int>(
                  initialValue: _selectedPlotCode,
                  decoration: InputDecoration(
                    labelText: "Pilih Plot",
                    border: const OutlineInputBorder(),
                    errorText:
                        _isDuplicateCode
                            ? 'Kode plot sudah dipakai, pilih kode lain.'
                            : null,
                    errorMaxLines: 2,
                  ),
                  items:
                      _availablePlotCodesForSelectedCluster
                          .map(
                            (code) => DropdownMenuItem<int>(
                              value: code,
                              child: Text('Plot $code'),
                            ),
                          )
                          .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedPlotCode = value;
                    });
                    _validateForm();
                  },
                ),
                if (_availablePlotCodesForSelectedCluster.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 4.0),
                    child: Text(
                      'Semua kode plot pada klaster ini sudah dipakai.',
                      style: TextStyle(fontSize: 12, color: Colors.redAccent),
                    ),
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
                  inputFormatters: [
                    _CommaToDotNoSpaceFormatter(),
                    FilteringTextInputFormatter.allow(RegExp(r'[-0-9\.,]')),
                  ],
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
                  inputFormatters: [
                    _CommaToDotNoSpaceFormatter(),
                    FilteringTextInputFormatter.allow(RegExp(r'[-0-9\.,]')),
                  ],
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
                  inputFormatters: [
                    _CommaToDotNoSpaceFormatter(),
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9\.,-]')),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text(
                "Batal",
                style: TextStyle(color: dialogText),
              ),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            ValueListenableBuilder<bool>(
              valueListenable: _isFormValid,
              builder: (context, isValid, _) {
                return TextButton(
                  onPressed: isValid ? _savePlot : null,
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all(dialogBgColor),
                    foregroundColor: WidgetStateProperty.resolveWith((states) {
                      if (isDark) return states.contains(WidgetState.disabled) ? Colors.grey : Colors.white;
                      return states.contains(WidgetState.disabled) ? Colors.grey : Colors.black;
                    }),
                  ),
                  child: const Text("Simpan"),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
