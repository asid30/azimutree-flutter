import 'package:azimutree/data/notifiers.dart';
import 'package:azimutree/views/pages/home_page.dart';
import 'package:azimutree/views/pages/location_map_page.dart';
import 'package:azimutree/views/pages/manage_data_page.dart';
import 'package:azimutree/views/pages/scan_label_page.dart';
import 'package:azimutree/views/pages/test_imgupload_page.dart';
import 'package:azimutree/views/pages/test_ocr1_page.dart';
import 'package:azimutree/views/pages/test_ocr2_page.dart';
import 'package:azimutree/views/pages/tutorial_page.dart';
import 'package:azimutree/views/widgets/sidebar_widget.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:azimutree/data/global_camera.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  globalCameras = await availableCameras();
  runApp(MainApp());
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
    "test_ocr_page1": TestOcrGoogleMlKitPage(),
    "test_ocr_page2": TestOcrGoogleVisionApiPage(),
    "test_imgupload_page": TestImageUploadPage(),
  };
  //* Title of Pages
  final Map<String?, String?> titleOfPages = {
    "home": "Home", // Default title Page
    "scan_label_page": "Scan Kode Label",
    "manage_data_page": "Kelola Data Sampel",
    "location_map_page": "Peta Lokasi Cluster Plot",
    "tutorial_page": "Panduan Aplikasi",
    "test_ocr_page1": "Test OCR Google ML Kit",
    "test_ocr_page2": "Test OCR Google Vision API",
    "test_imgupload_page": "Test Upload Gambar",
  };

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
        drawer: SidebarWidget(),
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
                return PopScope(
                  canPop:
                      selectedPage ==
                      "home", // hanya bisa pop (keluar) kalau di home
                  child:
                      pages[selectedPage] ??
                      Center(child: Text("Page not found")),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
