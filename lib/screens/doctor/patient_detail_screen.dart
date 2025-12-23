import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chemo_monitor_app/config/app_constants.dart';
import 'package:chemo_monitor_app/models/health_data_model.dart';
import 'package:chemo_monitor_app/models/user_model.dart';
import 'package:chemo_monitor_app/services/auth_service.dart';
import 'package:chemo_monitor_app/services/health_data_service.dart';
import 'package:chemo_monitor_app/screens/shared/message_screen.dart';
import 'package:chemo_monitor_app/widgets/common/glass_card.dart';
import 'package:chemo_monitor_app/widgets/common/glass_button.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:chemo_monitor_app/utils/chart_utils.dart';

class PatientDetailScreen extends StatefulWidget {
  final String patientId;
  final String patientEmail;

  const PatientDetailScreen({
    super.key,
    required this.patientId,
    required this.patientEmail,
  });

  @override
  State<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen> 
    with SingleTickerProviderStateMixin {
  final HealthDataService _healthDataService = HealthDataService();
  final AuthService _authService = AuthService();
  
  // Data
  UserModel? _patientProfile;
  HealthDataModel? _latestHealthData;
  List<HealthDataModel> _healthHistory = [];
  
  // UI State
  bool _isLoading = true;
  int _selectedTab = 0;
  int _selectedChartIndex = 0;
  
  // Animations
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _parallaxAnimation;
  
  // Chart data
  List<FlSpot> _heartRateSpots = [];
  List<FlSpot> _spo2Spots = [];
  List<FlSpot> _temperatureSpots = [];
  List<FlSpot> _bpSpots = [];

  @override
  void initState() {
    super.initState();
    
    // Initialize animations
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
    
    _parallaxAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );
    
    // Load data
    _loadData();
    
    // Start animations
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
    try {
      // Load patient profile
      final profile = await _authService.getUserProfile(widget.patientId);
      
      // Load latest health data
      final latestData = await _healthDataService.getLatestHealthData(widget.patientId);
      
      // Load health history
      final history = await _loadHealthHistory();
      
      // Prepare chart data
      _prepareChartData(history);
      
      if (mounted) {
        setState(() {
          _patientProfile = profile;
          _latestHealthData = latestData;
          _healthHistory = history;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading patient detail: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<List<HealthDataModel>> _loadHealthHistory() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('health_data')
          .where('patientId', isEqualTo: widget.patientId)
          .orderBy('timestamp', descending: true)
          .limit(30)
          .get();

      return snapshot.docs
          .map((doc) => HealthDataModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Error loading health history: $e');
      return [];
    }
  }

  void _prepareChartData(List<HealthDataModel> history) {
    final sortedHistory = List.from(history)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    
    _heartRateSpots = [];
    _spo2Spots = [];
    _temperatureSpots = [];
    _bpSpots = [];
    
    for (int i = 0; i < sortedHistory.length; i++) {
      final data = sortedHistory[i];
      final x = i.toDouble();
      
      _heartRateSpots.add(FlSpot(x, data.heartRate.toDouble()));
      _spo2Spots.add(FlSpot(x, data.spo2Level.toDouble()));
      _temperatureSpots.add(FlSpot(x, data.temperature));
      _bpSpots.add(FlSpot(x, data.systolicBP.toDouble()));
    }
  }

  Color get _riskColor {
    if (_latestHealthData == null) return AppColors.textSecondary;
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

  String get _riskLabel {
    if (_latestHealthData == null) return 'No Data';
    switch (_latestHealthData!.riskLevel) {
      case 0:
        return 'LOW RISK';
      case 1:
        return 'MODERATE RISK';
      case 2:
        return 'HIGH RISK';
      default:
        return 'UNKNOWN';
    }
  }

  String get _riskDescription {
    if (_latestHealthData == null) return 'No recent health data available';
    switch (_latestHealthData!.riskLevel) {
      case 0:
        return 'Patient is stable. Continue regular monitoring.';
      case 1:
        return 'Some vitals are concerning. Monitor closely.';
      case 2:
        return 'Immediate medical attention required.';
      default:
        return 'Health status unknown.';
    }
  }

  void _navigateToChat() {
  if (_patientProfile != null) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MessageScreen( // Changed from ChatScreen
          otherUserId: widget.patientId,
          otherUserName: _patientProfile!.name,
          otherUserRole: 'patient',
        ),
      ),
    );
  }
}

  List<FlSpot> get _selectedChartSpots {
    switch (_selectedChartIndex) {
      case 0:
        return _heartRateSpots;
      case 1:
        return _spo2Spots;
      case 2:
        return _temperatureSpots;
      case 3:
        return _bpSpots;
      default:
        return _heartRateSpots;
    }
  }

  String get _selectedChartType {
    switch (_selectedChartIndex) {
      case 0:
        return 'Heart Rate';
      case 1:
        return 'SpO2';
      case 2:
        return 'Temperature';
      case 3:
        return 'Blood Pressure';
      default:
        return 'Heart Rate';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mainBackground,
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnimation.value,
            child: Transform.translate(
              offset: Offset(0, _parallaxAnimation.value * 50),
              child: child,
            ),
          );
        },
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
                ),
              )
            : CustomScrollView(
                slivers: [
                  // Parallax Header
                  SliverAppBar(
                    expandedHeight: 180,
                    floating: false,
                    pinned: true,
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    flexibleSpace: LayoutBuilder(
                      builder: (context, constraints) {
                        final top = constraints.biggest.height;
                        return FlexibleSpaceBar(
                          background: Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [AppColors.primaryBlue, AppColors.softPurple],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                          ),
                          title: top <= 100
                              ? Text(
                                  _patientProfile?.name ?? 'Patient',
                                  style: AppTextStyles.bodyLarge.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                )
                              : null,
                          centerTitle: true,
                        );
                      },
                    ),
                    leading: IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    actions: [
                      IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: const Icon(
                            Icons.message_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        onPressed: _navigateToChat,
                      ),
                    ],
                  ),

                  // Content
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Patient Header Card
                          _buildPatientHeaderCard(),
                          
                          const SizedBox(height: 24),
                          
                          // Risk Status Card
                          _buildRiskStatusCard(),
                          
                          const SizedBox(height: 24),
                          
                          // Latest Vitals Grid
                          _buildVitalsGrid(),
                          
                          const SizedBox(height: 24),
                          
                          // Tabs
                          _buildTabs(),
                          
                          const SizedBox(height: 24),
                          
                          // Tab Content
                          if (_selectedTab == 0) ...[
                            _buildHealthTrends(),
                          ] else if (_selectedTab == 1) ...[
                            _buildHealthHistory(),
                          ],
                          
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildPatientHeaderCard() {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 24,
      blurSigma: 15.0,
      child: Row(
        children: [
          // Avatar
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primaryBlue, AppColors.softPurple],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
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
            child: _patientProfile?.profileImageUrl != null
                ? ClipOval(
                    child: Image.network(
                      _patientProfile!.profileImageUrl!,
                      fit: BoxFit.cover,
                    ),
                  )
                : Center(
                    child: Text(
                      _patientProfile?.getInitials() ?? 'P',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
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
                  _patientProfile?.name ?? 'Patient',
                  style: AppTextStyles.heading3.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 4),
                
                Text(
                  widget.patientEmail,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 8),
                
                Row(
                  children: [
                    if (_patientProfile?.age != null) ...[
                      _buildInfoChip(
                        icon: Icons.cake_rounded,
                        text: '${_patientProfile!.age} yrs',
                      ),
                      const SizedBox(width: 8),
                    ],
                    
                    if (_patientProfile?.gender != null) ...[
                      _buildInfoChip(
                        icon: Icons.wc_rounded,
                        text: _patientProfile!.gender!,
                      ),
                      const SizedBox(width: 8),
                    ],
                    
                    if (_patientProfile?.bloodGroup != null)
                      _buildInfoChip(
                        icon: Icons.bloodtype_rounded,
                        text: _patientProfile!.bloodGroup!,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({required IconData icon, required String text}) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 4,
      ),
      blurSigma: 5,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: AppColors.primaryBlue,
          ),
          
          const SizedBox(width: 4),
          
          Text(
            text,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskStatusCard() {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: AppDimensions.radiusLarge,
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _riskColor.withOpacity(0.2),
                      _riskColor.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                ),
                child: Icon(
                  _getRiskIcon(),
                  color: _riskColor,
                  size: 32,
                ),
              ),
              
              const SizedBox(width: 16),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _riskLabel,
                      style: AppTextStyles.heading3.copyWith(
                        color: _riskColor,
                      ),
                    ),
                    
                    const SizedBox(height: 2),
                    
                    Text(
                      _riskDescription,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          if (_latestHealthData != null)
            Text(
              'Last reading: ${DateFormat('MMM dd, hh:mm a').format(_latestHealthData!.timestamp)}',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          
          if (_latestHealthData?.mlOutputProbabilities != null) ...[
            const SizedBox(height: 16),
            _buildMLConfidenceBars(),
          ],
        ],
      ),
    );
  }

  IconData _getRiskIcon() {
    if (_latestHealthData == null) return Icons.help_outline_rounded;
    switch (_latestHealthData!.riskLevel) {
      case 0:
        return Icons.check_circle_rounded;
      case 1:
        return Icons.warning_amber_rounded;
      case 2:
        return Icons.error_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  Widget _buildMLConfidenceBars() {
    final probabilities = _latestHealthData!.mlOutputProbabilities!;
    
    return Column(
      children: [
        Text(
          'AI Prediction Confidence',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        
        const SizedBox(height: 12),
        
        Row(
          children: [
            Expanded(
              child: _buildConfidenceBar(
                label: 'Low',
                probability: probabilities[0],
                color: AppColors.riskLow,
                isActive: _latestHealthData!.riskLevel == 0,
              ),
            ),
            
            const SizedBox(width: 12),
            
            Expanded(
              child: _buildConfidenceBar(
                label: 'Moderate',
                probability: probabilities[1],
                color: AppColors.riskModerate,
                isActive: _latestHealthData!.riskLevel == 1,
              ),
            ),
            
            const SizedBox(width: 12),
            
            Expanded(
              child: _buildConfidenceBar(
                label: 'High',
                probability: probabilities[2],
                color: AppColors.riskHigh,
                isActive: _latestHealthData!.riskLevel == 2,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildConfidenceBar({
    required String label,
    required double probability,
    required Color color,
    required bool isActive,
  }) {
    return Column(
      children: [
        Text(
          '${(probability * 100).toStringAsFixed(0)}%',
          style: AppTextStyles.bodyMedium.copyWith(
            color: isActive ? color : AppColors.textSecondary,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
          ),
        ),
        
        const SizedBox(height: 4),
        
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: AppColors.lightBlue,
            borderRadius: BorderRadius.circular(100),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: probability,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withOpacity(0.8)],
                ),
                borderRadius: BorderRadius.circular(100),
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 4),
        
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: isActive ? color : AppColors.textSecondary,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildVitalsGrid() {
    if (_latestHealthData == null) {
      return GlassCard(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Text(
            'No health data available',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }
    
    final data = _latestHealthData!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Latest Vitals',
          style: AppTextStyles.heading3.copyWith(
            color: AppColors.textPrimary,
          ),
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
            _buildVitalCard(
              icon: Icons.favorite_rounded,
              label: 'Heart Rate',
              value: '${data.heartRate}',
              unit: 'bpm',
              isNormal: data.heartRate >= 60 && data.heartRate <= 100,
            ),
            _buildVitalCard(
              icon: Icons.air_rounded,
              label: 'SpO2 Level',
              value: '${data.spo2Level}',
              unit: '%',
              isNormal: data.spo2Level >= 95,
            ),
            _buildVitalCard(
              icon: Icons.thermostat_rounded,
              label: 'Temperature',
              value: '${data.temperature.toStringAsFixed(1)}',
              unit: '°C',
              isNormal: data.temperature >= 36.0 && data.temperature <= 37.5,
            ),
            _buildVitalCard(
              icon: Icons.monitor_heart_rounded,
              label: 'Blood Pressure',
              value: '${data.systolicBP}/${data.diastolicBP}',
              unit: 'mmHg',
              isNormal: data.systolicBP >= 90 && data.systolicBP <= 140,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVitalCard({
    required IconData icon,
    required String label,
    required String value,
    required String unit,
    required bool isNormal,
  }) {
    final color = isNormal ? AppColors.riskLow : AppColors.riskHigh;
    
    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: AppDimensions.radiusLarge,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withOpacity(0.2),
                  color.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          
          const SizedBox(height: 12),
          
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: AppTextStyles.heading3.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                TextSpan(
                  text: ' $unit',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 4),
          
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          
          const SizedBox(height: 4),
          
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
            ),
            child: Text(
              isNormal ? 'Normal' : 'Abnormal',
              style: AppTextStyles.caption.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return GlassCard(
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: GlassButton(
              onPressed: () => setState(() => _selectedTab = 0),
              text: 'Trends & Charts',
              type: ButtonType.primary,
              isSelected: _selectedTab == 0,
              height: 36,
            ),
          ),
          
          const SizedBox(width: 8),
          
          Expanded(
            child: GlassButton(
              onPressed: () => setState(() => _selectedTab = 1),
              text: 'History Timeline',
              type: ButtonType.primary,
              isSelected: _selectedTab == 1,
              height: 36,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthTrends() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Health Trends',
          style: AppTextStyles.heading3.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Chart Toggle Buttons
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ['Heart Rate', 'SpO2', 'Temperature', 'Blood Pressure']
                .asMap()
                .entries
                .map((entry) {
              final index = entry.key;
              final chart = entry.value;
              final isSelected = _selectedChartIndex == index;
              
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GlassButton(
                  onPressed: () => setState(() => _selectedChartIndex = index),
                  text: chart,
                  type: isSelected ? ButtonType.primary : ButtonType.secondary,
                  isSelected: isSelected,
                  height: 36,
                ),
              );
            }).toList(),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Chart Container
        GlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                _selectedChartType,
                style: AppTextStyles.heading3.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              
              const SizedBox(height: 12),
              
              Container(
                height: 200,
                child: LineChart(
                  ChartUtils.createHealthChart(
                    spots: _selectedChartSpots,
                    chartType: _selectedChartType,
                    minY: _getMinY(_selectedChartSpots),
                    maxY: _getMaxY(_selectedChartSpots),
                  ),
                ),
              ),
              
              const SizedBox(height: 12),
              
              Text(
                'Last ${_selectedChartSpots.length} readings',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  double _getMinY(List<FlSpot> spots) {
    if (spots.isEmpty) return 0;
    double min = spots.first.y;
    for (final spot in spots) {
      if (spot.y < min) min = spot.y;
    }
    return min - (min * 0.1);
  }

  double _getMaxY(List<FlSpot> spots) {
    if (spots.isEmpty) return 100;
    double max = spots.first.y;
    for (final spot in spots) {
      if (spot.y > max) max = spot.y;
    }
    return max + (max * 0.1);
  }

  Widget _buildHealthHistory() {
    if (_healthHistory.isEmpty) {
      return GlassCard(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Text(
            'No health history available',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Health History',
          style: AppTextStyles.heading3.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        
        const SizedBox(height: 16),
        
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _healthHistory.length,
          itemBuilder: (context, index) {
            final healthData = _healthHistory[index];
            return _buildHistoryCard(healthData, index);
          },
        ),
      ],
    );
  }

  Widget _buildHistoryCard(HealthDataModel healthData, int index) {
    Color getRiskColor(int? riskLevel) {
      switch (riskLevel) {
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
    
    final riskColor = getRiskColor(healthData.riskLevel);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        border: Border.all(
          color: riskColor.withOpacity(0.2),
          width: 2,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('MMM dd, yyyy • hh:mm a').format(healthData.timestamp),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        riskColor.withOpacity(0.1),
                        riskColor.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                    border: Border.all(color: riskColor),
                  ),
                  child: Text(
                    healthData.getRiskLevelString().toUpperCase(),
                    style: AppTextStyles.caption.copyWith(
                      color: riskColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Vitals Summary
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildHistoryVital(
                  icon: Icons.favorite_rounded,
                  value: '${healthData.heartRate}',
                  unit: 'bpm',
                ),
                _buildHistoryVital(
                  icon: Icons.air_rounded,
                  value: '${healthData.spo2Level}',
                  unit: '%',
                ),
                _buildHistoryVital(
                  icon: Icons.thermostat_rounded,
                  value: '${healthData.temperature.toStringAsFixed(1)}',
                  unit: '°C',
                ),
                _buildHistoryVital(
                  icon: Icons.monitor_heart_rounded,
                  value: '${healthData.systolicBP}/${healthData.diastolicBP}',
                  unit: 'mmHg',
                ),
              ],
            ),
            
            // Notes (if any)
            if (healthData.additionalNotes != null && healthData.additionalNotes!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    Text(
                      'Notes:',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      healthData.additionalNotes!,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryVital({
    required IconData icon,
    required String value,
    required String unit,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: AppColors.textSecondary,
        ),
        
        const SizedBox(height: 4),
        
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: value,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextSpan(
                text: ' $unit',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}