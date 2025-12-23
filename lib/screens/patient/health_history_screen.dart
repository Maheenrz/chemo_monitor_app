import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chemo_monitor_app/config/app_constants.dart';
import 'package:chemo_monitor_app/models/health_data_model.dart';
import 'package:chemo_monitor_app/services/health_data_service.dart';
import 'package:intl/intl.dart';
import 'package:chemo_monitor_app/widgets/common/ml_confidence_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:chemo_monitor_app/widgets/common/glass_card.dart';
import 'package:chemo_monitor_app/widgets/common/glass_button.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:chemo_monitor_app/utils/chart_utils.dart';

class HealthHistoryScreen extends StatefulWidget {
  const HealthHistoryScreen({super.key});

  @override
  State<HealthHistoryScreen> createState() => _HealthHistoryScreenState();
}

class _HealthHistoryScreenState extends State<HealthHistoryScreen> {
  final HealthDataService _healthDataService = HealthDataService();
  List<HealthDataModel> _healthData = [];
  bool _isLoading = true;
  String _selectedFilter = 'All';
  String _selectedTimeframe = 'Last 7 days';
  int _selectedTab = 0; // 0 = List, 1 = Charts

  @override
  void initState() {
    super.initState();
    _loadHealthData();
  }

  Future<void> _loadHealthData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('health_data')
          .where('patientId', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true)
          .get();

      final data = snapshot.docs
          .map((doc) => HealthDataModel.fromMap(doc.data()))
          .toList();
      
      if (mounted) {
        setState(() {
          _healthData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading health history: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<HealthDataModel> get _filteredData {
    List<HealthDataModel> data = List.from(_healthData);
    
    final now = DateTime.now();
    if (_selectedTimeframe == 'Last 7 days') {
      data = data.where((item) => 
        item.timestamp.isAfter(now.subtract(const Duration(days: 7)))
      ).toList();
    } else if (_selectedTimeframe == 'Last 30 days') {
      data = data.where((item) => 
        item.timestamp.isAfter(now.subtract(const Duration(days: 30)))
      ).toList();
    } else if (_selectedTimeframe == 'Last 3 months') {
      data = data.where((item) => 
        item.timestamp.isAfter(now.subtract(const Duration(days: 90)))
      ).toList();
    }
    
    if (_selectedFilter == 'High Risk') {
      data = data.where((item) => item.riskLevel == 2).toList();
    } else if (_selectedFilter == 'Moderate Risk') {
      data = data.where((item) => item.riskLevel == 1).toList();
    } else if (_selectedFilter == 'Low Risk') {
      data = data.where((item) => item.riskLevel == 0).toList();
    }
    
    return data;
  }

  double _calculateAverageHeartRate() {
    if (_filteredData.isEmpty) return 0;
    final sum = _filteredData.fold(0, (sum, item) => sum + item.heartRate);
    return sum / _filteredData.length;
  }

  double _calculateAverageSpO2() {
    if (_filteredData.isEmpty) return 0;
    final sum = _filteredData.fold(0, (sum, item) => sum + item.spo2Level);
    return sum / _filteredData.length;
  }

  Map<String, dynamic> _getRiskStyle(int? riskLevel) {
    switch (riskLevel) {
      case 0:
        return {
          'color': AppColors.riskLow,
          'bgColor': AppColors.riskLowBg,
          'label': 'LOW RISK',
          'icon': Icons.check_circle_rounded,
        };
      case 1:
        return {
          'color': AppColors.riskModerate,
          'bgColor': AppColors.riskModerateBg,
          'label': 'MODERATE RISK',
          'icon': Icons.warning_amber_rounded,
        };
      case 2:
        return {
          'color': AppColors.riskHigh,
          'bgColor': AppColors.riskHighBg,
          'label': 'HIGH RISK',
          'icon': Icons.error_rounded,
        };
      default:
        return {
          'color': AppColors.textSecondary,
          'bgColor': AppColors.lightBlue,
          'label': 'UNKNOWN',
          'icon': Icons.help_outline_rounded,
        };
    }
  }

  List<FlSpot> _getChartData(String type) {
    final sortedData = List.from(_filteredData)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    
    return sortedData.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      double value;
      
      switch (type) {
        case 'Heart Rate':
          value = data.heartRate.toDouble();
          break;
        case 'SpO2':
          value = data.spo2Level.toDouble();
          break;
        case 'Temperature':
          value = data.temperature;
          break;
        case 'Blood Pressure':
          value = data.systolicBP.toDouble();
          break;
        default:
          value = 0;
      }
      
      return FlSpot(index.toDouble(), value);
    }).toList();
  }

  Widget _buildChartSection() {
    final chartTypes = ['Heart Rate', 'SpO2', 'Temperature', 'Blood Pressure'];
    final selectedSpots = _getChartData(chartTypes[_selectedTab]);
    
    if (selectedSpots.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart_rounded, size: 64, color: AppColors.textSecondary.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text(
              'No data for charts',
              style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }
    
    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: chartTypes.asMap().entries.map((entry) {
              final index = entry.key;
              final type = entry.value;
              final isSelected = _selectedTab == index;
              
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GlassButton(
                  onPressed: () => setState(() => _selectedTab = index),
                  text: type,
                  type: isSelected ? ButtonType.primary : ButtonType.secondary,
                  isSelected: isSelected,
                  height: 36,
                ),
              );
            }).toList(),
          ),
        ),
        
        const SizedBox(height: 16),
        
        GlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                chartTypes[_selectedTab],
                style: AppTextStyles.heading3.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              
              const SizedBox(height: 12),
              
              Container(
                height: 200,
                child: LineChart(
                  ChartUtils.createHealthChart(
                    spots: selectedSpots,
                    chartType: chartTypes[_selectedTab],
                    minY: _getMinY(selectedSpots),
                    maxY: _getMaxY(selectedSpots),
                  ),
                ),
              ),
              
              const SizedBox(height: 12),
              
              Text(
                'Trend over ${_selectedTimeframe.toLowerCase()}',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mainBackground,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primaryBlue),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Health History',
          style: AppTextStyles.heading3.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
              ),
            )
          : Column(
              children: [
                // Filters Area
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Toggle for List/Charts
                      GlassCard(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: GlassButton(
                                onPressed: () => setState(() => _selectedTab = 0),
                                text: 'List View',
                                type: ButtonType.primary,
                                isSelected: _selectedTab == 0,
                                height: 36,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: GlassButton(
                                onPressed: () => setState(() => _selectedTab = 1),
                                text: 'Charts',
                                type: ButtonType.primary,
                                isSelected: _selectedTab == 1,
                                height: 36,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Timeframe Filter
                      GlassCard(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedTimeframe,
                            isExpanded: true,
                            icon: Icon(
                              Icons.arrow_drop_down_rounded,
                              color: AppColors.primaryBlue,
                            ),
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textPrimary,
                            ),
                            items: [
                              'Last 7 days',
                              'Last 30 days',
                              'Last 3 months',
                              'All time',
                            ].map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() => _selectedTimeframe = newValue);
                              }
                            },
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Risk Level Filter Chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip('All', AppColors.primaryBlue),
                            const SizedBox(width: 8),
                            _buildFilterChip('High Risk', AppColors.riskHigh),
                            const SizedBox(width: 8),
                            _buildFilterChip('Moderate Risk', AppColors.riskModerate),
                            const SizedBox(width: 8),
                            _buildFilterChip('Low Risk', AppColors.riskLow),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Stats Summary
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _buildStatCard(
                        label: 'Entries',
                        value: '${_filteredData.length}',
                        color: AppColors.primaryBlue,
                      ),
                      const SizedBox(width: 12),
                      _buildStatCard(
                        label: 'Avg HR',
                        value: '${_calculateAverageHeartRate().toInt()}',
                        unit: 'bpm',
                        color: AppColors.riskHigh,
                      ),
                      const SizedBox(width: 12),
                      _buildStatCard(
                        label: 'Avg SpO2',
                        value: '${_calculateAverageSpO2().toInt()}',
                        unit: '%',
                        color: AppColors.softGreen,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Content based on selected tab
                Expanded(
                  child: _selectedTab == 0
                      ? _buildListView()
                      : _buildChartView(),
                ),
              ],
            ),
    );
  }

  Widget _buildListView() {
    return _filteredData.isEmpty
        ? _buildEmptyState()
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _filteredData.length,
            itemBuilder: (context, index) {
              final healthData = _filteredData[index];
              return _buildHealthDataCard(healthData);
            },
          );
  }

  Widget _buildChartView() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildChartSection(),
        
        const SizedBox(height: 24),
        
        // Risk Distribution Pie Chart
        if (_filteredData.isNotEmpty)
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  'Risk Distribution',
                  style: AppTextStyles.heading3.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                
                const SizedBox(height: 12),
                
                Container(
                  height: 200,
                  child: PieChart(
                    ChartUtils.createRiskDistribution(
                      lowRisk: _filteredData.where((d) => d.riskLevel == 0).length,
                      moderateRisk: _filteredData.where((d) => d.riskLevel == 1).length,
                      highRisk: _filteredData.where((d) => d.riskLevel == 2).length,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildFilterChip(String label, Color color) {
    final isSelected = _selectedFilter == label;
    final buttonType = isSelected ? ButtonType.primary : ButtonType.secondary;
    
    return GlassButton(
      onPressed: () => setState(() => _selectedFilter = label),
      text: label,
      type: buttonType,
      isSelected: isSelected,
      height: 36,
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    String unit = '',
    required Color color,
  }) {
    return Expanded(
      child: GlassCard(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: value,
                    style: AppTextStyles.heading3.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (unit.isNotEmpty)
                    TextSpan(
                      text: ' $unit',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_rounded, size: 64, color: AppColors.textSecondary.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            'No records found',
            style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            'Try changing filters or timeframe',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthDataCard(HealthDataModel data) {
    final style = _getRiskStyle(data.riskLevel);
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('hh:mm a');
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        borderRadius: AppDimensions.radiusLarge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with date and risk
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dateFormat.format(data.timestamp),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      timeFormat.format(data.timestamp),
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: style['bgColor'],
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                    border: Border.all(color: style['color']),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        style['icon'],
                        size: 16,
                        color: style['color'],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        style['label'],
                        style: AppTextStyles.caption.copyWith(
                          color: style['color'],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Vitals Grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 2.8,
              crossAxisSpacing: 16,
              mainAxisSpacing: 8,
              children: [
                _buildVitalDetail(
                  icon: Icons.favorite_rounded,
                  label: 'Heart Rate',
                  value: '${data.heartRate}',
                  unit: 'bpm',
                  color: AppColors.riskHigh,
                ),
                _buildVitalDetail(
                  icon: Icons.air_rounded,
                  label: 'SpO2 Level',
                  value: '${data.spo2Level}',
                  unit: '%',
                  color: AppColors.primaryBlue,
                ),
                _buildVitalDetail(
                  icon: Icons.thermostat_rounded,
                  label: 'Temperature',
                  value: data.temperature.toStringAsFixed(1),
                  unit: '°C',
                  color: AppColors.riskModerate,
                ),
                _buildVitalDetail(
                  icon: Icons.monitor_heart_rounded,
                  label: 'Blood Pressure',
                  value: '${data.systolicBP}/${data.diastolicBP}',
                  unit: 'mmHg',
                  color: AppColors.softPurple,
                ),
              ],
            ),
            
            // ML Confidence
            if (data.mlOutputProbabilities != null) ...[
              const SizedBox(height: 12),
              Divider(height: 1, color: AppColors.divider),
              const SizedBox(height: 12),
              _buildMLConfidence(data),
            ],
            
            // Notes
            if (data.additionalNotes != null && data.additionalNotes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.lightBlue,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.note_rounded,
                      size: 20,
                      color: AppColors.primaryBlue,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        data.additionalNotes!,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVitalDetail({
    required IconData icon,
    required String label,
    required String value,
    required String unit,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 18,
            color: color,
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
            ),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: value,
                    style: const TextStyle(
                      fontSize: 14, 
                      fontWeight: FontWeight.bold, 
                      color: AppColors.textPrimary
                    ),
                  ),
                  TextSpan(
                    text: ' $unit',
                    style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMLConfidence(HealthDataModel data) {
    final probabilities = data.mlOutputProbabilities!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AI Prediction Confidence',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        
        const SizedBox(height: 8),
        
        Row(
          children: [
            Expanded(
              child: _buildConfidenceBar(
                label: 'Low',
                probability: probabilities[0],
                color: AppColors.riskLow,
                isActive: data.riskLevel == 0,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildConfidenceBar(
                label: 'Moderate',
                probability: probabilities[1],
                color: AppColors.riskModerate,
                isActive: data.riskLevel == 1,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildConfidenceBar(
                label: 'High',
                probability: probabilities[2],
                color: AppColors.riskHigh,
                isActive: data.riskLevel == 2,
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive ? color : AppColors.textSecondary,
              ),
            ),
            Text(
              '${(probability * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          height: 6,
          decoration: BoxDecoration(
            color: AppColors.lightBlue,
            borderRadius: BorderRadius.circular(3),
          ),
          child: FractionallySizedBox(
            widthFactor: probability,
            alignment: Alignment.centerLeft,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }
}