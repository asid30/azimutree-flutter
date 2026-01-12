import 'package:azimutree/data/notifiers/notifiers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemePreferenceService {
  static const String _keyIsLightMode = 'is_light_mode';

  ThemePreferenceService._();

  static final ThemePreferenceService instance = ThemePreferenceService._();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getBool(_keyIsLightMode);
    if (stored != null) {
      isLightModeNotifier.value = stored;
    }

    // Persist every change.
    isLightModeNotifier.addListener(() async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyIsLightMode, isLightModeNotifier.value);
    });

    _initialized = true;
  }
}
