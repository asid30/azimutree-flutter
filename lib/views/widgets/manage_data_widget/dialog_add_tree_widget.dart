import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:azimutree/data/models/cluster_model.dart';
import 'package:azimutree/data/models/plot_model.dart';
import 'package:azimutree/data/models/tree_model.dart';
import 'package:azimutree/data/notifiers/tree_notifier.dart';
import 'package:azimutree/services/azimuth_latlong_service.dart';
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

enum TreePositionInputMode { azimuthDistance, coordinates }

class DialogAddTreeWidget extends StatefulWidget {
  final TreeNotifier treeNotifier;
  final List<ClusterModel> clusters;
  final List<PlotModel> plots;

  const DialogAddTreeWidget({
    super.key,
    required this.treeNotifier,
    required this.clusters,
    required this.plots,
  });

  @override
  State<DialogAddTreeWidget> createState() => _DialogAddTreeWidgetState();
}

class _DialogAddTreeWidgetState extends State<DialogAddTreeWidget> {
  // Controllers field input
  final TextEditingController _kodePohonController = TextEditingController();
  final TextEditingController _namaPohonController = TextEditingController();
  final TextEditingController _namaIlmiahController = TextEditingController();
  final TextEditingController _azimutController = TextEditingController();
  final TextEditingController _jarakPusatController = TextEditingController();
  final TextEditingController _keteranganController = TextEditingController();
  final TextEditingController _urlFotoController = TextEditingController();

  // Koordinat
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();
  final TextEditingController _altitudeController = TextEditingController();

  int? _selectedClusterId;
  int? _selectedPlotId;
  bool _isDuplicateCode = false;

  TreePositionInputMode _positionMode = TreePositionInputMode.azimuthDistance;

  // Notifier status valid form
  final ValueNotifier<bool> _isFormValid = ValueNotifier(false);

  @override
  void initState() {
    super.initState();

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
      final firstPlots = _filteredPlots;
      if (firstPlots.isNotEmpty) {
        _selectedPlotId = firstPlots.first.id;
      }
    }

    // listener untuk validasi real-time
    _kodePohonController.addListener(_validateForm);
    _namaPohonController.addListener(() {
      _syncCapitalizedWords(_namaPohonController);
      _validateForm();
    });
    _namaIlmiahController.addListener(() {
      _syncCapitalizedWords(_namaIlmiahController);
      _validateForm();
    });
    _azimutController.addListener(_validateForm);
    _jarakPusatController.addListener(_validateForm);
    _latitudeController.addListener(_validateForm);
    _longitudeController.addListener(_validateForm);

    _validateForm();
  }

  @override
  void dispose() {
    _kodePohonController.dispose();
    _namaPohonController.dispose();
    _namaIlmiahController.dispose();
    _azimutController.dispose();
    _jarakPusatController.dispose();
    _keteranganController.dispose();
    _urlFotoController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _altitudeController.dispose();
    _isFormValid.dispose();
    super.dispose();
  }

  List<PlotModel> get _filteredPlots {
    if (_selectedClusterId == null) return [];
    return widget.plots
        .where((plot) => plot.idCluster == _selectedClusterId)
        .toList();
  }

  void _validateForm() {
    final plotsForSelectedCluster = _filteredPlots;
    final hasPlotsForSelectedCluster = plotsForSelectedCluster.isNotEmpty;
    final hasSelectedPlot = _selectedPlotId != null;

    final kodePohonText = _kodePohonController.text.trim();
    final namaPohonText = _namaPohonController.text.trim();
    final namaIlmiahText = _namaIlmiahController.text.trim();
    final kodePohon = int.tryParse(kodePohonText);

    // posisi
    bool positionValid = false;

    if (_positionMode == TreePositionInputMode.azimuthDistance) {
      final azimut = double.tryParse(_azimutController.text.trim());
      final jarak = double.tryParse(_jarakPusatController.text.trim());
      positionValid = azimut != null && jarak != null;
    } else {
      final lat = double.tryParse(_latitudeController.text.trim());
      final lon = double.tryParse(_longitudeController.text.trim());
      positionValid = lat != null && lon != null;
    }

    final hasDuplicate =
        _selectedPlotId != null && kodePohon != null
            ? widget.treeNotifier.value.any(
              (tree) =>
                  tree.plotId == _selectedPlotId && tree.kodePohon == kodePohon,
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
        hasPlotsForSelectedCluster &&
        hasSelectedPlot &&
        kodePohonText.isNotEmpty &&
        namaPohonText.isNotEmpty &&
        namaIlmiahText.isNotEmpty &&
        kodePohon != null &&
        positionValid &&
        !hasDuplicate;

    if (_isFormValid.value != isValid) {
      _isFormValid.value = isValid;
    }
  }

  Future<void> _saveTree() async {
    final plotsForSelectedCluster = _filteredPlots;
    final hasPlotsForSelectedCluster = plotsForSelectedCluster.isNotEmpty;
    if (!hasPlotsForSelectedCluster || _selectedPlotId == null) {
      // harusnya ga kejadian karena tombol disabled, tapi buat jaga-jaga
      return;
    }

    final selectedPlotId = _selectedPlotId!;
    final selectedPlot = plotsForSelectedCluster.firstWhere(
      (plot) => plot.id == selectedPlotId,
    );

    final kodePohonText = _kodePohonController.text.trim();
    final namaPohonText = _capitalizeWords(_namaPohonController.text.trim());
    final namaIlmiahText = _capitalizeWords(_namaIlmiahController.text.trim());
    final kodePohon = int.tryParse(kodePohonText)!;

    final keterangan =
        _keteranganController.text.trim().isNotEmpty
            ? _capitalizeWords(_keteranganController.text.trim())
            : null;
    final urlFoto =
        _urlFotoController.text.trim().isNotEmpty
            ? _urlFotoController.text.trim()
            : null;

    double? azimut;
    double? jarakPusatM;
    double? latitude;
    double? longitude;
    double? altitude;

    if (_altitudeController.text.trim().isNotEmpty) {
      altitude = double.tryParse(_altitudeController.text.trim());
    }

    if (_positionMode == TreePositionInputMode.azimuthDistance) {
      azimut = double.tryParse(_azimutController.text.trim());
      jarakPusatM = double.tryParse(_jarakPusatController.text.trim());
      if (azimut == null || jarakPusatM == null) return;

      final targetPoint = AzimuthLatLongService.fromAzimuthDistance(
        centerLatDeg: selectedPlot.latitude,
        centerLonDeg: selectedPlot.longitude,
        azimuthDeg: azimut,
        distanceM: jarakPusatM,
      );

      latitude = targetPoint.latitude;
      longitude = targetPoint.longitude;
    } else {
      latitude = double.tryParse(_latitudeController.text.trim());
      longitude = double.tryParse(_longitudeController.text.trim());
      if (latitude == null || longitude == null) return;

      final azimuthDistance = AzimuthLatLongService.toAzimuthDistance(
        centerLatDeg: selectedPlot.latitude,
        centerLonDeg: selectedPlot.longitude,
        targetLatDeg: latitude,
        targetLonDeg: longitude,
      );

      azimut = azimuthDistance.azimuthDeg;
      jarakPusatM = azimuthDistance.distanceM;
    }

    final hasDuplicate = widget.treeNotifier.value.any(
      (tree) => tree.plotId == selectedPlotId && tree.kodePohon == kodePohon,
    );

    if (hasDuplicate) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Kode pohon sudah ada pada plot ini. Gunakan kode pohon lain.',
          ),
        ),
      );
      return;
    }

    final newTree = TreeModel(
      plotId: selectedPlotId,
      kodePohon: kodePohon,
      namaPohon: namaPohonText,
      namaIlmiah: namaIlmiahText,
      azimut: azimut,
      jarakPusatM: jarakPusatM,
      latitude: latitude,
      longitude: longitude,
      altitude: altitude,
      keterangan: keterangan,
      urlFoto: urlFoto,
    );

    await widget.treeNotifier.addTree(newTree);

    if (!mounted) return;
    Navigator.of(context).pop(true);
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
    final plotsForSelectedCluster = _filteredPlots;
    final hasPlotsForSelectedCluster = plotsForSelectedCluster.isNotEmpty;
    final bool fieldsEnabled = hasPlotsForSelectedCluster;

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
          title: Text("Tambah Pohon Baru", style: TextStyle(color: dialogText)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 8),
                // Dropdown Klaster
                DropdownButtonFormField<int>(
                  initialValue: _selectedClusterId,
                  style: TextStyle(color: dialogText),
                  dropdownColor: dialogBgColor,
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
                  isExpanded: true,
                  items:
                      widget.clusters.map((cluster) {
                        return DropdownMenuItem<int>(
                          value: cluster.id,
                          child: Text(
                            cluster.kodeCluster,
                            style: TextStyle(color: dialogText),
                          ),
                        );
                      }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedClusterId = value;
                      final filtered = _filteredPlots;
                      _selectedPlotId =
                          filtered.isNotEmpty ? filtered.first.id : null;
                    });
                    _validateForm();
                  },
                ),
                const SizedBox(height: 8),

                // Dropdown Plot
                DropdownButtonFormField<int>(
                  initialValue: _selectedPlotId,
                  style: TextStyle(color: dialogText),
                  dropdownColor: dialogBgColor,
                  decoration: InputDecoration(
                    labelText: "Plot",
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
                  isExpanded: true,
                  items:
                      plotsForSelectedCluster.map((plot) {
                        return DropdownMenuItem<int>(
                          value: plot.id,
                          child: Text(
                            'Plot ${plot.kodePlot}',
                            style: TextStyle(color: dialogText),
                          ),
                        );
                      }).toList(),
                  onChanged:
                      fieldsEnabled
                          ? (value) {
                            setState(() {
                              _selectedPlotId = value;
                            });
                            _validateForm();
                          }
                          : null,
                ),
                if (!hasPlotsForSelectedCluster)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      "Belum ada plot untuk klaster ini. Tambahkan plot terlebih dahulu.",
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.orange : Colors.redAccent,
                      ),
                    ),
                  ),
                const SizedBox(height: 8),

                // Metode input posisi
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Metode input posisi",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: dialogText,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    SegmentedButton<TreePositionInputMode>(
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.resolveWith((
                          states,
                        ) {
                          if (isDark && states.contains(WidgetState.selected)) {
                            return const Color.fromARGB(255, 44, 93, 26);
                          }
                          return null;
                        }),
                        foregroundColor: WidgetStateProperty.resolveWith((
                          states,
                        ) {
                          return isDark ? Colors.white : null;
                        }),
                      ),
                      segments: [
                        ButtonSegment<TreePositionInputMode>(
                          value: TreePositionInputMode.azimuthDistance,
                          label: Text(
                            "Azimut & Jarak",
                            style: TextStyle(fontSize: 12, color: dialogText),
                          ),
                          icon: Icon(
                            Icons.explore_outlined,
                            size: 16,
                            color: dialogText,
                          ),
                        ),
                        ButtonSegment<TreePositionInputMode>(
                          value: TreePositionInputMode.coordinates,
                          label: Text(
                            "Koordinat",
                            style: TextStyle(fontSize: 12, color: dialogText),
                          ),
                          icon: Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: dialogText,
                          ),
                        ),
                      ],
                      selected: {_positionMode},
                      onSelectionChanged:
                          fieldsEnabled
                              ? (newSelection) {
                                setState(() {
                                  _positionMode = newSelection.first;
                                });
                                _validateForm();
                              }
                              : null,
                      multiSelectionEnabled: false,
                      showSelectedIcon: false,
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Field posisi sesuai mode
                if (_positionMode == TreePositionInputMode.azimuthDistance) ...[
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _azimutController,
                          style: TextStyle(color: dialogText),
                          decoration: InputDecoration(
                            labelText: "Azimut (°)",
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
                          inputFormatters: [
                            _CommaToDotNoSpaceFormatter(),
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9\.,]'),
                            ),
                          ],
                          enabled: fieldsEnabled,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _jarakPusatController,
                          style: TextStyle(color: dialogText),
                          decoration: InputDecoration(
                            labelText: "Jarak dari pusat (m)",
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
                          inputFormatters: [
                            _CommaToDotNoSpaceFormatter(),
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9\.,]'),
                            ),
                          ],
                          enabled: fieldsEnabled,
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
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
                          inputFormatters: [
                            _CommaToDotNoSpaceFormatter(),
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[-0-9\.,]'),
                            ),
                          ],
                          enabled: fieldsEnabled,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
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
                          inputFormatters: [
                            _CommaToDotNoSpaceFormatter(),
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[-0-9\.,]'),
                            ),
                          ],
                          enabled: fieldsEnabled,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),

                // Altitude
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
                  inputFormatters: [
                    _CommaToDotNoSpaceFormatter(),
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9\.,-]')),
                  ],
                  enabled: fieldsEnabled,
                ),
                const SizedBox(height: 8),

                // Identitas pohon
                TextField(
                  controller: _kodePohonController,
                  style: TextStyle(color: dialogText),
                  decoration: InputDecoration(
                    labelText: "Kode Pohon",
                    labelStyle: TextStyle(color: labelColor),
                    border: const OutlineInputBorder(),
                    errorText:
                        _isDuplicateCode
                            ? 'Kode pohon sudah ada, gunakan kode lain.'
                            : null,
                    errorStyle: TextStyle(
                      color: isDark ? Colors.orange : Colors.redAccent,
                    ),
                    errorBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: isDark ? Colors.orange : Colors.redAccent,
                      ),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color:
                            isDark
                                ? Colors.orange
                                : Theme.of(context).colorScheme.error,
                        width: 2.0,
                      ),
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
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  enabled: fieldsEnabled,
                ),
                const SizedBox(height: 8),

                TextField(
                  controller: _namaPohonController,
                  style: TextStyle(color: dialogText),
                  decoration: InputDecoration(
                    labelText: "Nama Pohon",
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
                  enabled: fieldsEnabled,
                ),
                const SizedBox(height: 8),

                TextField(
                  controller: _namaIlmiahController,
                  style: TextStyle(color: dialogText),
                  decoration: InputDecoration(
                    labelText: "Nama Ilmiah",
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
                  enabled: fieldsEnabled,
                ),
                const SizedBox(height: 8),

                // Opsional
                TextField(
                  controller: _keteranganController,
                  style: TextStyle(color: dialogText),
                  decoration: InputDecoration(
                    labelText: "Keterangan (opsional)",
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
                  maxLines: 2,
                  textCapitalization: TextCapitalization.sentences,
                  enabled: fieldsEnabled,
                ),
                const SizedBox(height: 8),

                TextField(
                  controller: _urlFotoController,
                  style: TextStyle(color: dialogText),
                  decoration: InputDecoration(
                    labelText: "URL Foto (opsional)",
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
                  enabled: fieldsEnabled,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text("Batal", style: TextStyle(color: dialogText)),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            ValueListenableBuilder<bool>(
              valueListenable: _isFormValid,
              builder: (context, isValid, _) {
                return TextButton(
                  onPressed:
                      (isValid && hasPlotsForSelectedCluster)
                          ? _saveTree
                          : null,
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
