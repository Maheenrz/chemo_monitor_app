import 'package:flutter/material.dart';
import 'dart:ui';

// App Information
class AppInfo {
  static const String appName = 'Chemo Monitor';
  static const String version = '1.0.0';
  static const String description = 'AI-Integrated Chemotherapy Patient Monitoring';
}

// ===================================================
// IMPROVED HEALTH-APP COLOR PALETTE
// ===================================================

class AppColors {
  
  
  // Primary Colors - Clean Medical Palette
  static const Color wisteriaBlue = Color(0xFF2C82C9);      // Professional medical blue
  static const Color powderBlue = Color(0xFF63B4D1);        // Softer medical blue
  static const Color frozenWater = Color(0xFF4ECDC4);       // Fresh teal - represents health
  static const Color honeydew = Color(0xFFA8E6CF);          // Soft mint green
  static const Color pastelPetal = Color(0xFFFFAAA5);       // Soft coral for alerts
  
  // For backwards compatibility/aliases - IMPROVED
  static const Color primaryBlue = Color(0xFF2C82C9);      // Same as wisteriaBlue
  static const Color softGreen = Color(0xFFA8E6CF);        // Same as honeydew
  static const Color softPurple = Color(0xFFA685E2);       // Medical purple for contrast
  
  // Risk Level Colors - Clear Medical Indicators
  static const Color riskLow = Color(0xFF4ECDC4);          // Teal for low risk
  static const Color riskLowBg = Color(0xFFE7F9F7);        // Very light teal
  static const Color riskModerate = Color(0xFFFFB347);     // Amber for moderate risk
  static const Color riskModerateBg = Color(0xFFFFF0E1);   // Light amber
  static const Color riskHigh = Color(0xFFFF6B6B);         // Coral for high risk
  static const Color riskHighBg = Color(0xFFFFE9E9);       // Very light coral
  
  // Background & Text - Clean Medical White Theme
  static const Color lightBackground = Color(0xFFF8FAFE);    // Clean medical white with blue tint
  static const Color mainBackground = Color(0xFFFFFFFF);     // Pure white
  static const Color cardBackground = Color(0xFFFFFFFF);     // Pure white cards
  static const Color textPrimary = Color(0xFF2C3E50);        // Professional dark blue-gray
  static const Color textSecondary = Color(0xFF7F8C8D);      // Professional medium gray
  
  // Accent Colors - Medical Support Colors
  static const Color palePurple = Color(0xFFE6E6FA);         // Very light lavender
  static const Color paleGreen = Color(0xFFE8F8F5);          // Very light mint
  static const Color lightBlue = Color(0xFFE3F2FD);          // Very light blue
  
  // For backwards compatibility - IMPROVED
  static const Color primary = Color(0xFF2C82C9);           // wisteriaBlue
  static const Color accent = Color(0xFFFFAAA5);            // pastelPetal
  static const Color success = Color(0xFF4ECDC4);           // frozenWater
  static const Color warning = Color(0xFFFFB347);           // riskModerate
  static const Color danger = Color(0xFFFF6B6B);            // riskHigh
  static const Color background = Color(0xFFF8FAFE);        // lightBackground
  static const Color surface = Color(0xFFFFFFFF);           // White
  static const Color divider = Color(0xFFECF0F1);           // Professional light gray
  
  // Message Status Colors - Improved
  static const Color messagePending = Color(0xFFFFB347);    // Amber for pending
  static const Color messageSent = Color(0xFF63B4D1);       // Powder blue for sent
  static const Color messageDelivered = Color(0xFF2C82C9);  // Wisteria blue for delivered
  static const Color messageRead = Color(0xFF4ECDC4);       // Frozen water for read
  
  // Additional Colors for Medical UI (NEW - Optional to use)
  static const Color vitalNormal = Color(0xFF4ECDC4);       // Normal vital sign
  static const Color vitalAlert = Color(0xFFFFB347);        // Alert vital sign
  static const Color vitalCritical = Color(0xFFFF6B6B);     // Critical vital sign
  static const Color medicalBlue = Color(0xFF2C82C9);       // Medical blue
  static const Color medicalTeal = Color(0xFF4ECDC4);       // Medical teal
  static const Color medicalCoral = Color(0xFFFF6B6B);      // Medical coral
  static const Color medicalAmber = Color(0xFFFFB347);      // Medical amber
}

// ===================================================
// IMPROVED TYPOGRAPHY FOR READABILITY
// ===================================================

class AppTextStyles {
  // Headlines (28-32px Bold)
  static const TextStyle heading1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.2,
    letterSpacing: -0.5,
  );
  
  // Titles (20-24px SemiBold)
  static const TextStyle heading2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.3,
    letterSpacing: -0.3,
  );
  
  static const TextStyle heading3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.4,
    letterSpacing: -0.2,
  );
  
  // Body (16px Regular)
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.6,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.6,
  );
  
  // Small Text (12-14px Regular)
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.5,
  );
  
  // Captions (10-12px Medium)
  static const TextStyle caption = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    height: 1.4,
    letterSpacing: 0.2,
  );
  
  // Special Styles
  static const TextStyle cardTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.4,
  );
  
  static const TextStyle statNumber = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.2,
  );
  
  static const TextStyle riskLabel = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );
  
  // Message Text Styles
  static const TextStyle messageText = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.5,
  );
  
  static const TextStyle messageTimestamp = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.2,
  );
  
  // Medical Specific Styles (NEW - Optional to use)
  static const TextStyle vitalValue = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );
  
  static const TextStyle vitalLabel = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    letterSpacing: 0.3,
  );
  
  static const TextStyle medicalAlert = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.riskHigh,
    letterSpacing: 0.2,
  );
}

// ===================================================
// DIMENSIONS & SPACING SYSTEM 
// ===================================================

class AppDimensions {
  // Spacing System
  static const double spaceXS = 4.0;
  static const double spaceS = 8.0;
  static const double spaceM = 12.0;
  static const double spaceL = 16.0;
  static const double spaceXL = 20.0;
  static const double spaceXXL = 24.0;
  static const double spaceXXXL = 32.0;
  
  // Padding
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXL = 32.0;
  
  // Border Radius
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXL = 20.0;
  static const double radiusXXL = 24.0;
  static const double radiusCircle = 100.0;
  
  // Icons
  static const double iconXS = 16.0;
  static const double iconS = 20.0;
  static const double iconM = 24.0;
  static const double iconL = 32.0;
  static const double iconXL = 48.0;
  static const double iconXXL = 64.0;
  
  // Card Sizes
  static const double cardHeightSmall = 80.0;
  static const double cardHeightMedium = 100.0;
  static const double cardHeightLarge = 180.0;
  
  // Button Sizes
  static const double buttonHeight = 56.0;
  static const double buttonHeightSmall = 40.0;
  
  // App Bar
  static const double appBarHeight = 56.0;
  
  // Message Specific
  static const double messageBubbleRadius = 16.0;
  static const double messageInputHeight = 56.0;
  static const double messageAvatarSize = 32.0;
}

// ===================================================
// IMPROVED SHADOWS & ELEVATION
// ===================================================

class AppShadows {
  static List<BoxShadow> elevation1 = [
    BoxShadow(
      color: Color(0x0D000000), // 5% opacity
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
  ];
  
  static List<BoxShadow> elevation2 = [
    BoxShadow(
      color: Color(0x1A000000), // 10% opacity
      blurRadius: 8,
      offset: Offset(0, 4),
    ),
  ];
  
  static List<BoxShadow> elevation3 = [
    BoxShadow(
      color: Color(0x26000000), // 15% opacity
      blurRadius: 12,
      offset: Offset(0, 6),
    ),
  ];
  
  static List<BoxShadow> glassShadow = [
    BoxShadow(
      color: Color(0x0D000000), // 5% opacity
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];
  
  static List<BoxShadow> buttonShadow = [
    BoxShadow(
      color: AppColors.wisteriaBlue.withOpacity(0.2),
      blurRadius: 8,
      offset: Offset(0, 4),
    ),
  ];
  
  static List<BoxShadow> messageShadow = [
    BoxShadow(
      color: Color(0x0A000000), // 4% opacity
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
  ];
  
  // New Medical UI Shadows
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x0D000000),
      blurRadius: 6,
      offset: Offset(0, 2),
      spreadRadius: -2,
    ),
  ];
}

// ===================================================
// REMOVED GRADIENTS - SOLID COLORS ONLY
// ===================================================

class AppGradients {
  // Keeping class for backward compatibility but using single colors
  
  static Gradient primary = LinearGradient(
    colors: [AppColors.wisteriaBlue, AppColors.wisteriaBlue], // Single color
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static Gradient success = LinearGradient(
    colors: [AppColors.frozenWater, AppColors.frozenWater], // Single color
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static Gradient warning = LinearGradient(
    colors: [AppColors.pastelPetal, AppColors.pastelPetal], // Single color
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static Gradient glass = LinearGradient(
    colors: [Colors.white, Colors.white], // Single color
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static Gradient messageSent = LinearGradient(
    colors: [AppColors.powderBlue, AppColors.powderBlue], // Single color
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

// ===================================================
// ANIMATION DURATIONS 
// ===================================================

class AppAnimations {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration verySlow = Duration(milliseconds: 800);
  
  static const Curve easeInOut = Curves.easeInOut;
  static const Curve easeOutCubic = Curves.easeOutCubic;
  static const Curve elasticOut = Curves.elasticOut;
}

// ===================================================
// ENUMS 
// ===================================================

enum UserRole {
  patient,
  doctor,
}

enum SeverityLevel {
  low,
  moderate,
  high,
}

// Message Status Enum
enum MessageStatus {
  pending,    // Message is being sent
  sent,       // Message reached server
  delivered,  // Message delivered to recipient device
  read        // Message read by recipient
}

// ===================================================
// UTILITY CLASSES FOR MEDICAL UI
// ===================================================

class GlassMorphism {
  static BoxDecoration card({
    double borderRadius = AppDimensions.radiusLarge,
    double blurSigma = 10.0,
    Color color = Colors.white,
  }) {
    return BoxDecoration(
      color: color.withOpacity(0.95), // Less opacity for better readability
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: Colors.white.withOpacity(0.3),
        width: 1,
      ),
      boxShadow: AppShadows.glassShadow,
    );
  }
  
  static Widget effect({
    required Widget child,
    double sigmaX = 10.0,
    double sigmaY = 10.0,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: sigmaX, sigmaY: sigmaY),
        child: child,
      ),
    );
  }
}

// ===================================================
// NEW: MEDICAL UI UTILITIES (Optional to use)
// ===================================================

class MedicalUI {
  // Get appropriate color for vital values
  static Color getVitalColor({
    required String vitalType,
    required double value,
  }) {
    switch (vitalType) {
      case 'heartRate':
        if (value >= 60 && value <= 100) return AppColors.vitalNormal;
        if (value >= 50 && value <= 120) return AppColors.vitalAlert;
        return AppColors.vitalCritical;
        
      case 'spo2':
        if (value >= 95) return AppColors.vitalNormal;
        if (value >= 90) return AppColors.vitalAlert;
        return AppColors.vitalCritical;
        
      case 'temperature':
        if (value >= 36.0 && value <= 37.5) return AppColors.vitalNormal;
        if (value >= 35.5 && value <= 38.5) return AppColors.vitalAlert;
        return AppColors.vitalCritical;
        
      default:
        return AppColors.textPrimary;
    }
  }
  
  // Get risk level display properties
  static Map<String, dynamic> getRiskLevelProperties(SeverityLevel level) {
    switch (level) {
      case SeverityLevel.low:
        return {
          'color': AppColors.riskLow,
          'backgroundColor': AppColors.riskLowBg,
          'label': 'Low Risk',
          'icon': Icons.check_circle,
        };
      case SeverityLevel.moderate:
        return {
          'color': AppColors.riskModerate,
          'backgroundColor': AppColors.riskModerateBg,
          'label': 'Monitor',
          'icon': Icons.warning,
        };
      case SeverityLevel.high:
        return {
          'color': AppColors.riskHigh,
          'backgroundColor': AppColors.riskHighBg,
          'label': 'High Risk',
          'icon': Icons.error,
        };
    }
  }
  
  // Create medical card decoration
  static BoxDecoration medicalCard({
    bool elevated = true,
    Color color = AppColors.cardBackground,
    SeverityLevel? riskLevel,
  }) {
    Color borderColor = riskLevel != null 
      ? MedicalUI.getRiskLevelProperties(riskLevel)['color']
      : AppColors.divider;
    
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
      border: Border.all(
        color: borderColor.withOpacity(riskLevel != null ? 0.3 : 0.1),
        width: riskLevel != null ? 2 : 1,
      ),
      boxShadow: elevated ? AppShadows.cardShadow : null,
    );
  }
  
  // Create vital display widget
  static Widget vitalDisplay({
    required String label,
    required String value,
    required String unit,
    Color? valueColor,
    bool isNormal = true,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(
          color: isNormal ? AppColors.divider : AppColors.riskHigh.withOpacity(0.3),
          width: isNormal ? 1 : 2,
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: AppTextStyles.vitalLabel,
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: AppTextStyles.vitalValue.copyWith(
                  color: valueColor ?? AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          if (!isNormal)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.riskHighBg,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Alert',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.riskHigh,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}