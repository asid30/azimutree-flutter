import 'package:azimutree/data/notifiers/notifiers.dart';
import 'package:azimutree/views/widgets/alert_development_widget.dart';
import 'package:azimutree/views/widgets/alert_warning_widget.dart';
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
      child: ValueListenableBuilder(
        valueListenable: selectedPageNotifier,
        builder: (context, selectedPage, child) {
          return ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(color: Color(0xFF1F4226)),
                child: Text(
                  'Menu',
                  style: TextStyle(color: Colors.white, fontSize: 24),
                ),
              ),
              ListTile(
                leading: Icon(Icons.home),
                title: Text('Home'),
                onTap: () => _selectPage(context, "home"),
              ),
              Divider(),
              ListTile(
                leading: Icon(Icons.qr_code_scanner),
                title: Text('Scan Kode Label'),
                onTap: () => _selectPage(context, "scan_label_page"),
              ),
              ListTile(
                leading: Icon(Icons.storage),
                title: Text('Kelola Data Cluster Plot'),
                onTap: () => _selectPage(context, "manage_data_page"),
              ),
              ListTile(
                leading: Icon(Icons.map),
                title: Text('Peta Lokasi Cluster Plot'),
                onTap: () => _selectPage(context, "location_map_page"),
              ),
              ListTile(
                leading: Icon(Icons.help),
                title: Text('Panduan Aplikasi'),
                onTap: () => _selectPage(context, "tutorial_page"),
              ),
              Divider(),
              ListTile(
                leading: Icon(Icons.developer_mode),
                title: Text('Test OCR Google ML Kit'),
                onTap: () => _selectPage(context, "test_ocr_page1"),
              ),
              ListTile(
                leading: Icon(Icons.developer_mode),
                title: Text('Test OCR Google Vision API'),
                // onTap: () => _selectPage(context, "test_ocr_page2"),
                onTap:
                    () => showDialog(
                      context: context,
                      builder:
                          (context) => AlertWarningWidget(
                            warningMessage: "This feature is locked ⛔",
                          ),
                    ),
              ),
              Divider(),
              ListTile(
                leading: Icon(Icons.settings),
                title: Text('Settings'),
                onTap:
                    () => showDialog(
                      context: context,
                      builder: (context) => AlertDevelopmentWidget(),
                    ),
              ),
              ListTile(
                leading: Icon(Icons.info),
                title: Text('About'),
                onTap:
                    () => showDialog(
                      context: context,
                      builder: (context) => AlertDevelopmentWidget(),
                    ),
              ),
              Divider(),
            ],
          );
        },
      ),
    );
  }
}
