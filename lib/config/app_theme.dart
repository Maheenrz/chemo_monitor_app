// lib/config/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  // Modern Medical Color Palette
  static const Color primaryBlue = Color(0xFF3A86FF);
  static const Color secondaryBlue = Color(0xFF7CB9FF);
  static const Color accentTeal = Color(0xFF00B4D8);
  static const Color lightTeal = Color(0xFF90E0EF);
  static const Color lightBackground = Color(0xFFF8FAFF);
  static const Color white = Color(0xFFFFFFFF);
  static const Color darkText = Color(0xFF1A1A2E);
  static const Color grayText = Color(0xFF6B7280);

  // Risk Colors (Soft gradients)
  static const Color lowRisk = Color(0xFF00C853);
  static const Color moderateRisk = Color(0xFFFF9800);
  static const Color highRisk = Color(0xFFFF3D00);
  static const Color criticalRisk = Color(0xFFD50000);

  // Gradient Sets
  static LinearGradient blueGradient = LinearGradient(
    colors: [primaryBlue, accentTeal],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient tealGradient = LinearGradient(
    colors: [accentTeal, lightTeal],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Text Styles
  static TextStyle heading1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: darkText,
    letterSpacing: -0.5,
  );

  static TextStyle heading2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: darkText,
    letterSpacing: -0.3,
  );

  static TextStyle heading3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: darkText,
  );

  static TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: darkText,
  );

  static TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: grayText,
  );

  static TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: grayText,
  );

  // Card Shadows
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 20,
      offset: Offset(0, 4),
    ),
  ];

  // Rounded Corners
  static BorderRadius cardRadius = BorderRadius.circular(20);
  static BorderRadius buttonRadius = BorderRadius.circular(15);
  static BorderRadius inputRadius = BorderRadius.circular(12);

  // App Theme Data
  static ThemeData get lightTheme {
    return ThemeData(
      scaffoldBackgroundColor: lightBackground,
      primaryColor: primaryBlue,
      colorScheme: ColorScheme.light(
        primary: primaryBlue,
        secondary: accentTeal,
        surface: white,
        background: lightBackground,
      ),
      fontFamily: 'Inter', // Add Inter font to pubspec.yaml
      appBarTheme: AppBarTheme(
        backgroundColor: white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: heading2.copyWith(color: darkText),
        iconTheme: IconThemeData(color: darkText),
      ),
      cardTheme: CardThemeData(
        color: white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: cardRadius,
        ),
      ),
      buttonTheme: ButtonThemeData(
        shape: RoundedRectangleBorder(borderRadius: buttonRadius),
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: white,
        border: OutlineInputBorder(
          borderRadius: inputRadius,
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
    );
  }
}
