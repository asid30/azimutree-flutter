//* Manages data for clusters, plots, and trees in the Azimutree app
import 'package:azimutree/views/widgets/appbar_widget.dart';
import 'package:azimutree/views/widgets/background_app_widget.dart';
import 'package:azimutree/views/widgets/sidebar_widget.dart';
import 'package:flutter/material.dart';
import 'package:azimutree/data/database/database_helper.dart';
import 'package:azimutree/data/models/cluster.dart';
import 'package:azimutree/data/models/plot.dart';
import 'package:azimutree/data/models/pohon.dart';
import 'package:azimutree/services/random_data_generator.dart';
import 'package:azimutree/services/location_utils.dart';
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
  late ScrollController _scrollController;
  double _lastScrollOffset = 0.0;

  //* Get instance DatabaseHelper
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _loadDataFromDatabase();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  //* Database Loading Function
  Future<void> _loadDataFromDatabase() async {
    setState(() {
      _isLoading = true;
    });

    // Save the last scroll position
    _lastScrollOffset =
        _scrollController.hasClients ? _scrollController.offset : 0.0;

    // Make sure the database is initialized and DAOs are ready
    await _dbHelper.database;

    // Load all clusters from the database
    _allClusters = await _dbHelper.clusterDao.getAllClusters();

    // If no clusters exist, reset selected cluster
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

    //* Load plots and pohons for the selected cluster
    _plots = []; // Reset plots
    _pohonMap = {}; // Reset pohon map
    _totalPohonCount = 0; // Reset sum pohon count
    // If a cluster is selected, load its plots and pohons
    if (_selectedCluster != null && _selectedCluster!.id != null) {
      _plots = await _dbHelper.plotDao.getPlotsByClusterId(
        _selectedCluster!.id!,
      );
      for (var plot in _plots) {
        if (plot.id != null) {
          final pohons = await _dbHelper.pohonDao.getAllPohonsByPlotId(
            plot.id!,
          );
          _pohonMap[plot.id!] = pohons;
          _totalPohonCount += pohons.length;
        }
      }
    }
    setState(() {
      _isLoading = false;
    });

    // return to the last scroll position
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_lastScrollOffset);
      }
    });
  }

  //! Functions to add random data for testing purposes
  //Todo: Update these functions to use a real data
  //* Adds a random cluster
  Future<void> _addRandomCluster() async {
    // Generate a new random cluster
    final newCluster = Cluster(
      kodeCluster: RandomDataGenerator.generateRandomKodeCluster(),
      namaPengukur: RandomDataGenerator.generateRandomNamaPengukur(),
      tanggalPengukuran: DateTime.now(),
    );
    // Insert the new cluster into the database
    final int newClusterId = await _dbHelper.clusterDao.insertCluster(
      newCluster,
    );
    // Notify the user of success
    _showSnackbar(
      'Cluster baru "${newCluster.kodeCluster}" berhasil ditambahkan!',
      Colors.green,
    );
    // Update the selected cluster and reload data
    _selectedClusterId = newClusterId;
    await _loadDataFromDatabase();
  }

  //* Adds a random plot to the currently selected cluster
  Future<void> _addRandomPlot() async {
    // Check if a cluster is selected
    // If no cluster is selected, show an error message
    if (_selectedCluster == null || _selectedCluster!.id == null) {
      _showSnackbar(
        'Tidak ada Cluster aktif untuk menambahkan Plot. Silakan pilih atau tambahkan cluster.',
        Colors.red,
      );
      return;
    }
    // Generate a new random plot
    // The plot will be associated with the currently selected cluster
    final newPlot = Plot(
      clusterId: _selectedCluster!.id!,
      nomorPlot: _plots.length + 1,
      latitude: RandomDataGenerator.generateRandomLatitude(),
      longitude: RandomDataGenerator.generateRandomLongitude(),
      altitude: RandomDataGenerator.generateRandomAltitude(),
    );
    // Insert the new plot into the database
    await _dbHelper.plotDao.insertPlot(newPlot);
    // Notify the user of success
    _showSnackbar(
      'Plot random berhasil ditambahkan ke cluster ${_selectedCluster!.kodeCluster}!',
      Colors.green,
    );
    // Reload data to reflect the new plot
    await _loadDataFromDatabase();
  }

  //* Adds a random pohon to a specific plot
  Future<void> _addRandomPohonToSpecificPlot(int plotId) async {
    // Check if the plot exists
    // If the plot is not found, show an error message
    final plot = await _dbHelper.plotDao.getPlotById(plotId);
    if (plot == null) {
      _showSnackbar('Plot tidak ditemukan.', Colors.red);
      return;
    }
    // Generate a new random pohon
    // The pohon will be associated with the specified plot
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
    // Use the LocationUtils (*/lib/services/location_utils.dart) to calculate the coordinates based on azimuth and distance
    final Map<String, double> coords = LocationUtils.calculatePohonCoordinates(
      plot.latitude,
      plot.longitude,
      newPohon.azimut,
      newPohon.jarakPusatM,
    );
    newPohon.latitude = coords['latitude'];
    newPohon.longitude = coords['longitude'];
    newPohon.altitude = plot.altitude;
    // Insert the new pohon into the database
    await _dbHelper.pohonDao.insertPohon(newPohon);
    // Notify the user of success
    _showSnackbar(
      'Pohon random berhasil ditambahkan ke Plot ${plot.nomorPlot}!',
      Colors.green,
    );
    // Reload data to reflect the new pohon
    await _loadDataFromDatabase();
  }

  //! Delete functions for clusters, plots, and trees
  //* Deletes a cluster and all its associated plots and trees
  Future<void> _deleteCluster(int clusterId) async {
    // Check if the cluster exists
    final cluster = await _dbHelper.clusterDao.getClusterById(clusterId);
    if (cluster == null) {
      _showSnackbar('Cluster tidak ditemukan.', Colors.red);
      return;
    }
    // Show confirmation dialog before deleting
    // If the user confirms, delete the cluster and all its plots and trees
    final confirm = await _showConfirmDeletionDialog(
      'Hapus Cluster',
      'Apakah Anda yakin ingin menghapus Cluster ini? Ini juga akan menghapus semua Plot dan Pohon di dalamnya.',
    );
    if (confirm) {
      // Delete the cluster using the DAO
      // This will also delete all associated plots and trees due to ON DELETE CASCADE
      await _dbHelper.clusterDao.deleteCluster(clusterId);
      // Notify the user of success
      _showSnackbar('Cluster berhasil dihapus.', Colors.green);
      // Reset selected cluster and reload data
      await _loadDataFromDatabase();
    }
  }

  //* Deletes a plot and all its associated trees
  Future<void> _deletePlot(int plotId, int plotNumber) async {
    // Check if the plot exists
    final plot = await _dbHelper.plotDao.getPlotById(plotId);
    if (plot == null) {
      _showSnackbar('Plot tidak ditemukan.', Colors.red);
      return;
    }
    // Show confirmation dialog before deleting
    // If the user confirms, delete the plot and all its trees
    final confirm = await _showConfirmDeletionDialog(
      'Hapus Plot',
      'Apakah Anda yakin ingin menghapus Plot $plotNumber? Ini juga akan menghapus semua pohon di dalamnya.',
    );
    if (confirm) {
      // Delete the plot using the DAO
      // This will also delete all associated trees due to ON DELETE CASCADE
      await _dbHelper.plotDao.deletePlot(plotId);
      // Notify the user of success
      _showSnackbar('Plot $plotNumber berhasil dihapus.', Colors.green);
      // Reload data to reflect the deletion
      await _loadDataFromDatabase();
    }
  }

  //* Deletes a specific tree from a plot
  Future<void> _deletePohon(int pohonId, int pohonNumber, int plotId) async {
    // Check if the tree exists
    final pohon = await _dbHelper.pohonDao.getPohonById(pohonId);
    if (pohon == null) {
      _showSnackbar('Pohon tidak ditemukan.', Colors.red);
      return;
    }
    // Show confirmation dialog before deleting
    // If the user confirms, delete the tree from the plot
    final confirm = await _showConfirmDeletionDialog(
      'Hapus Pohon',
      'Apakah Anda yakin ingin menghapus Pohon $pohonNumber dari Plot $plotId?',
    );
    if (confirm) {
      // Delete the tree using the DAO
      await _dbHelper.pohonDao.deletePohon(pohonId);
      // Notify the user of success
      _showSnackbar(
        'Pohon $pohonNumber dari Plot $plotId berhasil dihapus.',
        Colors.green,
      );
      // Reload data to reflect the deletion
      await _loadDataFromDatabase();
    }
  }

  //! Function to reset all data in the database (development purposes only)
  //* Resets all data including clusters, plots, and trees
  Future<void> _resetAllData() async {
    final confirm = await _showConfirmDeletionDialog(
      'Reset Semua Data',
      'INI AKAN MENGHAPUS SEMUA CLUSTER, PLOT, DAN POHON DARI DATABASE! Lanjutkan?',
    );
    if (confirm) {
      await _dbHelper.deleteAllData(); // Menggunakan metode dari DatabaseHelper
      _showSnackbar('Semua data berhasil dihapus!', Colors.red);
      await _loadDataFromDatabase(); // Muat ulang data untuk menampilkan UI kosong
    }
  }

  //! Snackbar and Dialog Functions
  //* Function to show a snackbar with a message
  void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  //! Function to show a confirmation dialog
  //* Returns true if the user confirms, false otherwise
  Future<bool> _showConfirmDeletionDialog(String title, String content) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(title),
              content: Text(content),
              actions: <Widget>[
                TextButton(
                  // If the user cancels, return false
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Batal'),
                ),
                TextButton(
                  // If the user confirms, return true
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

  //! UI Functions
  //* Main build method for the ManageDataPage
  @override
  Widget build(BuildContext context) {
    // For preventing pop when the user taps back button
    // This is to ensure that the user cannot accidentally close the app
    // Instead, they will be redirected to the home page.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }
        // If the user tries to pop, redirect them to the home page
        Navigator.pushNamedAndRemoveUntil(context, 'home', (route) => false);
      },
      // Main Scaffold for the ManageDataPage
      child: Scaffold(
        appBar: const AppbarWidget(title: "Kelola Data Cluster Plot"),
        drawer: const SidebarWidget(),
        body: Stack(
          children: [
            //* Background App
            BackgroundAppWidget(),
            //* Main Content
            // If loading, show a CircularProgressIndicator
            // If no clusters are found, show a "No Data Found" message
            // If clusters are found, show the main content with dropdown and data display
            if (_isLoading)
              Stack(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      BackButton(
                        onPressed: () {
                          Navigator.popAndPushNamed(context, "home");
                        },
                      ),
                      const Text("Kembali", style: TextStyle(fontSize: 18)),
                    ],
                  ),
                  Center(child: CircularProgressIndicator()),
                ],
              )
            else if (_allClusters.isEmpty)
              _buildNoDataFound()
            else
              // Main content when clusters are available
              SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        BackButton(
                          onPressed: () {
                            Navigator.popAndPushNamed(context, "home");
                          },
                        ),
                        const Text("Kembali", style: TextStyle(fontSize: 18)),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            // Dropdown to select a cluster
                            child: DropdownButtonFormField<int>(
                              initialValue: _selectedClusterId,
                              decoration: InputDecoration(
                                labelText: 'Pilih Cluster',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                filled: true,
                                fillColor: Theme.of(context).cardColor,
                              ),
                              // Dropdown items generated from the list of clusters
                              // Each item displays the cluster code and the name of the measurer
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
                              // On change, update the selected cluster ID and reload data
                              // This will trigger the loading of plots and trees for the selected cluster
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
                          //* Display the selected cluster's details
                          Card(
                            margin: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Data Klaster yang dipilih:',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
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

                          //* Display the plots and trees in the selected cluster
                          // If there are no plots, show a message indicating that there are no plots in this cluster
                          // If there are plots, display them in a list with details
                          // Each plot shows its number, coordinates, and the trees within it
                          // Each tree shows its number, species, azimuth, distance from center, and coordinates
                          _plots.isEmpty
                              ? const Card(
                                margin: EdgeInsets.symmetric(vertical: 8.0),
                                child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Data Plot:',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'Tidak ada data plot di cluster ini. Silakan tambahkan plot baru.',
                                        style: TextStyle(color: Colors.black),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                              : ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _plots.length,
                                itemBuilder: (context, plotIndex) {
                                  final plot = _plots[plotIndex];
                                  final pohonListForPlot =
                                      _pohonMap[plot.id!] ?? [];
                                  return Card(
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 8.0,
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Data Plot:',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
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
                                                  // Icon buttons for adding a tree to the plot and deleting the plot
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.add_circle,
                                                      color: Colors.blue,
                                                    ),
                                                    tooltip:
                                                        'Tambah Pohon Random',
                                                    onPressed: () {
                                                      _addRandomPohonToSpecificPlot(
                                                        plot.id!,
                                                      );
                                                    },
                                                  ),
                                                  // Icon button to delete the plot
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
                                                padding: EdgeInsets.only(
                                                  left: 16.0,
                                                ),
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
                                                itemCount:
                                                    pohonListForPlot.length,
                                                itemBuilder: (
                                                  context,
                                                  pohonIndex,
                                                ) {
                                                  final pohon =
                                                      pohonListForPlot[pohonIndex];
                                                  return Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                          left: 16.0,
                                                          top: 4.0,
                                                          bottom: 4.0,
                                                        ),
                                                    child: Row(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Expanded(
                                                          child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Text(
                                                                'No. Pohon: ${pohon.nomorPohonDiPlot}',
                                                                style: const TextStyle(
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
                                                        // Icon button to delete the tree
                                                        IconButton(
                                                          icon: const Icon(
                                                            Icons.close,
                                                            color: Colors.red,
                                                          ),
                                                          tooltip:
                                                              'Hapus Pohon',
                                                          onPressed: () {
                                                            _deletePohon(
                                                              pohon.id!,
                                                              pohon
                                                                  .nomorPohonDiPlot,
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
              ),
          ],
        ),
        // Floating action button to manage data
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
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.delete_forever),
                        title: const Text('Hapus Cluster saat ini'),
                        onTap: () {
                          Navigator.pop(context);
                          if (_selectedClusterId != null) {
                            _deleteCluster(_selectedClusterId!);
                          } else {
                            _showSnackbar(
                              'Tidak ada cluster terpilih. Tambahkan cluster baru terlebih dahulu.',
                              Colors.red,
                            );
                          }
                        },
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.warning, color: Colors.red),
                        title: const Text('RESET SEMUA DATA (DEVELOPMENT)'),
                        onTap: () {
                          Navigator.pop(context);
                          _resetAllData();
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

  //* Widget to display when no data is found
  Widget _buildNoDataFound() {
    return Stack(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            BackButton(
              onPressed: () {
                Navigator.popAndPushNamed(context, "home");
              },
            ),
            const Text("Kembali", style: TextStyle(fontSize: 18)),
          ],
        ),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Card(
                  child: Column(
                    children: [
                      const Icon(
                        Icons.folder_off,
                        size: 80,
                        color: Colors.black,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Ups! Sepertinya belum ada data cluster di sini.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Silakan tambahkan cluster baru menggunakan tombol "+" di kanan bawah.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.black),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),
                ElevatedButton.icon(
                  onPressed: () {
                    _addRandomCluster();
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Tambah Cluster Pertama Anda (random)'),
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
        ),
      ],
    );
  }
}
