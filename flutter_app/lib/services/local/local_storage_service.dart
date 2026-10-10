import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service managing persistent key-value storage via SharedPreferences.
class LocalStorageService {
  static const String _keyThemeMode = 'theme_mode';
  static const String _keyLatestAttemptId = 'latest_checkout_attempt_id';

  final SharedPreferences _prefs;

  LocalStorageService(this._prefs);

  /// Factory initializer awaiting SharedPreferences instance.
  static Future<LocalStorageService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return LocalStorageService(prefs);
  }

  // ==================== THEME PREFERENCE ====================

  /// Loads saved ThemeMode: 'system', 'light', 'dark'. Defaults to ThemeMode.system.
  ThemeMode getThemeMode() {
    final raw = _prefs.getString(_keyThemeMode);
    switch (raw) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  /// Persists selected ThemeMode.
  Future<bool> setThemeMode(ThemeMode mode) async {
    switch (mode) {
      case ThemeMode.light:
        return await _prefs.setString(_keyThemeMode, 'light');
      case ThemeMode.dark:
        return await _prefs.setString(_keyThemeMode, 'dark');
      case ThemeMode.system:
        return await _prefs.setString(_keyThemeMode, 'system');
    }
  }

  // ==================== CHECKOUT IDEMPOTENCY ====================

  /// Persists the active checkout attempt ID for retry resilience.
  Future<bool> setLatestAttemptId(String attemptId) async {
    return await _prefs.setString(_keyLatestAttemptId, attemptId);
  }

  /// Retrieves the active checkout attempt ID if any.
  String? getLatestAttemptId() {
    return _prefs.getString(_keyLatestAttemptId);
  }

  /// Clears the active checkout attempt ID upon confirmed completion.
  Future<bool> clearLatestAttemptId() async {
    return await _prefs.remove(_keyLatestAttemptId);
  }
}
