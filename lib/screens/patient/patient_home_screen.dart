import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chemo_monitor_app/config/app_constants.dart';
import 'package:chemo_monitor_app/services/auth_service.dart';
import 'package:chemo_monitor_app/services/health_data_service.dart';
import 'package:chemo_monitor_app/models/health_data_model.dart';
import 'package:chemo_monitor_app/models/user_model.dart';
import 'package:chemo_monitor_app/screens/patient/vitals_entry_screen.dart';
import 'package:chemo_monitor_app/screens/patient/health_history_screen.dart';
import 'package:chemo_monitor_app/screens/shared/chat_screen.dart'; 
import 'package:chemo_monitor_app/screens/patient/chatbot_screen.dart';
import 'package:intl/intl.dart';

// Soft Color Palette
class SoftColors {
  static const Color primaryBlue = Color(0xFF7BA3D6);      // Soft blue
  static const Color lightBlue = Color(0xFFE8F1FC);        // Very light blue background
  static const Color softGreen = Color(0xFF6FD195);        // Soft green
  static const Color paleGreen = Color(0xFFE8F8F0);        // Pale green background
  static const Color softPurple = Color(0xFF9B8ED4);       // Soft purple
  static const Color palePurple = Color(0xFFF2F0FC);       // Pale purple background
  
  // Soft Risk Colors
  static const Color riskLow = Color(0xFF6FD195);          // Soft green
  static const Color riskLowBg = Color(0xFFE8F8F0);        // Pale green
  static const Color riskModerate = Color(0xFFFAB87F);     // Soft orange/peach
  static const Color riskModerateBg = Color(0xFFFFF4EC);   // Pale orange
  static const Color riskHigh = Color(0xFFF08B9C);         // Soft pink/coral
  static const Color riskHighBg = Color(0xFFFFEEF1);       // Pale pink
  
  static const Color textPrimary = Color(0xFF2D3E50);
  static const Color textSecondary = Color(0xFF8E9AAF);
  static const Color cardBackground = Colors.white;
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

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final profile = await _authService.getUserProfile(user.uid);
      if (mounted) {
        setState(() {
          _userProfile = profile;
        });
      }
    }
  }

  Future<void> _logout() async {
    await _authService.signOut();
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  void _navigateToProfileEdit() {
    // TODO: Navigate to profile edit screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Profile edit coming soon!'),
        backgroundColor: SoftColors.softPurple,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _navigateToVitalsEntry() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => VitalsEntryScreen()),
    );

    if (result == true) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: SoftColors.lightBlue,
      appBar: AppBar(
        elevation: 0,
        title: Text(
          'Health Monitor',
          style: TextStyle(
            color: SoftColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: SoftColors.textPrimary),
        actions: [
          IconButton(
            icon: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: SoftColors.lightBlue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.edit_outlined, size: 20, color: SoftColors.primaryBlue),
            ),
            onPressed: _navigateToProfileEdit,
            tooltip: 'Edit Profile',
          ),
          IconButton(
            icon: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: SoftColors.lightBlue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.logout, size: 20, color: SoftColors.primaryBlue),
            ),
            onPressed: _logout,
          ),
          SizedBox(width: 12),
        ],
      ),
      body: user == null
          ? Center(child: Text('Not logged in'))
          : RefreshIndicator(
              onRefresh: () async {
                await _loadUserProfile();
                setState(() {});
              },
              color: SoftColors.primaryBlue,
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Header Card
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(32),
                          bottomRight: Radius.circular(32),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [SoftColors.primaryBlue, SoftColors.softPurple],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: SoftColors.primaryBlue.withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: _userProfile?.profileImageUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: Image.network(
                                    _userProfile!.profileImageUrl!,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Center(
                                  child: Text(
                                    _userProfile?.name.isNotEmpty == true 
                                      ? _userProfile!.name[0].toUpperCase() 
                                      : 'P',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hello,',
                                  style: TextStyle(
                                    color: SoftColors.textSecondary,
                                    fontSize: 14,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  _userProfile?.name ?? 'Patient',
                                  style: TextStyle(
                                    color: SoftColors.textPrimary,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (_userProfile?.age != null || _userProfile?.bloodGroup != null)
                                  Padding(
                                    padding: EdgeInsets.only(top: 4),
                                    child: Text(
                                      '${_userProfile?.age != null ? "${_userProfile!.age} yrs" : ""}'
                                      '${_userProfile?.age != null && _userProfile?.bloodGroup != null ? " • " : ""}'
                                      '${_userProfile?.bloodGroup != null ? "${_userProfile!.bloodGroup}" : ""}',
                                      style: TextStyle(
                                        color: SoftColors.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 20),

                    // Latest Health Status
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'Your Health Status',
                        style: TextStyle(
                          color: SoftColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    SizedBox(height: 12),

                    FutureBuilder<HealthDataModel?>(
                      future: _healthDataService.getLatestHealthData(user.uid),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Center(
                            child: Padding(
                              padding: EdgeInsets.all(40),
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(SoftColors.primaryBlue),
                              ),
                            ),
                          );
                        }

                        final latestData = snapshot.data;

                        if (latestData == null) {
                          return Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20),
                            child: Container(
                              padding: EdgeInsets.all(32),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Column(
                                children: [
                                  // Illustration placeholder
                                  Container(
                                    width: 200,
                                    height: 150,
                                    decoration: BoxDecoration(
                                      color: SoftColors.palePurple,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Icon(
                                      Icons.add_chart_rounded,
                                      size: 80,
                                      color: SoftColors.softPurple,
                                    ),
                                  ),
                                  SizedBox(height: 24),
                                  Text(
                                    'No health data yet',
                                    style: TextStyle(
                                      color: SoftColors.textPrimary,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Start tracking your health by entering your vitals',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: SoftColors.textSecondary,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        // Determine risk colors
                        Color riskColor = SoftColors.riskLow;
                        Color riskBgColor = SoftColors.riskLowBg;
                        String riskText = 'Low Risk';
                        
                        if (latestData.riskLevel == 1) {
                          riskColor = SoftColors.riskModerate;
                          riskBgColor = SoftColors.riskModerateBg;
                          riskText = 'Moderate Risk';
                        } else if (latestData.riskLevel == 2) {
                          riskColor = SoftColors.riskHigh;
                          riskBgColor = SoftColors.riskHighBg;
                          riskText = 'High Risk';
                        }

                        return Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Column(
                              children: [
                                // Header with date and risk badge
                                Padding(
                                  padding: EdgeInsets.all(20),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Latest Reading',
                                            style: TextStyle(
                                              color: SoftColors.textSecondary,
                                              fontSize: 12,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            DateFormat('MMM dd, hh:mm a').format(latestData.timestamp),
                                            style: TextStyle(
                                              color: SoftColors.textPrimary,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: riskBgColor,
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          riskText.toUpperCase(),
                                          style: TextStyle(
                                            color: riskColor,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Illustration/Visual Element
                                Container(
                                  margin: EdgeInsets.symmetric(horizontal: 20),
                                  padding: EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: SoftColors.lightBlue,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      _VitalIndicator(
                                        icon: Icons.favorite_rounded,
                                        label: 'Heart Rate',
                                        value: '${latestData.heartRate}',
                                        unit: 'bpm',
                                        color: SoftColors.riskHigh,
                                        bgColor: SoftColors.riskHighBg,
                                      ),
                                      _VitalIndicator(
                                        icon: Icons.air_rounded,
                                        label: 'SpO2',
                                        value: '${latestData.spo2Level}',
                                        unit: '%',
                                        color: SoftColors.primaryBlue,
                                        bgColor: SoftColors.lightBlue,
                                      ),
                                      _VitalIndicator(
                                        icon: Icons.thermostat_rounded,
                                        label: 'Temp',
                                        value: '${latestData.temperature}',
                                        unit: '°F',
                                        color: SoftColors.riskModerate,
                                        bgColor: SoftColors.riskModerateBg,
                                      ),
                                    ],
                                  ),
                                ),

                                // AI Confidence Section
                                if (latestData.mlOutputProbabilities != null)
                                  Padding(
                                    padding: EdgeInsets.all(20),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'AI Confidence Levels',
                                          style: TextStyle(
                                            color: SoftColors.textSecondary,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        SizedBox(height: 12),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: _ConfidenceBar(
                                                label: 'Low',
                                                probability: latestData.mlOutputProbabilities![0],
                                                color: SoftColors.riskLow,
                                                isActive: latestData.riskLevel == 0,
                                              ),
                                            ),
                                            SizedBox(width: 8),
                                            Expanded(
                                              child: _ConfidenceBar(
                                                label: 'Moderate',
                                                probability: latestData.mlOutputProbabilities![1],
                                                color: SoftColors.riskModerate,
                                                isActive: latestData.riskLevel == 1,
                                              ),
                                            ),
                                            SizedBox(width: 8),
                                            Expanded(
                                              child: _ConfidenceBar(
                                                label: 'High',
                                                probability: latestData.mlOutputProbabilities![2],
                                                color: SoftColors.riskHigh,
                                                isActive: latestData.riskLevel == 2,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    SizedBox(height: 24),

                    // Quick Actions
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'Quick Actions',
                        style: TextStyle(
                          color: SoftColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    SizedBox(height: 12),

                    // Action Cards Grid
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _ActionCard(
                                  icon: Icons.add_chart_rounded,
                                  label: 'Enter Vitals',
                                  color: SoftColors.softGreen,
                                  bgColor: SoftColors.paleGreen,
                                  onTap: _navigateToVitalsEntry,
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: _ActionCard(
                                  icon: Icons.history_rounded,
                                  label: 'View History',
                                  color: SoftColors.primaryBlue,
                                  bgColor: SoftColors.lightBlue,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => HealthHistoryScreen(),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _ActionCard(
                                  icon: Icons.chat_bubble_rounded,
                                  label: 'AI Assistant',
                                  color: SoftColors.softPurple,
                                  bgColor: SoftColors.palePurple,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => ChatbotScreen()),
                                    );
                                  },
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: _ActionCard(
                                  icon: Icons.message_rounded,
                                  label: 'Message Doctor',
                                  color: SoftColors.softGreen,
                                  bgColor: SoftColors.paleGreen,
                                  onTap: () async {
                                    if (_userProfile?.assignedDoctorId != null) {
                                      final doctorProfile = await _authService.getUserProfile(
                                        _userProfile!.assignedDoctorId!,
                                      );
                                      
                                      if (doctorProfile != null && mounted) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => ChatScreen(
                                              otherUserId: doctorProfile.uid,
                                              otherUserName: doctorProfile.name,
                                              otherUserRole: 'doctor',
                                            ),
                                          ),
                                        );
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Doctor profile not found'),
                                            backgroundColor: SoftColors.riskModerate,
                                          ),
                                        );
                                      }
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('No assigned doctor found'),
                                          backgroundColor: SoftColors.riskModerate,
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }
}

// Vital Indicator Widget
class _VitalIndicator extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final Color color;
  final Color bgColor;

  const _VitalIndicator({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: SoftColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          unit,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: SoftColors.textSecondary,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

// Action Card Widget
class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              SizedBox(height: 12),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: SoftColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Confidence Bar Widget
class _ConfidenceBar extends StatelessWidget {
  final String label;
  final double probability;
  final Color color;
  final bool isActive;

  const _ConfidenceBar({
    required this.label,
    required this.probability,
    required this.color,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '${(probability * 100).toStringAsFixed(0)}%',
          style: TextStyle(
            color: isActive ? color : SoftColors.textSecondary,
            fontSize: 16,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
          ),
        ),
        SizedBox(height: 6),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: SoftColors.lightBlue,
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: probability,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
        SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: isActive ? color : SoftColors.textSecondary,
            fontSize: 11,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}