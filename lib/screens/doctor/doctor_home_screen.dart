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
import 'package:chemo_monitor_app/widgets/common/glass_card.dart';
import 'package:chemo_monitor_app/screens/shared/settings_screen.dart';
import 'package:intl/intl.dart';

class DoctorHomeScreen extends StatefulWidget {
  const DoctorHomeScreen({super.key});

  @override
  State<DoctorHomeScreen> createState() => _DoctorHomeScreenState();
}

class _DoctorHomeScreenState extends State<DoctorHomeScreen>
    with SingleTickerProviderStateMixin {
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

  // Animation
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  // State
  bool _isLoading = true;
  List<Map<String, dynamic>> _recentPatients = [];
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _slideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _loadData();

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      print('📊 Loading doctor profile for: ${user.uid}');
      
      // Load doctor profile directly from Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        print('✅ Doctor data loaded: ${userData['name']}');
        
        setState(() {
          _doctorName = userData['name'] ?? user.email?.split('@').first ?? 'Doctor';
          _doctorSpecialization = userData['specialization'];
          _doctorCode = userData['doctorCode'];
          _profileImageUrl = userData['profileImageUrl'];
        });

        // Also load as UserModel for other uses
        _doctorProfile = UserModel.fromMap(userData);
      } else {
        print('⚠️ Doctor document not found!');
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

      print('✅ Statistics loaded - Patients: $total, High Risk: $highRisk');
    } catch (e) {
      print('❌ Error loading dashboard data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
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
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfileEditScreen()),
    ).then((_) {
      _loadData(); // Reload profile when returning
    });
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

  void _navigateToSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
  }

  List<Map<String, dynamic>> get _filteredPatients {
    if (_selectedFilter == 'All') return _recentPatients;
    if (_selectedFilter == 'High Risk') {
      return _recentPatients.where((p) => p['health'].riskLevel == 2).toList();
    }
    if (_selectedFilter == 'Moderate') {
      return _recentPatients.where((p) => p['health'].riskLevel == 1).toList();
    }
    if (_selectedFilter == 'Stable') {
      return _recentPatients.where((p) => (p['health'].riskLevel ?? 0) == 0).toList();
    }
    return _recentPatients;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppColors.mainBackground,
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnimation.value,
            child: Transform.translate(
              offset: Offset(0, _slideAnimation.value),
              child: child,
            ),
          );
        },
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: AppColors.primaryBlue,
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 180,
                floating: false,
                pinned: true,
                backgroundColor: Colors.white,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primaryBlue, AppColors.softPurple],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                ),
                title: Text(
                  'Dashboard',
                  style: AppTextStyles.heading3.copyWith(color: Colors.white),
                ),
                actions: [
                  Stack(
                    children: [
                      IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: const Icon(
                            Icons.notifications_outlined,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        onPressed: () {
                          Navigator.pushNamed(context, '/notifications');
                        },
                      ),
                      if (user != null)
                        StreamBuilder<int>(
                          stream: _notificationService.getUnreadCount(user.uid),
                          builder: (context, snapshot) {
                            final count = snapshot.data ?? 0;
                            if (count > 0) {
                              return Positioned(
                                right: 8,
                                top: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: AppColors.riskHigh,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 20,
                                    minHeight: 20,
                                  ),
                                  child: Text(
                                    count > 9 ? '9+' : '$count',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              );
                            }
                            return const SizedBox();
                          },
                        ),
                    ],
                  ),
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: const Icon(
                        Icons.settings_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    onPressed: _navigateToSettings,
                  ),
                ],
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(100),
                  child: _buildWelcomeCard(),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatisticsSection(),
                      const SizedBox(height: 24),
                      if (_highRiskCount > 0) ...[
                        _buildAlertBanner(),
                        const SizedBox(height: 24),
                      ],
                      _buildPatientListHeader(),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

              if (_isLoading)
                SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
                    ),
                  ),
                )
              else if (_filteredPatients.isEmpty)
                SliverFillRemaining(child: _buildEmptyState())
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final patient = _filteredPatients[index];
                      return _buildPatientCard(patient);
                    },
                    childCount: _filteredPatients.length,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        margin: EdgeInsets.zero,
        borderRadius: 24,
        blurSigma: 15.0,
        child: Row(
          children: [
            // Avatar with profile image support
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                gradient: _profileImageUrl == null 
                  ? const LinearGradient(
                      colors: [AppColors.primaryBlue, AppColors.softPurple],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
                color: _profileImageUrl != null ? Colors.transparent : null,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryBlue.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: _profileImageUrl != null
                  ? ClipOval(
                      child: Image.network(
                        _profileImageUrl!,
                        fit: BoxFit.cover,
                        width: 70,
                        height: 70,
                        errorBuilder: (context, error, stackTrace) {
                          print('❌ Error loading profile image: $error');
                          return _buildInitialsAvatar();
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          );
                        },
                      ),
                    )
                  : _buildInitialsAvatar(),
            ),

            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back,',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Dr. ${_doctorName ?? "Doctor"}',
                    style: AppTextStyles.heading3.copyWith(
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (_doctorSpecialization != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.palePurple,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _doctorSpecialization!,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.softPurple,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.paleGreen,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Code: ${_doctorCode ?? "N/A"}',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.softGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialsAvatar() {
    String initials = 'DR';
    if (_doctorName != null && _doctorName!.isNotEmpty) {
      final nameParts = _doctorName!.trim().split(' ');
      if (nameParts.length >= 2) {
        initials = '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
      } else {
        initials = _doctorName![0].toUpperCase();
      }
    }

    return Center(
      child: Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStatisticsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overview',
          style: AppTextStyles.heading3.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 1.2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildStatCard(
              icon: Icons.people_rounded,
              label: 'Total Patients',
              value: '$_totalPatients',
              color: AppColors.primaryBlue,
              bgColor: AppColors.lightBlue,
            ),
            _buildStatCard(
              icon: Icons.warning_amber_rounded,
              label: 'High Risk',
              value: '$_highRiskCount',
              color: AppColors.riskHigh,
              bgColor: AppColors.riskHighBg,
            ),
            _buildStatCard(
              icon: Icons.trending_up_rounded,
              label: 'Recent Updates',
              value: '$_recentEntries',
              color: AppColors.softGreen,
              bgColor: AppColors.paleGreen,
            ),
            _buildStatCard(
              icon: Icons.info_rounded,
              label: 'Moderate Risk',
              value: '$_moderateRiskCount',
              color: AppColors.riskModerate,
              bgColor: AppColors.riskModerateBg,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required Color bgColor,
  }) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 20,
      blurSigma: 8.0,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              value,
              key: ValueKey(value),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildAlertBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.riskHighBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.riskHigh.withOpacity(0.3), width: 2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.notifications_active_rounded,
              color: AppColors.riskHigh,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Attention Required',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.riskHigh,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$_highRiskCount patient${_highRiskCount > 1 ? 's' : ''} need${_highRiskCount == 1 ? 's' : ''} immediate attention',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios_rounded, color: AppColors.riskHigh, size: 20),
        ],
      ),
    );
  }

  Widget _buildPatientListHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'My Patients',
          style: AppTextStyles.heading3.copyWith(color: AppColors.textPrimary),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
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
              Icon(Icons.people_rounded, size: 20, color: AppColors.primaryBlue),
              const SizedBox(width: 4),
              Text(
                '$_totalPatients',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
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
    Color statusBgColor;
    String statusText;
    IconData statusIcon;

    if (health.riskLevel == 2) {
      statusColor = AppColors.riskHigh;
      statusBgColor = AppColors.riskHighBg;
      statusText = 'High Risk';
      statusIcon = Icons.error_rounded;
    } else if (health.riskLevel == 1) {
      statusColor = AppColors.riskModerate;
      statusBgColor = AppColors.riskModerateBg;
      statusText = 'Monitor';
      statusIcon = Icons.warning_amber_rounded;
    } else {
      statusColor = AppColors.riskLow;
      statusBgColor = AppColors.riskLowBg;
      statusText = 'Stable';
      statusIcon = Icons.check_circle_rounded;
    }

    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        borderRadius: 20,
        onTap: () => _navigateToPatientDetail(patientId, patient['name'] ?? 'Patient'),
        child: Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: statusBgColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: statusColor, width: 2),
                  ),
                  child: patient['profileImageUrl'] != null
                      ? ClipOval(
                          child: Image.network(
                            patient['profileImageUrl'],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Text(
                                  (patient['name'] ?? 'P')[0].toUpperCase(),
                                  style: TextStyle(
                                    color: statusColor,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            },
                          ),
                        )
                      : Center(
                          child: Text(
                            (patient['name'] ?? 'P')[0].toUpperCase(),
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    patient['name'] ?? 'Unknown',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (patient['age'] != null) ...[
                        Icon(Icons.cake_rounded, size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          '${patient['age']} yrs',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      if (patient['bloodGroup'] != null) ...[
                        Icon(Icons.bloodtype_rounded, size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          patient['bloodGroup'],
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusBgColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(statusIcon, size: 16, color: statusColor),
                            const SizedBox(width: 4),
                            Text(
                              statusText,
                              style: AppTextStyles.caption.copyWith(
                                color: statusColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        DateFormat('MMM dd').format(health.timestamp),
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.paleGreen,
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: Icon(Icons.message_rounded, color: AppColors.softGreen, size: 20),
                onPressed: () => _navigateToChat(patientId, patient['name'] ?? 'Patient'),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ),
          ],
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
              color: AppColors.lightBlue,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              Icons.person_add_rounded,
              size: 64,
              color: AppColors.primaryBlue,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'No patients yet',
            style: AppTextStyles.heading2.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),
          Text(
            'Share your doctor code with patients to get started',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primaryBlue, AppColors.softPurple],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryBlue.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Text(
              'Your Code: ${_doctorCode ?? "N/A"}',
              style: AppTextStyles.bodyLarge.copyWith(
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