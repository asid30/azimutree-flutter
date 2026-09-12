import 'package:azimutree/data/notifiers/notifiers.dart';
import 'package:azimutree/services/cloud_public_data_service.dart';
import 'package:azimutree/views/widgets/alert_dialog_widget/rename_downloaded_cluster_dialog.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:azimutree/views/widgets/alert_dialog_widget/app_alert_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Searches and downloads public research data without requiring sign-in.
class PublicCloudBrowserWidget extends StatefulWidget {
  const PublicCloudBrowserWidget({
    super.key,
    required this.showLogin,
    required this.onLogin,
    required this.loginInProgress,
  });

  final bool showLogin;
  final VoidCallback onLogin;
  final bool loginInProgress;

  @override
  State<PublicCloudBrowserWidget> createState() =>
      _PublicCloudBrowserWidgetState();
}

class _PublicCloudBrowserWidgetState extends State<PublicCloudBrowserWidget> {
  static const _hideEmptyLocationsKey =
      'cloud_public_hide_empty_research_locations';

  final CloudPublicDataService _service = CloudPublicDataService();
  final Set<String> _expandedLocationIds = <String>{};
  String _query = '';
  bool _hideEmptyLocations = true;
  String? _downloadingClusterId;

  @override
  void initState() {
    super.initState();
    _loadHideEmptyPreference();
  }

  Future<void> _loadHideEmptyPreference() async {
    final preferences = await SharedPreferences.getInstance();
    final value = preferences.getBool(_hideEmptyLocationsKey) ?? true;
    if (mounted) setState(() => _hideEmptyLocations = value);
  }

  Future<void> _setHideEmptyLocations(bool value) async {
    setState(() => _hideEmptyLocations = value);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_hideEmptyLocationsKey, value);
  }

  Future<void> _downloadCluster(
    CloudResearchLocation location,
    CloudClusterSummary cluster,
  ) async {
    if (_downloadingClusterId != null) return;

    var localCode = cluster.code;
    try {
      if (await _service.localCodeExists(localCode)) {
        if (!mounted) return;
        final replacement = await showDialog<String>(
          context: context,
          builder:
              (_) => RenameDownloadedClusterDialog(
                initialCode: '${cluster.code} SALINAN',
              ),
        );
        if (replacement == null || !mounted) return;
        localCode = replacement;
        if (await _service.localCodeExists(localCode)) {
          if (mounted) {
            await showAppWarning(
              context,
              'Kode klaster tersebut sudah digunakan.',
            );
          }
          return;
        }
      }

      if (!mounted) return;
      setState(() => _downloadingClusterId = cluster.id);
      await _service.downloadCluster(
        locationId: location.id,
        clusterId: cluster.id,
        localCode: localCode,
      );
      localDataRevisionNotifier.value++;
      if (mounted) {
        await showAppSuccess(context, 'Klaster $localCode berhasil diunduh.');
      }
    } catch (_) {
      if (mounted) {
        await showAppError(
          context,
          'Klaster gagal diunduh. Periksa koneksi dan kelengkapan datanya.',
        );
      }
    } finally {
      if (mounted) setState(() => _downloadingClusterId = null);
    }
  }

  bool _matchesLocation(CloudResearchLocation location) {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return true;
    return location.name.toLowerCase().contains(query);
  }

  String _date(DateTime? value) =>
      value == null ? '-' : DateFormat('dd-MM-yyyy').format(value);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isLightModeNotifier,
      builder: (context, isLight, _) {
        final isDark = !isLight;
        final foreground = isLight ? Colors.black87 : Colors.white;
        final cardColor =
            isLight
                ? const Color.fromARGB(240, 180, 216, 187)
                : const Color.fromARGB(255, 32, 72, 43);
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.cloud_queue, size: 44, color: foreground),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Data Penelitian Publik',
                          style: TextStyle(
                            color: foreground,
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Cari berdasarkan nama lokasi penelitian.',
                          style: TextStyle(
                            color: foreground.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (widget.showLogin) ...[
                ElevatedButton.icon(
                  onPressed: widget.loginInProgress ? null : widget.onLogin,
                  icon: const Icon(Icons.login),
                  label: const Text('Masuk dengan Google'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: const Color(0xFF1F4226),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              TextField(
                onChanged: (value) => setState(() => _query = value),
                onTapOutside: (_) => FocusScope.of(context).unfocus(),
                textInputAction: TextInputAction.search,
                style: TextStyle(color: foreground),
                decoration: InputDecoration(
                  hintText: 'Cari nama lokasi penelitian',
                  hintStyle: TextStyle(
                    color: foreground.withValues(alpha: 0.65),
                  ),
                  prefixIcon: Icon(Icons.search, color: foreground),
                  filled: true,
                  fillColor: cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Sembunyikan folder kosong',
                      style: TextStyle(color: foreground, fontSize: 13),
                    ),
                  ),
                  Transform.scale(
                    scale: 0.8,
                    child: Switch(
                      value: _hideEmptyLocations,
                      onChanged: _setHideEmptyLocations,
                      activeTrackColor:
                          isDark
                              ? const Color(0xFFC1FF72)
                              : const Color(0xFF1F4226),
                      activeThumbColor:
                          isDark
                              ? const Color(0xFF1F4226)
                              : const Color.fromARGB(255, 205, 237, 211),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: StreamBuilder<List<CloudResearchLocation>>(
                  stream: _service.watchPublicLocations(),
                  builder: (context, snapshot) {
                    final locations =
                        (snapshot.data ?? const <CloudResearchLocation>[])
                            .where(
                              (location) =>
                                  _matchesLocation(location) &&
                                  (!_hideEmptyLocations ||
                                      location.clusterCount > 0),
                            )
                            .toList();
                    if (snapshot.hasError) {
                      return ListView(
                        children: [
                          _messageCard(
                            'Data publik tidak dapat dimuat. Periksa koneksi internet.',
                            cardColor,
                            foreground,
                          ),
                        ],
                      );
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (locations.isEmpty) {
                      return ListView(
                        children: [
                          _messageCard(
                            _query.trim().isEmpty
                                ? 'Belum ada lokasi penelitian publik.'
                                : 'Tidak ada data yang cocok dengan pencarian.',
                            cardColor,
                            foreground,
                          ),
                        ],
                      );
                    }
                    return ListView.builder(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      itemCount: locations.length,
                      itemBuilder:
                          (context, index) => _locationCard(
                            locations[index],
                            cardColor,
                            foreground,
                          ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _locationCard(
    CloudResearchLocation location,
    Color cardColor,
    Color foreground,
  ) {
    return Card(
      color: cardColor,
      child: ExpansionTile(
        key: PageStorageKey<String>('public_location_${location.id}'),
        initiallyExpanded: _expandedLocationIds.contains(location.id),
        onExpansionChanged: (expanded) {
          setState(() {
            if (expanded) {
              _expandedLocationIds.add(location.id);
            } else {
              _expandedLocationIds.remove(location.id);
            }
          });
        },
        shape: const Border(),
        collapsedShape: const Border(),
        leading: Icon(Icons.folder, color: foreground),
        iconColor: foreground,
        collapsedIconColor: foreground,
        title: Text(
          location.name.isEmpty ? 'Lokasi tanpa nama' : location.name,
          style: TextStyle(color: foreground, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${location.ownerName} · ${_date(location.researchDate)} · ${location.clusterCount} klaster',
          style: TextStyle(color: foreground.withValues(alpha: 0.8)),
        ),
        children: [
          StreamBuilder<List<CloudClusterSummary>>(
            stream: _service.watchPublicClusters(location.id),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    'Klaster tidak dapat dimuat.',
                    style: TextStyle(color: foreground),
                  ),
                );
              }
              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(),
                );
              }
              final clusters = snapshot.data!;
              if (clusters.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    'Belum ada klaster pada lokasi ini.',
                    style: TextStyle(color: foreground),
                  ),
                );
              }
              return Column(
                children:
                    clusters
                        .map(
                          (cluster) => ListTile(
                            leading: Icon(Icons.data_object, color: foreground),
                            title: Text(
                              cluster.code,
                              style: TextStyle(color: foreground),
                            ),
                            subtitle: Text(
                              '${cluster.surveyorName} · ${_date(cluster.surveyDate)}',
                              style: TextStyle(
                                color: foreground.withValues(alpha: 0.75),
                              ),
                            ),
                            trailing:
                                _downloadingClusterId == cluster.id
                                    ? SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: foreground,
                                      ),
                                    )
                                    : Icon(
                                      Icons.download_outlined,
                                      color: foreground,
                                    ),
                            onTap:
                                _downloadingClusterId == null
                                    ? () => _downloadCluster(location, cluster)
                                    : null,
                          ),
                        )
                        .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _messageCard(String message, Color color, Color foreground) => Card(
    color: color,
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(color: foreground),
      ),
    ),
  );
}
