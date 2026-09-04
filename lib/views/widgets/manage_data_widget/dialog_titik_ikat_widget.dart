import 'package:azimutree/data/models/cluster_model.dart';
import 'package:azimutree/data/models/plot_model.dart';
import 'package:azimutree/data/models/titik_ikat_model.dart';
import 'package:azimutree/data/notifiers/notifiers.dart';
import 'package:azimutree/data/notifiers/titik_ikat_notifier.dart';
import 'package:azimutree/services/azimuth_latlong_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class _DecimalInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(',', '.').replaceAll(' ', '');
    if (text == newValue.text) return newValue;
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

enum TitikIkatPositionInputMode { azimuthDistance, coordinates }

class DialogTitikIkatWidget extends StatefulWidget {
  const DialogTitikIkatWidget({
    super.key,
    required this.clusters,
    required this.plots,
    required this.titikIkatNotifier,
    this.titikIkat,
    this.initialClusterId,
  });

  final List<ClusterModel> clusters;
  final List<PlotModel> plots;
  final TitikIkatNotifier titikIkatNotifier;
  final TitikIkatModel? titikIkat;
  final int? initialClusterId;

  bool get isEditing => titikIkat != null;

  @override
  State<DialogTitikIkatWidget> createState() => _DialogTitikIkatWidgetState();
}

class _DialogTitikIkatWidgetState extends State<DialogTitikIkatWidget> {
  late final TextEditingController _namaController;
  late final TextEditingController _jenisController;
  late final TextEditingController _latitudeController;
  late final TextEditingController _longitudeController;
  late final TextEditingController _altitudeController;
  late final TextEditingController _azimutController;
  late final TextEditingController _jarakController;
  late final TextEditingController _keteranganController;
  late final TextEditingController _urlFotoController;
  final ValueNotifier<bool> _isFormValid = ValueNotifier(false);
  int? _selectedClusterId;
  String? _coordinateError;
  late TitikIkatPositionInputMode _positionMode;

  @override
  void initState() {
    super.initState();
    final data = widget.titikIkat;
    _positionMode =
        data?.latitude != null && data?.longitude != null
            ? TitikIkatPositionInputMode.coordinates
            : TitikIkatPositionInputMode.azimuthDistance;
    _selectedClusterId =
        data?.idCluster ?? widget.initialClusterId ?? widget.clusters.first.id;
    _namaController = TextEditingController(text: data?.nama ?? '');
    _jenisController = TextEditingController(text: data?.jenis ?? '');
    _latitudeController = TextEditingController(
      text: data?.latitude?.toString() ?? '',
    );
    _longitudeController = TextEditingController(
      text: data?.longitude?.toString() ?? '',
    );
    _altitudeController = TextEditingController(
      text: data?.altitude?.toString() ?? '',
    );
    _azimutController = TextEditingController(
      text: data?.azimutKePlot1?.toString() ?? '',
    );
    _jarakController = TextEditingController(
      text: data?.jarakKePlot1M?.toString() ?? '',
    );
    _keteranganController = TextEditingController(text: data?.keterangan ?? '');
    _urlFotoController = TextEditingController(text: data?.urlFoto ?? '');

    for (final controller in _controllers) {
      controller.addListener(_validateForm);
    }
    _validateForm(notifyUi: false);
  }

  List<TextEditingController> get _controllers => [
    _namaController,
    _jenisController,
    _latitudeController,
    _longitudeController,
    _altitudeController,
    _azimutController,
    _jarakController,
    _keteranganController,
    _urlFotoController,
  ];

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    _isFormValid.dispose();
    super.dispose();
  }

  void _validateForm({bool notifyUi = true}) {
    final latitudeText = _latitudeController.text.trim();
    final longitudeText = _longitudeController.text.trim();
    final latitude = double.tryParse(latitudeText);
    final longitude = double.tryParse(longitudeText);
    final altitudeText = _altitudeController.text.trim();
    final azimut = double.tryParse(_azimutController.text.trim());
    final jarak = double.tryParse(_jarakController.text.trim());

    String? coordinateError;
    var positionValid = false;
    if (_positionMode == TitikIkatPositionInputMode.azimuthDistance) {
      positionValid =
          azimut != null &&
          azimut.isFinite &&
          azimut >= 0 &&
          azimut < 360 &&
          jarak != null &&
          jarak.isFinite &&
          jarak > 0;
    } else {
      if (_plot1ForSelectedCluster == null) {
        coordinateError =
            'Mode koordinat memerlukan Plot 1 pada klaster terpilih.';
      } else if (latitudeText.isEmpty || longitudeText.isEmpty) {
        coordinateError = 'Lintang dan bujur wajib diisi.';
      } else if (latitude == null ||
          !latitude.isFinite ||
          latitude < -90 ||
          latitude > 90) {
        coordinateError = 'Lintang harus berada antara -90 dan 90.';
      } else if (longitude == null ||
          !longitude.isFinite ||
          longitude < -180 ||
          longitude > 180) {
        coordinateError = 'Bujur harus berada antara -180 dan 180.';
      } else {
        positionValid = true;
      }
    }

    final valid =
        _selectedClusterId != null &&
        _namaController.text.trim().isNotEmpty &&
        positionValid &&
        coordinateError == null &&
        (altitudeText.isEmpty ||
            (double.tryParse(altitudeText)?.isFinite ?? false));

    if (_isFormValid.value != valid) _isFormValid.value = valid;
    if (_coordinateError != coordinateError) {
      if (notifyUi && mounted) {
        setState(() => _coordinateError = coordinateError);
      } else {
        _coordinateError = coordinateError;
      }
    }
  }

  PlotModel? get _plot1ForSelectedCluster {
    if (_selectedClusterId == null) return null;
    try {
      return widget.plots.firstWhere(
        (plot) => plot.idCluster == _selectedClusterId && plot.kodePlot == 1,
      );
    } catch (_) {
      return null;
    }
  }

  String? _optionalText(TextEditingController controller) {
    final value = controller.text.trim();
    return value.isEmpty ? null : value;
  }

  Future<void> _save() async {
    _validateForm();
    if (!_isFormValid.value || _selectedClusterId == null) return;

    double? latitude;
    double? longitude;
    late double azimutKePlot1;
    late double jarakKePlot1M;

    if (_positionMode == TitikIkatPositionInputMode.azimuthDistance) {
      azimutKePlot1 = double.parse(_azimutController.text.trim());
      jarakKePlot1M = double.parse(_jarakController.text.trim());
    } else {
      latitude = double.parse(_latitudeController.text.trim());
      longitude = double.parse(_longitudeController.text.trim());
      final plot1 = _plot1ForSelectedCluster;
      if (plot1 == null) return;
      final calculated = AzimuthLatLongService.toAzimuthDistance(
        centerLatDeg: latitude,
        centerLonDeg: longitude,
        targetLatDeg: plot1.latitude,
        targetLonDeg: plot1.longitude,
      );
      azimutKePlot1 = calculated.azimuthDeg;
      jarakKePlot1M = calculated.distanceM;
    }

    final result = TitikIkatModel(
      id: widget.titikIkat?.id,
      idCluster: _selectedClusterId!,
      nama: _namaController.text.trim(),
      jenis: _optionalText(_jenisController),
      latitude: latitude,
      longitude: longitude,
      altitude: double.tryParse(_altitudeController.text.trim()),
      azimutKePlot1: azimutKePlot1,
      jarakKePlot1M: jarakKePlot1M,
      keterangan: _optionalText(_keteranganController),
      urlFoto: _optionalText(_urlFotoController),
    );

    if (widget.isEditing) {
      await widget.titikIkatNotifier.updateTitikIkat(result);
    } else {
      await widget.titikIkatNotifier.addTitikIkat(result);
    }

    if (!mounted) return;
    Navigator.of(context).pop(result);
  }

  InputDecoration _decoration(
    BuildContext context,
    String label, {
    String? helperText,
    String? errorText,
  }) {
    final isDark = !isLightModeNotifier.value;
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: isDark ? Colors.white70 : null),
      helperText: helperText,
      helperMaxLines: 2,
      helperStyle: TextStyle(color: isDark ? Colors.white70 : null),
      errorText: errorText,
      errorMaxLines: 2,
      border: const OutlineInputBorder(),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: isDark ? Colors.white54 : Colors.grey),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(
          color: isDark ? Colors.white : Theme.of(context).colorScheme.primary,
          width: 2,
        ),
      ),
    );
  }

  Widget _field(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
    String? helperText,
    String? errorText,
    bool numeric = false,
    int maxLines = 1,
  }) {
    final textColor =
        !isLightModeNotifier.value ? Colors.white : Colors.black87;
    return TextField(
      controller: controller,
      style: TextStyle(color: textColor),
      maxLines: maxLines,
      keyboardType:
          numeric
              ? const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              )
              : TextInputType.text,
      inputFormatters: numeric ? [_DecimalInputFormatter()] : null,
      decoration: _decoration(
        context,
        label,
        helperText: helperText,
        errorText: errorText,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isLightModeNotifier,
      builder: (context, isLightMode, _) {
        final isDark = !isLightMode;
        final background =
            isDark ? const Color.fromARGB(255, 32, 72, 43) : Colors.white;
        final textColor = isDark ? Colors.white : Colors.black87;

        return AlertDialog(
          backgroundColor: background,
          title: Text(
            widget.isEditing ? 'Edit Titik Ikat' : 'Tambah Titik Ikat',
            style: TextStyle(color: textColor),
          ),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    initialValue: _selectedClusterId,
                    dropdownColor: background,
                    style: TextStyle(color: textColor),
                    decoration: _decoration(context, 'Klaster (wajib)'),
                    items:
                        widget.clusters
                            .where((cluster) => cluster.id != null)
                            .map(
                              (cluster) => DropdownMenuItem(
                                value: cluster.id,
                                child: Text(cluster.kodeCluster),
                              ),
                            )
                            .toList(),
                    onChanged: (value) {
                      setState(() => _selectedClusterId = value);
                      _validateForm();
                    },
                  ),
                  const SizedBox(height: 10),
                  _field(
                    context,
                    controller: _namaController,
                    label: 'Nama (wajib)',
                    helperText: 'Contoh: Patok Utama',
                  ),
                  const SizedBox(height: 10),
                  _field(
                    context,
                    controller: _jenisController,
                    label: 'Jenis (opsional)',
                    helperText: 'Contoh: Patok, batu besar, atau persimpangan',
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Metode input posisi',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  SegmentedButton<TitikIkatPositionInputMode>(
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.resolveWith((
                        states,
                      ) {
                        if (isDark && states.contains(WidgetState.selected)) {
                          return const Color.fromARGB(255, 44, 93, 26);
                        }
                        return null;
                      }),
                      foregroundColor: WidgetStateProperty.resolveWith(
                        (states) => isDark ? Colors.white : null,
                      ),
                    ),
                    segments: const [
                      ButtonSegment(
                        value: TitikIkatPositionInputMode.azimuthDistance,
                        label: Text(
                          'Azimut & Jarak',
                          style: TextStyle(fontSize: 12),
                        ),
                        icon: Icon(Icons.explore_outlined, size: 16),
                      ),
                      ButtonSegment(
                        value: TitikIkatPositionInputMode.coordinates,
                        label: Text(
                          'Koordinat',
                          style: TextStyle(fontSize: 12),
                        ),
                        icon: Icon(Icons.location_on_outlined, size: 16),
                      ),
                    ],
                    selected: {_positionMode},
                    onSelectionChanged: (selection) {
                      setState(() {
                        _positionMode = selection.first;
                        _coordinateError = null;
                      });
                      _validateForm();
                    },
                    multiSelectionEnabled: false,
                    showSelectedIcon: false,
                  ),
                  const SizedBox(height: 10),
                  if (_positionMode ==
                      TitikIkatPositionInputMode.azimuthDistance) ...[
                    _field(
                      context,
                      controller: _azimutController,
                      label: 'Azimut menuju Plot 1 (wajib)',
                      helperText: 'Nilai 0 sampai kurang dari 360 derajat',
                      numeric: true,
                    ),
                    const SizedBox(height: 10),
                    _field(
                      context,
                      controller: _jarakController,
                      label: 'Jarak menuju Plot 1, meter (wajib)',
                      helperText: 'Harus lebih dari 0 meter',
                      numeric: true,
                    ),
                  ] else ...[
                    _field(
                      context,
                      controller: _latitudeController,
                      label: 'Lintang Titik Ikat (wajib)',
                      errorText: _coordinateError,
                      numeric: true,
                    ),
                    const SizedBox(height: 10),
                    _field(
                      context,
                      controller: _longitudeController,
                      label: 'Bujur Titik Ikat (wajib)',
                      numeric: true,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Azimut dan jarak menuju Plot 1 dihitung otomatis.',
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  _field(
                    context,
                    controller: _altitudeController,
                    label: 'Altitude meter (opsional)',
                    numeric: true,
                  ),
                  const SizedBox(height: 10),
                  _field(
                    context,
                    controller: _keteranganController,
                    label: 'Keterangan (opsional)',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 10),
                  _field(
                    context,
                    controller: _urlFotoController,
                    label: 'Link gambar (opsional)',
                    helperText: 'URL gambar atau tautan Google Drive',
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Batal', style: TextStyle(color: textColor)),
            ),
            ValueListenableBuilder<bool>(
              valueListenable: _isFormValid,
              builder: (context, valid, _) {
                return TextButton(
                  onPressed: valid ? _save : null,
                  child: const Text('Simpan'),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
