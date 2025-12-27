import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chemo_monitor_app/config/app_constants.dart';
import 'package:chemo_monitor_app/models/health_data_model.dart';
import 'package:chemo_monitor_app/models/user_model.dart';
import 'package:chemo_monitor_app/services/auth_service.dart';
import 'package:chemo_monitor_app/services/health_data_service.dart';
import 'package:chemo_monitor_app/screens/shared/message_screen.dart';
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

class _PatientDetailScreenState extends State<PatientDetailScreen> {
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
  
  // Chart data
  List<FlSpot> _heartRateSpots = [];
  List<FlSpot> _spo2Spots = [];
  List<FlSpot> _temperatureSpots = [];
  List<FlSpot> _bpSpots = [];

  @override
  void initState() {
    super.initState();
    _loadData();
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
        return AppColors.frozenWater;
      case 1:
        return AppColors.powderBlue;
      case 2:
        return AppColors.pastelPetal;
      default:
        return AppColors.textSecondary;
    }
  }

  String get _riskLabel {
    if (_latestHealthData == null) return 'No Data';
    switch (_latestHealthData!.riskLevel) {
      case 0:
        return 'STABLE';
      case 1:
        return 'MONITOR';
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
        return 'Patient vitals are within normal range';
      case 1:
        return 'Some vitals need attention';
      case 2:
        return 'Immediate medical attention required';
      default:
        return 'Health status unknown';
    }
  }

  void _navigateToChat() {
    if (_patientProfile != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MessageScreen(
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
      backgroundColor: AppColors.lightBackground,
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.wisteriaBlue),
              ),
            )
          : CustomScrollView(
              slivers: [
                // Hero Header
                _buildHeroHeader(),

                // Content
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Patient Info Card
                        _buildPatientInfoCard(),
                        
                        const SizedBox(height: 20),
                        
                        // Risk Status Banner
                        _buildRiskStatusBanner(),
                        
                        const SizedBox(height: 20),
                        
                        // Latest Vitals - FIXED VERSION
                        _buildLatestVitals(),
                        
                        const SizedBox(height: 24),
                        
                        // Tabs
                        _buildTabs(),
                        
                        const SizedBox(height: 20),
                        
                        // Tab Content
                        if (_selectedTab == 0)
                          _buildHealthTrends()
                        else
                          _buildHealthHistory(),
                        
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildHeroHeader() {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      backgroundColor: AppColors.wisteriaBlue,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            color: AppColors.wisteriaBlue,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(32),
              bottomRight: Radius.circular(32),
            ),
          ),
          child: Stack(
            children: [
              // Patient Avatar
              Positioned(
                bottom: 20,
                left: 20,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
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
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Text(
                                  _patientProfile?.getInitials() ?? 'P',
                                  style: TextStyle(
                                    color: AppColors.wisteriaBlue,
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            },
                          ),
                        )
                      : Center(
                          child: Text(
                            _patientProfile?.getInitials() ?? 'P',
                            style: TextStyle(
                              color: AppColors.wisteriaBlue,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                ),
              ),
              
              // Patient Name
              Positioned(
                bottom: 30,
                left: 120,
                right: 80,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _patientProfile?.name ?? 'Patient',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.patientEmail,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.9),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
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
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.message_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          onPressed: _navigateToChat,
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildPatientInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.elevation1,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          if (_patientProfile?.age != null)
            _buildInfoItem(
              icon: Icons.cake_rounded,
              label: 'Age',
              value: '${_patientProfile!.age} yrs',
            ),
          if (_patientProfile?.gender != null)
            _buildInfoItem(
              icon: Icons.wc_rounded,
              label: 'Gender',
              value: _patientProfile!.gender!,
            ),
          if (_patientProfile?.bloodGroup != null)
            _buildInfoItem(
              icon: Icons.bloodtype_rounded,
              label: 'Blood',
              value: _patientProfile!.bloodGroup!,
            ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.honeydew,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: AppColors.wisteriaBlue,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildRiskStatusBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _riskColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _riskColor.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _riskColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getRiskIcon(),
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _riskLabel,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _riskColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _riskDescription,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (_latestHealthData != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Last: ${DateFormat('MMM dd, hh:mm a').format(_latestHealthData!.timestamp)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
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

  // FIXED: Latest Vitals Section with responsive grid
  Widget _buildLatestVitals() {
    if (_latestHealthData == null) {
      return _buildNoDataState();
    }
    
    final data = _latestHealthData!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Latest Vitals',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        
        const SizedBox(height: 16),
        
        // FIXED: Use responsive layout
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 400;
            final crossAxisCount = isWide ? 2 : 1;
            
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: crossAxisCount,
              childAspectRatio: isWide ? 1.3 : 2.0,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _buildVitalCard(
                  icon: Icons.favorite_rounded,
                  label: 'Heart Rate',
                  value: '${data.heartRate}',
                  unit: 'bpm',
                  color: AppColors.pastelPetal,
                  isNormal: data.heartRate >= 60 && data.heartRate <= 100,
                ),
                _buildVitalCard(
                  icon: Icons.air_rounded,
                  label: 'SpO2 Level',
                  value: '${data.spo2Level}',
                  unit: '%',
                  color: AppColors.wisteriaBlue,
                  isNormal: data.spo2Level >= 95,
                ),
                _buildVitalCard(
                  icon: Icons.thermostat_rounded,
                  label: 'Temperature',
                  value: data.temperature.toStringAsFixed(1),
                  unit: '°C',
                  color: AppColors.powderBlue,
                  isNormal: data.temperature >= 36.0 && data.temperature <= 37.5,
                ),
                _buildVitalCard(
                  icon: Icons.monitor_heart_rounded,
                  label: 'Blood Pressure',
                  value: '${data.systolicBP}/${data.diastolicBP}',
                  unit: '',
                  color: AppColors.frozenWater,
                  isNormal: data.systolicBP >= 90 && data.systolicBP <= 140,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildNoDataState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.elevation1,
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.heart_broken_rounded,
              size: 48,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 12),
            Text(
              'No health data available',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVitalCard({
    required IconData icon,
    required String label,
    required String value,
    required String unit,
    required Color color,
    required bool isNormal,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.elevation1,
        border: Border.all(
          color: isNormal ? color.withOpacity(0.3) : AppColors.pastelPetal.withOpacity(0.5),
          width: 2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
          ),
          
          const SizedBox(height: 12),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              if (unit.isNotEmpty)
                Text(
                  ' $unit',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 4),
          
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          
          const SizedBox(height: 6),
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isNormal ? color.withOpacity(0.1) : AppColors.pastelPetal.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              isNormal ? 'Normal' : 'Alert',
              style: TextStyle(
                fontSize: 10,
                color: isNormal ? color : AppColors.pastelPetal,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.elevation1,
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = 0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _selectedTab == 0 ? AppColors.wisteriaBlue : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Health Trends',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _selectedTab == 0 ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = 1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _selectedTab == 1 ? AppColors.wisteriaBlue : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'History',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _selectedTab == 1 ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
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
        const Text(
          'Health Trends',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Chart Type Selector
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildChartButton('Heart Rate', 0),
              const SizedBox(width: 8),
              _buildChartButton('SpO2', 1),
              const SizedBox(width: 8),
              _buildChartButton('Temperature', 2),
              const SizedBox(width: 8),
              _buildChartButton('BP', 3),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Chart Container
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppShadows.elevation1,
          ),
          child: Column(
            children: [
              Text(
                _selectedChartType,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              
              const SizedBox(height: 20),
              
              SizedBox(
                height: 220,
                child: _selectedChartSpots.isEmpty
                    ? Center(
                        child: Text(
                          'No data available',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      )
                    : LineChart(
                        ChartUtils.createHealthChart(
                          spots: _selectedChartSpots,
                          chartType: _selectedChartType,
                        ),
                      ),
              ),
              
              const SizedBox(height: 12),
              
              Text(
                'Last ${_selectedChartSpots.length} readings',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChartButton(String label, int index) {
    final isSelected = _selectedChartIndex == index;
    
    return GestureDetector(
      onTap: () => setState(() => _selectedChartIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.wisteriaBlue : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected ? AppShadows.elevation1 : [],
          border: Border.all(
            color: isSelected ? AppColors.wisteriaBlue : AppColors.lightBackground,
            width: 2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildHealthHistory() {
    if (_healthHistory.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppShadows.elevation1,
        ),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.history_rounded,
                size: 48,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: 12),
              Text(
                'No health history available',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent History',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        
        const SizedBox(height: 16),
        
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _healthHistory.length,
          itemBuilder: (context, index) {
            return _buildHistoryCard(_healthHistory[index]);
          },
        ),
      ],
    );
  }

  Widget _buildHistoryCard(HealthDataModel data) {
    Color statusColor;
    
    switch (data.riskLevel) {
      case 0:
        statusColor = AppColors.frozenWater;
        break;
      case 1:
        statusColor = AppColors.powderBlue;
        break;
      case 2:
        statusColor = AppColors.pastelPetal;
        break;
      default:
        statusColor = AppColors.textSecondary;
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.elevation1,
        border: Border.all(
          color: statusColor.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('MMM dd, hh:mm a').format(data.timestamp),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor),
                ),
                child: Text(
                  data.getRiskLevelString().toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildHistoryVital(
                Icons.favorite_rounded,
                '${data.heartRate}',
                'bpm',
              ),
              _buildHistoryVital(
                Icons.air_rounded,
                '${data.spo2Level}',
                '%',
              ),
              _buildHistoryVital(
                Icons.thermostat_rounded,
                data.temperature.toStringAsFixed(1),
                '°C',
              ),
              _buildHistoryVital(
                Icons.monitor_heart_rounded,
                '${data.systolicBP}/${data.diastolicBP}',
                '',
              ),
            ],
          ),
          
          if (data.additionalNotes != null && data.additionalNotes!.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Text(
              'Notes: ${data.additionalNotes}',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHistoryVital(IconData icon, String value, String unit) {
    return Column(
      children: [
        Icon(
          icon,
          size: 18,
          color: AppColors.textSecondary,
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            if (unit.isNotEmpty)
              Text(
                ' $unit',
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
              ),
          ],
        ),
      ],
    );
  }
}