import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/theme_provider.dart';
import 'theme/app_theme.dart';
import 'utils/app_config.dart';

/// Root application widget configuring themes and app shell.
class EcommerceApp extends StatelessWidget {
  final ThemeMode? themeMode;

  const EcommerceApp({
    super.key,
    this.themeMode,
  });

  @override
  Widget build(BuildContext context) {
    // Read from ThemeProvider if available in context, else fallback to constructor or system
    final resolvedThemeMode = themeMode ??
        (context.watch<ThemeProvider?>()?.themeMode ?? ThemeMode.system);

    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: resolvedThemeMode,
      home: const Scaffold(
        body: Center(
          child: Text(
            'e commerce app',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}
