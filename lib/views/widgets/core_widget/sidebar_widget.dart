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
    return Drawer(
      backgroundColor: const Color.fromARGB(255, 205, 237, 211),

      child: ValueListenableBuilder(
        valueListenable: selectedPageNotifier,
        builder: (context, selectedPage, child) {
          return ListView(
            padding: EdgeInsets.zero,
            children: [
              Container(
                color: const Color(0xFF1F4226),
                padding: const EdgeInsets.symmetric(
                  vertical: 60,
                  horizontal: 16,
                ),
                child: Text(
                  "Menu",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              ListTile(
                leading: const Icon(Icons.home),
                title: const Text('Home'),
                onTap: () => _selectPage(context, "home"),
              ),

              const Divider(color: Color(0xFF1F4226)),

              ListTile(
                leading: const Icon(Icons.qr_code_scanner),
                title: const Text('Scan Kode Label'),
                onTap: () => _selectPage(context, "scan_label_page"),
              ),
              ListTile(
                leading: const Icon(Icons.storage),
                title: const Text('Kelola Data Cluster Plot'),
                onTap: () => _selectPage(context, "manage_data_page"),
              ),
              ListTile(
                leading: const Icon(Icons.map),
                title: const Text('Peta Lokasi Cluster Plot'),
                onTap: () => _selectPage(context, "location_map_page"),
              ),
              ListTile(
                leading: const Icon(Icons.help),
                title: const Text('Panduan Aplikasi'),
                onTap: () => _selectPage(context, "tutorial_page"),
              ),

              const Divider(color: Color(0xFF1F4226)),

              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Settings'),
                onTap: () => _selectPage(context, "settings_page"),
              ),

              ListTile(
                leading: const Icon(Icons.info),
                title: const Text('About'),
                onTap: () => _selectPage(context, "about_page"),
              ),

              const Divider(color: Color(0xFF1F4226)),
            ],
          );
        },
      ),
    );
  }
}
