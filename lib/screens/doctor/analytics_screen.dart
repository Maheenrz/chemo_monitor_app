import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:chemo_monitor_app/config/app_constants.dart';
import 'package:chemo_monitor_app/widgets/common/glass_card.dart';
import 'package:intl/intl.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> with SingleTickerProviderStateMixin {
  // Mock data - Replace with real data from Firestore
  final Map<String, dynamic> _analyticsData = {
    'totalPatients': 24,
    'highRisk': 3,
    'moderateRisk': 8,
    'lowRisk': 13,
    'avgResponseTime': '2.5h',
    'alertsResolved': '18/21',
    'patientSatisfaction': '92%',
  };

  final List<Map<String, dynamic>> _riskTrendData = [
    {'date': 'Dec 15', 'high': 1, 'moderate': 4, 'low': 19},
    {'date': 'Dec 16', 'high': 2, 'moderate': 5, 'low': 17},
    {'date': 'Dec 17', 'high': 2, 'moderate': 6, 'low': 16},
    {'date': 'Dec 18', 'high': 3, 'moderate': 7, 'low': 14},
    {'date': 'Dec 19', 'high': 3, 'moderate': 8, 'low': 13},
    {'date': 'Dec 20', 'high': 3, 'moderate': 8, 'low': 13},
    {'date': 'Dec 21', 'high': 3, 'moderate': 8, 'low': 13},
  ];

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      vsync: this,
      duration: AppAnimations.slow,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
            child: child,
          );
        },
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 100,
              floating: false,
              pinned: true,
              backgroundColor: Colors.white,
              elevation: 0,
              title: Text(
                'Analytics Dashboard',
                style: AppTextStyles.heading3.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              actions: [
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(AppDimensions.spaceS),
                    decoration: BoxDecoration(
                      color: AppColors.lightBlue,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
                    ),
                    child: const Icon(
                      Icons.download_rounded,
                      size: AppDimensions.iconS,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                  onPressed: _exportReport,
                ),
              ],
            ),
            
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                child: Column(
                  children: [
                    // Time Period Selector
                    _buildTimeSelector(),
                    
                    const SizedBox(height: AppDimensions.spaceXL),
                    
                    // Risk Distribution
                    _buildRiskDistribution(),
                    
                    const SizedBox(height: AppDimensions.spaceXL),
                    
                    // Trend Over Time
                    _buildTrendChart(),
                    
                    const SizedBox(height: AppDimensions.spaceXL),
                    
                    // Key Insights
                    _buildKeyInsights(),
                    
                    const SizedBox(height: AppDimensions.spaceXL),
                    
                    // Performance Metrics
                    _buildPerformanceMetrics(),
                    
                    const SizedBox(height: AppDimensions.spaceXL),
                    
                    // Export Options
                    _buildExportOptions(),
                    
                    const SizedBox(height: AppDimensions.spaceXXXL),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSelector() {
    return GlassCard(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'This Week',
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spaceM,
              vertical: AppDimensions.spaceS,
            ),
            decoration: BoxDecoration(
              color: AppColors.lightBlue,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            ),
            child: Row(
              children: [
                Text(
                  DateFormat('MMM dd').format(DateTime.now().subtract(const Duration(days: 7))),
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primaryBlue,
                  ),
                ),
                const Text(' - ', style: AppTextStyles.caption),
                Text(
                  DateFormat('MMM dd').format(DateTime.now()),
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primaryBlue,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskDistribution() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Risk Distribution',
          style: AppTextStyles.heading3.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        
        const SizedBox(height: AppDimensions.spaceL),
        
        GlassCard(
          padding: const EdgeInsets.all(AppDimensions.paddingLarge),
          child: Column(
            children: [
              SizedBox(
                height: 200,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 50,
                    sections: [
                      PieChartSectionData(
                        color: AppColors.riskHigh,
                        value: _analyticsData['highRisk'].toDouble(),
                        title: '${_analyticsData['highRisk']}',
                        radius: 25,
                        titleStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      PieChartSectionData(
                        color: AppColors.riskModerate,
                        value: _analyticsData['moderateRisk'].toDouble(),
                        title: '${_analyticsData['moderateRisk']}',
                        radius: 25,
                        titleStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      PieChartSectionData(
                        color: AppColors.riskLow,
                        value: _analyticsData['lowRisk'].toDouble(),
                        title: '${_analyticsData['lowRisk']}',
                        radius: 25,
                        titleStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: AppDimensions.spaceL),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildLegendItem(
                    color: AppColors.riskHigh,
                    label: 'High Risk',
                    value: '${_analyticsData['highRisk']} (${((_analyticsData['highRisk'] / _analyticsData['totalPatients']) * 100).toStringAsFixed(0)}%)',
                  ),
                  _buildLegendItem(
                    color: AppColors.riskModerate,
                    label: 'Moderate',
                    value: '${_analyticsData['moderateRisk']} (${((_analyticsData['moderateRisk'] / _analyticsData['totalPatients']) * 100).toStringAsFixed(0)}%)',
                  ),
                  _buildLegendItem(
                    color: AppColors.riskLow,
                    label: 'Stable',
                    value: '${_analyticsData['lowRisk']} (${((_analyticsData['lowRisk'] / _analyticsData['totalPatients']) * 100).toStringAsFixed(0)}%)',
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        
        const SizedBox(height: AppDimensions.spaceXS),
        
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        
        Text(
          value,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTrendChart() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Trend Over Time',
          style: AppTextStyles.heading3.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        
        const SizedBox(height: AppDimensions.spaceL),
        
        GlassCard(
          padding: const EdgeInsets.all(AppDimensions.paddingLarge),
          child: SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < _riskTrendData.length) {
                          return Text(
                            _riskTrendData[index]['date'],
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: _riskTrendData.asMap().entries.map((entry) {
                      return FlSpot(entry.key.toDouble(), entry.value['high'].toDouble());
                    }).toList(),
                    isCurved: true,
                    color: AppColors.riskHigh,
                    barWidth: 3,
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.riskHigh.withOpacity(0.3),
                    ),
                  ),
                  LineChartBarData(
                    spots: _riskTrendData.asMap().entries.map((entry) {
                      return FlSpot(entry.key.toDouble(), entry.value['moderate'].toDouble());
                    }).toList(),
                    isCurved: true,
                    color: AppColors.riskModerate,
                    barWidth: 3,
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.riskModerate.withOpacity(0.3),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKeyInsights() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Key Insights',
          style: AppTextStyles.heading3.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        
        const SizedBox(height: AppDimensions.spaceL),
        
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 1.5,
          crossAxisSpacing: AppDimensions.spaceL,
          mainAxisSpacing: AppDimensions.spaceL,
          children: [
            _buildInsightCard(
              icon: Icons.people_rounded,
              title: '3 patients need follow-up',
              color: AppColors.riskHigh,
            ),
            _buildInsightCard(
              icon: Icons.timer_rounded,
              title: 'Avg response time: 2.5h',
              color: AppColors.riskModerate,
            ),
            _buildInsightCard(
              icon: Icons.check_circle_rounded,
              title: '18 out of 21 alerts resolved',
              color: AppColors.riskLow,
            ),
            _buildInsightCard(
              icon: Icons.trending_up_rounded,
              title: 'Patient count increased by 3',
              color: AppColors.primaryBlue,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInsightCard({
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return GlassCard(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimensions.spaceM),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            ),
            child: Icon(
              icon,
              color: color,
              size: AppDimensions.iconL,
            ),
          ),
          
          const SizedBox(height: AppDimensions.spaceM),
          
          Text(
            title,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceMetrics() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Performance Metrics',
          style: AppTextStyles.heading3.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        
        const SizedBox(height: AppDimensions.spaceL),
        
        GlassCard(
          padding: const EdgeInsets.all(AppDimensions.paddingLarge),
          child: Column(
            children: [
              _buildMetricRow(
                label: 'Patients Monitored',
                value: _analyticsData['totalPatients'].toString(),
              ),
              const Divider(height: 20),
              _buildMetricRow(
                label: 'Alerts Resolved',
                value: _analyticsData['alertsResolved'],
              ),
              const Divider(height: 20),
              _buildMetricRow(
                label: 'Avg Response Time',
                value: _analyticsData['avgResponseTime'],
              ),
              const Divider(height: 20),
              _buildMetricRow(
                label: 'Patient Satisfaction',
                value: _analyticsData['patientSatisfaction'],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricRow({
    required String label,
    required String value,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        
        Text(
          value,
          style: AppTextStyles.heading3.copyWith(
            color: AppColors.primaryBlue,
          ),
        ),
      ],
    );
  }

  Widget _buildExportOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Export Options',
          style: AppTextStyles.heading3.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        
        const SizedBox(height: AppDimensions.spaceL),
        
        Column(
          children: [
            _buildExportButton(
              icon: Icons.picture_as_pdf_rounded,
              label: 'Generate PDF Report',
              onTap: () => _exportPDF(),
            ),
            
            const SizedBox(height: AppDimensions.spaceM),
            
            _buildExportButton(
              icon: Icons.email_rounded,
              label: 'Email Report to Team',
              onTap: () => _emailReport(),
            ),
            
            const SizedBox(height: AppDimensions.spaceM),
            
            _buildExportButton(
              icon: Icons.download_rounded,
              label: 'Download CSV Data',
              onTap: () => _downloadCSV(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildExportButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GlassCard(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimensions.spaceM),
              decoration: BoxDecoration(
                color: AppColors.lightBlue,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              ),
              child: Icon(
                icon,
                color: AppColors.primaryBlue,
                size: AppDimensions.iconM,
              ),
            ),
            
            const SizedBox(width: AppDimensions.spaceL),
            
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: AppDimensions.iconS,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  void _exportReport() {
    // TODO: Implement export functionality
  }

  void _exportPDF() {
    // TODO: Implement PDF export
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('PDF export started'),
        backgroundColor: AppColors.softGreen,
      ),
    );
  }

  void _emailReport() {
    // TODO: Implement email export
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Preparing email report'),
        backgroundColor: AppColors.primaryBlue,
      ),
    );
  }

  void _downloadCSV() {
    // TODO: Implement CSV download
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('CSV download started'),
        backgroundColor: AppColors.softPurple,
      ),
    );
  }
}