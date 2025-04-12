import 'package:azimutree/data/notifiers.dart';
import 'package:azimutree/views/pages/home_page.dart';
import 'package:azimutree/views/pages/location_map_page.dart';
import 'package:azimutree/views/pages/manage_data_page.dart';
import 'package:azimutree/views/pages/scan_label_page.dart';
import 'package:azimutree/views/pages/tutorial_page.dart';
import 'package:azimutree/views/widgets/alert_development_widget.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  //* Pages
  final Map<String?, Widget?> pages = {
    "home": HomePage(), // Default Page
    "scan_label_page": ScanLabelPage(),
    "manage_data_page": ManageDataPage(),
    "location_map_page": LocationMapPage(),
    "tutorial_page": TutorialPage(),
  };
  //* Title of Pages
  final Map<String?, String?> titleOfPages = {
    "home": "Home", // Default title Page
    "scan_label_page": "Scan Kode Label",
    "manage_data_page": "Kelola Data Sampel",
    "location_map_page": "Peta Lokasi Cluster Plot",
    "tutorial_page": "Panduan Aplikasi",
  };

  void _selectPage(BuildContext context, String page) {
    selectedPageNotifier.value = page;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFF1F4226),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        scaffoldBackgroundColor: Colors.white,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: FittedBox(
            fit: BoxFit.scaleDown,
            child: ValueListenableBuilder(
              valueListenable: selectedPageNotifier,
              builder: (context, value, child) {
                return Text(
                  titleOfPages[selectedPageNotifier.value] ?? "Error",
                );
              },
            ),
          ),
          actions: [
            Text(isLightModeNotifier.value ? "Light Theme" : "Dark Theme"),
            ValueListenableBuilder(
              valueListenable: isLightModeNotifier,
              builder: (context, isLightMode, child) {
                return IconButton(
                  onPressed: () {
                    setState(() {
                      isLightModeNotifier.value = !isLightMode;
                    });
                  },
                  icon: Icon(isLightMode ? Icons.light_mode : Icons.dark_mode),
                );
              },
            ),
          ],
        ),
        drawer: Drawer(
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
                    leading: Icon(Icons.photo_camera),
                    title: Text('Scan Kode Label'),
                    onTap: () => _selectPage(context, "scan_label_page"),
                  ),
                  ListTile(
                    leading: Icon(Icons.storage),
                    title: Text('Kelola Data Sampel'),
                    onTap: () => _selectPage(context, "manage_data_page"),
                  ),
                  ListTile(
                    leading: Icon(Icons.map),
                    title: Text('Peta Lokasi Cluster Plot'),
                    onTap: () => _selectPage(context, "location_map_page"),
                  ),
                  ListTile(
                    leading: Icon(Icons.book),
                    title: Text('Panduan Aplikasi'),
                    onTap: () => _selectPage(context, "tutorial_page"),
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
        ),
        body: Stack(
          children: [
            //* Background App
            Image(
              image: AssetImage(
                isLightModeNotifier.value
                    ? "assets/images/light-bg-notitle.png"
                    : "assets/images/dark-bg-notitle.png",
              ),
              fit: BoxFit.cover,
              height: double.infinity,
              width: double.infinity,
            ),
            //* Pages App
            ValueListenableBuilder(
              valueListenable: selectedPageNotifier,
              builder: (context, selectedPage, child) {
                return pages[selectedPage] ??
                    Center(child: Text("Page not found"));
              },
            ),
          ],
        ),
      ),
    );
  }
}
