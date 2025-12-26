import 'package:flutter/material.dart';
import 'dart:ui';

// App Information
class AppInfo {
  static const String appName = 'Chemo Monitor';
  static const String version = '1.0.0';
  static const String description = 'AI-Integrated Chemotherapy Patient Monitoring';
}

// ===================================================
// YOUR NEW SOFT PASTEL COLOR PALETTE
// ===================================================

class AppColors {
  // Your specified colors
  static const Color wisteriaBlue = Color.fromARGB(255, 104, 145, 221);      // Primary soft blue-violet
  static const Color powderBlue = Color.fromARGB(255, 102, 125, 142);        // Comforting blue
  static const Color frozenWater = Color.fromARGB(255, 108, 138, 127);       // Turquoise shimmer
  static const Color honeydew = Color.fromARGB(255, 143, 220, 178);          // Pale green
  static const Color pastelPetal = Color.fromARGB(255, 225, 157, 188);       // Blush pink
  
  // For backwards compatibility/aliases
  static const Color primaryBlue = Color(0xFF809bce);      // Same as wisteriaBlue
  static const Color softGreen = Color(0xFFb8e0d2);        // Same as frozenWater
  static const Color softPurple = Color(0xFFeac4d5);       // Same as pastelPetal
  
  // Risk Level Colors using your palette
  static const Color riskLow = Color.fromARGB(255, 125, 189, 167);          // Frozen Water
  static const Color riskLowBg = Color(0xFFE8F8F0);
  static const Color riskModerate = Color.fromARGB(255, 235, 154, 191);     // Pastel Petal
  static const Color riskModerateBg = Color.fromARGB(255, 244, 219, 200);
  static const Color riskHigh = Color.fromARGB(255, 243, 144, 169);         // Slightly deeper petal
  static const Color riskHighBg = Color(0xFFFFEEF1);
  
  // Background & Text
  static const Color lightBackground = Color(0xFFF5F7FA);    // Very light gray-blue
  static const Color mainBackground = Color(0xFFFFFFFF);     // White
  static const Color cardBackground = Color(0xFFFFFFFF);     // White
  static const Color textPrimary = Color(0xFF2D3E50);        // Dark blue-gray
  static const Color textSecondary = Color(0xFF8E9AAF);      // Medium blue-gray
  
  // Accent Colors
  static const Color palePurple = Color(0xFFF2F0FC);
  static const Color paleGreen = Color(0xFFE8F8F0);
  static const Color lightBlue = Color(0xFFE8F1FC);
  
  // For backwards compatibility
  static const Color primary = Color(0xFF809bce);           // wisteriaBlue
  static const Color accent = Color(0xFFeac4d5);            // pastelPetal
  static const Color success = Color(0xFFb8e0d2);           // frozenWater
  static const Color warning = Color(0xFFeac4d5);           // pastelPetal
  static const Color danger = Color(0xFFf4b4c4);            // deeper pastelPetal
  static const Color background = Color(0xFFF5F7FA);        // lightBackground
  static const Color surface = Color(0xFFFFFFFF);           // White
  static const Color divider = Color(0xFFE8EAF6);
  
  // Message Status Colors
  static const Color messagePending = Color.fromARGB(255, 254, 167, 206);    // Pink for pending
  static const Color messageSent = Color.fromARGB(255, 255, 255, 255);       // Powder blue for sent
  static const Color messageDelivered = Color.fromARGB(255, 28, 104, 245);  // Wisteria blue for delivered
  static const Color messageRead = Color.fromARGB(255, 10, 152, 103);       // Frozen water for read
}

// ===================================================
// TYPOGRAPHY (Poppins/Inter style)
// ===================================================

class AppTextStyles {
  // Headlines (28-32px Bold)
  static const TextStyle heading1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.2,
  );
  
  // Titles (20-24px SemiBold)
  static const TextStyle heading2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.3,
  );
  
  static const TextStyle heading3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.4,
  );
  
  // Body (16px Regular)
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.5,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.5,
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
  );
  
  // Special Styles
  static const TextStyle cardTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle statNumber = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
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
    height: 1.4,
  );
  
  static const TextStyle messageTimestamp = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.2,
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
  static const double buttonHeightSmall = 36.0;
  
  // App Bar
  static const double appBarHeight = 56.0;
  
  // Message Specific
  static const double messageBubbleRadius = 16.0;
  static const double messageInputHeight = 56.0;
  static const double messageAvatarSize = 32.0;
}

// ===================================================
// SHADOWS & ELEVATION SYSTEM
// ===================================================

class AppShadows {
  static List<BoxShadow> elevation1 = [
    BoxShadow(
      color: AppColors.textPrimary.withOpacity(0.05),
      blurRadius: 10,
      offset: Offset(0, 4),
    ),
  ];
  
  static List<BoxShadow> elevation2 = [
    BoxShadow(
      color: AppColors.textPrimary.withOpacity(0.08),
      blurRadius: 15,
      offset: Offset(0, 6),
    ),
  ];
  
  static List<BoxShadow> elevation3 = [
    BoxShadow(
      color: AppColors.textPrimary.withOpacity(0.1),
      blurRadius: 20,
      offset: Offset(0, 8),
    ),
  ];
  
  static List<BoxShadow> glassShadow = [
    BoxShadow(
      color: AppColors.textPrimary.withOpacity(0.05),
      blurRadius: 20,
      offset: Offset(0, 5),
    ),
  ];
  
  static List<BoxShadow> buttonShadow = [
    BoxShadow(
      color: AppColors.wisteriaBlue.withOpacity(0.3),
      blurRadius: 20,
      offset: Offset(0, 10),
    ),
  ];
  
  static List<BoxShadow> messageShadow = [
    BoxShadow(
      color: AppColors.textPrimary.withOpacity(0.06),
      blurRadius: 6,
      offset: Offset(0, 2),
    ),
  ];
}

// ===================================================
// GRADIENTS (Using your new palette)
// ===================================================

class AppGradients {
  static Gradient primary = LinearGradient(
    colors: [AppColors.wisteriaBlue, AppColors.powderBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static Gradient success = LinearGradient(
    colors: [AppColors.frozenWater, AppColors.honeydew],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static Gradient warning = LinearGradient(
    colors: [AppColors.pastelPetal, Color(0xFFf4b4c4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static Gradient glass = LinearGradient(
    colors: [
      Colors.white.withOpacity(0.7),
      Colors.white.withOpacity(0.3),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static Gradient messageSent = LinearGradient(
    colors: [AppColors.wisteriaBlue, AppColors.powderBlue],
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
// UTILITY CLASSES FOR GLASSMORPHISM
// ===================================================

class GlassMorphism {
  static BoxDecoration card({
    double borderRadius = AppDimensions.radiusLarge,
    double blurSigma = 10.0,
    Color color = Colors.white,
  }) {
    return BoxDecoration(
      color: color.withOpacity(0.7),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: Colors.white.withOpacity(0.2),
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