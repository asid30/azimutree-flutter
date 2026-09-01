import 'dart:async';
import 'dart:math' as math;

import 'package:azimutree/data/database/cluster_dao.dart';
import 'package:azimutree/data/database/plot_dao.dart';
import 'package:azimutree/data/database/titik_ikat_dao.dart';
import 'package:azimutree/data/models/cluster_model.dart';
import 'package:azimutree/data/models/plot_model.dart';
import 'package:azimutree/data/models/titik_ikat_model.dart';
import 'package:azimutree/data/notifiers/notifiers.dart';
import 'package:azimutree/data/notifiers/survey_navigation_notifier.dart';
import 'package:azimutree/services/azimuth_latlong_service.dart';
import 'package:azimutree/services/compass_navigation_service.dart';
import 'package:azimutree/services/compass_service.dart';
import 'package:azimutree/views/widgets/alert_dialog_widget/alert_confirmation_widget.dart';
import 'package:azimutree/views/widgets/core_widget/appbar_widget.dart';
import 'package:azimutree/views/widgets/core_widget/background_app_widget.dart';
import 'package:azimutree/views/widgets/core_widget/sidebar_widget.dart';
import 'package:flutter/material.dart';
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
  List<ClusterModel> _clusters = [];
  List<TitikIkatModel> _anchors = [];
  List<PlotModel> _plots = [];
  int? _selectedClusterId;
  geo.Position? _position;
  StreamSubscription<geo.Position>? _positionSubscription;
  String? _locationMessage;
  bool _checkingLocation = false;
  bool _loading = true;

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
    ]);
    if (!mounted) return;
    setState(() {
      _clusters = data[0] as List<ClusterModel>;
      _anchors = data[1] as List<TitikIkatModel>;
      _plots = data[2] as List<PlotModel>;
      _loading = false;
    });
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
    selectedLocationFromSearchNotifier.value = true;
    selectedLocationNotifier.value = mapbox.Position(
      anchor.longitude!,
      anchor.latitude!,
    );
    Navigator.pushNamed(context, 'location_map_page');
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
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
        DropdownButtonFormField<int>(
          initialValue: _selectedClusterId,
          dropdownColor: cardColor,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.hub_outlined),
          ),
          hint: const Text('Pilih klaster survei'),
          items:
              _clusters
                  .where((item) => item.id != null)
                  .map(
                    (item) => DropdownMenuItem(
                      value: item.id,
                      child: Text(item.kodeCluster),
                    ),
                  )
                  .toList(),
          onChanged: _selectCluster,
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
        else if (session.currentReference == SurveyReferenceType.anchorPoint)
          _compass(session, cardColor, foreground)
        else
          _completed(cardColor, foreground),
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
        onPressed: () => _openAnchorOnMap(anchor),
        icon: const Icon(Icons.map_outlined),
        label: const Text('LIHAT TITIK IKAT DI PETA'),
      ),
      const SizedBox(height: 8),
      FilledButton.icon(
        onPressed: _session.start,
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
      Text(anchor.nama, style: _title(foreground)),
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
      if (_locationMessage != null) ...[
        Text(_locationMessage!, style: const TextStyle(color: Colors.orange)),
        const SizedBox(height: 8),
        OutlinedButton.icon(
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
      Text(
        'GPS hanya digunakan untuk mendekati lokasi. Temukan objek Titik Ikat secara fisik.',
        style: TextStyle(color: foreground),
      ),
      const SizedBox(height: 20),
      OutlinedButton.icon(
        onPressed: () => _openAnchorOnMap(anchor),
        icon: const Icon(Icons.map_outlined),
        label: const Text('LIHAT DI PETA'),
      ),
      const SizedBox(height: 8),
      FilledButton(
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
          Text('Menuju Plot 1', style: _title(foreground)),
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
          const SizedBox(height: 20),
          FilledButton(
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
        ]);
      },
    );
  }

  Widget _completed(Color color, Color foreground) => _card(color, [
    const Icon(Icons.check_circle, color: Colors.green, size: 72),
    const SizedBox(height: 12),
    Text(
      'Plot 1 terkonfirmasi',
      textAlign: TextAlign.center,
      style: _title(foreground),
    ),
    const SizedBox(height: 8),
    Text(
      'Referensi saat ini: Plot 1',
      textAlign: TextAlign.center,
      style: TextStyle(color: foreground),
    ),
  ]);

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
}
