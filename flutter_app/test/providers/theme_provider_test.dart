import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ecommerceapp/providers/theme_provider.dart';
import 'package:ecommerceapp/services/local/local_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ThemeProvider', () {
    test('initializes with default system mode when no preference stored', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = await LocalStorageService.create();
      final provider = ThemeProvider(storage);

      expect(provider.themeMode, ThemeMode.system);
    });

    test('initializes with stored preference', () async {
      SharedPreferences.setMockInitialValues({'theme_mode': 'dark'});
      final storage = await LocalStorageService.create();
      final provider = ThemeProvider(storage);

      expect(provider.themeMode, ThemeMode.dark);
    });

    test('updates and persists new theme mode', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = await LocalStorageService.create();
      final provider = ThemeProvider(storage);

      bool notified = false;
      provider.addListener(() => notified = true);

      await provider.setThemeMode(ThemeMode.light);

      expect(provider.themeMode, ThemeMode.light);
      expect(notified, isTrue);
      expect(storage.getThemeMode(), ThemeMode.light);
    });
  });
}
