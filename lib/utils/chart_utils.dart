// lib/utils/chart_utils.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:chemo_monitor_app/config/app_constants.dart';
import 'package:intl/intl.dart';

class ChartUtils {
  // ==================== HEALTH LINE CHARTS ====================
  
  static LineChartData createHealthChart({
    required List<FlSpot> spots,
    required String chartType,
    double? minY,
    double? maxY,
    List<DateTime>? timestamps,
  }) {
    if (spots.isEmpty) {
      return _createEmptyChart();
    }

    // Define normal ranges for each vital
    Map<String, dynamic> vitalConfig = _getVitalConfig(chartType);
    Color lineColor = vitalConfig['lineColor'] as Color;
    Color fillColor = vitalConfig['fillColor'] as Color;
    Color normalZoneColor = vitalConfig['normalZoneColor'] as Color;
    double normalMin = vitalConfig['normalMin'] as double;
    double normalMax = vitalConfig['normalMax'] as double;
    String unit = vitalConfig['unit'] as String;
    
    // Calculate dynamic min/max
    final calculatedMinMax = _calculateMinMax(spots, normalMin, normalMax);
    final chartMinY = calculatedMinMax['min'] as double;
    final chartMaxY = calculatedMinMax['max'] as double;
    
    // Generate X-axis labels from timestamps
    List<String> xLabels = [];
    if (timestamps != null && timestamps.isNotEmpty) {
      xLabels = _generateTimeLabels(timestamps);
    }

    return LineChartData(
      lineTouchData: LineTouchData(
        enabled: true,
        handleBuiltInTouches: true,
        touchTooltipData: LineTouchTooltipData(
          tooltipBgColor: Colors.white.withOpacity(0.95),
          tooltipRoundedRadius: 8,
          tooltipPadding: const EdgeInsets.all(8),
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((touchedSpot) {
              final timeLabel = xLabels.isNotEmpty && 
                  touchedSpot.x.toInt() < xLabels.length
                  ? xLabels[touchedSpot.x.toInt()]
                  : 'Reading ${touchedSpot.x.toInt() + 1}';
              
              return LineTooltipItem(
                '$timeLabel\n',
                const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
                children: [
                  TextSpan(
                    text: '${touchedSpot.y.toStringAsFixed(1)} $unit',
                    style: TextStyle(
                      color: lineColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  TextSpan(
                    text: _getHealthStatusText(chartType, touchedSpot.y),
                    style: TextStyle(
                      color: _getStatusColor(chartType, touchedSpot.y),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              );
            }).toList();
          },
        ),
      ),
      
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: (chartMaxY - chartMinY) / 5,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: AppColors.lightBackground,
            strokeWidth: 1,
            dashArray: [3, 3],
          );
        },
      ),
      
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: _calculateLabelInterval(spots.length),
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index >= 0 && index < xLabels.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: 6.0),
                  child: Text(
                    xLabels[index],
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                );
              } else if (index >= 0 && index < spots.length && index % 3 == 0) {
                return Padding(
                  padding: const EdgeInsets.only(top: 6.0),
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
        
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 50,
            interval: _calculateLeftInterval(chartMinY, chartMaxY),
            getTitlesWidget: (value, meta) {
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Text(
                  '${value.toInt()}$unit',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
              );
            },
          ),
        ),
      ),
      
      borderData: FlBorderData(
        show: true,
        border: Border.all(
          color: AppColors.lightBackground,
          width: 1,
        ),
      ),
      
      minX: 0,
      maxX: (spots.length - 1).toDouble(),
      minY: chartMinY,
      maxY: chartMaxY,
      
      lineBarsData: [
        // Normal range background zone
        LineChartBarData(
          spots: [
            FlSpot(0, normalMin),
            FlSpot((spots.length - 1).toDouble(), normalMin),
          ],
          isCurved: false,
          color: Colors.transparent,
          barWidth: 0,
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                normalZoneColor.withOpacity(0.2),
                normalZoneColor.withOpacity(0.05),
              ],
              stops: const [0.0, 1.0],
            ),
            cutOffY: normalMax,
            applyCutOffY: true,
          ),
        ),
        
        // Main data line
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: lineColor,
          barWidth: 3,
          isStrokeCapRound: true,
          preventCurveOverShooting: true,
          shadow: Shadow(
            color: lineColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 4,
                color: Colors.white,
                strokeWidth: 2,
                strokeColor: lineColor,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                fillColor.withOpacity(0.4),
                fillColor.withOpacity(0.05),
              ],
              stops: const [0.0, 1.0],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        
        // Normal range lower line
        LineChartBarData(
          spots: [
            FlSpot(0, normalMin),
            FlSpot((spots.length - 1).toDouble(), normalMin),
          ],
          isCurved: false,
          color: AppColors.softGreen.withOpacity(0.6),
          barWidth: 1.5,
          dashArray: [5, 5],
          dotData: const FlDotData(show: false),
        ),
        
        // Normal range upper line
        LineChartBarData(
          spots: [
            FlSpot(0, normalMax),
            FlSpot((spots.length - 1).toDouble(), normalMax),
          ],
          isCurved: false,
          color: AppColors.softGreen.withOpacity(0.6),
          barWidth: 1.5,
          dashArray: [5, 5],
          dotData: const FlDotData(show: false),
        ),
      ],
    );
  }

  static LineChartData _createEmptyChart() {
    return LineChartData(
      lineTouchData: const LineTouchData(enabled: false),
      gridData: const FlGridData(show: false),
      titlesData: const FlTitlesData(show: false),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: AppColors.lightBackground),
      ),
      minX: 0,
      maxX: 1,
      minY: 0,
      maxY: 1,
      lineBarsData: [],
    );
  }

  // ==================== HELPER METHODS ====================
  
  static Map<String, dynamic> _getVitalConfig(String vitalType) {
    switch (vitalType) {
      case 'Heart Rate':
        return {
          'lineColor': AppColors.pastelPetal,
          'fillColor': AppColors.pastelPetal,
          'normalZoneColor': AppColors.softGreen,
          'normalMin': 60.0,
          'normalMax': 100.0,
          'unit': 'bpm',
          'criticalHigh': 140.0,
          'criticalLow': 40.0,
        };
      case 'SpO2':
        return {
          'lineColor': AppColors.wisteriaBlue,
          'fillColor': AppColors.wisteriaBlue,
          'normalZoneColor': AppColors.softGreen,
          'normalMin': 95.0,
          'normalMax': 100.0,
          'unit': '%',
          'criticalHigh': 100.0,
          'criticalLow': 90.0,
        };
      case 'Temperature':
        return {
          'lineColor': AppColors.powderBlue,
          'fillColor': AppColors.powderBlue,
          'normalZoneColor': AppColors.softGreen,
          'normalMin': 36.0,
          'normalMax': 37.5,
          'unit': '°C',
          'criticalHigh': 38.5,
          'criticalLow': 35.0,
        };
      case 'Blood Pressure':
        return {
          'lineColor': AppColors.frozenWater,
          'fillColor': AppColors.frozenWater,
          'normalZoneColor': AppColors.softGreen,
          'normalMin': 90.0,
          'normalMax': 140.0,
          'unit': 'mmHg',
          'criticalHigh': 180.0,
          'criticalLow': 70.0,
        };
      default:
        return {
          'lineColor': AppColors.textSecondary,
          'fillColor': AppColors.textSecondary,
          'normalZoneColor': AppColors.lightBackground,
          'normalMin': 0.0,
          'normalMax': 100.0,
          'unit': '',
          'criticalHigh': 100.0,
          'criticalLow': 0.0,
        };
    }
  }

  static Map<String, double> _calculateMinMax(
    List<FlSpot> spots,
    double normalMin,
    double normalMax,
  ) {
    if (spots.isEmpty) {
      return {'min': normalMin * 0.8, 'max': normalMax * 1.2};
    }
    
    double dataMin = spots.first.y;
    double dataMax = spots.first.y;
    
    for (final spot in spots) {
      if (spot.y < dataMin) dataMin = spot.y;
      if (spot.y > dataMax) dataMax = spot.y;
    }
    
    // Include normal range in view
    final viewMin = dataMin < normalMin ? dataMin : normalMin;
    final viewMax = dataMax > normalMax ? dataMax : normalMax;
    
    // Add padding
    final range = viewMax - viewMin;
    final padding = range * 0.15;
    
    return {
      'min': (viewMin - padding).clamp(0, double.infinity),
      'max': viewMax + padding,
    };
  }

  static List<String> _generateTimeLabels(List<DateTime> timestamps) {
    if (timestamps.isEmpty) return [];
    
    if (timestamps.length <= 5) {
      return timestamps.map((time) {
        return DateFormat('HH:mm').format(time);
      }).toList();
    }
    
    // Show labels at strategic points
    final labels = List<String>.filled(timestamps.length, '');
    
    // First point
    labels[0] = DateFormat('HH:mm').format(timestamps[0]);
    
    // Last point
    labels[timestamps.length - 1] = DateFormat('HH:mm').format(timestamps[timestamps.length - 1]);
    
    // Middle points
    final step = timestamps.length ~/ 4;
    for (int i = step; i < timestamps.length - 1; i += step) {
      labels[i] = DateFormat('HH:mm').format(timestamps[i]);
    }
    
    return labels;
  }

  static double _calculateLabelInterval(int dataPoints) {
    if (dataPoints <= 5) return 1.0;
    if (dataPoints <= 10) return 2.0;
    if (dataPoints <= 20) return 3.0;
    return (dataPoints / 5.0).ceilToDouble();
  }

  static double _calculateLeftInterval(double minY, double maxY) {
    final range = maxY - minY;
    if (range <= 20) return 5;
    if (range <= 50) return 10;
    if (range <= 100) return 20;
    if (range <= 200) return 40;
    return 50;
  }

  static String _getHealthStatusText(String vitalType, double value) {
    final config = _getVitalConfig(vitalType);
    final criticalLow = config['criticalLow'] as double;
    final criticalHigh = config['criticalHigh'] as double;
    final normalMin = config['normalMin'] as double;
    final normalMax = config['normalMax'] as double;
    
    if (value < criticalLow) return '\nCRITICALLY LOW ⚠️';
    if (value > criticalHigh) return '\nCRITICALLY HIGH ⚠️';
    if (value < normalMin) return '\nBelow Normal';
    if (value > normalMax) return '\nAbove Normal';
    return '\nNormal ✓';
  }

  static Color _getStatusColor(String vitalType, double value) {
    final config = _getVitalConfig(vitalType);
    final criticalLow = config['criticalLow'] as double;
    final criticalHigh = config['criticalHigh'] as double;
    final normalMin = config['normalMin'] as double;
    final normalMax = config['normalMax'] as double;
    
    if (value < criticalLow || value > criticalHigh) {
      return AppColors.riskHigh;
    }
    if (value < normalMin || value > normalMax) {
      return AppColors.riskModerate;
    }
    return AppColors.riskLow;
  }

  static Color _getVitalColor(String vitalName) {
    switch (vitalName) {
      case 'Heart Rate':
        return AppColors.pastelPetal;
      case 'SpO2':
        return AppColors.wisteriaBlue;
      case 'Temperature':
        return AppColors.powderBlue;
      case 'Blood Pressure':
        return AppColors.frozenWater;
      default:
        return AppColors.textSecondary;
    }
  }

  static double _getVitalMax(String vitalName) {
    switch (vitalName) {
      case 'Heart Rate':
        return 180.0;
      case 'SpO2':
        return 100.0;
      case 'Temperature':
        return 40.0;
      case 'Blood Pressure':
        return 200.0;
      default:
        return 100.0;
    }
  }

  // ==================== RISK PIE CHART ====================
  
  static PieChartData createRiskPieChart({
    required int lowRisk,
    required int moderateRisk,
    required int highRisk,
    required String timeframe,
  }) {
    final total = lowRisk + moderateRisk + highRisk;
    
    if (total == 0) {
      return PieChartData(
        sectionsSpace: 0,
        centerSpaceRadius: 60,
        sections: [
          PieChartSectionData(
            color: AppColors.lightBackground,
            value: 1,
            title: 'No Data',
            radius: 40,
            titleStyle: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }
    
    final List<PieChartSectionData> sections = [];
    
    if (lowRisk > 0) {
      sections.add(
        PieChartSectionData(
          color: AppColors.riskLow,
          value: lowRisk.toDouble(),
          title: '${((lowRisk / total) * 100).toStringAsFixed(0)}%',
          radius: 35,
          titleStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          badgeWidget: _RiskBadge(
            icon: Icons.check_circle_rounded,
            label: 'Low',
            color: AppColors.riskLow,
          ),
          badgePositionPercentageOffset: 1.4,
        ),
      );
    }
    
    if (moderateRisk > 0) {
      sections.add(
        PieChartSectionData(
          color: AppColors.riskModerate,
          value: moderateRisk.toDouble(),
          title: '${((moderateRisk / total) * 100).toStringAsFixed(0)}%',
          radius: 35,
          titleStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          badgeWidget: _RiskBadge(
            icon: Icons.warning_amber_rounded,
            label: 'Moderate',
            color: AppColors.riskModerate,
          ),
          badgePositionPercentageOffset: 1.4,
        ),
      );
    }
    
    if (highRisk > 0) {
      sections.add(
        PieChartSectionData(
          color: AppColors.riskHigh,
          value: highRisk.toDouble(),
          title: '${((highRisk / total) * 100).toStringAsFixed(0)}%',
          radius: 35,
          titleStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          badgeWidget: _RiskBadge(
            icon: Icons.error_rounded,
            label: 'High',
            color: AppColors.riskHigh,
          ),
          badgePositionPercentageOffset: 1.4,
        ),
      );
    }
    
    return PieChartData(
      pieTouchData: PieTouchData(
        touchCallback: (FlTouchEvent event, pieTouchResponse) {},
      ),
      sectionsSpace: 3,
      centerSpaceRadius: 55,
      startDegreeOffset: 270,
      sections: sections,
    );
  }

  // ==================== VITAL COMPARISON BAR CHART ====================
  
  static BarChartData createVitalComparisonChart({
    required List<double> values,
    required List<String> labels,
    required String timeframe,
  }) {
    if (values.isEmpty || labels.isEmpty) {
      return BarChartData(
        barGroups: [],
        titlesData: const FlTitlesData(show: false),
      );
    }

    return BarChartData(
      alignment: BarChartAlignment.spaceAround,
      maxY: values.reduce((curr, next) => curr > next ? curr : next) * 1.2,
      barTouchData: BarTouchData(
        enabled: true,
        touchTooltipData: BarTouchTooltipData(
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            return BarTooltipItem(
              '${labels[group.x.toInt()]}\n${rod.toY.toStringAsFixed(1)}',
              TextStyle(
                color: _getVitalColor(labels[group.x.toInt()]),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            );
          },
          tooltipBgColor: Colors.white.withOpacity(0.95),
        ),
      ),
      
      titlesData: FlTitlesData(
        show: true,
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index >= 0 && index < labels.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    labels[index],
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 20,
            getTitlesWidget: (value, meta) {
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Text(
                  value.toInt().toString(),
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
              );
            },
          ),
        ),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 20,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: AppColors.lightBackground,
            strokeWidth: 1,
            dashArray: [3, 3],
          );
        },
      ),
      
      borderData: FlBorderData(
        show: true,
        border: Border.all(
          color: AppColors.lightBackground,
          width: 1,
        ),
      ),
      
      barGroups: values.asMap().entries.map((entry) {
        final index = entry.key;
        final value = entry.value;
        final vitalName = labels[index];
        final color = _getVitalColor(vitalName);
        
        return BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: value,
              width: 24,
              borderRadius: BorderRadius.circular(6),
              gradient: LinearGradient(
                colors: [
                  color,
                  color.withOpacity(0.7),
                ],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: _getVitalMax(vitalName),
                color: AppColors.lightBackground,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

// ==================== WIDGETS ====================

class _RiskBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  
  const _RiskBadge({
    required this.icon,
    required this.label,
    required this.color,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== DATA PROCESSING ====================

class ChartDataProcessor {
  static List<FlSpot> processHealthDataForChart({
    required List<double> values,
    required List<DateTime> timestamps,
    String? chartType,
  }) {
    if (values.isEmpty || timestamps.isEmpty) return [];
    
    // Ensure same length
    final length = values.length < timestamps.length ? values.length : timestamps.length;
    
    // Sort by timestamp
    final List<Map<String, dynamic>> combined = List.generate(
      length,
      (index) => {
        'value': values[index],
        'time': timestamps[index],
      },
    );
    
    combined.sort((a, b) => 
      (a['time'] as DateTime).compareTo(b['time'] as DateTime)
    );
    
    return List.generate(
      combined.length,
      (index) => FlSpot(index.toDouble(), combined[index]['value'] as double),
    );
  }
  
  static List<DateTime> getTimestampsFromData(List<dynamic> data) {
    return data.map((item) {
      if (item is DateTime) return item;
      if (item is Map<String, dynamic> && item['timestamp'] is DateTime) {
        return item['timestamp'] as DateTime;
      }
      return DateTime.now();
    }).toList();
  }
  
  static Map<String, List<double>> groupDataByTimeframe({
    required List<double> values,
    required List<DateTime> timestamps,
    required String timeframe,
  }) {
    // Group data by day, week, or month based on timeframe
    final Map<String, List<double>> grouped = {};
    
    for (int i = 0; i < values.length && i < timestamps.length; i++) {
      final key = _getTimeframeKey(timestamps[i], timeframe);
      grouped.putIfAbsent(key, () => []);
      grouped[key]!.add(values[i]);
    }
    
    return grouped;
  }
  
  static String _getTimeframeKey(DateTime date, String timeframe) {
    switch (timeframe) {
      case 'Last 7 days':
        return DateFormat('E').format(date); // Day of week
      case 'Last 30 days':
        return DateFormat('MMM d').format(date); // Month day
      case 'Last 3 months':
        return DateFormat('MMM').format(date); // Month
      default:
        return DateFormat('MMM yyyy').format(date); // Month year
    }
  }
}