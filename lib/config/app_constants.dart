import 'package:flutter/material.dart';

// App Information
class AppInfo {
  static const String appName = 'Chemo Monitor';
  static const String version = '1.0.0';
  static const String description = 'AI-Integrated Chemotherapy Patient Monitoring';
}

// Color Palette - Blue & Lavender Theme
class AppColors {
  // Primary Colors - Blue Theme
  static const Color primary = Color(0xFF4A90E2); // Soft Blue
  static const Color primaryDark = Color(0xFF2E5C8A);
  static const Color primaryLight = Color(0xFF7BB3FF);
  
  // Accent Colors - Lavender Theme
  static const Color accent = Color(0xFFB8A4E0); // Lavender
  static const Color accentLight = Color(0xFFE6DEFF);
  static const Color accentDark = Color(0xFF8B7BB8);
  
  // Status Colors
  static const Color success = Color(0xFF66BB6A); // Soft Green
  static const Color warning = Color(0xFFFFA726); // Soft Orange
  static const Color danger = Color.fromARGB(255, 244, 103, 100); // Soft Red
  static const Color info = Color(0xFF4A90E2); // Blue
  
  // Severity Colors (matching risk levels)
  static const Color severityLow = Color(0xFF66BB6A);
  static const Color severityMedium = Color(0xFFFFA726);
  static const Color severityHigh = Color(0xFFEF5350);
  
  // Text Colors
  static const Color textPrimary = Color(0xFF2C3E50);
  static const Color textSecondary = Color(0xFF7F8C8D);
  static const Color textHint = Color(0xFFBDC3C7);
  
  // Background Colors
  static const Color background = Color(0xFFF8F9FE); // Very light blue-ish
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBackground = Color(0xFFF3F4FF); // Light lavender tint
  static const Color divider = Color(0xFFE8EAF6);
  
  // Chat Colors
  static const Color chatBubbleMe = Color(0xFF4A90E2); // Blue for user
  static const Color chatBubbleOther = Color(0xFFE6DEFF); // Light lavender for others
  static const Color chatBotBubble = Color(0xFFB8A4E0); // Lavender for AI
}
// Text Styles
class AppTextStyles {
  static const TextStyle heading1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle heading2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle heading3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    color: AppColors.textSecondary,
  );
  
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    color: AppColors.textHint,
  );
}

// App Dimensions
class AppDimensions {
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXL = 32.0;
  
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  
  static const double iconSmall = 20.0;
  static const double iconMedium = 24.0;
  static const double iconLarge = 32.0;
  static const double iconXL = 48.0;
}

// User Roles
enum UserRole {
  patient,
  doctor,
}

// Severity Levels
enum SeverityLevel {
  low,
  medium,
  high,
}