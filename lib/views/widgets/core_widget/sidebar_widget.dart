import 'package:azimutree/data/notifiers/notifiers.dart';
import 'package:flutter/material.dart';

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
          child: ValueListenableBuilder(
            valueListenable: selectedPageNotifier,
            builder: (context, selectedPage, child) {
              return ListView(
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
                      "Menu",
                      style: TextStyle(
                        color: isDark ? const Color(0xFFC1FF72) : Colors.white,
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
                    onTap: () => _selectPage(context, "home"),
                  ),

                  Divider(
                    color: isDark ? Colors.white24 : const Color(0xFF1F4226),
                  ),

                  // Scan feature removed
                  ListTile(
                    leading: Icon(
                      Icons.storage,
                      color: isDark ? Colors.white : null,
                    ),
                    title: Text(
                      'Kelola Data Cluster Plot',
                      style: TextStyle(color: isDark ? Colors.white : null),
                    ),
                    onTap: () => _selectPage(context, "manage_data_page"),
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
                    onTap: () => _selectPage(context, "location_map_page"),
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
                    onTap: () => _selectPage(context, "tutorial_page"),
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
                    onTap: () => _selectPage(context, "settings_page"),
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
                    onTap: () => _selectPage(context, "about_page"),
                  ),

                  Divider(
                    color: isDark ? Colors.white24 : const Color(0xFF1F4226),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
