import 'dart:async';

import 'package:azimutree/data/models/app_version_model.dart';
import 'package:azimutree/data/notifiers/notifiers.dart';
import 'package:azimutree/services/app_version_service.dart';
import 'package:azimutree/views/widgets/core_widget/appbar_widget.dart';
import 'package:azimutree/views/widgets/core_widget/background_app_widget.dart';
import 'package:azimutree/views/widgets/core_widget/sidebar_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppVersionPage extends StatefulWidget {
  const AppVersionPage({super.key});

  @override
  State<AppVersionPage> createState() => _AppVersionPageState();
}

class _AppVersionPageState extends State<AppVersionPage> {
  final AppVersionService _service = AppVersionService();
  late Future<List<AppVersionModel>> _versions;

  @override
  void initState() {
    super.initState();
    selectedPageNotifier.value = 'app_version_page';
    _versions = _service.getPublishedVersions();
  }

  void _reload() {
    setState(() => _versions = _service.getPublishedVersions());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppbarWidget(title: 'Versi Aplikasi'),
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
              builder: (context, isLight, _) {
                final foreground = isLight ? Colors.black87 : Colors.white;
                return Column(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          BackButton(
                            color: foreground,
                            onPressed: () {
                              selectedPageNotifier.value = 'home';
                              Navigator.popAndPushNamed(context, 'home');
                            },
                          ),
                          Text(
                            'Kembali',
                            style: TextStyle(fontSize: 18, color: foreground),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: FutureBuilder<List<AppVersionModel>>(
                        future: _versions,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          if (snapshot.hasError) {
                            return _ErrorView(
                              foreground: foreground,
                              message: _errorMessage(snapshot.error),
                              onRetry: _reload,
                            );
                          }
                          final versions = snapshot.data ?? const [];
                          if (versions.isEmpty) {
                            return Center(
                              child: Text(
                                'Belum ada catatan perubahan versi.',
                                style: TextStyle(color: foreground),
                              ),
                            );
                          }
                          return RefreshIndicator(
                            onRefresh: () async {
                              _reload();
                              await _versions;
                            },
                            child: ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                              itemCount: versions.length,
                              separatorBuilder:
                                  (_, __) => const SizedBox(height: 12),
                              itemBuilder:
                                  (context, index) => _VersionCard(
                                    version: versions[index],
                                    isLight: isLight,
                                  ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _errorMessage(Object? error) {
    if (error is TimeoutException) {
      return 'Waktu koneksi habis. Periksa jaringan lalu coba kembali.';
    }
    if (error is FirebaseException && error.code == 'permission-denied') {
      return 'Catatan versi tidak dapat dibaca. Periksa Firestore Security Rules.';
    }
    return 'Catatan versi gagal dimuat. Periksa koneksi lalu coba kembali.';
  }
}

class _VersionCard extends StatelessWidget {
  const _VersionCard({required this.version, required this.isLight});

  final AppVersionModel version;
  final bool isLight;

  @override
  Widget build(BuildContext context) {
    final foreground = isLight ? Colors.black87 : Colors.white;
    return Card(
      color:
          isLight
              ? const Color.fromARGB(240, 180, 216, 187)
              : const Color.fromARGB(255, 36, 67, 42),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Versi ${version.version}',
              style: TextStyle(
                color: foreground,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (version.title.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(version.title, style: TextStyle(color: foreground)),
            ],
            if (version.publishedAt != null) ...[
              const SizedBox(height: 4),
              Text(
                DateFormat('dd-MM-yyyy').format(version.publishedAt!),
                style: TextStyle(
                  color: isLight ? Colors.black54 : Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
            const SizedBox(height: 12),
            for (final change in version.changes)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('•  ', style: TextStyle(color: foreground)),
                    Expanded(
                      child: Text(change, style: TextStyle(color: foreground)),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.foreground,
    required this.message,
    required this.onRetry,
  });

  final Color foreground;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off, color: foreground, size: 44),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: foreground),
            ),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: onRetry, child: const Text('Coba Lagi')),
          ],
        ),
      ),
    );
  }
}
