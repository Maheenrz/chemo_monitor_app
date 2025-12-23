// lib/screens/patient/patient_home_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chemo_monitor_app/config/app_constants.dart';
import 'package:chemo_monitor_app/services/auth_service.dart';
import 'package:chemo_monitor_app/services/health_data_service.dart';
import 'package:chemo_monitor_app/models/health_data_model.dart';
import 'package:chemo_monitor_app/models/user_model.dart';
import 'package:chemo_monitor_app/screens/patient/vitals_entry_screen.dart';
import 'package:chemo_monitor_app/screens/patient/health_history_screen.dart';
import 'package:chemo_monitor_app/screens/patient/chatbot_screen.dart';
import 'package:chemo_monitor_app/screens/shared/message_screen.dart';
import 'package:chemo_monitor_app/screens/shared/settings_screen.dart';
import 'package:intl/intl.dart';

// Soft Pastel Color Palette for Chemo Care
class ChemoColors {
  static const Color wisteriaBlue =
      Color(0xFF809bce); // Primary soft blue-violet
  static const Color powderBlue = Color(0xFF95b8d1); // Comforting blue
  static const Color frozenWater = Color(0xFFb8e0d2); // Turquoise shimmer
  static const Color honeydew = Color(0xFFd6eadf); // Pale green
  static const Color pastelPetal = Color(0xFFeac4d5); // Blush pink

  // Background shades
  static const Color lightBackground = Color(0xFFF5F7FA);
  static const Color cardBackground = Colors.white;

  // Text colors
  static const Color textPrimary = Color(0xFF2D3E50);
  static const Color textSecondary = Color(0xFF8E9AAF);

  // Risk levels (softer versions)
  static const Color riskLow = Color(0xFFb8e0d2); // Frozen Water
  static const Color riskModerate = Color(0xFFeac4d5); // Pastel Petal
  static const Color riskHigh = Color(0xFFf4b4c4); // Slightly deeper petal
}

class PatientHomeScreen extends StatefulWidget {
  const PatientHomeScreen({super.key});

  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> {
  final AuthService _authService = AuthService();
  final HealthDataService _healthDataService = HealthDataService();

  UserModel? _userProfile;
  HealthDataModel? _latestHealthData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final profile = await _authService.getUserProfile(user.uid);
      final latestData = await _healthDataService.getLatestHealthData(user.uid);

      if (mounted) {
        setState(() {
          _userProfile = profile;
          _latestHealthData = latestData;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading patient data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getRiskLevelText() {
    if (_latestHealthData == null) return 'Not Recorded';
    switch (_latestHealthData!.riskLevel) {
      case 0:
        return 'Stable';
      case 1:
        return 'Monitor';
      case 2:
        return 'Attention';
      default:
        return 'Unknown';
    }
  }

  Color _getRiskColor() {
    if (_latestHealthData == null) return ChemoColors.frozenWater;
    switch (_latestHealthData!.riskLevel) {
      case 0:
        return ChemoColors.riskLow;
      case 1:
        return ChemoColors.riskModerate;
      case 2:
        return ChemoColors.riskHigh;
      default:
        return ChemoColors.textSecondary;
    }
  }

  void _navigateToVitalsEntry() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const VitalsEntryScreen()),
    );

    if (result == true) {
      await _loadData();
    }
  }

  void _navigateToChatWithDoctor() async {
    if (_userProfile?.assignedDoctorId != null) {
      final doctorProfile = await _authService.getUserProfile(
        _userProfile!.assignedDoctorId!,
      );

      if (doctorProfile != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MessageScreen(
              otherUserId: doctorProfile.uid,
              otherUserName: doctorProfile.name,
              otherUserRole: 'doctor',
            ),
          ),
        );
      } else {
        _showSnackBar('Doctor profile not found');
      }
    } else {
      _showSnackBar('No assigned doctor found');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: ChemoColors.wisteriaBlue,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ChemoColors.lightBackground,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: ChemoColors.wisteriaBlue,
          child: _isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(ChemoColors.wisteriaBlue),
                  ),
                )
              : CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    // Header
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                        child: _buildHeader(),
                      ),
                    ),

                    // Hero Card (Chemo Journey Card)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: _buildHeroCard(),
                      ),
                    ),

                    // Vitals Summary
                    if (_latestHealthData != null)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          child: _buildVitalsSummaryRow(),
                        ),
                      ),

                    // Doctor Contact Card
                    if (_userProfile?.assignedDoctorId != null)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          child: _buildDoctorCard(),
                        ),
                      ),

                    // Quick Actions
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                        child: Text(
                          'Quick Actions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: ChemoColors.textPrimary,
                          ),
                        ),
                      ),
                    ),

                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        child: _buildQuickActions(),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        // Avatar
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [ChemoColors.wisteriaBlue, ChemoColors.powderBlue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              _userProfile?.name.isNotEmpty == true
                  ? _userProfile!.name[0].toUpperCase()
                  : 'P',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        const SizedBox(width: 12),

        // Greeting
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Hello, ${_userProfile?.name.split(' ').first ?? 'Patient'}!',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: ChemoColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              Text(
                DateFormat('EEEE, MMM dd').format(DateTime.now()),
                style: const TextStyle(
                  fontSize: 12,
                  color: ChemoColors.textSecondary,
                ),
              ),
            ],
          ),
        ),

        // Settings Button
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: ChemoColors.honeydew,
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(
              Icons.settings_rounded,
              color: ChemoColors.wisteriaBlue,
              size: 20,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
            padding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }

  Widget _buildHeroCard() {
    final riskColor = _getRiskColor();
    final riskText = _getRiskLevelText();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            riskColor.withOpacity(0.15),
            riskColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: riskColor.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: riskColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              riskText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Main Content Row - FIXED LAYOUT
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Side - Image (Fixed width instead of Expanded)
              Container(
                width: MediaQuery.of(context).size.width *
                    0.35, // 35% of screen width
                height: 140,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: riskColor.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    'assets/images/chemo_care.png',
                    fit: BoxFit.cover, // Changed to cover to show full image
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        decoration: BoxDecoration(
                          color: riskColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.local_hospital_rounded,
                            size: 40,
                            color: riskColor.withOpacity(0.4),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Right Side - Text Content (Takes remaining space)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title
                    Text(
                      'Your Care\nJourney',
                      style: TextStyle(
                        fontSize: 22, // Slightly smaller
                        fontWeight: FontWeight.bold,
                        color: ChemoColors.textPrimary,
                        height: 1.2,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Subtitle
                    Text(
                      _latestHealthData != null
                          ? 'Last check: ${_getTimeAgo(_latestHealthData!.timestamp)}'
                          : 'Track your vitals daily',
                      style: const TextStyle(
                        fontSize: 13,
                        color: ChemoColors.textSecondary,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Motivational Message - SOLID COLOR SECTION
                    Container(
                      padding: const EdgeInsets.all(12), // Increased padding
                      decoration: BoxDecoration(
                        color: riskColor.withOpacity(0.8), // More solid color
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: riskColor.withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.favorite_rounded,
                            size: 16,
                            color: Colors.white, // White icon for contrast
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Stay strong on your journey',
                              style: TextStyle(
                                fontSize: 13, // Slightly larger
                                fontWeight: FontWeight.w600,
                                color: Colors.white, // White text for contrast
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVitalsSummaryRow() {
    final data = _latestHealthData!;

    return Row(
      children: [
        // Heart Rate Card
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.favorite_rounded,
                      color: ChemoColors.pastelPetal,
                      size: 20,
                    ),
                    const Spacer(),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Heart Rate',
                  style: TextStyle(
                    fontSize: 12,
                    color: ChemoColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '${data.heartRate}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: ChemoColors.textPrimary,
                          ),
                        ),
                        const Text(
                          ' bpm',
                          style: TextStyle(
                            fontSize: 12,
                            color: ChemoColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 12),

        // SpO2 Card
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.air_rounded,
                      color: ChemoColors.frozenWater,
                      size: 20,
                    ),
                    const Spacer(),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Oxygen',
                  style: TextStyle(
                    fontSize: 12,
                    color: ChemoColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '${data.spo2Level}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: ChemoColors.textPrimary,
                          ),
                        ),
                        const Text(
                          ' %',
                          style: TextStyle(
                            fontSize: 12,
                            color: ChemoColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDoctorCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, // Changed to white background
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Doctor Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [ChemoColors.wisteriaBlue, ChemoColors.powderBlue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.medical_services_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),

          const SizedBox(width: 12),

          // Doctor Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Your Doctor',
                  style: TextStyle(
                    fontSize: 12,
                    color: ChemoColors.textSecondary,
                  ),
                ),
                Text(
                  'Dr. ${_userProfile?.assignedDoctorId?.substring(0, 8) ?? 'Assigned'}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: ChemoColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),

          // Message Button - Redesigned like image
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: ChemoColors.wisteriaBlue, // Solid color background
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: ChemoColors.wisteriaBlue.withOpacity(0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(
                Icons.message_rounded,
                color: Colors.white, // White icon
                size: 20,
              ),
              onPressed: _navigateToChatWithDoctor,
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          children: [
            Expanded(
              child: _buildActionButton(
                icon: Icons.add_circle_rounded,
                label: 'Enter Vitals',
                color: ChemoColors.wisteriaBlue,
                onTap: _navigateToVitalsEntry,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                icon: Icons.history_rounded,
                label: 'History',
                color: ChemoColors.powderBlue,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HealthHistoryScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                icon: Icons.smart_toy_rounded,
                label: 'AI Help',
                color: ChemoColors.frozenWater,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ChatbotScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: color,
                  size: 28,
                ),
                const SizedBox(height: 6),
                Flexible(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: ChemoColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return DateFormat('MMM dd').format(timestamp);
  }
}
