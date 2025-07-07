import 'package:azimutree/views/pages/home_page.dart';
import 'package:azimutree/views/pages/location_map_page.dart';
import 'package:azimutree/views/pages/manage_data_page.dart';
import 'package:azimutree/views/pages/scan_label_page.dart';
import 'package:azimutree/views/pages/test_ocr1_page.dart';
import 'package:azimutree/views/pages/test_ocr2_page.dart';
import 'package:azimutree/views/pages/tutorial_page.dart';
import 'package:azimutree/data/global_variables/global_camera.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

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
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case 'home':
            return _buildFadeTransitionPageRoute(const HomePage(), settings);
          case 'scan_label_page':
            return _buildFadeTransitionPageRoute(
              const ScanLabelPage(),
              settings,
            );
          case 'manage_data_page':
            return _buildFadeTransitionPageRoute(
              const ManageDataPage(),
              settings,
            );
          case 'location_map_page':
            return _buildFadeTransitionPageRoute(
              const LocationMapPage(),
              settings,
            );
          case 'tutorial_page':
            return _buildFadeTransitionPageRoute(
              const TutorialPage(),
              settings,
            );
          case 'test_ocr_page1':
            return _buildFadeTransitionPageRoute(
              const TestOcrGoogleMlKitPage(),
              settings,
            );
          case 'test_ocr_page2':
            return _buildFadeTransitionPageRoute(
              const TestOcrGoogleVisionApiPage(),
              settings,
            );
          default:
            return _buildPageRoute(const HomePage(), settings);
        }
      },
      home: HomePage(),
    );
  }
}

//* Helper
PageRoute<dynamic> _buildPageRoute(Widget page, RouteSettings settings) {
  return MaterialPageRoute(builder: (context) => page, settings: settings);
}

// Helper function for PageRouteBuilder Animation (Fade In/Out)
PageRoute<dynamic> _buildFadeTransitionPageRoute(
  Widget page,
  RouteSettings settings,
) {
  return PageRouteBuilder(
    settings: settings,
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
    transitionDuration: const Duration(milliseconds: 300), // Duration
  );
}
