import 'package:chemo_monitor_app/services/chat_initializer_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chemo_monitor_app/config/app_constants.dart';
import 'package:chemo_monitor_app/services/health_data_service.dart';
import 'package:chemo_monitor_app/screens/shared/login_screen.dart';
import 'package:chemo_monitor_app/screens/shared/register_screen.dart';
import 'package:chemo_monitor_app/screens/doctor/doctor_home_screen.dart';
import 'package:chemo_monitor_app/screens/patient/patient_home_screen.dart';
import 'package:chemo_monitor_app/screens/doctor/analytics_screen.dart';
import 'package:chemo_monitor_app/screens/doctor/notifications_screen.dart';
import 'package:chemo_monitor_app/screens/shared/profile_edit_screen.dart';
import 'package:chemo_monitor_app/screens/shared/settings_screen.dart';
import 'firebase_options.dart';

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
  }

  try{
    final chatInitializer = ChatInitializer();
    await chatInitializer.initializeUserChats();
    print('Chats initialized successfully');
  }catch(e){
    print('Error initializing chats: $e');
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
        fontFamily: 'Poppins',
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryBlue,
          background: AppColors.mainBackground,
          surface: Colors.white,
        ),
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: AppTextStyles.heading3.copyWith(
            color: AppColors.textPrimary,
          ),
          iconTheme: IconThemeData(color: AppColors.primaryBlue),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
            borderSide: BorderSide(
              color: AppColors.primaryBlue,
              width: 2,
            ),
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingMedium,
            vertical: AppDimensions.paddingSmall,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryBlue,
            foregroundColor: Colors.white,
            minimumSize: Size(double.infinity, AppDimensions.buttonHeight),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
            ),
            textStyle: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      home: const AuthWrapper(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/doctor': (context) => const DoctorHomeScreen(),
        '/patient': (context) => const PatientHomeScreen(),
        '/analytics': (context) => const AnalyticsScreen(),
        '/notifications': (context) => const NotificationsScreen(),
        '/profile': (context) => const ProfileEditScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }
}


class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);  // FIXED: Proper constructor

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        // Show loading while checking auth state
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingScreen();
        }

        // User is NOT logged in
        if (!authSnapshot.hasData || authSnapshot.data == null) {
          return const LoginScreen();
        }

        // User IS logged in - check Firestore
        final user = authSnapshot.data!;
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get(),
          builder: (context, userSnapshot) {
            // Show loading while fetching user data
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingScreen();
            }

            // Handle errors or missing user document
            if (userSnapshot.hasError || 
                !userSnapshot.hasData || 
                userSnapshot.data == null) {
              // Create user document if missing
              _createUserDocument(user.uid, user.email ?? '');
              return _buildLoadingScreen(message: 'Setting up your profile...');
            }

            final userDoc = userSnapshot.data!;
            
            // If document doesn't exist, create it
            if (!userDoc.exists) {
              _createUserDocument(user.uid, user.email ?? '');
              return _buildLoadingScreen(message: 'Creating your profile...');
            }

            // Document exists - get role and navigate
            final userData = userDoc.data() as Map<String, dynamic>;
            final role = userData['role']?.toString() ?? 'patient';

            return role == 'doctor' 
                ? const DoctorHomeScreen()
                : const PatientHomeScreen();
          },
        );
      },
    );
  }

  Future<void> _createUserDocument(String uid, String email) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'email': email,
        'role': 'patient',
        'name': email.split('@').first,
        'assignedDoctorId': '',
        'profileImageUrl': '',
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)); // Use merge to avoid overwriting existing data
    } catch (e) {
      print('Error creating user document: $e');
    }
  }

  Widget _buildLoadingScreen({String message = 'Loading...'}) {
    return Scaffold(
      backgroundColor: AppColors.mainBackground,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
           const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
            ),
            const SizedBox(height: 20),
            Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}