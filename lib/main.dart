import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:chemo_monitor_app/config/app_constants.dart';
import 'package:chemo_monitor_app/services/health_data_service.dart';
import 'firebase_options.dart';
import 'package:chemo_monitor_app/screens/auth_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 2. Initialize DotEnv (Secrets)
  try {
    await dotenv.load(fileName: ".env");
    print('✅ DotEnv loaded successfully');
  } catch (e) {
    print('⚠️ Failed to load .env file: $e');
  }
  
  // 3. Initialize ML Model
  try {
    final healthService = HealthDataService();
    await healthService.initializeMLModel();
    print('✅ ML model ready!');
  } catch (e) {
    print('⚠️ ML model initialization failed: $e');
    print('📝 App will continue with rule-based predictions');
  }
  
  runApp(const ChemoMonitorApp());
}

class ChemoMonitorApp extends StatelessWidget {
  const ChemoMonitorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppInfo.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Modern soft color scheme
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        
        // Custom font (you'll need to add Poppins font files)
        fontFamily: 'Poppins',
        
        // App bar theme
        appBarTheme: AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textPrimary,
          titleTextStyle: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        
        // Card theme
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        
        // Button theme
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}