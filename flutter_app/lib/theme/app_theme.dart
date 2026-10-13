import 'package:flutter/material.dart';
import '../models/order.dart';

/// Design tokens and ThemeData definitions for Palette 2: Warm Earth & Terracotta.
class AppTheme {
  const AppTheme._();

  // --- Light Palette Tokens ---
  static const Color lightScaffold = Color(0xFFFAF8F5);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceWarm = Color(0xFFF4EFEA);
  static const Color lightTextPrimary = Color(0xFF1C1917);
  static const Color lightTextSecondary = Color(0xFF78716C);
  static const Color lightAccent = Color(0xFFC2410C); // Terracotta
  static const Color lightAccentHover = Color(0xFFEA580C);
  static const Color lightAccentContainer = Color(0xFFFFEDD5);
  static const Color lightOnAccentContainer = Color(0xFF9A3412);
  static const Color lightBorder = Color(0xFFE7E5E4);

  // --- Dark Palette Tokens ---
  static const Color darkScaffold = Color(0xFF18181B);
  static const Color darkSurface = Color(0xFF27272A);
  static const Color darkTextPrimary = Color(0xFFFAF8F5);
  static const Color darkTextSecondary = Color(0xFFA1A1AA);
  static const Color darkAccent = Color(
    0xFFFB923C,
  ); // Glowing Amber / Warm Terracotta
  static const Color darkAccentHover = Color(0xFFEA580C);
  static const Color darkAccentContainer = Color(0xFF431407);
  static const Color darkOnAccentContainer = Color(0xFFFDBA74);
  static const Color darkBorder = Color(0xFF3F3F46);

  // --- Shared Semantics ---
  static const Color success = Color(0xFF15803D);
  static const Color successContainer = Color(0xFFDCFCE7);
  static const Color warning = Color(0xFFD97706);
  static const Color warningContainer = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFB91C1C);
  static const Color errorContainer = Color(0xFFFEE2E2);

  // --- Unified 6 Order Status Colors ---
  static const Color statusPending = Color(0xFFD97706); // Warm Amber
  static const Color statusPendingDark = Color(0xFFFBBF24);
  static const Color statusConfirmed = Color(0xFF0284C7); // Trust Sky Blue
  static const Color statusConfirmedDark = Color(0xFF38BDF8);
  static const Color statusProcessing = Color(0xFF7C3AED); // Royal Purple
  static const Color statusProcessingDark = Color(0xFFC084FC);
  static const Color statusShipped = Color(0xFF4F46E5); // Transit Indigo
  static const Color statusShippedDark = Color(0xFF818CF8);
  static const Color statusDelivered = Color(0xFF16A34A); // Success Green
  static const Color statusDeliveredDark = Color(0xFF34D399);
  static const Color statusCancelled = Color(0xFFDC2626); // Alert Red
  static const Color statusCancelledDark = Color(0xFFF87171);

  /// Canonical accent color for an order lifecycle state.
  static Color orderStatusColor(OrderStatus status, {bool isDark = false}) {
    switch (status) {
      case OrderStatus.pending:
        return isDark ? statusPendingDark : statusPending;
      case OrderStatus.confirmed:
        return isDark ? statusConfirmedDark : statusConfirmed;
      case OrderStatus.processing:
        return isDark ? statusProcessingDark : statusProcessing;
      case OrderStatus.shipped:
        return isDark ? statusShippedDark : statusShipped;
      case OrderStatus.delivered:
        return isDark ? statusDeliveredDark : statusDelivered;
      case OrderStatus.cancelled:
        return isDark ? statusCancelledDark : statusCancelled;
    }
  }

  /// Color tokens (bg, fg, border) for order status chips and pill badges.
  static ({Color bg, Color fg, Color border}) orderStatusChipColors(OrderStatus status, {bool isDark = false}) {
    switch (status) {
      case OrderStatus.pending:
        return (
          bg: isDark ? const Color(0xFF38230B) : const Color(0xFFFEF3C7),
          fg: isDark ? statusPendingDark : const Color(0xFF92400E),
          border: isDark ? const Color(0xFF78350F) : const Color(0xFFFDE68A),
        );
      case OrderStatus.confirmed:
        return (
          bg: isDark ? const Color(0xFF0C2D48) : const Color(0xFFE0F2FE),
          fg: isDark ? statusConfirmedDark : const Color(0xFF0369A1),
          border: isDark ? const Color(0xFF0369A1) : const Color(0xFFBAE6FD),
        );
      case OrderStatus.processing:
        return (
          bg: isDark ? const Color(0xFF2E1045) : const Color(0xFFF3E8FF),
          fg: isDark ? statusProcessingDark : const Color(0xFF6B21A8),
          border: isDark ? const Color(0xFF581C87) : const Color(0xFFE9D5FF),
        );
      case OrderStatus.shipped:
        return (
          bg: isDark ? const Color(0xFF1E1B4B) : const Color(0xFFEEF2FF),
          fg: isDark ? statusShippedDark : const Color(0xFF3730A3),
          border: isDark ? const Color(0xFF312E81) : const Color(0xFFC7D2FE),
        );
      case OrderStatus.delivered:
        return (
          bg: isDark ? const Color(0xFF063319) : const Color(0xFFDCFCE7),
          fg: isDark ? statusDeliveredDark : const Color(0xFF166534),
          border: isDark ? const Color(0xFF065F46) : const Color(0xFFBBF7D0),
        );
      case OrderStatus.cancelled:
        return (
          bg: isDark ? const Color(0xFF2C1316) : const Color(0xFFFEF2F2),
          fg: isDark ? statusCancelledDark : const Color(0xFFDC2626),
          border: isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFECACA),
        );
    }
  }

  // Background aliases
  static const Color lightBackground = lightScaffold;
  static const Color darkBackground = darkScaffold;

  // --- Spacing Scale ---
  static const double space4 = 4.0;
  static const double space8 = 8.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space20 = 20.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;
  static const double space48 = 48.0;

  // --- Border Radii ---
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusFull = 999.0;

  /// Light ThemeData
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightScaffold,
      primaryColor: lightAccent,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: lightAccent,
        onPrimary: Colors.white,
        primaryContainer: lightAccentContainer,
        onPrimaryContainer: lightOnAccentContainer,
        secondary: lightAccentHover,
        onSecondary: Colors.white,
        surface: lightSurface,
        onSurface: lightTextPrimary,
        error: error,
        onError: Colors.white,
        errorContainer: errorContainer,
        onErrorContainer: error,
        outline: lightBorder,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: lightScaffold,
        foregroundColor: lightTextPrimary,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0.5,
        titleTextStyle: TextStyle(
          color: lightTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          side: const BorderSide(color: lightBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: lightAccent,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, 48),
          padding: const EdgeInsets.symmetric(
            horizontal: space24,
            vertical: space12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSmall),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: lightTextPrimary,
          minimumSize: const Size(double.infinity, 48),
          side: const BorderSide(color: lightBorder, width: 1.2),
          padding: const EdgeInsets.symmetric(
            horizontal: space24,
            vertical: space12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSmall),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightSurface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: space16,
          vertical: space16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
          borderSide: const BorderSide(color: lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
          borderSide: const BorderSide(color: lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
          borderSide: const BorderSide(color: lightAccent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
          borderSide: const BorderSide(color: error),
        ),
        hintStyle: const TextStyle(color: lightTextSecondary, fontSize: 14),
        labelStyle: const TextStyle(color: lightTextSecondary, fontSize: 14),
      ),
      dividerTheme: const DividerThemeData(
        color: lightBorder,
        thickness: 1,
        space: 1,
      ),
    );
  }

  /// Dark ThemeData
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkScaffold,
      primaryColor: darkAccent,
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: darkAccent,
        onPrimary: Color(0xFF18181B),
        primaryContainer: darkAccentContainer,
        onPrimaryContainer: darkOnAccentContainer,
        secondary: darkAccentHover,
        onSecondary: Colors.white,
        surface: darkSurface,
        onSurface: darkTextPrimary,
        error: Color(0xFFF87171),
        onError: Colors.black,
        outline: darkBorder,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkScaffold,
        foregroundColor: darkTextPrimary,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0.5,
        titleTextStyle: TextStyle(
          color: darkTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          side: const BorderSide(color: darkBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkAccent,
          foregroundColor: const Color(0xFF18181B),
          elevation: 0,
          minimumSize: const Size(double.infinity, 48),
          padding: const EdgeInsets.symmetric(
            horizontal: space24,
            vertical: space12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSmall),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: darkTextPrimary,
          minimumSize: const Size(double.infinity, 48),
          side: const BorderSide(color: darkBorder, width: 1.2),
          padding: const EdgeInsets.symmetric(
            horizontal: space24,
            vertical: space12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSmall),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: space16,
          vertical: space16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
          borderSide: const BorderSide(color: darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
          borderSide: const BorderSide(color: darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
          borderSide: const BorderSide(color: darkAccent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
          borderSide: const BorderSide(color: Color(0xFFF87171)),
        ),
        hintStyle: const TextStyle(color: darkTextSecondary, fontSize: 14),
        labelStyle: const TextStyle(color: darkTextSecondary, fontSize: 14),
      ),
      dividerTheme: const DividerThemeData(
        color: darkBorder,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
