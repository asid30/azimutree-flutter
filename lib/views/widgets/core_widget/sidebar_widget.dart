import 'package:azimutree/data/notifiers/notifiers.dart';
import 'package:azimutree/services/cloud_connection_service.dart';
import 'package:azimutree/views/widgets/alert_dialog_widget/alert_warning_widget.dart';
import 'package:flutter/material.dart';
import 'package:azimutree/views/widgets/alert_dialog_widget/alert_loading_widget.dart';

/// Application drawer that exposes primary and secondary navigation routes.
class SidebarWidget extends StatelessWidget {
  const SidebarWidget({super.key});

  void _selectPage(BuildContext context, String page) {
    selectedPageNotifier.value = page;
    Navigator.pop(context);
    Navigator.popAndPushNamed(context, page);
  }

  Future<void> _selectCloudStorage(BuildContext context) async {
    await _selectFirebasePage(
      context,
      page: 'cloud_storage_page',
      loadingMessage: 'Memeriksa layanan awan...',
    );
  }

  Future<void> _selectAppVersions(BuildContext context) async {
    await _selectFirebasePage(
      context,
      page: 'app_version_page',
      loadingMessage: 'Memeriksa layanan versi...',
    );
  }

  Future<void> _selectFirebasePage(
    BuildContext context, {
    required String page,
    required String loadingMessage,
  }) async {
    final navigator = Navigator.of(context);
    navigator.pop();
    await Future<void>.delayed(Duration.zero);
    if (!navigator.mounted) return;

    final loadingDialog = showDialog<void>(
      context: navigator.context,
      barrierDismissible: false,
      builder: (_) => AlertLoadingWidget(message: loadingMessage),
    );
    final result = await CloudConnectionService().checkConnection();
    if (!navigator.mounted) return;
    navigator.pop();
    await loadingDialog;
    if (!navigator.mounted) return;

    final isDark = !isLightModeNotifier.value;
    await showDialog<void>(
      context: navigator.context,
      barrierDismissible: false,
      builder:
          (_) => AlertWarningWidget(
            title: result.isConnected ? 'Berhasil Terhubung' : 'Koneksi Gagal',
            warningMessage: result.message,
            backgroundColor:
                result.isConnected
                    ? Colors.lightGreen.shade200
                    : Colors.red.shade200,
            textColor: isDark ? Colors.white : Colors.black,
          ),
    );
    if (!result.isConnected || !navigator.mounted) return;

    selectedPageNotifier.value = page;
    navigator.pushReplacementNamed(page);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isLightModeNotifier,
      builder: (context, isLight, child) {
        final isDark = !isLight;
        return Drawer(
          backgroundColor:
              isDark
                  ? const Color(0xFF1F4226)
                  : const Color.fromARGB(255, 205, 237, 211),
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    Container(
                      color:
                          isDark
                              ? const Color.fromARGB(255, 19, 41, 23)
                              : const Color(0xFF1F4226),
                      padding: const EdgeInsets.symmetric(
                        vertical: 60,
                        horizontal: 16,
                      ),
                      child: Text(
                        'Menu',
                        style: TextStyle(
                          color:
                              isDark ? const Color(0xFFC1FF72) : Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    ListTile(
                      leading: Icon(
                        Icons.home,
                        color: isDark ? Colors.white : null,
                      ),
                      title: Text(
                        'Beranda',
                        style: TextStyle(color: isDark ? Colors.white : null),
                      ),
                      onTap: () => _selectPage(context, 'home'),
                    ),

                    Divider(
                      color: isDark ? Colors.white24 : const Color(0xFF1F4226),
                    ),

                    Theme(
                      data: Theme.of(context).copyWith(
                        dividerColor: Colors.transparent,
                        expansionTileTheme: ExpansionTileThemeData(
                          iconColor: isDark ? Colors.white : Colors.black87,
                          collapsedIconColor:
                              isDark ? Colors.white : Colors.black87,
                          textColor: isDark ? Colors.white : Colors.black87,
                          collapsedTextColor:
                              isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      child: ExpansionTile(
                        initiallyExpanded:
                            selectedPageNotifier.value == 'manage_data_page' ||
                            selectedPageNotifier.value == 'cloud_storage_page',
                        leading: Icon(
                          Icons.storage,
                          color: isDark ? Colors.white : null,
                        ),
                        title: Text(
                          'Kelola Data',
                          style: TextStyle(color: isDark ? Colors.white : null),
                        ),
                        childrenPadding: const EdgeInsets.only(left: 24),
                        children: [
                          ListTile(
                            leading: Icon(
                              Icons.folder_copy,
                              color: isDark ? Colors.white70 : null,
                            ),
                            title: Text(
                              'Data Klaster Plot',
                              style: TextStyle(
                                color: isDark ? Colors.white : null,
                              ),
                            ),
                            onTap:
                                () => _selectPage(context, 'manage_data_page'),
                          ),
                          ListTile(
                            leading: Icon(
                              Icons.cloud,
                              color: isDark ? Colors.white70 : null,
                            ),
                            title: Text(
                              'Penyimpanan Awan',
                              style: TextStyle(
                                color: isDark ? Colors.white : null,
                              ),
                            ),
                            onTap: () => _selectCloudStorage(context),
                          ),
                        ],
                      ),
                    ),

                    ListTile(
                      leading: Icon(
                        Icons.map,
                        color: isDark ? Colors.white : null,
                      ),
                      title: Text(
                        'Peta Lokasi Klaster Plot',
                        style: TextStyle(color: isDark ? Colors.white : null),
                      ),
                      onTap: () => _selectPage(context, 'location_map_page'),
                    ),

                    ListTile(
                      leading: Icon(
                        Icons.explore,
                        color: isDark ? Colors.white : null,
                      ),
                      title: Text(
                        'Survey Lokasi',
                        style: TextStyle(color: isDark ? Colors.white : null),
                      ),
                      onTap: () => _selectPage(context, 'survey_location_page'),
                    ),

                    ListTile(
                      leading: Icon(
                        Icons.book,
                        color: isDark ? Colors.white : null,
                      ),
                      title: Text(
                        'Panduan Aplikasi',
                        style: TextStyle(color: isDark ? Colors.white : null),
                      ),
                      onTap: () => _selectPage(context, 'tutorial_page'),
                    ),

                    Divider(
                      color: isDark ? Colors.white24 : const Color(0xFF1F4226),
                    ),

                    ListTile(
                      leading: Icon(
                        Icons.settings,
                        color: isDark ? Colors.white : null,
                      ),
                      title: Text(
                        'Pengaturan',
                        style: TextStyle(color: isDark ? Colors.white : null),
                      ),
                      onTap: () => _selectPage(context, 'settings_page'),
                    ),

                    ListTile(
                      leading: Icon(
                        Icons.info,
                        color: isDark ? Colors.white : null,
                      ),
                      title: Text(
                        'Tentang',
                        style: TextStyle(color: isDark ? Colors.white : null),
                      ),
                      onTap: () => _selectPage(context, 'about_page'),
                    ),

                    ListTile(
                      leading: Icon(
                        Icons.new_releases,
                        color: isDark ? Colors.white : null,
                      ),
                      title: Text(
                        'Versi Aplikasi',
                        style: TextStyle(color: isDark ? Colors.white : null),
                      ),
                      onTap: () => _selectAppVersions(context),
                    ),

                    Divider(
                      color: isDark ? Colors.white24 : const Color(0xFF1F4226),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Text(
                        'Developed by Asid30 © 2026',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Center(
                      child: Text(
                        'https://azimutree.heavysnack.my.id/',
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
