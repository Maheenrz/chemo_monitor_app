import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:chemo_monitor_app/config/app_constants.dart';

class ChartUtils {
  // Create beautiful health chart with proper error handling
  static LineChartData createHealthChart({
    required List<FlSpot> spots,
    required String chartType,
    double? minY,
    double? maxY,
  }) {
    // Handle empty data
    if (spots.isEmpty) {
      spots = [FlSpot(0, 0), FlSpot(1, 0)];
    }

    // Auto-calculate min/max if not provided
    if (minY == null || maxY == null) {
      double min = spots.first.y;
      double max = spots.first.y;
      
      for (var spot in spots) {
        if (spot.y < min) min = spot.y;
        if (spot.y > max) max = spot.y;
      }
      
      // Add 15% padding for better visualization
      final range = max - min;
      final padding = range > 0 ? range * 0.15 : 10;
      minY ??= (min - padding).clamp(0, double.infinity);
      maxY ??= max + padding;
    }

    Color lineColor;
    Color fillColor;
    
    switch (chartType) {
      case 'Heart Rate':
        lineColor = AppColors.pastelPetal;
        fillColor = AppColors.pastelPetal.withOpacity(0.3);
        break;
      case 'SpO2':
        lineColor = AppColors.wisteriaBlue;
        fillColor = AppColors.wisteriaBlue.withOpacity(0.3);
        break;
      case 'Temperature':
        lineColor = AppColors.powderBlue;
        fillColor = AppColors.powderBlue.withOpacity(0.3);
        break;
      case 'Blood Pressure':
        lineColor = AppColors.frozenWater;
        fillColor = AppColors.frozenWater.withOpacity(0.3);
        break;
      default:
        lineColor = AppColors.wisteriaBlue;
        fillColor = AppColors.wisteriaBlue.withOpacity(0.3);
    }

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: (maxY! - minY!) / 4,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: AppColors.lightBackground.withOpacity(0.5),
            strokeWidth: 1,
            dashArray: [5, 5],
          );
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 28,
            interval: spots.length > 10 ? (spots.length / 4).ceilToDouble() : spots.length > 5 ? 2 : 1,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index >= 0 && index < spots.length) {
                // Show every nth label to avoid crowding
                if (index % _getLabelSkip(spots.length) == 0 || index == spots.length - 1) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }
              }
              return const SizedBox.shrink();
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 42,
            interval: _calculateInterval(minY, maxY),
            getTitlesWidget: (value, meta) {
              return Padding(
                padding: const EdgeInsets.only(right: 6.0),
                child: Text(
                  value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.right,
                ),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border(
          left: BorderSide(color: AppColors.lightBackground, width: 1),
          bottom: BorderSide(color: AppColors.lightBackground, width: 1),
        ),
      ),
      minX: 0,
      maxX: spots.length > 1 ? (spots.length - 1).toDouble() : 1,
      minY: minY,
      maxY: maxY,
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.3,
          color: lineColor,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: spots.length <= 15, // Show dots only if not too crowded
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 3.5,
                color: Colors.white,
                strokeWidth: 2,
                strokeColor: lineColor,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [fillColor, fillColor.withOpacity(0.0)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0.0, 1.0],
            ),
          ),
          shadow: Shadow(
            color: lineColor.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ),
      ],
      lineTouchData: LineTouchData(
        enabled: true,
        touchTooltipData: LineTouchTooltipData(
          tooltipBgColor: lineColor.withOpacity(0.9),
          tooltipRoundedRadius: 8,
          tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          fitInsideHorizontally: true,
          fitInsideVertically: true,
          getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
            return touchedBarSpots.map((barSpot) {
              return LineTooltipItem(
                '${barSpot.y.toStringAsFixed(1)}',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                children: [
                  TextSpan(
                    text: '\nReading ${barSpot.x.toInt() + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              );
            }).toList();
          },
        ),
        touchCallback: (FlTouchEvent event, LineTouchResponse? touchResponse) {},
        handleBuiltInTouches: true,
      ),
    );
  }

  // Helper method to calculate appropriate interval for Y-axis
  static double _calculateInterval(double min, double max) {
    final range = max - min;
    if (range <= 10) return 2;
    if (range <= 20) return 5;
    if (range <= 50) return 10;
    if (range <= 100) return 20;
    return 50;
  }

  // Helper method to determine label skip count
  static int _getLabelSkip(int dataPoints) {
    if (dataPoints <= 5) return 1;
    if (dataPoints <= 10) return 2;
    if (dataPoints <= 20) return 4;
    if (dataPoints <= 30) return 5;
    return 7;
  }

  // Generate spots from values
  static List<FlSpot> generateSpots(List<double> values) {
    if (values.isEmpty) return [FlSpot(0, 0)];
    
    return values.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value);
    }).toList();
  }

  // Get chart color based on value range
  static Color getChartColor(double value, double min, double max) {
    final percentage = (value - min) / (max - min);
    if (percentage < 0.3) return AppColors.frozenWater;
    if (percentage < 0.7) return AppColors.powderBlue;
    return AppColors.pastelPetal;
  }

  // Create risk distribution donut chart
  static PieChartData createRiskDistribution({
    required int lowRisk,
    required int moderateRisk,
    required int highRisk,
  }) {
    final total = lowRisk + moderateRisk + highRisk;
    
    if (total == 0) {
      return PieChartData(sections: []);
    }
    
    return PieChartData(
      sectionsSpace: 2,
      centerSpaceRadius: 40,
      sections: [
        if (lowRisk > 0)
          PieChartSectionData(
            color: AppColors.frozenWater,
            value: lowRisk.toDouble(),
            title: '${((lowRisk / total) * 100).toStringAsFixed(0)}%',
            radius: 30,
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        if (moderateRisk > 0)
          PieChartSectionData(
            color: AppColors.powderBlue,
            value: moderateRisk.toDouble(),
            title: '${((moderateRisk / total) * 100).toStringAsFixed(0)}%',
            radius: 30,
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        if (highRisk > 0)
          PieChartSectionData(
            color: AppColors.pastelPetal,
            value: highRisk.toDouble(),
            title: '${((highRisk / total) * 100).toStringAsFixed(0)}%',
            radius: 30,
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
      ],
    );
  }

  // Create bar chart for vital comparison
  static BarChartData createVitalComparison({
    required List<double> values,
    required List<String> labels,
  }) {
    if (values.isEmpty) {
      return BarChartData(barGroups: []);
    }

    return BarChartData(
      alignment: BarChartAlignment.spaceAround,
      maxY: values.reduce((a, b) => a > b ? a : b) * 1.2,
      barGroups: values.asMap().entries.map((entry) {
        final index = entry.key;
        final value = entry.value;
        
        return BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: value,
              gradient: const LinearGradient(
                colors: [
                  AppColors.wisteriaBlue,
                  AppColors.honeydew,
                ],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
              width: 20,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(6),
              ),
            ),
          ],
        );
      }).toList(),
      titlesData: FlTitlesData(
        show: true,
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index >= 0 && index < labels.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    labels[index],
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
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
            reservedSize: 40,
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
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
      ),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: AppColors.lightBackground,
            strokeWidth: 1,
          );
        },
      ),
      borderData: FlBorderData(show: false),
    );
  }
}