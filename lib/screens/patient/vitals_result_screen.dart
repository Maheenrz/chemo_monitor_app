import 'package:flutter/material.dart';
import 'package:chemo_monitor_app/models/health_data_model.dart';
import 'package:chemo_monitor_app/config/app_constants.dart';
import 'package:chemo_monitor_app/widgets/common/glass_card.dart';
import 'package:chemo_monitor_app/widgets/common/glass_button.dart';

class VitalsResultScreen extends StatelessWidget {
  final HealthDataModel healthData;
  
  const VitalsResultScreen({super.key, required this.healthData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mainBackground,
      appBar: AppBar(
        title: Text('Risk Assessment'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppDimensions.paddingLarge),
        child: Column(
          children: [
            // Risk Level Card
            GlassCard(
              padding: EdgeInsets.all(AppDimensions.paddingLarge),
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: _getRiskColor(healthData.riskLevel ?? 0).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusXXL),
                    ),
                    child: Icon(
                      _getRiskIcon(healthData.riskLevel ?? 0),
                      size: 50,
                      color: _getRiskColor(healthData.riskLevel ?? 0),
                    ),
                  ),
                  SizedBox(height: AppDimensions.spaceL),
                  Text(
                    healthData.getRiskLevelString().toUpperCase(),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _getRiskColor(healthData.riskLevel ?? 0),
                    ),
                  ),
                  SizedBox(height: AppDimensions.spaceM),
                  Text(
                    healthData.getRiskDescription(),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: AppDimensions.spaceL),
            
            // Vitals Summary
            GlassCard(
              padding: EdgeInsets.all(AppDimensions.paddingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Vitals',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: AppDimensions.spaceM),
                  _buildVitalItem('Heart Rate', '${healthData.heartRate} bpm'),
                  _buildVitalItem('Oxygen Level', '${healthData.spo2Level}%'),
                  _buildVitalItem('Blood Pressure', '${healthData.systolicBP}/${healthData.diastolicBP} mmHg'),
                  _buildVitalItem('Temperature', '${healthData.temperature.toStringAsFixed(1)}°C'),
                ],
              ),
            ),
            
            SizedBox(height: AppDimensions.spaceL),
            
            // Recommended Actions
            GlassCard(
              padding: EdgeInsets.all(AppDimensions.paddingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recommended Actions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: AppDimensions.spaceM),
                  Text(healthData.getRecommendedAction()),
                ],
              ),
            ),
            
            SizedBox(height: AppDimensions.spaceL),
            
            // Buttons
            Row(
              children: [
                Expanded(
                  child: GlassButton(
                    text: 'Done',
                    type: ButtonType.primary,
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                SizedBox(width: AppDimensions.spaceM),
                Expanded(
                  child: GlassButton(
                    text: 'Share Results',
                    type: ButtonType.secondary,
                    onPressed: () {
                      // TODO: Implement share functionality
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildVitalItem(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppDimensions.spaceS),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: AppColors.textSecondary),
          ),
          Text(
            value,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
  
  Color _getRiskColor(int riskLevel) {
    switch (riskLevel) {
      case 0: return AppColors.riskLow;
      case 1: return AppColors.riskModerate;
      case 2: return AppColors.riskHigh;
      default: return Colors.grey;
    }
  }
  
  IconData _getRiskIcon(int riskLevel) {
    switch (riskLevel) {
      case 0: return Icons.check_circle;
      case 1: return Icons.warning;
      case 2: return Icons.error;
      default: return Icons.help;
    }
  }
}