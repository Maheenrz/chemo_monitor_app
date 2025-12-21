import 'package:flutter/material.dart';
import 'package:chemo_monitor_app/config/app_constants.dart';

class MLConfidenceWidget extends StatelessWidget {
  final List<double> probabilities;
  final int predictedRiskLevel;

  const MLConfidenceWidget({
    super.key,
    required this.probabilities,
    required this.predictedRiskLevel,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(AppDimensions.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.psychology, color: AppColors.primary, size: 20),
                SizedBox(width: 8),
                Text(
                  'AI Prediction Confidence',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            _buildConfidenceBar('Low Risk', probabilities[0], 0),
            SizedBox(height: 8),
            _buildConfidenceBar('Moderate Risk', probabilities[1], 1),
            SizedBox(height: 8),
            _buildConfidenceBar('High Risk', probabilities[2], 2),
          ],
        ),
      ),
    );
  }

  Widget _buildConfidenceBar(String label, double probability, int level) {
    Color color = _getColorForLevel(level);
    bool isActive = level == predictedRiskLevel;
    double percentage = probability * 100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive ? color : AppColors.textSecondary,
              ),
            ),
            Text(
              '${percentage.toStringAsFixed(1)}%',
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        SizedBox(height: 4),
        LinearProgressIndicator(
          value: probability,
          backgroundColor: color.withOpacity(0.2),
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: isActive ? 8 : 6,
        ),
      ],
    );
  }

  Color _getColorForLevel(int level) {
    switch (level) {
      case 0:
        return AppColors.success;
      case 1:
        return AppColors.warning;
      case 2:
        return AppColors.danger;
      default:
        return AppColors.textSecondary;
    }
  }
}