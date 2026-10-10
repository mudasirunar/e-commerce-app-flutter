import 'package:flutter/material.dart';
import '../services/local/local_storage_service.dart';

/// Provider managing active ThemeMode with persistence via SharedPreferences.
class ThemeProvider extends ChangeNotifier {
  final LocalStorageService _storage;
  late ThemeMode _themeMode;

  ThemeProvider(this._storage) {
    _themeMode = _storage.getThemeMode();
  }

  ThemeMode get themeMode => _themeMode;

  /// Returns true if currently in dark mode (taking platform brightness into account if system).
  bool isDarkMode(BuildContext context) {
    if (_themeMode == ThemeMode.dark) return true;
    if (_themeMode == ThemeMode.light) return false;
    return MediaQuery.platformBrightnessOf(context) == Brightness.dark;
  }

  /// Updates and persists the theme mode.
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    await _storage.setThemeMode(mode);
    notifyListeners();
  }
}
