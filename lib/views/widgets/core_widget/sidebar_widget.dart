import 'package:azimutree/data/notifiers/notifiers.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SidebarWidget extends StatelessWidget {
  const SidebarWidget({super.key});

  void _selectPage(BuildContext context, String page) {
    selectedPageNotifier.value = page;
    Navigator.pop(context);
    Navigator.popAndPushNamed(context, page);
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

                    ListTile(
                      leading: Icon(
                        Icons.storage,
                        color: isDark ? Colors.white : null,
                      ),
                      title: Text(
                        'Kelola Data Cluster Plot',
                        style: TextStyle(color: isDark ? Colors.white : null),
                      ),
                      onTap: () => _selectPage(context, 'manage_data_page'),
                    ),

                    ListTile(
                      leading: Icon(
                        Icons.map,
                        color: isDark ? Colors.white : null,
                      ),
                      title: Text(
                        'Peta Lokasi Cluster Plot',
                        style: TextStyle(color: isDark ? Colors.white : null),
                      ),
                      onTap: () => _selectPage(context, 'location_map_page'),
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
                      child: InkWell(
                        borderRadius: BorderRadius.circular(4),
                        onTap: () async {
                          const urlString = 'https://azimutree.my.id/';
                          final uri = Uri.parse(urlString);
                          final messenger = ScaffoldMessenger.of(context);
                          try {
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(
                                uri,
                                mode: LaunchMode.externalApplication,
                              );
                            } else {
                              final bg =
                                  isDark
                                      ? const Color.fromARGB(255, 131, 30, 23)
                                      : Colors.red.shade200;
                              messenger.showSnackBar(
                                SnackBar(
                                  content: const Text('Cannot open link'),
                                  backgroundColor: bg,
                                ),
                              );
                            }
                          } catch (e) {
                            final bg =
                                isDark
                                    ? const Color.fromARGB(255, 131, 30, 23)
                                    : Colors.red.shade200;
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text('Error opening link: $e'),
                                backgroundColor: bg,
                              ),
                            );
                          }
                        },
                        child: Text(
                          'https://azimutree.my.id/',
                          style: TextStyle(
                            decoration: TextDecoration.underline,
                            color:
                                isDark ? Colors.white70 : Colors.blue.shade700,
                            fontSize: 12,
                          ),
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
