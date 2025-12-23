import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:chemo_monitor_app/config/app_constants.dart';

class ChartUtils {
  static LineChartData sampleLineData(List<FlSpot> spots) {
    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        horizontalInterval: 1,
        verticalInterval: 1,
        getDrawingHorizontalLine: (value) {
          return const FlLine(
            color: AppColors.lightBlue,
            strokeWidth: 1,
          );
        },
        getDrawingVerticalLine: (value) {
          return const FlLine(
            color: AppColors.lightBlue,
            strokeWidth: 1,
          );
        },
      ),
      titlesData: const FlTitlesData(
        show: true,
        rightTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 1,
            getTitlesWidget: bottomTitleWidgets,
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 1,
            getTitlesWidget: leftTitleWidgets,
            reservedSize: 42,
          ),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: AppColors.lightBlue),
      ),
      minX: 0,
      maxX: 11,
      minY: 0,
      maxY: 6,
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          gradient: LinearGradient(
            colors: [
              AppColors.primaryBlue.withOpacity(0.5),
              AppColors.softPurple,
            ],
          ),
          barWidth: 5,
          isStrokeCapRound: true,
          dotData: const FlDotData(
            show: false,
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                AppColors.primaryBlue.withOpacity(0.3),
                AppColors.primaryBlue.withOpacity(0.1),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static Widget bottomTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      color: AppColors.textSecondary,
      fontWeight: FontWeight.bold,
      fontSize: 12,
    );
    Widget text;
    switch (value.toInt()) {
      case 2:
        text = const Text('MAR', style: style);
        break;
      case 5:
        text = const Text('JUN', style: style);
        break;
      case 8:
        text = const Text('SEP', style: style);
        break;
      default:
        text = const Text('', style: style);
        break;
    }

    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: text,
    );
  }

  static Widget leftTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      color: AppColors.textSecondary,
      fontWeight: FontWeight.bold,
      fontSize: 12,
    );
    String text;
    switch (value.toInt()) {
      case 1:
        text = '10k';
        break;
      case 3:
        text = '30k';
        break;
      case 5:
        text = '50k';
        break;
      default:
        return Container();
    }

    return Text(text, style: style, textAlign: TextAlign.left);
  }

  static List<FlSpot> generateSpots(List<double> values) {
    return values.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value);
    }).toList();
  }

  static Color getChartColor(double value, double min, double max) {
    final percentage = (value - min) / (max - min);
    if (percentage < 0.3) return AppColors.riskLow;
    if (percentage < 0.7) return AppColors.riskModerate;
    return AppColors.riskHigh;
  }

  // New: Create gradient line chart for health data
  static LineChartData createHealthChart({
    required List<FlSpot> spots,
    required String chartType,
    double minY = 0,
    double maxY = 100,
  }) {
    Color lineColor;
    Color fillColor;
    
    switch (chartType) {
      case 'Heart Rate':
        lineColor = AppColors.riskHigh;
        fillColor = AppColors.riskHigh.withOpacity(0.3);
        break;
      case 'SpO2':
        lineColor = AppColors.primaryBlue;
        fillColor = AppColors.primaryBlue.withOpacity(0.3);
        break;
      case 'Temperature':
        lineColor = AppColors.riskModerate;
        fillColor = AppColors.riskModerate.withOpacity(0.3);
        break;
      case 'Blood Pressure':
        lineColor = AppColors.softPurple;
        fillColor = AppColors.softPurple.withOpacity(0.3);
        break;
      default:
        lineColor = AppColors.primaryBlue;
        fillColor = AppColors.primaryBlue.withOpacity(0.3);
    }

    return LineChartData(
      gridData: const FlGridData(show: false),
      titlesData: const FlTitlesData(show: false),
      borderData: FlBorderData(show: false),
      minX: 0,
      maxX: spots.length > 1 ? (spots.length - 1).toDouble() : 1,
      minY: minY,
      maxY: maxY,
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: lineColor,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [fillColor, fillColor.withOpacity(0.1)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
    );
  }

  // New: Create donut chart for risk distribution
  static PieChartData createRiskDistribution({
    required int lowRisk,
    required int moderateRisk,
    required int highRisk,
  }) {
    final total = lowRisk + moderateRisk + highRisk;
    
    return PieChartData(
      sectionsSpace: 2,
      centerSpaceRadius: 40,
      sections: [
        PieChartSectionData(
          color: AppColors.riskLow,
          value: lowRisk.toDouble(),
          title: '${((lowRisk / total) * 100).toStringAsFixed(0)}%',
          radius: 25,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        PieChartSectionData(
          color: AppColors.riskModerate,
          value: moderateRisk.toDouble(),
          title: '${((moderateRisk / total) * 100).toStringAsFixed(0)}%',
          radius: 25,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        PieChartSectionData(
          color: AppColors.riskHigh,
          value: highRisk.toDouble(),
          title: '${((highRisk / total) * 100).toStringAsFixed(0)}%',
          radius: 25,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  // New: Create bar chart for vital comparison
  static BarChartData createVitalComparison({
    required List<double> values,
    required List<String> labels,
    required String unit,
  }) {
    return BarChartData(
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
                  AppColors.primaryBlue,
                  AppColors.softPurple,
                ],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
              width: 16,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        );
      }).toList(),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index < labels.length) {
                return Text(
                  labels[index],
                  style: const TextStyle(
                    fontSize: 10,
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
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
              );
            },
          ),
        ),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      gridData: const FlGridData(show: false),
      borderData: FlBorderData(show: false),
    );
  }
}