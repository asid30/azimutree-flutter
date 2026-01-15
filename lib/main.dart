import 'package:azimutree/views/pages/about_page.dart';
import 'package:azimutree/views/pages/home_page.dart';
import 'package:azimutree/views/pages/location_map_page.dart';
import 'package:azimutree/views/pages/manage_data_page.dart';
// Scan feature removed: no scan_label_page import
import 'package:azimutree/views/pages/settings_page.dart';
import 'package:azimutree/views/pages/tutorial_page.dart';
import 'package:azimutree/services/debug_mode_service.dart';
import 'package:azimutree/services/theme_preference_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  MapboxOptions.setAccessToken(dotenv.env['MAP_BOX_ACCESS']!);
  await DebugModeService.instance.init();
  await ThemePreferenceService.instance.init();
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
          // 'scan_label_page' removed
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
          case 'settings_page':
            return _buildFadeTransitionPageRoute(
              const SettingsPage(),
              settings,
            );
          case 'about_page':
            return _buildFadeTransitionPageRoute(const AboutPage(), settings);
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
