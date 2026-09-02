import 'package:azimutree/data/models/cluster_model.dart';
import 'package:azimutree/data/models/plot_model.dart';
import 'package:azimutree/data/models/titik_ikat_model.dart';
import 'package:azimutree/data/notifiers/notifiers.dart';
import 'package:azimutree/data/notifiers/plot_notifier.dart';
import 'package:azimutree/services/azimuth_latlong_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class _CommaToDotNoSpaceFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final sanitized = newValue.text.replaceAll(',', '.').replaceAll(' ', '');
    if (sanitized == newValue.text) return newValue;
    final offset = newValue.selection.baseOffset.clamp(0, newValue.text.length);
    final beforeCursor = newValue.text
        .substring(0, offset)
        .replaceAll(',', '.')
        .replaceAll(' ', '');
    return TextEditingValue(
      text: sanitized,
      selection: TextSelection.collapsed(offset: beforeCursor.length),
    );
  }
}

enum PlotPositionInputMode { azimuthDistance, coordinates }

class _PlotReference {
  final String key;
  final String label;
  final double latitude;
  final double longitude;

  const _PlotReference({
    required this.key,
    required this.label,
    required this.latitude,
    required this.longitude,
  });
}

class DialogAddPlotWidget extends StatefulWidget {
  final PlotNotifier plotNotifier;
  final List<ClusterModel> clusters;
  final List<TitikIkatModel> titikIkat;

  const DialogAddPlotWidget({
    super.key,
    required this.plotNotifier,
    required this.clusters,
    required this.titikIkat,
  });

  @override
  State<DialogAddPlotWidget> createState() => _DialogAddPlotWidgetState();
}

class _DialogAddPlotWidgetState extends State<DialogAddPlotWidget> {
  final _azimuthController = TextEditingController();
  final _distanceController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _altitudeController = TextEditingController();
  final _isFormValid = ValueNotifier(false);

  int? _selectedClusterId;
  int? _selectedPlotCode;
  String? _selectedReferenceKey;
  bool _isDuplicateCode = false;
  PlotPositionInputMode _positionMode = PlotPositionInputMode.azimuthDistance;

  @override
  void initState() {
    super.initState();
    if (widget.clusters.isNotEmpty) {
      final activeCode = selectedDropdownClusterNotifier.value;
      final active = widget.clusters.where(
        (cluster) => cluster.kodeCluster == activeCode,
      );
      _selectedClusterId =
          active.isNotEmpty ? active.first.id : widget.clusters.first.id;
      _resetSelections();
    }
    for (final controller in [
      _azimuthController,
      _distanceController,
      _latitudeController,
      _longitudeController,
    ]) {
      controller.addListener(_validateForm);
    }
    _validateForm();
  }

  @override
  void dispose() {
    _azimuthController.dispose();
    _distanceController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _altitudeController.dispose();
    _isFormValid.dispose();
    super.dispose();
  }

  List<PlotModel> get _plotsForSelectedCluster =>
      widget.plotNotifier.value
          .where((plot) => plot.idCluster == _selectedClusterId)
          .toList()
        ..sort((a, b) => a.kodePlot.compareTo(b.kodePlot));

  List<int> get _availablePlotCodes {
    final used = _plotsForSelectedCluster.map((plot) => plot.kodePlot).toSet();
    return [1, 2, 3, 4].where((code) => !used.contains(code)).toList();
  }

  List<_PlotReference> get _referenceOptions {
    final references = <_PlotReference>[];
    final anchors = widget.titikIkat.where(
      (anchor) =>
          anchor.idCluster == _selectedClusterId &&
          anchor.latitude != null &&
          anchor.longitude != null,
    );
    if (anchors.isNotEmpty) {
      final anchor = anchors.first;
      references.add(
        _PlotReference(
          key: 'anchor:${anchor.id ?? anchor.idCluster}',
          label: 'Titik Ikat',
          latitude: anchor.latitude!,
          longitude: anchor.longitude!,
        ),
      );
    }

    // Plot pertama wajib mengacu ke Titik Ikat. Setelah itu plot yang sudah
    // tersimpan ikut menjadi pilihan referensi.
    if (_plotsForSelectedCluster.isNotEmpty) {
      for (final plot in _plotsForSelectedCluster) {
        if (plot.id == null) continue;
        references.add(
          _PlotReference(
            key: 'plot:${plot.id}',
            label: 'Plot ${plot.kodePlot}',
            latitude: plot.latitude,
            longitude: plot.longitude,
          ),
        );
      }
    }
    return references;
  }

  _PlotReference? get _selectedReference {
    for (final reference in _referenceOptions) {
      if (reference.key == _selectedReferenceKey) return reference;
    }
    return null;
  }

  void _resetSelections() {
    final codes = _availablePlotCodes;
    _selectedPlotCode = codes.isEmpty ? null : codes.first;
    final references = _referenceOptions;
    _selectedReferenceKey = references.isEmpty ? null : references.first.key;
  }

  void _validateForm() {
    final duplicate =
        _selectedClusterId != null &&
        _selectedPlotCode != null &&
        widget.plotNotifier.value.any(
          (plot) =>
              plot.idCluster == _selectedClusterId &&
              plot.kodePlot == _selectedPlotCode,
        );
    if (_isDuplicateCode != duplicate && mounted) {
      setState(() => _isDuplicateCode = duplicate);
    } else {
      _isDuplicateCode = duplicate;
    }

    bool positionValid;
    if (_positionMode == PlotPositionInputMode.azimuthDistance) {
      final azimuth = double.tryParse(_azimuthController.text.trim());
      final distance = double.tryParse(_distanceController.text.trim());
      positionValid =
          azimuth != null &&
          azimuth.isFinite &&
          azimuth >= 0 &&
          azimuth < 360 &&
          distance != null &&
          distance.isFinite &&
          distance >= 0;
    } else {
      final latitude = double.tryParse(_latitudeController.text.trim());
      final longitude = double.tryParse(_longitudeController.text.trim());
      positionValid =
          latitude != null &&
          latitude.isFinite &&
          latitude >= -90 &&
          latitude <= 90 &&
          longitude != null &&
          longitude.isFinite &&
          longitude >= -180 &&
          longitude <= 180;
    }

    final valid =
        _selectedClusterId != null &&
        _selectedPlotCode != null &&
        _selectedReference != null &&
        !_isDuplicateCode &&
        positionValid;
    if (_isFormValid.value != valid) _isFormValid.value = valid;
  }

  Future<void> _savePlot() async {
    final clusterId = _selectedClusterId;
    final plotCode = _selectedPlotCode;
    final reference = _selectedReference;
    if (clusterId == null || plotCode == null || reference == null) return;

    late final double latitude;
    late final double longitude;
    if (_positionMode == PlotPositionInputMode.azimuthDistance) {
      final point = AzimuthLatLongService.fromAzimuthDistance(
        centerLatDeg: reference.latitude,
        centerLonDeg: reference.longitude,
        azimuthDeg: double.parse(_azimuthController.text.trim()),
        distanceM: double.parse(_distanceController.text.trim()),
      );
      latitude = point.latitude;
      longitude = point.longitude;
    } else {
      latitude = double.parse(_latitudeController.text.trim());
      longitude = double.parse(_longitudeController.text.trim());
    }

    final duplicate = widget.plotNotifier.value.any(
      (plot) => plot.idCluster == clusterId && plot.kodePlot == plotCode,
    );
    if (duplicate) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kode plot sudah digunakan.')),
      );
      return;
    }

    final altitudeText = _altitudeController.text.trim();
    await widget.plotNotifier.addPlot(
      PlotModel(
        idCluster: clusterId,
        kodePlot: plotCode,
        latitude: latitude,
        longitude: longitude,
        altitude: altitudeText.isEmpty ? null : double.tryParse(altitudeText),
      ),
    );
    if (mounted) Navigator.of(context).pop(true);
  }

  InputDecoration _decoration(String label, bool isDark, {String? errorText}) =>
      InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: isDark ? Colors.white70 : null),
        border: const OutlineInputBorder(),
        errorText: errorText,
        errorMaxLines: 2,
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: isDark ? Colors.white54 : Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color:
                isDark ? Colors.white : Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
      );

  TextField _numberField(
    TextEditingController controller,
    String label,
    bool isDark, {
    bool signed = false,
  }) => TextField(
    controller: controller,
    style: TextStyle(color: isDark ? Colors.white : Colors.black),
    decoration: _decoration(label, isDark),
    keyboardType: TextInputType.numberWithOptions(
      decimal: true,
      signed: signed,
    ),
    inputFormatters: [
      _CommaToDotNoSpaceFormatter(),
      FilteringTextInputFormatter.allow(
        RegExp(signed ? r'[-0-9\.,]' : r'[0-9\.,]'),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isLightModeNotifier,
      builder: (context, isLightMode, _) {
        final isDark = !isLightMode;
        final background =
            isDark ? const Color.fromARGB(255, 32, 72, 43) : Colors.white;
        final foreground = isDark ? Colors.white : Colors.black;
        final references = _referenceOptions;
        return AlertDialog(
          backgroundColor: background,
          title: Text('Tambah Plot Baru', style: TextStyle(color: foreground)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  initialValue: _selectedClusterId,
                  dropdownColor: background,
                  style: TextStyle(color: foreground),
                  decoration: _decoration('Klaster', isDark),
                  isExpanded: true,
                  items:
                      widget.clusters
                          .map(
                            (cluster) => DropdownMenuItem(
                              value: cluster.id,
                              child: Text(cluster.kodeCluster),
                            ),
                          )
                          .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedClusterId = value;
                      _resetSelections();
                    });
                    _validateForm();
                  },
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<int>(
                  key: ValueKey('plot-code-$_selectedClusterId'),
                  initialValue: _selectedPlotCode,
                  dropdownColor: background,
                  style: TextStyle(color: foreground),
                  decoration: _decoration(
                    'Pilih Plot',
                    isDark,
                    errorText:
                        _isDuplicateCode ? 'Kode plot sudah dipakai.' : null,
                  ),
                  items:
                      _availablePlotCodes
                          .map(
                            (code) => DropdownMenuItem(
                              value: code,
                              child: Text('Plot $code'),
                            ),
                          )
                          .toList(),
                  onChanged: (value) {
                    setState(() => _selectedPlotCode = value);
                    _validateForm();
                  },
                ),
                if (_availablePlotCodes.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Text(
                      'Semua kode plot pada klaster ini sudah digunakan.',
                      style: TextStyle(
                        color: isDark ? Colors.orange : Colors.red,
                      ),
                    ),
                  ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  key: ValueKey('plot-reference-$_selectedClusterId'),
                  initialValue: _selectedReferenceKey,
                  dropdownColor: background,
                  style: TextStyle(color: foreground),
                  decoration: _decoration('Referensi posisi', isDark),
                  isExpanded: true,
                  items:
                      references
                          .map(
                            (reference) => DropdownMenuItem(
                              value: reference.key,
                              child: Text(reference.label),
                            ),
                          )
                          .toList(),
                  onChanged: (value) {
                    setState(() => _selectedReferenceKey = value);
                    _validateForm();
                  },
                ),
                if (references.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Text(
                      'Titik Ikat klaster belum memiliki koordinat.',
                      style: TextStyle(
                        color: isDark ? Colors.orange : Colors.red,
                      ),
                    ),
                  ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Metode input posisi',
                    style: TextStyle(
                      color: foreground,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                SegmentedButton<PlotPositionInputMode>(
                  segments: const [
                    ButtonSegment(
                      value: PlotPositionInputMode.azimuthDistance,
                      label: Text(
                        'Azimut & Jarak',
                        style: TextStyle(fontSize: 11),
                      ),
                      icon: Icon(Icons.explore_outlined, size: 16),
                    ),
                    ButtonSegment(
                      value: PlotPositionInputMode.coordinates,
                      label: Text(
                        'Lintang & Bujur',
                        style: TextStyle(fontSize: 11),
                      ),
                      icon: Icon(Icons.location_on_outlined, size: 16),
                    ),
                  ],
                  selected: {_positionMode},
                  multiSelectionEnabled: false,
                  showSelectedIcon: false,
                  style: ButtonStyle(
                    foregroundColor: WidgetStatePropertyAll(foreground),
                    backgroundColor: WidgetStateProperty.resolveWith((states) {
                      if (isDark && states.contains(WidgetState.selected)) {
                        return const Color(0xFF14351D);
                      }
                      return null;
                    }),
                  ),
                  onSelectionChanged: (selection) {
                    setState(() => _positionMode = selection.first);
                    _validateForm();
                  },
                ),
                const SizedBox(height: 10),
                if (_positionMode == PlotPositionInputMode.azimuthDistance)
                  Row(
                    children: [
                      Expanded(
                        child: _numberField(
                          _azimuthController,
                          'Azimut (°)',
                          isDark,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _numberField(
                          _distanceController,
                          'Jarak (m)',
                          isDark,
                        ),
                      ),
                    ],
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: _numberField(
                          _latitudeController,
                          'Lintang',
                          isDark,
                          signed: true,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _numberField(
                          _longitudeController,
                          'Bujur',
                          isDark,
                          signed: true,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 10),
                _numberField(
                  _altitudeController,
                  'Altitude (opsional)',
                  isDark,
                  signed: true,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Batal', style: TextStyle(color: foreground)),
            ),
            ValueListenableBuilder<bool>(
              valueListenable: _isFormValid,
              builder:
                  (context, valid, _) => TextButton(
                    onPressed: valid ? _savePlot : null,
                    style: TextButton.styleFrom(
                      backgroundColor: isDark ? const Color(0xFF14351D) : null,
                      foregroundColor: foreground,
                    ),
                    child: const Text('Simpan'),
                  ),
            ),
          ],
        );
      },
    );
  }
}
