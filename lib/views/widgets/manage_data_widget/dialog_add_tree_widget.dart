import 'package:flutter/material.dart';
import 'package:azimutree/data/models/cluster_model.dart';
import 'package:azimutree/data/models/plot_model.dart';
import 'package:azimutree/data/models/tree_model.dart';
import 'package:azimutree/data/notifiers/tree_notifier.dart';

enum TreePositionInputMode { azimuthDistance, coordinates }

class DialogAddTreeWidget extends StatefulWidget {
  final TreeNotifier treeNotifier;
  final List<ClusterModel> clusters;
  final List<PlotModel> plots; // semua plot, nanti difilter per klaster

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
  // Controllers untuk field input
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

  TreePositionInputMode _positionMode = TreePositionInputMode.azimuthDistance;

  @override
  void initState() {
    super.initState();

    if (widget.clusters.isNotEmpty) {
      _selectedClusterId = widget.clusters.first.id;

      final firstPlots = _filteredPlots;
      if (firstPlots.isNotEmpty) {
        _selectedPlotId = firstPlots.first.id;
      }
    }
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
    super.dispose();
  }

  List<PlotModel> get _filteredPlots {
    if (_selectedClusterId == null) return [];
    return widget.plots
        .where((plot) => plot.idCluster == _selectedClusterId)
        .toList();
  }

  Future<void> _saveTree() async {
    final plotsForSelectedCluster = _filteredPlots;
    final hasPlotsForSelectedCluster = plotsForSelectedCluster.isNotEmpty;

    if (!hasPlotsForSelectedCluster || _selectedPlotId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Klaster ini belum memiliki plot. Tambahkan plot dulu.',
          ),
        ),
      );
      return;
    }

    final selectedPlotId = _selectedPlotId;

    // --- Common required fields ---
    final kodePohonText = _kodePohonController.text.trim();
    final namaPohonText = _namaPohonController.text.trim();
    final namaIlmiahText = _namaIlmiahController.text.trim();

    final kodePohon = int.tryParse(kodePohonText);

    if (kodePohonText.isEmpty ||
        namaPohonText.isEmpty ||
        namaIlmiahText.isEmpty ||
        kodePohon == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Kode pohon, nama pohon, dan nama ilmiah wajib diisi dan kode harus angka.',
          ),
        ),
      );
      return;
    }

    // --- Optional fields ---
    final keterangan =
        _keteranganController.text.trim().isNotEmpty
            ? _keteranganController.text.trim()
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

    // Altitude bisa diisi di kedua mode
    if (_altitudeController.text.trim().isNotEmpty) {
      altitude = double.tryParse(_altitudeController.text.trim());
    }

    // --- Mode 1: Azimut & Jarak ---
    if (_positionMode == TreePositionInputMode.azimuthDistance) {
      final azimutText = _azimutController.text.trim();
      final jarakText = _jarakPusatController.text.trim();

      azimut = double.tryParse(azimutText);
      jarakPusatM = double.tryParse(jarakText);

      if (azimutText.isEmpty ||
          jarakText.isEmpty ||
          azimut == null ||
          jarakPusatM == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Azimut dan jarak dari pusat wajib diisi di mode ini.',
            ),
          ),
        );
        return;
      }

      // Di mode ini koordinat tidak diisi manual (nanti bisa dihitung dari helper)
      latitude = null;
      longitude = null;
    } else {
      // --- Mode 2: Koordinat langsung ---
      final latText = _latitudeController.text.trim();
      final lonText = _longitudeController.text.trim();

      latitude = double.tryParse(latText);
      longitude = double.tryParse(lonText);

      if (latText.isEmpty ||
          lonText.isEmpty ||
          latitude == null ||
          longitude == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Latitude dan longitude wajib diisi di mode koordinat.',
            ),
          ),
        );
        return;
      }

      // Di mode koordinat, azimut & jarak dibiarkan null
      azimut = null;
      jarakPusatM = null;
    }

    final newTree = TreeModel(
      plotId: selectedPlotId!,
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

  @override
  Widget build(BuildContext context) {
    final plotsForSelectedCluster = _filteredPlots;
    final hasPlotsForSelectedCluster = plotsForSelectedCluster.isNotEmpty;

    final bool fieldsEnabled = hasPlotsForSelectedCluster;

    return AlertDialog(
      backgroundColor: Colors.white,
      title: const Text("Tambah Pohon Baru"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Dropdown Klaster (selalu aktif)
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
                  final filtered = _filteredPlots;
                  _selectedPlotId =
                      filtered.isNotEmpty ? filtered.first.id : null;
                });
              },
            ),
            const SizedBox(height: 8),

            // Dropdown Plot (tergantung klaster)
            DropdownButtonFormField<int>(
              initialValue: _selectedPlotId,
              decoration: const InputDecoration(
                labelText: "Plot",
                border: OutlineInputBorder(),
              ),
              isExpanded: true,
              items:
                  plotsForSelectedCluster.map((plot) {
                    return DropdownMenuItem<int>(
                      value: plot.id,
                      child: Text('Plot ${plot.kodePlot}'),
                    );
                  }).toList(),
              onChanged:
                  fieldsEnabled
                      ? (value) {
                        setState(() {
                          _selectedPlotId = value;
                        });
                      }
                      : null,
            ),
            if (!hasPlotsForSelectedCluster)
              const Padding(
                padding: EdgeInsets.only(top: 4.0),
                child: Text(
                  "Belum ada plot untuk klaster ini. Tambahkan plot terlebih dahulu.",
                  style: TextStyle(fontSize: 12, color: Colors.redAccent),
                ),
              ),
            const SizedBox(height: 8),

            // Mode input posisi
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Metode input posisi",
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(height: 4),
                SegmentedButton<TreePositionInputMode>(
                  segments: const [
                    ButtonSegment<TreePositionInputMode>(
                      value: TreePositionInputMode.azimuthDistance,
                      label: Text(
                        "Azimut & Jarak",
                        style: TextStyle(fontSize: 12),
                      ),
                      icon: Icon(Icons.explore_outlined, size: 16),
                    ),
                    ButtonSegment<TreePositionInputMode>(
                      value: TreePositionInputMode.coordinates,
                      label: Text("Koordinat", style: TextStyle(fontSize: 12)),
                      icon: Icon(Icons.location_on_outlined, size: 16),
                    ),
                  ],
                  selected: {_positionMode},
                  onSelectionChanged:
                      fieldsEnabled
                          ? (newSelection) {
                            setState(() {
                              _positionMode = newSelection.first;
                            });
                          }
                          : null,
                  multiSelectionEnabled: false,
                  showSelectedIcon: false,
                ),
              ],
            ),
            const SizedBox(height: 8),

            // 🔁 Field posisi: tergantung mode
            if (_positionMode == TreePositionInputMode.azimuthDistance) ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _azimutController,
                      decoration: const InputDecoration(
                        labelText: "Azimut (°)",
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      enabled: fieldsEnabled,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _jarakPusatController,
                      decoration: const InputDecoration(
                        labelText: "Jarak dari pusat (m)",
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
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
                      decoration: const InputDecoration(
                        labelText: "Latitude",
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      enabled: fieldsEnabled,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _longitudeController,
                      decoration: const InputDecoration(
                        labelText: "Longitude",
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      enabled: fieldsEnabled,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),

            // Altitude selalu setelah field posisi
            TextField(
              controller: _altitudeController,
              decoration: const InputDecoration(
                labelText: "Altitude (opsional)",
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              enabled: fieldsEnabled,
            ),
            const SizedBox(height: 8),

            TextField(
              controller: _kodePohonController,
              decoration: const InputDecoration(
                labelText: "Kode Pohon",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              enabled: fieldsEnabled,
            ),
            const SizedBox(height: 8),

            TextField(
              controller: _namaPohonController,
              decoration: const InputDecoration(
                labelText: "Nama Pohon",
                border: OutlineInputBorder(),
              ),
              enabled: fieldsEnabled,
            ),
            const SizedBox(height: 8),

            TextField(
              controller: _namaIlmiahController,
              decoration: const InputDecoration(
                labelText: "Nama Ilmiah",
                border: OutlineInputBorder(),
              ),
              enabled: fieldsEnabled,
            ),
            const SizedBox(height: 8),

            TextField(
              controller: _keteranganController,
              decoration: const InputDecoration(
                labelText: "Keterangan (opsional)",
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              enabled: fieldsEnabled,
            ),
            const SizedBox(height: 8),

            TextField(
              controller: _urlFotoController,
              decoration: const InputDecoration(
                labelText: "URL Foto (opsional)",
                border: OutlineInputBorder(),
              ),
              enabled: fieldsEnabled,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          child: const Text("Batal"),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        TextButton(
          onPressed: hasPlotsForSelectedCluster ? _saveTree : null,
          child: const Text("Simpan"),
        ),
      ],
    );
  }
}
