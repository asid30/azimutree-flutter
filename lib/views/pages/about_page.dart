import 'package:azimutree/data/notifiers/notifiers.dart';
import 'package:azimutree/views/widgets/alert_dialog_widget/app_alert_service.dart';
import 'package:azimutree/views/widgets/core_widget/appbar_widget.dart';
import 'package:azimutree/views/widgets/core_widget/background_app_widget.dart';
import 'package:azimutree/views/widgets/core_widget/sidebar_widget.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  Future<void> _openLink(BuildContext context, String url) async {
    try {
      final uri = Uri.parse(url);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
          context.mounted) {
        await showAppError(context, 'Tautan tidak dapat dibuka.');
      }
    } catch (_) {
      if (context.mounted) {
        await showAppError(context, 'Terjadi kesalahan saat membuka tautan.');
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) {
        Navigator.pushNamedAndRemoveUntil(context, 'home', (_) => false);
      }
    },
    child: Scaffold(
      appBar: const AppbarWidget(title: 'Tentang Aplikasi'),
      drawer: const SidebarWidget(),
      body: Stack(
        children: [
          const BackgroundAppWidget(
            lightBackgroundImage: 'assets/images/light-bg-notitle.png',
            darkBackgroundImage: 'assets/images/dark-bg-notitle.png',
          ),
          ValueListenableBuilder<bool>(
            valueListenable: isLightModeNotifier,
            builder: (context, isLight, _) {
              final foreground = isLight ? Colors.black87 : Colors.white;
              final secondary = isLight ? Colors.black54 : Colors.white70;
              final linkColor =
                  isLight ? Colors.blue.shade800 : const Color(0xFFC1FF72);
              final cardColor =
                  isLight
                      ? const Color.fromARGB(240, 180, 216, 187)
                      : const Color.fromARGB(255, 36, 67, 42);
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                children: [
                  Row(
                    children: [
                      BackButton(
                        color: foreground,
                        onPressed:
                            () => Navigator.popAndPushNamed(context, 'home'),
                      ),
                      Text(
                        'Kembali',
                        style: TextStyle(fontSize: 18, color: foreground),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Card(
                    color: cardColor,
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Azimutree 🌲🧭',
                            style: TextStyle(
                              color: foreground,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Azimutree adalah aplikasi Android yang membantu kegiatan pemantauan kesehatan hutan dengan metode Forest Health Monitoring (FHM). Aplikasi ini digunakan untuk mencatat lokasi Titik Ikat, klaster, plot, dan pohon, lalu menampilkannya pada peta digital. Fitur radar dan kompas membantu pengguna menemukan lokasi survei di lapangan dengan lebih mudah.',
                            textAlign: TextAlign.justify,
                            style: TextStyle(color: foreground, height: 1.5),
                          ),
                          const SizedBox(height: 28),
                          Center(
                            child: Text(
                              'Developed by Asid30 © 2026',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: secondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          _AboutLink(
                            label:
                                'https://github.com/asid30/azimutree-flutter',
                            color: linkColor,
                            onTap:
                                () => _openLink(
                                  context,
                                  'https://github.com/asid30/azimutree-flutter',
                                ),
                          ),
                          const SizedBox(height: 6),
                          _AboutLink(
                            label: 'https://azimutree.my.id/',
                            color: linkColor,
                            onTap:
                                () => _openLink(
                                  context,
                                  'https://azimutree.my.id/',
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    ),
  );
}

class _AboutLink extends StatelessWidget {
  const _AboutLink({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Center(
    child: InkWell(
      borderRadius: BorderRadius.circular(4),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(color: color, decoration: TextDecoration.underline),
        ),
      ),
    ),
  );
}
