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
  String? _doctorName;
  String? _doctorId;
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

      // Load doctor info if assigned - FIXED: Added null check
      if (profile!.assignedDoctorId != null && profile.assignedDoctorId!.isNotEmpty) {
        try {
          final doctorProfile = await _authService.getUserProfile(
            profile.assignedDoctorId!,
          );
          if (doctorProfile != null) {
            setState(() {
              _doctorName = doctorProfile.name;
              _doctorId = doctorProfile.uid;
            });
          }
        } catch (e) {
          print('Error loading doctor profile: $e');
        }
      }

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
    if (_latestHealthData == null) return AppColors.frozenWater;
    switch (_latestHealthData!.riskLevel) {
      case 0:
        return AppColors.riskLow;
      case 1:
        return AppColors.riskModerate;
      case 2:
        return AppColors.riskHigh;
      default:
        return AppColors.textSecondary;
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
    if (_doctorId != null && _doctorName != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MessageScreen(
            otherUserId: _doctorId!,
            otherUserName: _doctorName!,
            otherUserRole: 'doctor',
          ),
        ),
      );
    } else {
      _showSnackBar('No assigned doctor found');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.wisteriaBlue,
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
      backgroundColor: AppColors.lightBackground,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: AppColors.wisteriaBlue,
          child: _isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppColors.wisteriaBlue),
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
                    if (_doctorName != null || (_userProfile?.assignedDoctorId != null && _userProfile!.assignedDoctorId!.isNotEmpty))
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
                            color: AppColors.textPrimary,
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
              colors: [AppColors.wisteriaBlue, AppColors.powderBlue],
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
                  color: AppColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              Text(
                DateFormat('EEEE, MMM dd').format(DateTime.now()),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
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
            color: AppColors.honeydew,
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(
              Icons.settings_rounded,
              color: AppColors.wisteriaBlue,
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

          // Main Content Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Side - Image
              Container(
                width: MediaQuery.of(context).size.width * 0.35,
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
                    fit: BoxFit.cover,
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

              // Right Side - Text Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title
                    Text(
                      'Your Care\nJourney',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
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
                        color: AppColors.textSecondary,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Motivational Message
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: riskColor.withOpacity(0.8),
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
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Stay strong on your journey',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
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
                      color: AppColors.pastelPetal,
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
                    color: AppColors.textSecondary,
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
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const Text(
                          ' bpm',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
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
                      color: AppColors.frozenWater,
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
                    color: AppColors.textSecondary,
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
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const Text(
                          ' %',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
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
      child: Row(
        children: [
          // Doctor Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.wisteriaBlue, AppColors.powderBlue],
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
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  _doctorName != null 
                    ? 'Dr. $_doctorName' 
                    : 'Doctor Not Assigned',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                if (_doctorName != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Available for consultations',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Message Button - Only show if doctor is assigned
          if (_doctorName != null)
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.wisteriaBlue,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.wisteriaBlue.withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.message_rounded,
                  color: Colors.white,
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
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            icon: Icons.add_circle_rounded,
            label: 'Enter Vitals',
            color: AppColors.wisteriaBlue,
            onTap: _navigateToVitalsEntry,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            icon: Icons.history_rounded,
            label: 'History',
            color: AppColors.powderBlue,
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
            color: AppColors.frozenWater,
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
                      color: AppColors.textPrimary,
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