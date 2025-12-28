// lib/screens/patient/vitals_result_screen.dart
import 'package:flutter/material.dart';
import 'package:chemo_monitor_app/models/health_data_model.dart';
import 'package:chemo_monitor_app/config/app_constants.dart';
import 'package:chemo_monitor_app/widgets/common/glass_card.dart';
import 'package:chemo_monitor_app/widgets/common/glass_button.dart';
import 'package:intl/intl.dart';

class VitalsResultScreen extends StatelessWidget {
  final HealthDataModel healthData;
  
  const VitalsResultScreen({super.key, required this.healthData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mainBackground,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          'Risk Assessment',
          style: AppTextStyles.heading3.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.lightBlue,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.arrow_back_rounded,
              color: AppColors.wisteriaBlue,
              size: 20,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.paddingLarge),
        child: Column(
          children: [
            // Risk Level Card
            GlassCard(
              padding: const EdgeInsets.all(AppDimensions.paddingLarge),
              child: Column(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: _getRiskColor(healthData.riskLevel ?? 0).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusXXL),
                      border: Border.all(
                        color: _getRiskColor(healthData.riskLevel ?? 0).withOpacity(0.3),
                        width: 3,
                      ),
                    ),
                    child: Icon(
                      _getRiskIcon(healthData.riskLevel ?? 0),
                      size: 60,
                      color: _getRiskColor(healthData.riskLevel ?? 0),
                    ),
                  ),
                  
                  const SizedBox(height: AppDimensions.spaceXL),
                  
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.paddingLarge,
                      vertical: AppDimensions.paddingSmall,
                    ),
                    decoration: BoxDecoration(
                      color: _getRiskColor(healthData.riskLevel ?? 0).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
                      border: Border.all(
                        color: _getRiskColor(healthData.riskLevel ?? 0).withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      healthData.getRiskLevelString().toUpperCase(),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _getRiskColor(healthData.riskLevel ?? 0),
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: AppDimensions.spaceL),
                  
                  Text(
                    healthData.getRiskDescription(),
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  
                  const SizedBox(height: AppDimensions.spaceM),
                  
                  // Timestamp
                  Text(
                    'Recorded: ${DateFormat('MMM dd, yyyy • hh:mm a').format(healthData.timestamp)}',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: AppDimensions.spaceXL),
            
            // Vitals Summary
            GlassCard(
              padding: const EdgeInsets.all(AppDimensions.paddingLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.favorite_rounded,
                        color: AppColors.wisteriaBlue,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Your Vitals',
                        style: AppTextStyles.heading3.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: AppDimensions.spaceL),
                  
                  _buildVitalItem(
                    icon: Icons.favorite_rounded,
                    label: 'Heart Rate',
                    value: '${healthData.heartRate} bpm',
                    color: AppColors.pastelPetal,
                  ),
                  
                  _buildVitalItem(
                    icon: Icons.air_rounded,
                    label: 'Oxygen Level',
                    value: '${healthData.spo2Level}%',
                    color: AppColors.wisteriaBlue,
                  ),
                  
                  _buildVitalItem(
                    icon: Icons.monitor_heart_rounded,
                    label: 'Blood Pressure',
                    value: '${healthData.systolicBP}/${healthData.diastolicBP} mmHg',
                    color: AppColors.frozenWater,
                  ),
                  
                  _buildVitalItem(
                    icon: Icons.thermostat_rounded,
                    label: 'Temperature',
                    value: '${healthData.temperature.toStringAsFixed(1)}°C',
                    color: AppColors.riskModerate,
                    isLast: true,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: AppDimensions.spaceXL),
            
            // ML Confidence (if available)
            if (healthData.mlOutputProbabilities != null)
              GlassCard(
                padding: const EdgeInsets.all(AppDimensions.paddingLarge),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.psychology_rounded,
                          color: AppColors.wisteriaBlue,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'AI Prediction Confidence',
                          style: AppTextStyles.heading3.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: AppDimensions.spaceL),
                    
                    _buildConfidenceBar(
                      'Low Risk',
                      healthData.mlOutputProbabilities![0],
                      AppColors.riskLow,
                      healthData.riskLevel == 0,
                    ),
                    
                    const SizedBox(height: AppDimensions.spaceM),
                    
                    _buildConfidenceBar(
                      'Moderate Risk',
                      healthData.mlOutputProbabilities![1],
                      AppColors.riskModerate,
                      healthData.riskLevel == 1,
                    ),
                    
                    const SizedBox(height: AppDimensions.spaceM),
                    
                    _buildConfidenceBar(
                      'High Risk',
                      healthData.mlOutputProbabilities![2],
                      AppColors.riskHigh,
                      healthData.riskLevel == 2,
                    ),
                  ],
                ),
              ),
            
            if (healthData.mlOutputProbabilities != null)
              const SizedBox(height: AppDimensions.spaceXL),
            
            // Recommended Actions
            GlassCard(
              padding: const EdgeInsets.all(AppDimensions.paddingLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.medical_information_rounded,
                        color: AppColors.wisteriaBlue,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Recommended Actions',
                        style: AppTextStyles.heading3.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: AppDimensions.spaceL),
                  
                  Container(
                    padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                    decoration: BoxDecoration(
                      color: _getRiskColor(healthData.riskLevel ?? 0).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                      border: Border.all(
                        color: _getRiskColor(healthData.riskLevel ?? 0).withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      healthData.getRecommendedAction(),
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                        height: 1.6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Additional Notes (if any)
            if (healthData.additionalNotes != null && healthData.additionalNotes!.isNotEmpty) ...[
              const SizedBox(height: AppDimensions.spaceXL),
              GlassCard(
                padding: const EdgeInsets.all(AppDimensions.paddingLarge),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.note_rounded,
                          color: AppColors.wisteriaBlue,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Your Notes',
                          style: AppTextStyles.heading3.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.spaceM),
                    Text(
                      healthData.additionalNotes!,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: AppDimensions.spaceXXXL),
            
            
            SizedBox(
              width: double.infinity,
              child: GlassButton(
                text: 'Done',
                type: ButtonType.primary,
                onPressed: () => Navigator.pop(context),
                height: AppDimensions.buttonHeight,
              ),
            ),
            
            const SizedBox(height: AppDimensions.spaceL),
          ],
        ),
      ),
    );
  }
  
  Widget _buildVitalItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    bool isLast = false,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (!isLast) ...[
          const SizedBox(height: AppDimensions.spaceM),
          Divider(height: 1, color: AppColors.lightBlue),
          const SizedBox(height: AppDimensions.spaceM),
        ],
      ],
    );
  }
  
  Widget _buildConfidenceBar(
    String label,
    double probability,
    Color color,
    bool isActive,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isActive ? color : AppColors.textSecondary,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            Text(
              '${(probability * 100).toStringAsFixed(1)}%',
              style: AppTextStyles.bodyMedium.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: AppColors.lightBlue,
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            widthFactor: probability,
            alignment: Alignment.centerLeft,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  Color _getRiskColor(int riskLevel) {
    switch (riskLevel) {
      case 0: return AppColors.riskLow;
      case 1: return AppColors.riskModerate;
      case 2: return AppColors.riskHigh;
      default: return AppColors.textSecondary;
    }
  }
  
  IconData _getRiskIcon(int riskLevel) {
    switch (riskLevel) {
      case 0: return Icons.check_circle_rounded;
      case 1: return Icons.warning_amber_rounded;
      case 2: return Icons.error_rounded;
      default: return Icons.help_outline_rounded;
    }
  }
}