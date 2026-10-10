import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'utils/app_config.dart';

/// Root application widget configuring themes and app shell.
class EcommerceApp extends StatelessWidget {
  final ThemeMode themeMode;

  const EcommerceApp({
    super.key,
    this.themeMode = ThemeMode.system,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
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
