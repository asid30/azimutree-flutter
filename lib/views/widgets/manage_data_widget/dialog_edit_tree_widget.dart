import 'package:flutter/material.dart';
import 'package:azimutree/data/models/cluster_model.dart';
import 'package:azimutree/data/models/plot_model.dart';
import 'package:azimutree/data/models/tree_model.dart';
import 'package:azimutree/data/notifiers/tree_notifier.dart';

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
    _kodeController = TextEditingController(text: widget.tree.kodePohon.toString());
    _namaController = TextEditingController(text: widget.tree.namaPohon ?? "");
    _ilmiahController = TextEditingController(text: widget.tree.namaIlmiah ?? "");
    _azimutController = TextEditingController(
      text: widget.tree.azimut != null ? widget.tree.azimut!.toStringAsFixed(1) : "",
    );
    _jarakController = TextEditingController(
      text: widget.tree.jarakPusatM != null ? widget.tree.jarakPusatM!.toStringAsFixed(2) : "",
    );
    _latitudeController = TextEditingController(
      text: widget.tree.latitude != null ? widget.tree.latitude!.toStringAsFixed(6) : "",
    );
    _longitudeController = TextEditingController(
      text: widget.tree.longitude != null ? widget.tree.longitude!.toStringAsFixed(6) : "",
    );
    _altitudeController = TextEditingController(
      text: widget.tree.altitude != null ? widget.tree.altitude!.toString() : "",
    );
    _keteranganController = TextEditingController(text: widget.tree.keterangan ?? "");
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

    final duplicate = kode != null
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
        _keteranganController.text.trim().isNotEmpty ? _capitalizeWords(_keteranganController.text.trim()) : null;
    final urlFoto = _urlController.text.trim().isNotEmpty ? _urlController.text.trim() : null;

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
  }) =>
      TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          errorText: errorText,
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
    return AlertDialog(
      title: const Text("Edit Pohon"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              initialValue: _clusterLabel,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: "Klaster",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: _plotLabel,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: "Plot",
                border: OutlineInputBorder(),
              ),
            ),
            _textField(
              controller: _kodeController,
              label: "Kode Pohon",
              type: TextInputType.number,
              errorText: _isDuplicate ? "Kode pohon sudah ada" : null,
            ),
            const SizedBox(height: 8),
            _textField(
              controller: _namaController,
              label: "Nama Pohon",
              caps: TextCapitalization.words,
            ),
            const SizedBox(height: 8),
            _textField(
              controller: _ilmiahController,
              label: "Nama Ilmiah",
              caps: TextCapitalization.words,
            ),
            const SizedBox(height: 8),
            _dualFields(
              _textField(
                controller: _latitudeController,
                label: "Latitude",
                type: const TextInputType.numberWithOptions(decimal: true, signed: true),
              ),
              _textField(
                controller: _longitudeController,
                label: "Longitude",
                type: const TextInputType.numberWithOptions(decimal: true, signed: true),
              ),
            ),
            const SizedBox(height: 8),
            _textField(
              controller: _altitudeController,
              label: "Altitude (opsional)",
              type: const TextInputType.numberWithOptions(decimal: true),
            ),
            _textField(
              controller: _urlController,
              label: "URL Foto",
              type: TextInputType.url,
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
