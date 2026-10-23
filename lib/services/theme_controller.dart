import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ThemeController extends ChangeNotifier {
  static const String _settingsBoxName = 'app_settings';
  static const String _themeModeKey = 'themeMode';

  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  /// Restore the saved theme preference.
  Future<void> init() async {
    final box = Hive.box(_settingsBoxName);
    final savedMode = box.get(_themeModeKey);

    switch (savedMode) {
      case 'light':
        _themeMode = ThemeMode.light;
      case 'dark':
        _themeMode = ThemeMode.dark;
      case 'system':
      default:
        _themeMode = ThemeMode.system;
    }

    notifyListeners();
  }

  /// Update the theme and persist the preference.
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) {
      return;
    }

    _themeMode = mode;
    notifyListeners();

    final box = Hive.box(_settingsBoxName);
    await box.put(_themeModeKey, _modeToString(mode));
  }

  String _modeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}