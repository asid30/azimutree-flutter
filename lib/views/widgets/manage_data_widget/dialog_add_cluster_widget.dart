import 'package:flutter/material.dart';
import 'package:azimutree/data/notifiers/cluster_notifier.dart';
import 'package:azimutree/data/notifiers/notifiers.dart';
import 'package:azimutree/data/models/cluster_model.dart';
import 'package:azimutree/data/models/titik_ikat_model.dart';
import 'package:azimutree/data/notifiers/titik_ikat_notifier.dart';

class DialogAddClusterWidget extends StatefulWidget {
  final ClusterNotifier clusterNotifier;

  final TitikIkatNotifier titikIkatNotifier;

  const DialogAddClusterWidget({
    super.key,
    required this.clusterNotifier,
    required this.titikIkatNotifier,
  });

  @override
  State<DialogAddClusterWidget> createState() => _DialogAddClusterWidgetState();
}

class _DialogAddClusterWidgetState extends State<DialogAddClusterWidget> {
  final TextEditingController _kodeClusterController = TextEditingController();
  final TextEditingController _namaPengukurController = TextEditingController();
  final TextEditingController _tanggalPengukuranController =
      TextEditingController();
  final TextEditingController _titikIkatLatitudeController =
      TextEditingController();
  final TextEditingController _titikIkatLongitudeController =
      TextEditingController();
  final TextEditingController _titikIkatAltitudeController =
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
    _titikIkatLatitudeController.addListener(_validateForm);
    _titikIkatLongitudeController.addListener(_validateForm);
    _titikIkatAltitudeController.addListener(_validateForm);
  }

  @override
  void dispose() {
    _kodeClusterController.dispose();
    _namaPengukurController.dispose();
    _tanggalPengukuranController.dispose();
    _titikIkatLatitudeController.dispose();
    _titikIkatLongitudeController.dispose();
    _titikIkatAltitudeController.dispose();
    _isFormValid.dispose();
    super.dispose();
  }

  void _validateForm() {
    final kode =
        _kodeClusterController.text
            .replaceAll(RegExp(r'\s+'), '')
            .toUpperCase();
    final nama = _namaPengukurController.text.trim();
    final latitude = double.tryParse(
      _titikIkatLatitudeController.text.trim().replaceAll(',', '.'),
    );
    final longitude = double.tryParse(
      _titikIkatLongitudeController.text.trim().replaceAll(',', '.'),
    );
    final altitudeText = _titikIkatAltitudeController.text.trim();
    final altitude = double.tryParse(altitudeText.replaceAll(',', '.'));

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
        coordinatesValid &&
        altitudeValid &&
        !isDuplicate;

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

    final titikIkat = TitikIkatModel(
      idCluster: 0,
      nama: 'Titik Ikat $kodeCluster',
      latitude: double.parse(
        _titikIkatLatitudeController.text.trim().replaceAll(',', '.'),
      ),
      longitude: double.parse(
        _titikIkatLongitudeController.text.trim().replaceAll(',', '.'),
      ),
      altitude:
          _titikIkatAltitudeController.text.trim().isEmpty
              ? null
              : double.parse(
                _titikIkatAltitudeController.text.trim().replaceAll(',', '.'),
              ),
    );

    await widget.clusterNotifier.addClusterWithTitikIkat(newCluster, titikIkat);
    await widget.titikIkatNotifier.loadTitikIkat();

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
            isDark ? const Color.fromARGB(255, 32, 72, 43) : Colors.white;
        final dialogText = isDark ? Colors.white : Colors.black;
        final labelColor = isDark ? Colors.white70 : null;
        return AlertDialog(
          backgroundColor: dialogBgColor,
          title: Text(
            "Tambah Klaster Baru",
            style: TextStyle(color: dialogText),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Kode Klaster
                TextField(
                  controller: _kodeClusterController,
                  style: TextStyle(color: dialogText),
                  decoration: InputDecoration(
                    labelText: "Kode Klaster (wajib)",
                    labelStyle: TextStyle(color: labelColor),
                    border: const OutlineInputBorder(),
                    helperText: "Contoh: CL1 (otomatis huruf besar)",
                    helperStyle: TextStyle(color: dialogText),
                    helperMaxLines: 2,
                    errorText:
                        _isDuplicateCode
                            ? 'Kode klaster sudah ada, gunakan kode lain.'
                            : null,
                    errorStyle: TextStyle(
                      color: isDark ? Colors.orange : Colors.redAccent,
                    ),
                    errorMaxLines: 2,
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
                  textCapitalization: TextCapitalization.characters,
                ),
                const SizedBox(height: 8),

                // Nama Pengukur
                TextField(
                  controller: _namaPengukurController,
                  style: TextStyle(color: dialogText),
                  decoration: InputDecoration(
                    labelText: "Nama Pengukur (wajib)",
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

                // Tanggal opsional
                GestureDetector(
                  onTap: _selectDate,
                  child: AbsorbPointer(
                    child: TextField(
                      controller: _tanggalPengukuranController,
                      readOnly: true,
                      style: TextStyle(color: dialogText),
                      decoration: InputDecoration(
                        labelText: "Tanggal Pengukuran (opsional)",
                        labelStyle: TextStyle(color: labelColor),
                        border: const OutlineInputBorder(),
                        suffixIcon: Icon(
                          Icons.calendar_today,
                          color: dialogText,
                        ),
                        hintText: "YYYY-MM-DD",
                        hintStyle: TextStyle(
                          color: isDark ? Colors.white54 : null,
                        ),
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
                  controller: _titikIkatLatitudeController,
                  style: TextStyle(color: dialogText),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Lintang Titik Ikat (wajib)',
                    labelStyle: TextStyle(color: labelColor),
                    helperText: 'Rentang -90 sampai 90',
                    helperStyle: TextStyle(color: labelColor),
                    border: const OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: isDark ? Colors.white54 : Colors.grey,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _titikIkatLongitudeController,
                  style: TextStyle(color: dialogText),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Bujur Titik Ikat (wajib)',
                    labelStyle: TextStyle(color: labelColor),
                    helperText: 'Rentang -180 sampai 180',
                    helperStyle: TextStyle(color: labelColor),
                    border: const OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: isDark ? Colors.white54 : Colors.grey,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _titikIkatAltitudeController,
                  style: TextStyle(color: dialogText),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Altitude Titik Ikat (opsional)',
                    labelStyle: TextStyle(color: labelColor),
                    border: const OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: isDark ? Colors.white54 : Colors.grey,
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
              child: Text("Batal", style: TextStyle(color: dialogText)),
              onPressed: () => Navigator.of(context).pop(false),
            ),

            // Tombol Simpan pakai ValueListenableBuilder
            ValueListenableBuilder<bool>(
              valueListenable: _isFormValid,
              builder: (context, isValid, _) {
                return TextButton(
                  onPressed: isValid ? _saveCluster : null,
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all(dialogBgColor),
                    foregroundColor: WidgetStateProperty.resolveWith((states) {
                      if (isDark) {
                        return states.contains(WidgetState.disabled)
                            ? Colors.grey
                            : Colors.white;
                      }
                      return states.contains(WidgetState.disabled)
                          ? Colors.grey
                          : Colors.black;
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
