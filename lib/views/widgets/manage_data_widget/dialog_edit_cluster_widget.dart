import 'package:flutter/material.dart';
import 'package:azimutree/data/models/cluster_model.dart';
import 'package:azimutree/data/notifiers/cluster_notifier.dart';
import 'package:azimutree/data/notifiers/notifiers.dart';
import 'package:azimutree/data/models/titik_ikat_model.dart';
import 'package:azimutree/data/notifiers/titik_ikat_notifier.dart';
import 'package:azimutree/views/widgets/location_map_widget/coordinate_picker_page.dart';

class DialogEditClusterWidget extends StatefulWidget {
  final ClusterModel cluster;
  final ClusterNotifier clusterNotifier;
  final TitikIkatModel titikIkat;
  final TitikIkatNotifier titikIkatNotifier;

  const DialogEditClusterWidget({
    super.key,
    required this.cluster,
    required this.clusterNotifier,
    required this.titikIkat,
    required this.titikIkatNotifier,
  });

  @override
  State<DialogEditClusterWidget> createState() =>
      _DialogEditClusterWidgetState();
}

class _DialogEditClusterWidgetState extends State<DialogEditClusterWidget> {
  late final TextEditingController _kodeController;
  late final TextEditingController _namaController;
  late final TextEditingController _tanggalController;
  late final TextEditingController _latitudeController;
  late final TextEditingController _longitudeController;
  late final TextEditingController _altitudeController;
  late final TextEditingController _keteranganController;
  late final TextEditingController _urlFotoController;
  final ValueNotifier<bool> _isFormValid = ValueNotifier(false);
  bool _isDuplicate = false;

  @override
  void initState() {
    super.initState();
    _kodeController = TextEditingController(text: widget.cluster.kodeCluster);
    _namaController = TextEditingController(
      text: widget.cluster.namaPengukur ?? "",
    );
    _tanggalController = TextEditingController(
      text:
          widget.cluster.tanggalPengukuran != null
              ? widget.cluster.tanggalPengukuran!
                  .toIso8601String()
                  .split('T')
                  .first
              : "",
    );
    _latitudeController = TextEditingController(
      text: widget.titikIkat.latitude?.toString() ?? '',
    );
    _longitudeController = TextEditingController(
      text: widget.titikIkat.longitude?.toString() ?? '',
    );
    _altitudeController = TextEditingController(
      text: widget.titikIkat.altitude?.toString() ?? '',
    );
    _keteranganController = TextEditingController(
      text: widget.titikIkat.keterangan ?? '',
    );
    _urlFotoController = TextEditingController(
      text: widget.titikIkat.urlFoto ?? '',
    );

    _kodeController.addListener(_validateForm);
    _namaController.addListener(() {
      _syncCapitalizedWords(_namaController);
      _validateForm();
    });
    _tanggalController.addListener(_validateForm);
    _latitudeController.addListener(_validateForm);
    _longitudeController.addListener(_validateForm);
    _altitudeController.addListener(_validateForm);
    _validateForm();
  }

  @override
  void dispose() {
    _kodeController.dispose();
    _namaController.dispose();
    _tanggalController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _altitudeController.dispose();
    _keteranganController.dispose();
    _urlFotoController.dispose();
    _isFormValid.dispose();
    super.dispose();
  }

  void _validateForm() {
    final kode =
        _kodeController.text.replaceAll(RegExp(r'\s+'), '').toUpperCase();
    final nama = _namaController.text.trim();
    final latitude = double.tryParse(
      _latitudeController.text.trim().replaceAll(',', '.'),
    );
    final longitude = double.tryParse(
      _longitudeController.text.trim().replaceAll(',', '.'),
    );
    final altitudeText = _altitudeController.text.trim();
    final altitude = double.tryParse(altitudeText.replaceAll(',', '.'));
    final tanggal = DateTime.tryParse(_tanggalController.text.trim());

    final duplicate = widget.clusterNotifier.value.any(
      (c) => c.id != widget.cluster.id && c.kodeCluster.toUpperCase() == kode,
    );

    if (_isDuplicate != duplicate) {
      setState(() {
        _isDuplicate = duplicate;
      });
    } else {
      _isDuplicate = duplicate;
    }

    final coordinatesValid =
        latitude != null &&
        latitude.isFinite &&
        latitude >= -90 &&
        latitude <= 90 &&
        longitude != null &&
        longitude.isFinite &&
        longitude >= -180 &&
        longitude <= 180;
    final altitudeValid =
        altitudeText.isEmpty || (altitude != null && altitude.isFinite);
    final isValid =
        kode.isNotEmpty &&
        nama.isNotEmpty &&
        tanggal != null &&
        !duplicate &&
        coordinatesValid &&
        altitudeValid;
    if (_isFormValid.value != isValid) {
      _isFormValid.value = isValid;
    }
  }

  Future<void> _save() async {
    final kodeCluster =
        _kodeController.text.replaceAll(RegExp(r'\s+'), '').toUpperCase();
    final namaPengukur = _capitalizeWords(_namaController.text.trim());
    final tanggalText = _tanggalController.text.trim();
    DateTime? tanggalPengukuran;
    if (tanggalText.isNotEmpty) {
      tanggalPengukuran = DateTime.tryParse(tanggalText);
    }

    final updated = ClusterModel(
      id: widget.cluster.id,
      kodeCluster: kodeCluster,
      namaPengukur: namaPengukur,
      tanggalPengukuran: tanggalPengukuran,
    );

    await widget.clusterNotifier.updateCluster(updated);
    final keterangan = _keteranganController.text.trim();
    final urlFoto = _urlFotoController.text.trim();
    await widget.titikIkatNotifier.updateTitikIkat(
      TitikIkatModel(
        id: widget.titikIkat.id,
        idCluster: widget.cluster.id!,
        nama: 'Titik Ikat $kodeCluster',
        latitude: double.parse(
          _latitudeController.text.trim().replaceAll(',', '.'),
        ),
        longitude: double.parse(
          _longitudeController.text.trim().replaceAll(',', '.'),
        ),
        altitude:
            _altitudeController.text.trim().isEmpty
                ? null
                : double.parse(
                  _altitudeController.text.trim().replaceAll(',', '.'),
                ),
        keterangan: keterangan.isEmpty ? null : keterangan,
        urlFoto: urlFoto.isEmpty ? null : urlFoto,
      ),
    );
    if (!mounted) return;
    Navigator.of(context).pop(updated);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: widget.cluster.tanggalPengukuran ?? now,
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

  Future<void> _pickCoordinate() async {
    final selected = await pickCoordinateFromMap(
      context,
      initialLatitude: double.tryParse(
        _latitudeController.text.trim().replaceAll(',', '.'),
      ),
      initialLongitude: double.tryParse(
        _longitudeController.text.trim().replaceAll(',', '.'),
      ),
    );
    if (selected == null || !mounted) return;
    _latitudeController.text = selected.latitude.toStringAsFixed(7);
    _longitudeController.text = selected.longitude.toStringAsFixed(7);
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
          title: Text("Edit Klaster", style: TextStyle(color: dialogText)),
          content: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _kodeController,
                    style: TextStyle(color: dialogText),
                    decoration: InputDecoration(
                      labelText: "Kode Klaster",
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
                      errorText: _isDuplicate ? "Kode klaster sudah ada" : null,
                    ),
                    textCapitalization: TextCapitalization.characters,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _namaController,
                    style: TextStyle(color: dialogText),
                    decoration: InputDecoration(
                      labelText: "Nama Pengukur",
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
                          suffixIcon: Icon(
                            Icons.calendar_today,
                            color: isDark ? Colors.white70 : null,
                          ),
                          hintText: "YYYY-MM-DD",
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Koordinat Titik Ikat',
                      style: TextStyle(
                        color: dialogText,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Nama dibuat otomatis mengikuti kode klaster.',
                      style: TextStyle(color: labelColor, fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _latitudeController,
                    style: TextStyle(color: dialogText),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    decoration: _fieldDecoration(
                      'Lintang Titik Ikat (wajib)',
                      isDark,
                      labelColor,
                      helperText: 'Rentang -90 sampai 90',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _longitudeController,
                    style: TextStyle(color: dialogText),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    decoration: _fieldDecoration(
                      'Bujur Titik Ikat (wajib)',
                      isDark,
                      labelColor,
                      helperText: 'Rentang -180 sampai 180',
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _pickCoordinate,
                      icon: const Icon(Icons.map_outlined),
                      label: const Text('Pilih dari Peta'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: dialogText,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _altitudeController,
                    style: TextStyle(color: dialogText),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    decoration: _fieldDecoration(
                      'Altitude Titik Ikat (opsional)',
                      isDark,
                      labelColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _keteranganController,
                    style: TextStyle(color: dialogText),
                    maxLines: 3,
                    decoration: _fieldDecoration(
                      'Keterangan Titik Ikat (opsional)',
                      isDark,
                      labelColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _urlFotoController,
                    style: TextStyle(color: dialogText),
                    keyboardType: TextInputType.url,
                    decoration: _fieldDecoration(
                      'Link gambar Titik Ikat (opsional)',
                      isDark,
                      labelColor,
                      helperText: 'URL gambar atau tautan Google Drive',
                    ),
                  ),
                ],
              ),
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
                  style: ButtonStyle(
                    foregroundColor: WidgetStateProperty.resolveWith(
                      (states) =>
                          states.contains(WidgetState.disabled)
                              ? Colors.grey
                              : dialogText,
                    ),
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

  InputDecoration _fieldDecoration(
    String label,
    bool isDark,
    Color? labelColor, {
    String? helperText,
  }) => InputDecoration(
    labelText: label,
    labelStyle: TextStyle(color: labelColor),
    helperText: helperText,
    helperStyle: TextStyle(color: labelColor),
    border: const OutlineInputBorder(),
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(color: isDark ? Colors.white54 : Colors.grey),
    ),
  );
}
