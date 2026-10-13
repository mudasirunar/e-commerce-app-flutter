import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/theme_provider.dart';
import 'screens/cart/cart_screen.dart';
import 'screens/catalog/catalog_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/orders/orders_screen.dart';
import 'theme/app_theme.dart';
import 'utils/app_config.dart';
import 'widgets/navigation/app_navigation_shell.dart';

/// Root application widget configuring themes and hosting the core navigation shell.
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
      home: const AppNavigationShell(
        destinations: [
          HomeScreen(),
          CatalogScreen(),
          CartScreen(),
          OrdersScreen(),
        ],
      ),
    );
  }
}
