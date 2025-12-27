import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chemo_monitor_app/config/app_constants.dart';
import 'package:chemo_monitor_app/services/auth_service.dart';
import 'package:chemo_monitor_app/services/health_data_service.dart';
import 'package:chemo_monitor_app/services/notification_service.dart';
import 'package:chemo_monitor_app/models/health_data_model.dart';
import 'package:chemo_monitor_app/models/user_model.dart';
import 'package:chemo_monitor_app/screens/doctor/patient_detail_screen.dart';
import 'package:chemo_monitor_app/screens/shared/message_screen.dart';
import 'package:chemo_monitor_app/screens/shared/profile_edit_screen.dart';
import 'package:chemo_monitor_app/screens/shared/settings_screen.dart';
import 'package:intl/intl.dart';

class DoctorHomeScreen extends StatefulWidget {
  const DoctorHomeScreen({super.key});

  @override
  State<DoctorHomeScreen> createState() => _DoctorHomeScreenState();
}

class _DoctorHomeScreenState extends State<DoctorHomeScreen> {
  final AuthService _authService = AuthService();
  final HealthDataService _healthDataService = HealthDataService();
  final NotificationService _notificationService = NotificationService();
  
  UserModel? _doctorProfile;
  String? _doctorName;
  String? _doctorSpecialization;
  String? _doctorCode;
  String? _profileImageUrl;

  // Statistics
  int _totalPatients = 0;
  int _highRiskCount = 0;
  int _moderateRiskCount = 0;
  int _recentEntries = 0;

  // State
  bool _isLoading = true;
  List<Map<String, dynamic>> _recentPatients = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Load doctor profile
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        setState(() {
          _doctorName = userData['name'] ?? user.email?.split('@').first ?? 'Doctor';
          _doctorSpecialization = userData['specialization'];
          _doctorCode = userData['doctorCode'];
          _profileImageUrl = userData['profileImageUrl'];
        });
        _doctorProfile = UserModel.fromMap(userData);
      }

      // Load statistics
      final patientsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'patient')
          .where('assignedDoctorId', isEqualTo: user.uid)
          .get();

      int total = patientsSnapshot.docs.length;
      int highRisk = 0;
      int moderateRisk = 0;
      int recentCount = 0;
      DateTime today = DateTime.now();

      List<Map<String, dynamic>> recentPatients = [];

      for (var doc in patientsSnapshot.docs) {
        String patientId = doc.id;
        final patientData = doc.data();
        final latestData = await _healthDataService.getLatestHealthData(patientId);

        if (latestData != null) {
          if (latestData.riskLevel == 2) highRisk++;
          if (latestData.riskLevel == 1) moderateRisk++;
          if (latestData.timestamp.isAfter(today.subtract(const Duration(hours: 24)))) {
            recentCount++;
          }

          recentPatients.add({
            'id': patientId,
            'data': patientData,
            'health': latestData,
          });
        }
      }

      recentPatients.sort((a, b) {
        final riskA = a['health'].riskLevel ?? 0;
        final riskB = b['health'].riskLevel ?? 0;
        final timeA = a['health'].timestamp;
        final timeB = b['health'].timestamp;
        if (riskA != riskB) return riskB.compareTo(riskA);
        return timeB.compareTo(timeA);
      });

      if (mounted) {
        setState(() {
          _totalPatients = total;
          _highRiskCount = highRisk;
          _moderateRiskCount = moderateRisk;
          _recentEntries = recentCount;
          _recentPatients = recentPatients;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading dashboard data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _navigateToPatientDetail(String patientId, String patientName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PatientDetailScreen(
          patientId: patientId,
          patientEmail: '',
        ),
      ),
    );
  }

  void _navigateToChat(String patientId, String patientName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MessageScreen(
          otherUserId: patientId,
          otherUserName: patientName,
          otherUserRole: 'patient',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.wisteriaBlue,
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.wisteriaBlue),
                ),
              )
            : CustomScrollView(
                slivers: [
                  // HERO SECTION
                  SliverToBoxAdapter(
                    child: _buildHeroSection(),
                  ),

                  // SPACING AFTER HERO
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 24),
                  ),

                  // QUICK STATS
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildQuickStats(),
                    ),
                  ),

                  // SPACING AFTER STATS
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 24),
                  ),

                  // PRIORITY PATIENTS
                  if (_highRiskCount > 0)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                        child: _buildPriorityPatientsHeader(),
                      ),
                    ),

                  if (_highRiskCount > 0)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 20, bottom: 24),
                        child: _buildPriorityPatientsList(),
                      ),
                    ),

                  // ALL PATIENTS HEADER
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                      child: _buildAllPatientsHeader(),
                    ),
                  ),

                  // ALL PATIENTS LIST
                  if (_recentPatients.isEmpty)
                    SliverFillRemaining(
                      child: _buildEmptyState(),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final patient = _recentPatients[index];
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                            child: _buildPatientCard(patient),
                          );
                        },
                        childCount: _recentPatients.length,
                      ),
                    ),

                  // BOTTOM PADDING
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 20),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
      decoration: BoxDecoration(
        color: AppColors.wisteriaBlue,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Stack(
        children: [
          // OPTIONAL: Background Decoration Image
          // Uncomment and replace 'assets/images/hero_decoration.png' with your image path
          /*
          Positioned(
            right: -30,
            top: -20,
            child: Opacity(
              opacity: 0.15,
              child: Image.asset(
                'assets/images/hero_decoration.png',
                width: 200,
                height: 200,
                fit: BoxFit.contain,
              ),
            ),
          ),
          */
          
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row - Welcome & Notifications
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back,',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                        Text(
                          'Dr. ${_doctorName?.split(' ').first ?? 'Doctor'}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      _buildNotificationButton(),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(
                          Icons.settings_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const SettingsScreen()),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Doctor Profile Card with Optional Side Decoration
              Row(
                children: [
                  Expanded(
                    child: _buildDoctorProfileCard(),
                  ),
                  
                  // OPTIONAL: Side Decoration Image
                  // Uncomment and replace 'assets/images/doctor_illustration.png' with your image
                  /*
                  const SizedBox(width: 12),
                  Container(
                    width: 80,
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Image.asset(
                      'assets/images/doctor_illustration.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  */
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorProfileCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Doctor Avatar
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: AppColors.wisteriaBlue,
              shape: BoxShape.circle,
            ),
            child: _profileImageUrl != null
                ? ClipOval(
                    child: Image.network(
                      _profileImageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Text(
                            _doctorName != null && _doctorName!.isNotEmpty
                                ? _doctorName!.substring(0, 1).toUpperCase()
                                : 'D',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),
                  )
                : Center(
                    child: Text(
                      _doctorName != null && _doctorName!.isNotEmpty
                          ? _doctorName!.substring(0, 1).toUpperCase()
                          : 'D',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
          ),

          const SizedBox(width: 16),

          // Doctor Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dr. ${_doctorName ?? 'Doctor'}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (_doctorSpecialization != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.honeydew,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _doctorSpecialization!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  'Code: ${_doctorCode ?? "N/A"}',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          
          // OPTIONAL: Small decoration icon in profile card
          // Uncomment to add a small medical icon/illustration
          /*
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Image.asset(
              'assets/images/medical_icon.png',
              width: 40,
              height: 40,
              fit: BoxFit.contain,
            ),
          ),
          */
        ],
      ),
    );
  }

  Widget _buildNotificationButton() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox();

    return StreamBuilder<int>(
      stream: _notificationService.getUnreadCount(user.uid),
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        return Stack(
          children: [
            IconButton(
              icon: const Icon(
                Icons.notifications_outlined,
                color: Colors.white,
                size: 22,
              ),
              onPressed: () {
                Navigator.pushNamed(context, '/notifications');
              },
            ),
            if (count > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.pastelPetal,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.wisteriaBlue, width: 2),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    count > 9 ? '9+' : '$count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildQuickStats() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.elevation1,
      ),
      child: Column(
        children: [
          // Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Overview',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'Total: $_totalPatients',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Stats Grid - Made responsive
          LayoutBuilder(
            builder: (context, constraints) {
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                childAspectRatio: 1.4,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: [
                  _buildStatItem(
                    icon: Icons.people_rounded,
                    label: 'Total Patients',
                    value: '$_totalPatients',
                    color: AppColors.wisteriaBlue,
                  ),
                  _buildStatItem(
                    icon: Icons.warning_amber_rounded,
                    label: 'High Risk',
                    value: '$_highRiskCount',
                    color: AppColors.pastelPetal,
                  ),
                  _buildStatItem(
                    icon: Icons.update_rounded,
                    label: 'Recent Updates',
                    value: '$_recentEntries',
                    color: AppColors.frozenWater,
                  ),
                  _buildStatItem(
                    icon: Icons.info_rounded,
                    label: 'Moderate Risk',
                    value: '$_moderateRiskCount',
                    color: AppColors.powderBlue,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: color,
            size: 26,
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityPatientsHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Priority Attention',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.pastelPetal,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$_highRiskCount patient${_highRiskCount != 1 ? 's' : ''}',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPriorityPatientsList() {
    final highRiskPatients = _recentPatients.where((p) => p['health'].riskLevel == 2).toList();
    if (highRiskPatients.isEmpty) return const SizedBox();

    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: highRiskPatients.length,
        itemBuilder: (context, index) {
          final patient = highRiskPatients[index];
          return Container(
            width: 240,
            margin: EdgeInsets.only(right: index == highRiskPatients.length - 1 ? 20 : 12),
            child: _buildPriorityPatientCard(patient),
          );
        },
      ),
    );
  }

  Widget _buildPriorityPatientCard(Map<String, dynamic> patientData) {
    final patient = patientData['data'] as Map<String, dynamic>;
    final health = patientData['health'] as HealthDataModel;
    final patientId = patientData['id'] as String;

    return GestureDetector(
      onTap: () => _navigateToPatientDetail(patientId, patient['name'] ?? 'Patient'),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppShadows.elevation1,
          border: Border.all(color: AppColors.pastelPetal.withOpacity(0.3), width: 2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Patient Header
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.pastelPetal,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        (patient['name'] ?? 'P')[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          patient['name'] ?? 'Unknown',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'High Risk',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.pastelPetal,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Vitals Row
              Row(
                children: [
                  _buildPriorityVital(
                    icon: Icons.favorite_rounded,
                    value: '${health.heartRate}',
                    unit: 'bpm',
                  ),
                  const SizedBox(width: 8),
                  _buildPriorityVital(
                    icon: Icons.air_rounded,
                    value: '${health.spo2Level}',
                    unit: '%',
                  ),
                ],
              ),
              
              const Spacer(),
              
              // Message Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _navigateToChat(patientId, patient['name'] ?? 'Patient'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.wisteriaBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    elevation: 0,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.message_rounded, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Message',
                        style: TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityVital({
    required IconData icon,
    required String value,
    required String unit,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.lightBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                '$value$unit',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllPatientsHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'All Patients',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          'Sorted by risk',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildPatientCard(Map<String, dynamic> patientData) {
    final patient = patientData['data'] as Map<String, dynamic>;
    final health = patientData['health'] as HealthDataModel;
    final patientId = patientData['id'] as String;

    Color statusColor;
    String statusText;
    
    if (health.riskLevel == 2) {
      statusColor = AppColors.pastelPetal;
      statusText = 'High Risk';
    } else if (health.riskLevel == 1) {
      statusColor = AppColors.powderBlue;
      statusText = 'Monitor';
    } else {
      statusColor = AppColors.frozenWater;
      statusText = 'Stable';
    }

    return GestureDetector(
      onTap: () => _navigateToPatientDetail(patientId, patient['name'] ?? 'Patient'),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppShadows.elevation1,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Patient Avatar
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: statusColor, width: 2),
                ),
                child: Center(
                  child: Text(
                    (patient['name'] ?? 'P')[0].toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Patient Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patient['name'] ?? 'Unknown',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            statusText,
                            style: TextStyle(
                              fontSize: 11,
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.access_time_rounded, size: 12, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('MMM dd').format(health.timestamp),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Message Button
              IconButton(
                icon: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.honeydew,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.message_rounded,
                    color: AppColors.wisteriaBlue,
                    size: 20,
                  ),
                ),
                onPressed: () => _navigateToChat(patientId, patient['name'] ?? 'Patient'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              color: AppColors.honeydew,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.person_add_rounded,
              size: 64,
              color: AppColors.wisteriaBlue,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No patients yet',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Share your doctor code with patients to get started',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.wisteriaBlue,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'Your Code: ${_doctorCode ?? "N/A"}',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}