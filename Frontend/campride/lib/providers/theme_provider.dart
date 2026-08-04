import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppearanceMode { system, light, dark }

class ThemeProvider extends ChangeNotifier {
  static const String _appearanceKey = 'appearance_mode';

  AppearanceMode _appearanceMode = AppearanceMode.system;

  AppearanceMode get appearanceMode => _appearanceMode;

  ThemeMode get themeMode {
    switch (_appearanceMode) {
      case AppearanceMode.light:
        return ThemeMode.light;
      case AppearanceMode.dark:
        return ThemeMode.dark;
      case AppearanceMode.system:
        return ThemeMode.system;
    }
  }

  /// Whether dark colors are currently in effect. For [AppearanceMode.system]
  /// this follows the platform brightness.
  bool get isDarkMode {
    if (_appearanceMode == AppearanceMode.dark) return true;
    if (_appearanceMode == AppearanceMode.light) return false;
    final platformBrightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    return platformBrightness == Brightness.dark;
  }

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_appearanceKey);
    _appearanceMode = _fromStored(stored);
    notifyListeners();
  }

  AppearanceMode _fromStored(String? stored) {
    switch (stored) {
      case 'light':
        return AppearanceMode.light;
      case 'dark':
        return AppearanceMode.dark;
      case 'system':
        return AppearanceMode.system;
      default:
        return AppearanceMode.system;
    }
  }

  Future<void> setAppearance(AppearanceMode mode) async {
    _appearanceMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_appearanceKey, mode.name);
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    await setAppearance(isDarkMode ? AppearanceMode.light : AppearanceMode.dark);
  }
}
