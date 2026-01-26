import 'package:flutter/material.dart';
import 'package:azimutree/data/models/cluster_model.dart';
import 'package:azimutree/data/models/plot_model.dart';
import 'package:azimutree/data/models/tree_model.dart';
import 'package:azimutree/data/notifiers/tree_notifier.dart';
import 'package:azimutree/data/notifiers/notifiers.dart';

class DialogEditTreeWidget extends StatefulWidget {
  final TreeModel tree;
  final List<ClusterModel> clusters;
  final List<PlotModel> plots;
  final TreeNotifier treeNotifier;

  const DialogEditTreeWidget({
    super.key,
    required this.tree,
    required this.clusters,
    required this.plots,
    required this.treeNotifier,
  });

  @override
  State<DialogEditTreeWidget> createState() => _DialogEditTreeWidgetState();
}

class _DialogEditTreeWidgetState extends State<DialogEditTreeWidget> {
  late final TextEditingController _kodeController;
  late final TextEditingController _namaController;
  late final TextEditingController _ilmiahController;
  late final TextEditingController _azimutController;
  late final TextEditingController _jarakController;
  late final TextEditingController _latitudeController;
  late final TextEditingController _longitudeController;
  late final TextEditingController _altitudeController;
  late final TextEditingController _keteranganController;
  late final TextEditingController _urlController;

  late final String _clusterLabel;
  late final String _plotLabel;
  late final int _selectedPlotId;
  bool _isDuplicate = false;
  final ValueNotifier<bool> _isFormValid = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    _kodeController = TextEditingController(
      text: widget.tree.kodePohon.toString(),
    );
    _namaController = TextEditingController(text: widget.tree.namaPohon ?? "");
    _ilmiahController = TextEditingController(
      text: widget.tree.namaIlmiah ?? "",
    );
    _azimutController = TextEditingController(
      text:
          widget.tree.azimut != null
              ? widget.tree.azimut!.toStringAsFixed(1)
              : "",
    );
    _jarakController = TextEditingController(
      text:
          widget.tree.jarakPusatM != null
              ? widget.tree.jarakPusatM!.toStringAsFixed(2)
              : "",
    );
    _latitudeController = TextEditingController(
      text:
          widget.tree.latitude != null
              ? widget.tree.latitude!.toStringAsFixed(6)
              : "",
    );
    _longitudeController = TextEditingController(
      text:
          widget.tree.longitude != null
              ? widget.tree.longitude!.toStringAsFixed(6)
              : "",
    );
    _altitudeController = TextEditingController(
      text:
          widget.tree.altitude != null ? widget.tree.altitude!.toString() : "",
    );
    _keteranganController = TextEditingController(
      text: widget.tree.keterangan ?? "",
    );
    _urlController = TextEditingController(text: widget.tree.urlFoto ?? "");

    _selectedPlotId = widget.tree.plotId;
    final plot = widget.plots.firstWhere((p) => p.id == widget.tree.plotId);
    _plotLabel = "Plot ${plot.kodePlot}";
    _clusterLabel =
        widget.clusters.firstWhere((c) => c.id == plot.idCluster).kodeCluster;

    _kodeController.addListener(_validateForm);
    _namaController.addListener(_validateForm);
    _ilmiahController.addListener(_validateForm);
    _latitudeController.addListener(_validateForm);
    _longitudeController.addListener(_validateForm);
    _validateForm();
  }

  @override
  void dispose() {
    _kodeController.dispose();
    _namaController.dispose();
    _ilmiahController.dispose();
    _azimutController.dispose();
    _jarakController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _altitudeController.dispose();
    _keteranganController.dispose();
    _urlController.dispose();
    _isFormValid.dispose();
    super.dispose();
  }

  void _validateForm() {
    final kode = int.tryParse(_kodeController.text.trim());
    final nama = _namaController.text.trim();
    final ilmiah = _ilmiahController.text.trim();
    final latValid = double.tryParse(_latitudeController.text.trim()) != null;
    final lonValid = double.tryParse(_longitudeController.text.trim()) != null;

    final duplicate =
        kode != null
            ? widget.treeNotifier.value.any(
              (tree) =>
                  tree.plotId == _selectedPlotId &&
                  tree.id != widget.tree.id &&
                  tree.kodePohon == kode,
            )
            : false;

    if (_isDuplicate != duplicate) {
      setState(() {
        _isDuplicate = duplicate;
      });
    } else {
      _isDuplicate = duplicate;
    }

    final isValid =
        kode != null &&
        nama.isNotEmpty &&
        ilmiah.isNotEmpty &&
        latValid &&
        lonValid &&
        !_isDuplicate;

    if (_isFormValid.value != isValid) {
      _isFormValid.value = isValid;
    }
  }

  Future<void> _save() async {
    final kode = int.tryParse(_kodeController.text.trim());
    final lat = double.tryParse(_latitudeController.text.trim());
    final lon = double.tryParse(_longitudeController.text.trim());
    if (kode == null || lat == null || lon == null) return;

    final azimut = _parseDouble(_azimutController.text);
    final jarak = _parseDouble(_jarakController.text);
    final altitude = _parseDouble(_altitudeController.text);
    final keterangan =
        _keteranganController.text.trim().isNotEmpty
            ? _capitalizeWords(_keteranganController.text.trim())
            : null;
    final urlFoto =
        _urlController.text.trim().isNotEmpty
            ? _urlController.text.trim()
            : null;

    final updated = TreeModel(
      id: widget.tree.id,
      plotId: _selectedPlotId,
      kodePohon: kode,
      namaPohon: _capitalizeWords(_namaController.text.trim()),
      namaIlmiah: _capitalizeWords(_ilmiahController.text.trim()),
      azimut: azimut,
      jarakPusatM: jarak,
      latitude: lat,
      longitude: lon,
      altitude: altitude,
      keterangan: keterangan,
      urlFoto: urlFoto,
    );

    await widget.treeNotifier.updateTree(updated);
    if (!mounted) return;
    Navigator.of(context).pop(updated);
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

  double? _parseDouble(String input) {
    return input.trim().isNotEmpty ? double.tryParse(input.trim()) : null;
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    TextInputType? type,
    TextCapitalization caps = TextCapitalization.none,
    String? errorText,
    required Color dialogText,
    Color? labelColor,
    required bool isDark,
  }) => TextField(
    controller: controller,
    style: TextStyle(color: dialogText),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: labelColor),
      border: const OutlineInputBorder(),
      errorText: errorText,
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: isDark ? Colors.white54 : Colors.grey),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(
          color: isDark ? Colors.white : Theme.of(context).colorScheme.primary,
          width: 2.0,
        ),
      ),
    ),
    keyboardType: type,
    textCapitalization: caps,
  );

  Widget _dualFields(Widget left, Widget right) => Row(
    children: [
      Expanded(child: left),
      const SizedBox(width: 8),
      Expanded(child: right),
    ],
  );

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
          title: Text("Edit Pohon", style: TextStyle(color: dialogText)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  initialValue: _clusterLabel,
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
                TextFormField(
                  initialValue: _plotLabel,
                  readOnly: true,
                  style: TextStyle(color: dialogText),
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
                ),
                const SizedBox(height: 10),
                _textField(
                  controller: _kodeController,
                  label: "Kode Pohon",
                  type: TextInputType.number,
                  errorText: _isDuplicate ? "Kode pohon sudah ada" : null,
                  dialogText: dialogText,
                  labelColor: labelColor,
                  isDark: isDark,
                ),
                const SizedBox(height: 8),
                _textField(
                  controller: _namaController,
                  label: "Nama Pohon",
                  caps: TextCapitalization.words,
                  dialogText: dialogText,
                  labelColor: labelColor,
                  isDark: isDark,
                ),
                const SizedBox(height: 8),
                _textField(
                  controller: _ilmiahController,
                  label: "Nama Ilmiah",
                  caps: TextCapitalization.words,
                  dialogText: dialogText,
                  labelColor: labelColor,
                  isDark: isDark,
                ),
                const SizedBox(height: 8),
                _dualFields(
                  _textField(
                    controller: _latitudeController,
                    label: "Latitude",
                    type: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    dialogText: dialogText,
                    labelColor: labelColor,
                    isDark: isDark,
                  ),
                  _textField(
                    controller: _longitudeController,
                    label: "Longitude",
                    type: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    dialogText: dialogText,
                    labelColor: labelColor,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(height: 8),
                _textField(
                  controller: _altitudeController,
                  label: "Altitude (opsional)",
                  type: const TextInputType.numberWithOptions(decimal: true),
                  dialogText: dialogText,
                  labelColor: labelColor,
                  isDark: isDark,
                ),
                const SizedBox(height: 8),
                _textField(
                  controller: _urlController,
                  label: "URL Foto",
                  type: TextInputType.url,
                  dialogText: dialogText,
                  labelColor: labelColor,
                  isDark: isDark,
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
