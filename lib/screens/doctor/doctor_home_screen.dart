import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chemo_monitor_app/config/app_constants.dart';
import 'package:chemo_monitor_app/services/auth_service.dart';
import 'package:chemo_monitor_app/services/health_data_service.dart';
import 'package:chemo_monitor_app/models/health_data_model.dart';
import 'package:chemo_monitor_app/models/user_model.dart';
import 'package:chemo_monitor_app/screens/doctor/patient_detail_screen.dart';
import 'package:chemo_monitor_app/screens/shared/chat_screen.dart';
import 'package:chemo_monitor_app/screens/shared/profile_edit_screen.dart'; // ✅ ADDED
import 'package:intl/intl.dart';

// Soft Color Palette
class SoftColors {
  static const Color primaryBlue = Color(0xFF7BA3D6);
  static const Color lightBlue = Color(0xFFE8F1FC);
  static const Color softGreen = Color(0xFF6FD195);
  static const Color paleGreen = Color(0xFFE8F8F0);
  static const Color softPurple = Color(0xFF9B8ED4);
  static const Color palePurple = Color(0xFFF2F0FC);
  
  static const Color riskLow = Color(0xFF6FD195);
  static const Color riskLowBg = Color(0xFFE8F8F0);
  static const Color riskModerate = Color(0xFFFAB87F);
  static const Color riskModerateBg = Color(0xFFFFF4EC);
  static const Color riskHigh = Color(0xFFF08B9C);
  static const Color riskHighBg = Color(0xFFFFEEF1);
  
  static const Color textPrimary = Color(0xFF2D3E50);
  static const Color textSecondary = Color(0xFF8E9AAF);
}

class DoctorHomeScreen extends StatefulWidget {
  const DoctorHomeScreen({super.key});

  @override
  State<DoctorHomeScreen> createState() => _DoctorHomeScreenState();
}

class _DoctorHomeScreenState extends State<DoctorHomeScreen> {
  final AuthService _authService = AuthService();
  final HealthDataService _healthDataService = HealthDataService();
  UserModel? _doctorProfile;
  
  int _totalPatients = 0;
  int _highRiskCount = 0;
  int _moderateRiskCount = 0;
  int _recentEntries = 0;

  @override
  void initState() {
    super.initState();
    _loadDoctorProfile();
    _loadStatistics();
  }

  Future<void> _loadDoctorProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final profile = await _authService.getUserProfile(user.uid);
      setState(() {
        _doctorProfile = profile;
      });
    }
  }

  Future<void> _loadStatistics() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final patientsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'patient')
          .where('assignedDoctorId', isEqualTo: user.uid)
          .get();

      int highRisk = 0;
      int moderateRisk = 0;
      int recentCount = 0;
      DateTime today = DateTime.now();

      for (var doc in patientsSnapshot.docs) {
        String patientId = doc.id;
        final latestData = await _healthDataService.getLatestHealthData(patientId);
        
        if (latestData != null) {
          if (latestData.riskLevel == 2) highRisk++;
          if (latestData.riskLevel == 1) moderateRisk++;
          if (latestData.timestamp.isAfter(today.subtract(Duration(hours: 24)))) {
            recentCount++;
          }
        }
      }

      setState(() {
        _totalPatients = patientsSnapshot.docs.length;
        _highRiskCount = highRisk;
        _moderateRiskCount = moderateRisk;
        _recentEntries = recentCount;
      });
    } catch (e) {
      print('Error loading statistics: $e');
    }
  }

  Future<void> _logout() async {
    await _authService.signOut();
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  void _navigateToProfileEdit() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ProfileEditScreen()),
    ).then((_) {
      // Reload profile when returning
      _loadDoctorProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(body: Center(child: Text('Not logged in')));
    }

    return Scaffold(
      backgroundColor: SoftColors.lightBlue,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          'Doctor Dashboard',
          style: TextStyle(
            color: SoftColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
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
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadDoctorProfile();
          await _loadStatistics();
          setState(() {});
        },
        color: SoftColors.primaryBlue,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Header
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
                    // Avatar with donut shape
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [SoftColors.primaryBlue, SoftColors.softPurple],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: SoftColors.primaryBlue.withOpacity(0.3),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: _doctorProfile?.profileImageUrl != null
                          ? ClipOval(
                              child: Image.network(
                                _doctorProfile!.profileImageUrl!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Center(
                              child: Text(
                                _doctorProfile?.getInitials() ?? 'DR',
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
                            'Welcome back,',
                            style: TextStyle(
                              color: SoftColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Dr. ${_doctorProfile?.name ?? "Doctor"}',
                            style: TextStyle(
                              color: SoftColors.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_doctorProfile?.specialization != null)
                            Padding(
                              padding: EdgeInsets.only(top: 4),
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: SoftColors.palePurple,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _doctorProfile!.specialization!,
                                  style: TextStyle(
                                    color: SoftColors.softPurple,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: SoftColors.paleGreen,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Code: ${_doctorProfile?.doctorCode ?? "N/A"}',
                        style: TextStyle(
                          color: SoftColors.softGreen,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 20),

              // Statistics Section
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Overview',
                  style: TextStyle(
                    color: SoftColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              SizedBox(height: 12),

              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.people_rounded,
                        label: 'Total Patients',
                        value: '$_totalPatients',
                        color: SoftColors.primaryBlue,
                        bgColor: SoftColors.lightBlue,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.trending_up_rounded,
                        label: 'Recent Updates',
                        value: '$_recentEntries',
                        color: SoftColors.softGreen,
                        bgColor: SoftColors.paleGreen,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 12),

              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.warning_amber_rounded,
                        label: 'High Risk',
                        value: '$_highRiskCount',
                        color: SoftColors.riskHigh,
                        bgColor: SoftColors.riskHighBg,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.info_rounded,
                        label: 'Moderate Risk',
                        value: '$_moderateRiskCount',
                        color: SoftColors.riskModerate,
                        bgColor: SoftColors.riskModerateBg,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 20),

              // Alert Banner
              if (_highRiskCount > 0)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: SoftColors.riskHighBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: SoftColors.riskHigh.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.notifications_active_rounded, 
                            color: SoftColors.riskHigh, size: 24),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Attention Required',
                                style: TextStyle(
                                  color: SoftColors.riskHigh,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                '$_highRiskCount patient${_highRiskCount > 1 ? 's' : ''} need${_highRiskCount == 1 ? 's' : ''} immediate attention',
                                style: TextStyle(
                                  color: SoftColors.textPrimary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              if (_highRiskCount > 0) SizedBox(height: 20),

              // Patients List
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'My Patients',
                      style: TextStyle(
                        color: SoftColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.people, size: 16, color: SoftColors.primaryBlue),
                          SizedBox(width: 6),
                          Text(
                            '$_totalPatients',
                            style: TextStyle(
                              color: SoftColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 12),

              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .where('role', isEqualTo: 'patient')
                    .where('assignedDoctorId', isEqualTo: user.uid)
                    .snapshots(),
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

                  if (snapshot.hasError) {
                    return Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(child: Text('Error loading patients')),
                    );
                  }

                  final patients = snapshot.data?.docs ?? [];

                  if (patients.isEmpty) {
                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        padding: EdgeInsets.all(40),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: SoftColors.lightBlue,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Icon(
                                Icons.person_add_rounded,
                                size: 50,
                                color: SoftColors.primaryBlue,
                              ),
                            ),
                            SizedBox(height: 20),
                            Text(
                              'No patients yet',
                              style: TextStyle(
                                color: SoftColors.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Share your doctor code with patients to get started',
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

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    itemCount: patients.length,
                    itemBuilder: (context, index) {
                      final patientData = patients[index].data() as Map<String, dynamic>;
                      final patientId = patients[index].id;
                      
                      return _PatientCard(
                        patientId: patientId,
                        patientData: patientData,
                        healthDataService: _healthDataService,
                      );
                    },
                  );
                },
              ),

              SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// Statistics Card Widget
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final Color bgColor;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              color: SoftColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: SoftColors.textSecondary,
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}

// Patient Card Widget
class _PatientCard extends StatelessWidget {
  final String patientId;
  final Map<String, dynamic> patientData;
  final HealthDataService healthDataService;

  const _PatientCard({
    required this.patientId,
    required this.patientData,
    required this.healthDataService,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<HealthDataModel?>(
      future: healthDataService.getLatestHealthData(patientId),
      builder: (context, healthSnapshot) {
        final latestHealth = healthSnapshot.data;
        
        Color statusColor = SoftColors.textSecondary;
        Color statusBgColor = SoftColors.lightBlue;
        String statusText = 'No Data';
        IconData statusIcon = Icons.help_outline_rounded;
        
        if (latestHealth != null) {
          if (latestHealth.riskLevel == 0) {
            statusColor = SoftColors.riskLow;
            statusBgColor = SoftColors.riskLowBg;
            statusText = 'Stable';
            statusIcon = Icons.check_circle_rounded;
          } else if (latestHealth.riskLevel == 1) {
            statusColor = SoftColors.riskModerate;
            statusBgColor = SoftColors.riskModerateBg;
            statusText = 'Monitor';
            statusIcon = Icons.warning_amber_rounded;
          } else if (latestHealth.riskLevel == 2) {
            statusColor = SoftColors.riskHigh;
            statusBgColor = SoftColors.riskHighBg;
            statusText = 'Alert';
            statusIcon = Icons.error_rounded;
          }
        }
        
        return Container(
          margin: EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: statusColor.withOpacity(0.2), width: 2),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PatientDetailScreen(
                      patientId: patientId,
                      patientEmail: patientData['email'] ?? 'Unknown',
                    ),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Avatar
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: statusBgColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: statusColor, width: 2),
                      ),
                      child: patientData['profileImageUrl'] != null
                          ? ClipOval(
                              child: Image.network(
                                patientData['profileImageUrl'],
                                fit: BoxFit.cover,
                              ),
                            )
                          : Center(
                              child: Text(
                                (patientData['name'] ?? 'P')[0].toUpperCase(),
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                    ),
                    
                    SizedBox(width: 16),
                    
                    // Patient Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            patientData['name'] ?? 'Unknown',
                            style: TextStyle(
                              color: SoftColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 6),
                          Row(
                            children: [
                              if (patientData['age'] != null) ...[
                                Icon(Icons.cake_rounded, 
                                  size: 14, color: SoftColors.textSecondary),
                                SizedBox(width: 4),
                                Text(
                                  '${patientData['age']} yrs',
                                  style: TextStyle(
                                    color: SoftColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                                SizedBox(width: 12),
                              ],
                              if (patientData['bloodGroup'] != null) ...[
                                Icon(Icons.bloodtype_rounded, 
                                  size: 14, color: SoftColors.textSecondary),
                                SizedBox(width: 4),
                                Text(
                                  patientData['bloodGroup'],
                                  style: TextStyle(
                                    color: SoftColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusBgColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Icon(statusIcon, size: 14, color: statusColor),
                                    SizedBox(width: 4),
                                    Text(
                                      statusText,
                                      style: TextStyle(
                                        color: statusColor,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (latestHealth != null) ...[
                                SizedBox(width: 8),
                                Text(
                                  DateFormat('MMM dd').format(latestHealth.timestamp),
                                  style: TextStyle(
                                    color: SoftColors.textSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    // Message Button
                    Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: SoftColors.paleGreen,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.message_rounded,
                        color: SoftColors.softGreen,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}