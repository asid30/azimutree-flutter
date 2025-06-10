import 'package:azimutree/data/notifiers/notifiers.dart';
import 'package:azimutree/views/widgets/appbar_widget.dart';
import 'package:azimutree/views/widgets/sidebar_widget.dart';
import 'package:flutter/material.dart';

// Import DatabaseHelper yang baru
import 'package:azimutree/data/database/database_helper.dart'; // Perhatikan perubahan path
import 'package:azimutree/data/models/cluster.dart';
import 'package:azimutree/data/models/plot.dart';
import 'package:azimutree/data/models/pohon.dart';
import 'package:azimutree/services/random_data_generator.dart';
import 'package:azimutree/services/location_utils.dart'; // Import LocationUtils yang baru
import 'package:intl/intl.dart';

class ManageDataPage extends StatefulWidget {
  const ManageDataPage({super.key});

  @override
  State<ManageDataPage> createState() => _ManageDataPageState();
}

class _ManageDataPageState extends State<ManageDataPage> {
  Cluster? _selectedCluster;
  List<Cluster> _allClusters = [];
  int? _selectedClusterId;

  List<Plot> _plots = [];
  Map<int, List<Pohon>> _pohonMap = {};
  int _totalPohonCount = 0;

  bool _isLoading = true;

  // Mendapatkan instance DatabaseHelper
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  @override
  void initState() {
    super.initState();
    _loadDataFromDatabase();
  }

  Future<void> _loadDataFromDatabase() async {
    setState(() {
      _isLoading = true;
    });

    // Pastikan database terinisialisasi dan DAO siap
    await _dbHelper.database;

    _allClusters = await _dbHelper.clusterDao.getAllClusters();

    if (_allClusters.isEmpty) {
      _selectedClusterId = null;
      _selectedCluster = null;
    } else {
      if (_selectedClusterId == null ||
          !_allClusters.any((c) => c.id == _selectedClusterId)) {
        _selectedClusterId = _allClusters.first.id;
      }
      _selectedCluster = await _dbHelper.clusterDao.getClusterById(
        _selectedClusterId!,
      );
    }

    _plots = [];
    _pohonMap = {};
    _totalPohonCount = 0;

    if (_selectedCluster != null && _selectedCluster!.id != null) {
      _plots = await _dbHelper.plotDao.getPlotsByClusterId(
        _selectedCluster!.id!,
      );
      for (var plot in _plots) {
        if (plot.id != null) {
          final pohons = await _dbHelper.pohonDao.getPohonsByPlotId(plot.id!);
          _pohonMap[plot.id!] = pohons;
          _totalPohonCount += pohons.length;
        }
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  // --- Fungsi Penambahan Data Random ---

  Future<void> _addRandomCluster() async {
    final newCluster = Cluster(
      kodeCluster: RandomDataGenerator.generateRandomKodeCluster(),
      namaPengukur: RandomDataGenerator.generateRandomNamaPengukur(),
      tanggalPengukuran: DateTime.now(),
    );

    final int newClusterId = await _dbHelper.clusterDao.insertCluster(
      newCluster,
    );
    _showSnackbar(
      'Cluster baru "${newCluster.kodeCluster}" berhasil ditambahkan!',
      Colors.green,
    );

    _selectedClusterId = newClusterId;
    await _loadDataFromDatabase();
  }

  Future<void> _addRandomPlot() async {
    if (_selectedCluster == null || _selectedCluster!.id == null) {
      _showSnackbar(
        'Tidak ada Cluster aktif untuk menambahkan Plot. Silakan pilih atau tambahkan cluster.',
        Colors.red,
      );
      return;
    }

    final newPlot = Plot(
      clusterId: _selectedCluster!.id!,
      nomorPlot: _plots.length + 1,
      latitude: RandomDataGenerator.generateRandomLatitude(),
      longitude: RandomDataGenerator.generateRandomLongitude(),
      altitude: RandomDataGenerator.generateRandomAltitude(),
    );

    await _dbHelper.plotDao.insertPlot(newPlot);
    _showSnackbar(
      'Plot random berhasil ditambahkan ke cluster ${_selectedCluster!.kodeCluster}!',
      Colors.green,
    );
    await _loadDataFromDatabase();
  }

  Future<void> _addRandomPohonToSpecificPlot(int plotId) async {
    // Menggunakan plotDao untuk mendapatkan plot
    final plot = await _dbHelper.plotDao.getPlotById(plotId);
    if (plot == null) {
      _showSnackbar('Plot tidak ditemukan.', Colors.red);
      return;
    }

    final currentPohonsInPlot = _pohonMap[plotId] ?? [];
    final nextNomorPohon = currentPohonsInPlot.length + 1;

    final jenisPohon = RandomDataGenerator.generateRandomJenisPohon();
    final newPohon = Pohon(
      plotId: plotId,
      nomorPohonDiPlot: nextNomorPohon,
      jenisPohon: jenisPohon,
      namaIlmiah: RandomDataGenerator.generateRandomNamaIlmiah(jenisPohon),
      azimut: RandomDataGenerator.generateRandomAzimuth(),
      jarakPusatM: RandomDataGenerator.generateRandomJarakPusatM(),
    );

    // Menggunakan LocationUtils untuk perhitungan koordinat
    final Map<String, double> coords = LocationUtils.calculatePohonCoordinates(
      plot.latitude,
      plot.longitude,
      newPohon.azimut,
      newPohon.jarakPusatM,
    );
    newPohon.latitude = coords['latitude'];
    newPohon.longitude = coords['longitude'];
    newPohon.altitude = plot.altitude;

    await _dbHelper.pohonDao.insertPohon(newPohon);
    _showSnackbar(
      'Pohon random berhasil ditambahkan ke Plot ${plot.nomorPlot}!',
      Colors.green,
    );
    await _loadDataFromDatabase();
  }

  // --- Fungsi Penghapusan Data ---

  Future<void> _deletePlot(int plotId, int plotNumber) async {
    final confirm = await _showConfirmDialog(
      'Hapus Plot',
      'Apakah Anda yakin ingin menghapus Plot $plotNumber? Ini juga akan menghapus semua pohon di dalamnya.',
    );
    if (confirm) {
      await _dbHelper.plotDao.deletePlot(plotId);
      _showSnackbar('Plot $plotNumber berhasil dihapus.', Colors.green);
      await _loadDataFromDatabase();
    }
  }

  Future<void> _deletePohon(
    int pohonId,
    int pohonNumber,
    int plotNumber,
  ) async {
    final confirm = await _showConfirmDialog(
      'Hapus Pohon',
      'Apakah Anda yakin ingin menghapus Pohon $pohonNumber dari Plot $plotNumber?',
    );
    if (confirm) {
      await _dbHelper.pohonDao.deletePohon(pohonId);
      _showSnackbar(
        'Pohon $pohonNumber dari Plot $plotNumber berhasil dihapus.',
        Colors.green,
      );
      await _loadDataFromDatabase();
    }
  }

  // --- Fungsi Reset Data (Tambahan) ---
  Future<void> _resetAllData() async {
    final confirm = await _showConfirmDialog(
      'Reset Semua Data',
      'INI AKAN MENGHAPUS SEMUA CLUSTER, PLOT, DAN POHON DARI DATABASE! Lanjutkan?',
    );
    if (confirm) {
      await _dbHelper.deleteAllData(); // Menggunakan metode dari DatabaseHelper
      _showSnackbar('Semua data berhasil dihapus!', Colors.red);
      await _loadDataFromDatabase(); // Muat ulang data untuk menampilkan UI kosong
    }
  }

  // --- Helper UI ---

  void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<bool> _showConfirmDialog(String title, String content) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(title),
              content: Text(content),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Batal'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text(
                    'Hapus',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }
        Navigator.pushNamedAndRemoveUntil(context, 'home', (route) => false);
      },
      child: Scaffold(
        appBar: const AppbarWidget(title: "Kelola Data Cluster Plot"),
        drawer: const SidebarWidget(),
        body: Stack(
          children: [
            //* Background App
            ValueListenableBuilder(
              valueListenable: isLightModeNotifier,
              builder: (context, isLightMode, child) {
                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 800),
                  transitionBuilder: (
                    Widget child,
                    Animation<double> animation,
                  ) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                  child: Image(
                    key: ValueKey<bool>(isLightMode),
                    image: AssetImage(
                      isLightMode
                          ? "assets/images/light-bg-notitle.png"
                          : "assets/images/dark-bg-notitle.png",
                    ),
                    fit: BoxFit.cover,
                    height: double.infinity,
                    width: double.infinity,
                  ),
                );
              },
            ),
            //* Konten Utama
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_allClusters.isEmpty)
              _buildNoDataFound()
            else
              SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: DropdownButtonFormField<int>(
                        value: _selectedClusterId,
                        decoration: InputDecoration(
                          labelText: 'Pilih Cluster',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          filled: true,
                          fillColor: Theme.of(context).cardColor,
                        ),
                        items:
                            _allClusters.map((cluster) {
                              return DropdownMenuItem<int>(
                                value: cluster.id,
                                child: Text(
                                  '${cluster.kodeCluster} - ${cluster.namaPengukur}',
                                  style: TextStyle(
                                    color:
                                        Theme.of(
                                          context,
                                        ).textTheme.bodyLarge?.color,
                                  ),
                                ),
                              );
                            }).toList(),
                        onChanged: (int? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedClusterId = newValue;
                            });
                            _loadDataFromDatabase();
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Data Klaster yang dipilih:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Card(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Kode Klaster: ${_selectedCluster!.kodeCluster}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Pengukur: ${_selectedCluster!.namaPengukur ?? '-'}',
                            ),
                            Text(
                              'Tanggal Pengukuran: ${_selectedCluster!.tanggalPengukuran != null ? DateFormat('dd-MM-yyyy').format(_selectedCluster!.tanggalPengukuran!) : '-'}',
                            ),
                            Text('Jumlah Plot: ${_plots.length}'),
                            Text(
                              'Total Pohon di Semua Plot: $_totalPohonCount',
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Data Plot:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    _plots.isEmpty
                        ? const Card(
                          margin: EdgeInsets.symmetric(vertical: 8.0),
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text(
                              'Tidak ada data plot di cluster ini. Silakan tambahkan plot baru.',
                              style: TextStyle(color: Colors.black),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                        : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _plots.length,
                          itemBuilder: (context, plotIndex) {
                            final plot = _plots[plotIndex];
                            final pohonListForPlot = _pohonMap[plot.id!] ?? [];
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Nomor Plot: ${plot.nomorPlot}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            IconButton(
                                              icon: const Icon(
                                                Icons.add_circle,
                                                color: Colors.blue,
                                              ),
                                              tooltip: 'Tambah Pohon Random',
                                              onPressed: () {
                                                _addRandomPohonToSpecificPlot(
                                                  plot.id!,
                                                );
                                              },
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.delete_forever,
                                                color: Colors.red,
                                              ),
                                              tooltip: 'Hapus Plot',
                                              onPressed: () {
                                                _deletePlot(
                                                  plot.id!,
                                                  plot.nomorPlot,
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    Text(
                                      'Latitude: ${plot.latitude.toStringAsFixed(6)}',
                                    ),
                                    Text(
                                      'Longitude: ${plot.longitude.toStringAsFixed(6)}',
                                    ),
                                    Text(
                                      'Altitude: ${plot.altitude?.toStringAsFixed(2) ?? '-'}',
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'Pohon di Plot ini (${pohonListForPlot.length} pohon):',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                    pohonListForPlot.isEmpty
                                        ? const Padding(
                                          padding: EdgeInsets.only(left: 16.0),
                                          child: Text(
                                            'Tidak ada pohon di plot ini.',
                                            style: TextStyle(
                                              color: Colors.grey,
                                            ),
                                          ),
                                        )
                                        : ListView.builder(
                                          shrinkWrap: true,
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          itemCount: pohonListForPlot.length,
                                          itemBuilder: (context, pohonIndex) {
                                            final pohon =
                                                pohonListForPlot[pohonIndex];
                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                left: 16.0,
                                                top: 4.0,
                                                bottom: 4.0,
                                              ),
                                              child: Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          'No. Pohon: ${pohon.nomorPohonDiPlot}',
                                                          style:
                                                              const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                              ),
                                                        ),
                                                        Text(
                                                          'Jenis: ${pohon.jenisPohon ?? '-'} (${pohon.namaIlmiah ?? '-'})',
                                                        ),
                                                        Text(
                                                          'Azimuth: ${pohon.azimut.toStringAsFixed(1)}°',
                                                        ),
                                                        Text(
                                                          'Jarak Pusat: ${pohon.jarakPusatM} m',
                                                        ),
                                                        Text(
                                                          'Koordinat: ${pohon.latitude?.toStringAsFixed(6) ?? '-'} Lat, ${pohon.longitude?.toStringAsFixed(6) ?? '-'} Lon, ${pohon.altitude?.toStringAsFixed(2) ?? '-'} Alt',
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.close,
                                                      color: Colors.red,
                                                    ),
                                                    tooltip: 'Hapus Pohon',
                                                    onPressed: () {
                                                      _deletePohon(
                                                        pohon.id!,
                                                        pohon.nomorPohonDiPlot,
                                                        plot.nomorPlot,
                                                      );
                                                    },
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            showModalBottomSheet(
              context: context,
              builder: (BuildContext context) {
                return SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      ListTile(
                        leading: const Icon(Icons.group_add),
                        title: const Text('Tambah Cluster Baru (Random)'),
                        onTap: () {
                          Navigator.pop(context);
                          _addRandomCluster();
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.location_on),
                        title: const Text('Tambah Plot Baru (Random)'),
                        onTap: () {
                          Navigator.pop(context);
                          if (_selectedClusterId != null) {
                            _addRandomPlot();
                          } else {
                            _showSnackbar(
                              'Tidak ada cluster terpilih. Tambahkan cluster baru terlebih dahulu.',
                              Colors.red,
                            );
                          }
                        },
                      ),
                      const Divider(), // Garis pemisah untuk tombol reset
                      ListTile(
                        leading: const Icon(Icons.warning, color: Colors.red),
                        title: const Text('RESET SEMUA DATA (DEVELOPMENT)'),
                        onTap: () {
                          Navigator.pop(context); // Tutup bottom sheet
                          _resetAllData(); // Panggil fungsi reset data
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          },
          tooltip: 'Tambah Data',
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildNoDataFound() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.folder_off, size: 80, color: Colors.white70),
            const SizedBox(height: 20),
            Text(
              'Ups! Sepertinya belum ada data cluster di sini.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Silakan tambahkan cluster baru menggunakan tombol "+" di kanan bawah.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () {
                _addRandomCluster();
              },
              icon: const Icon(Icons.add),
              label: const Text('Tambah Cluster Pertama Anda'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.blue,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                textStyle: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
