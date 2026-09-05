import 'dart:async';
import 'dart:math' as math;

import 'package:azimutree/data/database/cluster_dao.dart';
import 'package:azimutree/data/database/plot_dao.dart';
import 'package:azimutree/data/database/titik_ikat_dao.dart';
import 'package:azimutree/data/database/tree_dao.dart';
import 'package:azimutree/data/models/cluster_model.dart';
import 'package:azimutree/data/models/plot_model.dart';
import 'package:azimutree/data/models/titik_ikat_model.dart';
import 'package:azimutree/data/models/tree_model.dart';
import 'package:azimutree/data/notifiers/notifiers.dart';
import 'package:azimutree/data/notifiers/survey_navigation_notifier.dart';
import 'package:azimutree/services/azimuth_latlong_service.dart';
import 'package:azimutree/services/compass_navigation_service.dart';
import 'package:azimutree/services/compass_service.dart';
import 'package:azimutree/services/survey_session_storage.dart';
import 'package:azimutree/services/survey_ui_constants.dart';
import 'package:azimutree/services/tree_direction_filter_service.dart';
import 'package:azimutree/views/widgets/alert_dialog_widget/alert_confirmation_widget.dart';
import 'package:azimutree/views/widgets/core_widget/appbar_widget.dart';
import 'package:azimutree/views/widgets/core_widget/background_app_widget.dart';
import 'package:azimutree/views/widgets/core_widget/sidebar_widget.dart';
import 'package:azimutree/views/widgets/survey_widget/tree_radar_widget.dart';
import 'package:azimutree/views/widgets/survey_widget/anchor_mini_map_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;

class SurveyLocationPage extends StatefulWidget {
  const SurveyLocationPage({
    super.key,
    this.compassService = const CompassService(),
  });
  final CompassService compassService;

  @override
  State<SurveyLocationPage> createState() => _SurveyLocationPageState();
}

class _SurveyLocationPageState extends State<SurveyLocationPage> {
  final _session = SurveyNavigationNotifier();
  final _sessionStorage = SurveySessionStorage();
  List<ClusterModel> _clusters = [];
  List<TitikIkatModel> _anchors = [];
  List<PlotModel> _plots = [];
  List<TreeModel> _trees = [];
  int? _selectedClusterId;
  geo.Position? _position;
  StreamSubscription<geo.Position>? _positionSubscription;
  String? _locationMessage;
  bool _checkingLocation = false;
  bool _loading = true;
  bool _sessionListenerAttached = false;
  bool _radarCompassEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    _startLocationUpdates();
  }

  Future<void> _loadData() async {
    final data = await Future.wait([
      ClusterDao.getAllClusters(),
      TitikIkatDao.getAllTitikIkat(),
      PlotDao.getAllPlots(),
      TreeDao.getAllTrees(),
    ]);
    _clusters = data[0] as List<ClusterModel>;
    _anchors = data[1] as List<TitikIkatModel>;
    _plots = data[2] as List<PlotModel>;
    _trees = data[3] as List<TreeModel>;
    await _restoreSession();
    if (!_sessionListenerAttached) {
      _session.addListener(_persistSession);
      _sessionListenerAttached = true;
    }
    if (!mounted) return;
    setState(() => _loading = false);
  }

  Future<void> _restoreSession() async {
    final snapshot = await _sessionStorage.load();
    if (snapshot == null) return;
    final cluster = _findCluster(snapshot.clusterId);
    final anchor = _anchorFor(snapshot.clusterId);
    final targetPlot = _findPlot(snapshot.targetPlotId);
    final currentPlot = _findPlot(snapshot.currentPlotId);
    final valid =
        cluster != null &&
        anchor != null &&
        targetPlot != null &&
        (snapshot.currentPlotId == null || currentPlot != null);
    if (!valid) {
      await _sessionStorage.clear();
      return;
    }
    _selectedClusterId = cluster.id;
    _session.restore(
      cluster: cluster,
      anchorPoint: anchor,
      targetPlot: targetPlot,
      currentPlot: currentPlot,
      currentReference: snapshot.currentReference,
      currentTarget: snapshot.currentTarget,
      targetAzimuth: snapshot.targetAzimuth,
      targetDistanceM: snapshot.targetDistanceM,
      hasStarted: snapshot.hasStarted,
    );
  }

  void _persistSession() {
    unawaited(_sessionStorage.save(_session.value));
  }

  ClusterModel? _findCluster(int id) {
    for (final item in _clusters) {
      if (item.id == id) return item;
    }
    return null;
  }

  PlotModel? _findPlot(int? id) {
    if (id == null) return null;
    for (final item in _plots) {
      if (item.id == id) return item;
    }
    return null;
  }

  Future<void> _startLocationUpdates() async {
    if (_checkingLocation) return;
    setState(() {
      _checkingLocation = true;
      _locationMessage = null;
    });
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    try {
      if (!await geo.Geolocator.isLocationServiceEnabled()) {
        if (mounted) setState(() => _locationMessage = 'GPS tidak aktif');
        return;
      }
      var permission = await geo.Geolocator.checkPermission();
      if (permission == geo.LocationPermission.denied) {
        permission = await geo.Geolocator.requestPermission();
      }
      if (permission == geo.LocationPermission.denied ||
          permission == geo.LocationPermission.deniedForever) {
        if (mounted) {
          setState(() => _locationMessage = 'Izin lokasi tidak tersedia');
        }
        return;
      }
      _positionSubscription = geo.Geolocator.getPositionStream(
        locationSettings: const geo.LocationSettings(
          accuracy: geo.LocationAccuracy.high,
          distanceFilter: 2,
        ),
      ).listen(
        (value) {
          if (mounted) {
            setState(() {
              _position = value;
              _locationMessage = null;
            });
          }
        },
        onError: (_) {
          if (mounted) {
            setState(() => _locationMessage = 'Lokasi gagal diperbarui');
          }
        },
      );
    } finally {
      if (mounted) setState(() => _checkingLocation = false);
    }
  }

  Future<void> _retryLocationAccess() async {
    if (!await geo.Geolocator.isLocationServiceEnabled()) {
      await geo.Geolocator.openLocationSettings();
    } else if (await geo.Geolocator.checkPermission() ==
        geo.LocationPermission.deniedForever) {
      await geo.Geolocator.openAppSettings();
    }
    if (mounted) await _startLocationUpdates();
  }

  TitikIkatModel? _anchorFor(int clusterId) {
    for (final item in _anchors) {
      if (item.idCluster == clusterId) return item;
    }
    return null;
  }

  PlotModel? _plot1For(int clusterId) {
    for (final item in _plots) {
      if (item.idCluster == clusterId && item.kodePlot == 1) return item;
    }
    return null;
  }

  void _selectCluster(int? clusterId) {
    if (clusterId == null) return;
    final cluster = _clusters.firstWhere((item) => item.id == clusterId);
    final anchor = _anchorFor(clusterId);
    final plot1 = _plot1For(clusterId);
    double? azimuth;
    double? distance;
    if (anchor?.latitude != null &&
        anchor?.longitude != null &&
        plot1 != null) {
      final result = AzimuthLatLongService.toAzimuthDistance(
        centerLatDeg: anchor!.latitude!,
        centerLonDeg: anchor.longitude!,
        targetLatDeg: plot1.latitude,
        targetLonDeg: plot1.longitude,
      );
      azimuth = result.azimuthDeg;
      distance = result.distanceM;
    }
    setState(() => _selectedClusterId = clusterId);
    _session.selectSurvey(
      cluster: cluster,
      anchorPoint: anchor,
      plot1: plot1,
      targetAzimuth: azimuth,
      targetDistanceM: distance,
    );
  }

  Future<bool> _confirm(String title, String message) async =>
      await showDialog<bool>(
        context: context,
        builder:
            (_) => AlertConfirmationWidget(
              title: title,
              message: message,
              confirmText: 'Ya, konfirmasi',
              cancelText: 'Batal',
            ),
      ) ??
      false;

  void _openAnchorOnMap(TitikIkatModel anchor) {
    selectedTreeNotifier.value = null;
    selectedPlotNotifier.value = null;
    selectedCentroidNotifier.value = null;
    selectedTitikIkatNotifier.value = anchor;
    selectedTitikIkatClusterNotifier.value = _findCluster(anchor.idCluster);
    selectedLocationFromSearchNotifier.value = false;
    isFollowingUserLocationNotifier.value = false;
    selectedLocationNotifier.value = mapbox.Position(
      anchor.longitude!,
      anchor.latitude!,
    );
    Navigator.pushNamed(context, 'location_map_page');
  }

  Future<void> _endSurvey() async {
    if (!await _confirm(
      'Akhiri Sesi Survey',
      'Progress sesi survey akan dihapus. Data klaster, plot, dan Titik Ikat tetap aman.',
    )) {
      return;
    }
    await _sessionStorage.clear();
    _session.reset();
    if (mounted) setState(() => _selectedClusterId = null);
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    if (_sessionListenerAttached) {
      _session.removeListener(_persistSession);
    }
    _session.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Navigator.pushNamedAndRemoveUntil(context, 'home', (_) => false);
        }
      },
      child: Scaffold(
        appBar: const AppbarWidget(title: 'Survey Lokasi'),
        drawer: const SidebarWidget(),
        body: Stack(
          children: [
            const BackgroundAppWidget(
              lightBackgroundImage: 'assets/images/light-bg-notitle.png',
              darkBackgroundImage: 'assets/images/dark-bg-notitle.png',
            ),
            SafeArea(
              child: ValueListenableBuilder<bool>(
                valueListenable: isLightModeNotifier,
                builder:
                    (_, isLight, __) =>
                        ValueListenableBuilder<SurveyNavigationState>(
                          valueListenable: _session,
                          builder:
                              (_, session, __) => _content(session, !isLight),
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _content(SurveyNavigationState session, bool isDark) {
    final foreground = isDark ? Colors.white : Colors.black87;
    final cardColor =
        isDark
            ? const Color.fromARGB(245, 36, 67, 42)
            : const Color.fromARGB(245, 220, 238, 223);
    if (_loading) return const Center(child: CircularProgressIndicator());
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Pilih Klaster',
          style: TextStyle(color: foreground, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color:
                isDark
                    ? const Color.fromARGB(255, 36, 67, 42)
                    : const Color.fromARGB(240, 180, 216, 187),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value:
                  _clusters.any((item) => item.id == _selectedClusterId)
                      ? _selectedClusterId
                      : null,
              isExpanded: true,
              dropdownColor:
                  isDark
                      ? const Color.fromARGB(255, 36, 67, 42)
                      : const Color(0xFFb4d8bb),
              style: TextStyle(
                color: foreground,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              hint: Text(
                _clusters.isEmpty ? 'Tidak ada Klaster' : 'Pilih Klaster',
                style: TextStyle(color: foreground),
              ),
              items:
                  _clusters
                      .where((item) => item.id != null)
                      .map(
                        (item) => DropdownMenuItem<int>(
                          value: item.id,
                          child: Text(
                            item.kodeCluster,
                            style: TextStyle(color: foreground),
                          ),
                        ),
                      )
                      .toList(),
              onChanged: _selectCluster,
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (_clusters.isEmpty)
          _message('Belum ada data klaster.', cardColor, foreground)
        else if (session.cluster == null)
          _message(
            'Pilih klaster untuk memulai alur survey.',
            cardColor,
            foreground,
          )
        else if (session.anchorPoint == null)
          _message(
            'Klaster ini belum memiliki Titik Ikat.',
            cardColor,
            foreground,
          )
        else if (session.targetPlot == null)
          _message(
            'Plot 1 belum tersedia pada klaster ini.',
            cardColor,
            foreground,
          )
        else if (!session.hasStarted)
          _overview(session, cardColor, foreground)
        else if (session.currentReference == SurveyReferenceType.none)
          _findAnchor(session, cardColor, foreground)
        else if (session.currentReference == SurveyReferenceType.anchorPoint &&
            session.currentTarget == SurveyTargetType.plot)
          _compass(session, cardColor, foreground)
        else if (session.currentReference == SurveyReferenceType.anchorPoint)
          _anchorReached(session, cardColor, foreground)
        else if (session.currentTarget == SurveyTargetType.anchorPoint)
          _anchorCompass(session, cardColor, foreground)
        else if (session.currentTarget == SurveyTargetType.plot)
          _plotCompass(session, cardColor, foreground)
        else if (session.currentPlot != null)
          _plotTargetSelection(session, cardColor, foreground)
        else
          _plotReached(session, cardColor, foreground),
        if (session.hasStarted) ...[
          const SizedBox(height: 12),
          FilledButton.icon(
            style: _primaryButtonStyle,
            onPressed: _endSurvey,
            icon: const Icon(Icons.stop_circle_outlined),
            label: const Text('AKHIRI SESI SURVEY'),
          ),
        ],
      ],
    );
  }

  Widget _message(String text, Color color, Color foreground) => Card(
    color: color,
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Text(text, style: TextStyle(color: foreground)),
    ),
  );

  Widget _overview(
    SurveyNavigationState session,
    Color color,
    Color foreground,
  ) {
    final anchor = session.anchorPoint!;
    return _card(color, [
      Text(anchor.nama, style: _title(foreground)),
      const SizedBox(height: 8),
      Text(
        'Status: Belum ada titik referensi',
        style: TextStyle(color: foreground),
      ),
      const SizedBox(height: 20),
      OutlinedButton.icon(
        style: _secondaryButtonStyle(foreground),
        onPressed: () => _openAnchorOnMap(anchor),
        icon: const Icon(Icons.map_outlined),
        label: const Text('LIHAT TITIK IKAT DI PETA'),
      ),
      const SizedBox(height: 8),
      FilledButton.icon(
        style: _themedPrimaryButtonStyle(
          isDark: foreground.computeLuminance() > 0.5,
        ),
        onPressed: () async {
          if (await _confirm(
            'Mulai Survey Lapangan',
            'Anda akan melakukan survey di lapangan. Pastikan Anda sudah berada di sekitar lokasi. Alur survey dimulai dengan mencari Titik Ikat, dilanjutkan mencari pusat plot, lalu mencari pohon berdasarkan azimut yang telah didata.',
          )) {
            _session.start();
          }
        },
        icon: const Icon(Icons.explore),
        label: const Text('MULAI SURVEY'),
      ),
    ]);
  }

  Widget _findAnchor(
    SurveyNavigationState session,
    Color color,
    Color foreground,
  ) {
    final anchor = session.anchorPoint!;
    final estimate = _gpsDistanceTo(anchor.latitude!, anchor.longitude!);
    return _card(color, [
      Text('Langkah 1 · Temukan Titik Ikat', style: _title(foreground)),
      const SizedBox(height: 8),
      Text(
        '${anchor.nama} · ${session.cluster!.kodeCluster}',
        style: TextStyle(color: foreground, fontSize: 16),
      ),
      const SizedBox(height: 16),
      _metric(
        'Estimasi jarak GPS',
        estimate == null ? '-' : _meters(estimate),
        foreground,
      ),
      _metric(
        'Akurasi GPS',
        _position == null ? '-' : '±${_meters(_position!.accuracy)}',
        foreground,
      ),
      if (_position != null &&
          _position!.accuracy > SurveyUiConstants.poorGpsAccuracyThresholdM)
        const Text(
          'GPS kurang akurat. Gunakan Titik Ikat dan kompas sebagai referensi lapangan.',
          style: TextStyle(color: Colors.orange),
        ),
      if (_locationMessage != null) ...[
        Text(_locationMessage!, style: const TextStyle(color: Colors.orange)),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          style: _secondaryButtonStyle(foreground),
          onPressed: _checkingLocation ? null : _retryLocationAccess,
          icon:
              _checkingLocation
                  ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Icon(Icons.refresh),
          label: Text(
            _checkingLocation ? 'MEMERIKSA GPS...' : 'REFRESH AKSES GPS',
          ),
        ),
      ],
      const SizedBox(height: 16),
      AnchorMiniMapWidget(
        anchorLatitude: anchor.latitude!,
        anchorLongitude: anchor.longitude!,
        userLatitude: _position?.latitude,
        userLongitude: _position?.longitude,
        standardStyleUri:
            dotenv.env['MAPBOX_STYLE_STANDARD']?.trim().isNotEmpty == true
                ? dotenv.env['MAPBOX_STYLE_STANDARD']!.trim()
                : 'mapbox://styles/mapbox/streets-v12',
        satelliteStyleUri:
            dotenv.env['MAPBOX_STYLE_SATELLITE']?.trim().isNotEmpty == true
                ? dotenv.env['MAPBOX_STYLE_SATELLITE']!.trim()
                : mapbox.MapboxStyles.SATELLITE_STREETS,
      ),
      const SizedBox(height: 8),
      Text(
        'Pin merah menunjukkan Titik Ikat; indikator lokasi menunjukkan posisi GPS Anda.',
        style: TextStyle(color: foreground.withValues(alpha: 0.75)),
      ),
      const SizedBox(height: 16),
      Text(
        'GPS hanya digunakan untuk mendekati lokasi. Temukan objek Titik Ikat secara fisik.',
        style: TextStyle(color: foreground),
      ),
      const SizedBox(height: 20),
      OutlinedButton.icon(
        style: _secondaryButtonStyle(foreground),
        onPressed: () => _openAnchorOnMap(anchor),
        icon: const Icon(Icons.map_outlined),
        label: const Text('LIHAT DI PETA'),
      ),
      const SizedBox(height: 8),
      FilledButton(
        style: _themedPrimaryButtonStyle(
          isDark: foreground.computeLuminance() > 0.5,
        ),
        onPressed: () async {
          if (await _confirm(
            'Konfirmasi Titik Ikat',
            'Pastikan Anda sudah menemukan Titik Ikat secara fisik. Koordinat tidak akan diubah dari GPS.',
          )) {
            _session.confirmAnchorPoint();
          }
        },
        child: const Text('SAYA SUDAH DI TITIK IKAT'),
      ),
    ]);
  }

  Widget _compass(
    SurveyNavigationState session,
    Color color,
    Color foreground,
  ) {
    return StreamBuilder<double?>(
      stream: widget.compassService.headingStream,
      builder: (_, snapshot) {
        final heading = snapshot.data;
        final target = session.targetAzimuth!;
        final difference =
            heading == null ? null : signedAngleDifference(target, heading);
        final instruction =
            difference == null
                ? 'Sensor kompas belum terbaca'
                : difference.abs() <= compassAlignmentTolerance
                ? 'Arah sudah sesuai'
                : difference > 0
                ? 'Putar kanan ${difference.abs().toStringAsFixed(0)}°'
                : 'Putar kiri ${difference.abs().toStringAsFixed(0)}°';
        return _card(color, [
          Text('Langkah 2 · Menuju Pusat Plot 1', style: _title(foreground)),
          const SizedBox(height: 20),
          Transform.rotate(
            angle:
                heading == null
                    ? 0
                    : signedAngleDifference(target, heading) * math.pi / 180,
            child: Icon(Icons.navigation, size: 82, color: foreground),
          ),
          const SizedBox(height: 16),
          _metric('Target', '${target.toStringAsFixed(1)}°', foreground),
          _metric(
            'Heading Anda',
            heading == null ? '-' : '${heading.toStringAsFixed(1)}°',
            foreground,
          ),
          Text(
            instruction,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: foreground,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _metric(
            'Jarak referensi',
            _meters(session.targetDistanceM!),
            foreground,
          ),
          Text(
            'Jarak adalah referensi pengukuran lapangan, bukan sisa jarak GPS.',
            textAlign: TextAlign.center,
            style: TextStyle(color: foreground.withValues(alpha: 0.75)),
          ),
          _compassCalibrationInfo(foreground),
          const SizedBox(height: 20),
          FilledButton(
            style: _themedPrimaryButtonStyle(
              isDark: foreground.computeLuminance() > 0.5,
            ),
            onPressed: () async {
              if (await _confirm(
                'Konfirmasi Plot 1',
                'Pastikan Anda sudah menemukan Plot 1 secara fisik. Koordinat Plot 1 tidak akan diubah.',
              )) {
                _session.confirmPlot1();
              }
            },
            child: const Text('SAYA SUDAH DI PLOT 1'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            style: _secondaryButtonStyle(foreground),
            onPressed: _session.cancelNavigation,
            icon: const Icon(Icons.arrow_back),
            label: const Text('BATAL, KEMBALI KE TITIK IKAT'),
          ),
        ]);
      },
    );
  }

  Widget _anchorReached(
    SurveyNavigationState session,
    Color color,
    Color foreground,
  ) {
    final anchor = session.anchorPoint!;
    final plot1 = session.targetPlot!;
    return _card(color, [
      const Icon(Icons.location_on, color: Colors.green, size: 64),
      const SizedBox(height: 8),
      Text(
        'Referensi saat ini: Titik Ikat',
        textAlign: TextAlign.center,
        style: _title(foreground),
      ),
      const SizedBox(height: 16),
      FilledButton.icon(
        style: _themedPrimaryButtonStyle(
          isDark: foreground.computeLuminance() > 0.5,
        ),
        onPressed: () {
          final direction = AzimuthLatLongService.toAzimuthDistance(
            centerLatDeg: anchor.latitude!,
            centerLonDeg: anchor.longitude!,
            targetLatDeg: plot1.latitude,
            targetLonDeg: plot1.longitude,
          );
          _session.resumePlot1Navigation(
            azimuth: direction.azimuthDeg,
            distanceM: direction.distanceM,
          );
        },
        icon: const Icon(Icons.navigation),
        label: const Text('LANJUT KE PLOT 1'),
      ),
    ]);
  }

  Widget _plotTargetSelection(
    SurveyNavigationState session,
    Color color,
    Color foreground,
  ) {
    final availableTargets =
        _plots
            .where(
              (plot) =>
                  plot.idCluster == session.cluster!.id &&
                  plot.kodePlot >= 1 &&
                  plot.kodePlot <= 4 &&
                  plot.id != session.currentPlot?.id,
            )
            .toList()
          ..sort((a, b) => a.kodePlot.compareTo(b.kodePlot));
    return _card(color, [
      const Icon(Icons.check_circle, color: Colors.green, size: 64),
      const SizedBox(height: 8),
      Text(
        'Plot ${session.currentPlot!.kodePlot} terkonfirmasi',
        textAlign: TextAlign.center,
        style: _title(foreground),
      ),
      const SizedBox(height: 20),
      Text('Pilih Tujuan', style: _title(foreground)),
      const SizedBox(height: 12),
      if (availableTargets.isEmpty)
        Text(
          'Belum ada plot lain yang dapat dituju pada klaster ini.',
          style: TextStyle(color: foreground),
        )
      else
        ...availableTargets.map((plot) {
          final direction = AzimuthLatLongService.toAzimuthDistance(
            centerLatDeg: session.currentPlot!.latitude,
            centerLonDeg: session.currentPlot!.longitude,
            targetLatDeg: plot.latitude,
            targetLonDeg: plot.longitude,
          );
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: FilledButton(
              style: _plotTargetButtonStyle(
                isDark: foreground.computeLuminance() > 0.5,
              ),
              onPressed:
                  () => _session.selectPlotTarget(
                    plot: plot,
                    azimuth: direction.azimuthDeg,
                    distanceM: direction.distanceM,
                  ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'P${plot.kodePlot}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${direction.azimuthDeg.toStringAsFixed(1)}°  •  '
                      '${_meters(direction.distanceM)}',
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      const Divider(height: 32),
      OutlinedButton.icon(
        style: _secondaryButtonStyle(foreground),
        onPressed: () => _navigateBackToAnchor(session),
        icon: const Icon(Icons.location_pin),
        label: const Text('BATAL, KEMBALI KE TITIK IKAT'),
      ),
      const Divider(height: 32),
      _treeCompassPanel(session.currentPlot!, foreground),
    ]);
  }

  Widget _plotCompass(
    SurveyNavigationState session,
    Color color,
    Color foreground,
  ) {
    final plotCode = session.targetPlot!.kodePlot;
    return StreamBuilder<double?>(
      stream: widget.compassService.headingStream,
      builder: (_, snapshot) {
        final heading = snapshot.data;
        final target = session.targetAzimuth!;
        final difference =
            heading == null ? null : signedAngleDifference(target, heading);
        final instruction =
            difference == null
                ? 'Sensor kompas belum terbaca'
                : difference.abs() <= compassAlignmentTolerance
                ? 'Arah sudah sesuai'
                : difference > 0
                ? 'Putar kanan ${difference.abs().toStringAsFixed(0)}°'
                : 'Putar kiri ${difference.abs().toStringAsFixed(0)}°';
        return _card(color, [
          Text('Menuju Plot $plotCode', style: _title(foreground)),
          const SizedBox(height: 20),
          Transform.rotate(
            angle:
                heading == null
                    ? 0
                    : signedAngleDifference(target, heading) * math.pi / 180,
            child: Icon(Icons.navigation, size: 82, color: foreground),
          ),
          const SizedBox(height: 16),
          _metric('Target', '${target.toStringAsFixed(1)}°', foreground),
          _metric(
            'Heading Anda',
            heading == null ? '-' : '${heading.toStringAsFixed(1)}°',
            foreground,
          ),
          Text(
            instruction,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: foreground,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _metric(
            'Jarak referensi',
            _meters(session.targetDistanceM!),
            foreground,
          ),
          Text(
            'Ukur jarak dari pusat Plot 1 di lapangan. GPS tidak digunakan untuk konfirmasi posisi.',
            textAlign: TextAlign.center,
            style: TextStyle(color: foreground.withValues(alpha: 0.75)),
          ),
          _compassCalibrationInfo(foreground),
          const SizedBox(height: 20),
          FilledButton(
            style: _themedPrimaryButtonStyle(
              isDark: foreground.computeLuminance() > 0.5,
            ),
            onPressed: () async {
              if (await _confirm(
                'Konfirmasi Plot $plotCode',
                'Pastikan Anda sudah berada di pusat Plot $plotCode secara fisik.',
              )) {
                _session.confirmTargetPlot();
              }
            },
            child: Text('SAYA SUDAH DI PLOT $plotCode'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            style: _secondaryButtonStyle(foreground),
            onPressed: () => _navigateBackToAnchor(session),
            icon: const Icon(Icons.location_pin),
            label: const Text('BATAL, KEMBALI KE TITIK IKAT'),
          ),
        ]);
      },
    );
  }

  void _navigateBackToAnchor(SurveyNavigationState session) {
    final anchor = session.anchorPoint;
    final source = session.currentPlot;
    if (anchor?.latitude == null ||
        anchor?.longitude == null ||
        source == null) {
      return;
    }
    final direction = AzimuthLatLongService.toAzimuthDistance(
      centerLatDeg: source.latitude,
      centerLonDeg: source.longitude,
      targetLatDeg: anchor!.latitude!,
      targetLonDeg: anchor.longitude!,
    );
    _session.selectAnchorTarget(
      azimuth: direction.azimuthDeg,
      distanceM: direction.distanceM,
    );
  }

  Widget _anchorCompass(
    SurveyNavigationState session,
    Color color,
    Color foreground,
  ) {
    return StreamBuilder<double?>(
      stream: widget.compassService.headingStream,
      builder: (_, snapshot) {
        final heading = snapshot.data;
        final target = session.targetAzimuth!;
        final difference =
            heading == null ? null : signedAngleDifference(target, heading);
        return _card(color, [
          Text('Kembali ke Titik Ikat', style: _title(foreground)),
          const SizedBox(height: 12),
          Transform.rotate(
            angle:
                heading == null
                    ? 0
                    : signedAngleDifference(target, heading) * math.pi / 180,
            child: Icon(Icons.navigation, size: 82, color: foreground),
          ),
          const SizedBox(height: 12),
          _metric('Target', '${target.toStringAsFixed(1)}°', foreground),
          _metric(
            'Heading Anda',
            heading == null ? '-' : '${heading.toStringAsFixed(1)}°',
            foreground,
          ),
          _metric(
            'Jarak referensi',
            _meters(session.targetDistanceM!),
            foreground,
          ),
          if (difference != null)
            Text(
              difference.abs() <= compassAlignmentTolerance
                  ? 'Arah sudah sesuai'
                  : difference > 0
                  ? 'Putar kanan ${difference.abs().toStringAsFixed(0)}°'
                  : 'Putar kiri ${difference.abs().toStringAsFixed(0)}°',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: foreground,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          const SizedBox(height: 20),
          FilledButton(
            style: _themedPrimaryButtonStyle(
              isDark: foreground.computeLuminance() > 0.5,
            ),
            onPressed: () async {
              if (await _confirm(
                'Konfirmasi Titik Ikat',
                'Pastikan Anda sudah kembali ke Titik Ikat secara fisik.',
              )) {
                _session.confirmAnchorReturn();
              }
            },
            child: const Text('SAYA SUDAH DI TITIK IKAT'),
          ),
        ]);
      },
    );
  }

  Widget _plotReached(
    SurveyNavigationState session,
    Color color,
    Color foreground,
  ) {
    final plotCode = session.currentPlot!.kodePlot;
    return _card(color, [
      const Icon(Icons.check_circle, color: Colors.green, size: 72),
      const SizedBox(height: 12),
      Text(
        'Plot $plotCode terkonfirmasi',
        textAlign: TextAlign.center,
        style: _title(foreground),
      ),
      const SizedBox(height: 8),
      Text(
        'Referensi saat ini: Plot $plotCode',
        textAlign: TextAlign.center,
        style: TextStyle(color: foreground),
      ),
      const Divider(height: 32),
      _treeCompassPanel(session.currentPlot!, foreground),
    ]);
  }

  Widget _treeCompassPanel(PlotModel activePlot, Color foreground) {
    final plotTrees =
        _trees.where((tree) => tree.plotId == activePlot.id).toList();
    return StreamBuilder<double?>(
      stream: widget.compassService.headingStream,
      builder: (_, snapshot) {
        final heading = snapshot.data;
        final visibleTrees =
            heading == null || activePlot.id == null
                ? <TreeModel>[]
                : TreeDirectionFilterService.filter(
                  trees: plotTrees,
                  plotId: activePlot.id!,
                  heading: heading,
                );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Langkah 3 · Radar Lokasi Pohon', style: _title(foreground)),
            const SizedBox(height: 8),
            Text(
              'Pusat radar adalah pusat plot, bukan posisi pemegang ponsel. Untuk hasil yang lebih mudah dibaca, sebaiknya berdiri di pusat plot.',
              style: TextStyle(color: foreground),
            ),
            const SizedBox(height: 8),
            _metric('Plot aktif', 'P${activePlot.kodePlot}', foreground),
            _metric(
              'Heading',
              !_radarCompassEnabled
                  ? 'Kompas nonaktif (utara tetap)'
                  : heading == null
                  ? '-'
                  : '${heading.toStringAsFixed(1)}°',
              foreground,
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Aktifkan kompas radar',
                style: TextStyle(color: foreground),
              ),
              subtitle: Text(
                _radarCompassEnabled
                    ? 'Sektor radar mengikuti arah ponsel.'
                    : 'Sektor radar dimatikan',
                style: TextStyle(color: foreground.withValues(alpha: 0.75)),
              ),
              value: _radarCompassEnabled,
              activeThumbColor: const Color(0xFFC1FF72),
              onChanged:
                  (value) => setState(() => _radarCompassEnabled = value),
            ),
            const SizedBox(height: 12),
            TreeRadarWidget(
              trees: plotTrees,
              heading: heading,
              isDark: foreground.computeLuminance() > 0.5,
              plotCode: activePlot.kodePlot,
              compassEnabled: _radarCompassEnabled,
            ),
            const SizedBox(height: 12),
            Text(
              'Pohon di arah ±${compassAlignmentTolerance.toStringAsFixed(0)}°',
              style: TextStyle(color: foreground),
            ),
            const SizedBox(height: 12),
            if (plotTrees.isEmpty)
              Text(
                'Belum ada data pohon pada plot ini.',
                style: TextStyle(color: foreground),
              )
            else if (!_radarCompassEnabled)
              Text(
                'Semua pohon tetap ditampilkan dengan orientasi utara tetap. Tahan sebentar marker untuk melihat informasinya.',
                style: TextStyle(color: foreground),
              )
            else if (heading == null)
              _compassUnavailableInfo(foreground)
            else if (visibleTrees.isEmpty)
              Text(
                'Tidak ada pohon pada arah ini. Putar perangkat perlahan.',
                style: TextStyle(color: foreground),
              )
            else
              ...visibleTrees.map(
                (tree) => _treeDirectionTile(tree, heading, foreground),
              ),
            _compassCalibrationInfo(foreground),
          ],
        );
      },
    );
  }

  Widget _treeDirectionTile(TreeModel tree, double heading, Color foreground) {
    final difference = signedAngleDifference(tree.azimut!, heading).abs();
    final commonName = tree.namaPohon?.trim();
    final scientificName = tree.namaIlmiah?.trim();
    return Card(
      color:
          foreground.computeLuminance() > 0.5
              ? const Color(0xFF14351D)
              : const Color(0xFF1F4226),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.park, color: Colors.white),
        title: Text(
          'Pohon ${tree.kodePohon.toString().padLeft(3, '0')}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          '${tree.azimut!.toStringAsFixed(1)}° • '
          '${tree.jarakPusatM == null ? '- m' : _meters(tree.jarakPusatM!)}'
          '${commonName == null || commonName.isEmpty ? '' : '\n$commonName'}'
          '${scientificName == null || scientificName.isEmpty ? '' : ' • $scientificName'}',
          style: const TextStyle(color: Colors.white70),
        ),
        trailing: Text(
          'Δ${difference.toStringAsFixed(1)}°',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _compassUnavailableInfo(Color foreground) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.sensors_off, color: Colors.orange),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Sensor kompas tidak tersedia atau belum dapat dibaca.',
            style: TextStyle(color: foreground),
          ),
        ),
      ],
    ),
  );

  Widget _compassCalibrationInfo(Color foreground) => Padding(
    padding: const EdgeInsets.only(top: 12),
    child: Text(
      'Jika arah tidak stabil, jauhkan smartphone dari magnet atau benda logam lalu lakukan kalibrasi kompas.',
      textAlign: TextAlign.center,
      style: TextStyle(color: foreground.withValues(alpha: 0.72), fontSize: 12),
    ),
  );

  Widget _card(Color color, List<Widget> children) => Card(
    color: color,
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    ),
  );

  double? _gpsDistanceTo(double latitude, double longitude) =>
      _position == null
          ? null
          : geo.Geolocator.distanceBetween(
            _position!.latitude,
            _position!.longitude,
            latitude,
            longitude,
          );

  String _meters(double value) =>
      value < 1000
          ? '${value.toStringAsFixed(1)} m'
          : '${(value / 1000).toStringAsFixed(2)} km';

  Widget _metric(String label, String value, Color foreground) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: foreground)),
        Text(
          value,
          style: TextStyle(color: foreground, fontWeight: FontWeight.bold),
        ),
      ],
    ),
  );

  TextStyle _title(Color color) =>
      TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold);

  ButtonStyle get _primaryButtonStyle => FilledButton.styleFrom(
    backgroundColor: const Color(0xFF1F4226),
    foregroundColor: Colors.white,
    disabledBackgroundColor: const Color(0xFF1F4226).withValues(alpha: 0.45),
    disabledForegroundColor: Colors.white70,
  );

  ButtonStyle _plotTargetButtonStyle({required bool isDark}) {
    final backgroundColor =
        isDark ? const Color(0xFF14351D) : const Color(0xFF1F4226);
    return FilledButton.styleFrom(
      backgroundColor: backgroundColor,
      foregroundColor: Colors.white,
      disabledBackgroundColor: backgroundColor.withValues(alpha: 0.45),
      disabledForegroundColor: Colors.white70,
    );
  }

  ButtonStyle _themedPrimaryButtonStyle({required bool isDark}) {
    final backgroundColor =
        isDark ? const Color(0xFF14351D) : const Color(0xFF1F4226);
    return FilledButton.styleFrom(
      backgroundColor: backgroundColor,
      foregroundColor: Colors.white,
      disabledBackgroundColor: backgroundColor.withValues(alpha: 0.45),
      disabledForegroundColor: Colors.white70,
    );
  }

  ButtonStyle _secondaryButtonStyle(Color foreground) =>
      OutlinedButton.styleFrom(
        foregroundColor: foreground,
        disabledForegroundColor: foreground.withValues(alpha: 0.45),
        side: BorderSide(color: foreground.withValues(alpha: 0.75)),
      );
}
