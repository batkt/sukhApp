import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService extends ChangeNotifier {
  static const String _themeKey = 'theme_mode_v2';
  ThemeMode _themeMode = ThemeMode.dark;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  ThemeService() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // New storage format: string 'dark' | 'light'
      final stored = prefs.getString(_themeKey);
      if (stored == 'light') {
        _themeMode = ThemeMode.light;
      } else if (stored == 'dark') {
        _themeMode = ThemeMode.dark;
      } else {
        // Backwards‑compat: old int value (ThemeMode index)
        final legacyIndex = prefs.getInt(_themeKey);
        if (legacyIndex != null) {
          if (legacyIndex == ThemeMode.light.index) {
            _themeMode = ThemeMode.light;
          } else if (legacyIndex == ThemeMode.dark.index) {
            _themeMode = ThemeMode.dark;
          } else {
            _themeMode = ThemeMode.dark;
          }
        } else {
          // Default to dark if nothing stored
          _themeMode = ThemeMode.dark;
        }
      }

      notifyListeners();
    } catch (e) {
      // Default to dark mode on error
      _themeMode = ThemeMode.dark;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    // We only support explicit dark/light, never ThemeMode.system
    final normalizedMode =
        (mode == ThemeMode.light) ? ThemeMode.light : ThemeMode.dark;

    if (_themeMode == normalizedMode) return;

    _themeMode = normalizedMode;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _themeKey,
        _themeMode == ThemeMode.dark ? 'dark' : 'light',
      );
    } catch (e) {
      print('Error saving theme: $e');
    }
  }

  Future<void> toggleTheme() async {
    final newMode =
        _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await setThemeMode(newMode);
  }
}

