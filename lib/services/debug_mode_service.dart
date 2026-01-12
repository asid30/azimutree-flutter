import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DebugModeService {
  static const String _keyDebugModeEnabled = 'debug_mode_enabled';

  DebugModeService._();

  static final DebugModeService instance = DebugModeService._();

  final ValueNotifier<bool> enabled = ValueNotifier<bool>(false);

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    final prefs = await SharedPreferences.getInstance();
    enabled.value = prefs.getBool(_keyDebugModeEnabled) ?? false;
    _initialized = true;
  }

  Future<void> setEnabled(bool value) async {
    // Ensure listeners update immediately.
    enabled.value = value;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDebugModeEnabled, value);
  }

  Future<bool> isEnabled() async {
    if (!_initialized) {
      await init();
    }
    return enabled.value;
  }
}
