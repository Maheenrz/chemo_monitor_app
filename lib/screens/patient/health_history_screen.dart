import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chemo_monitor_app/config/app_constants.dart';
import 'package:chemo_monitor_app/models/health_data_model.dart';
import 'package:chemo_monitor_app/services/health_data_service.dart';
import 'package:intl/intl.dart';
import 'package:chemo_monitor_app/widgets/common/ml_confidence_widget.dart';

class HealthHistoryScreen extends StatelessWidget {
  const HealthHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        body: Center(child: Text('Not logged in')),
      );
    }

    final HealthDataService healthDataService = HealthDataService();

    return Scaffold(
      appBar: AppBar(
        title: Text('Health History'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<HealthDataModel>>(
        stream: healthDataService.getPatientHealthData(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final healthDataList = snapshot.data ?? [];

          if (healthDataList.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No health data yet', style: AppTextStyles.heading3),
                  SizedBox(height: 8),
                  Text(
                    'Start by entering your vitals',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(AppDimensions.paddingMedium),
            itemCount: healthDataList.length,
            itemBuilder: (context, index) {
              return _HealthDataCard(data: healthDataList[index]);
            },
          );
        },
      ),
    );
  }
}

class _HealthDataCard extends StatelessWidget {
  final HealthDataModel data;

  const _HealthDataCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy - hh:mm a');

    Color riskColor = AppColors.success;
    if (data.riskLevel == 1) riskColor = AppColors.warning;
    if (data.riskLevel == 2) riskColor = AppColors.danger;

    return Card(
      margin: EdgeInsets.only(bottom: AppDimensions.paddingMedium),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        side: BorderSide(color: riskColor, width: 2),
      ),
      child: Padding(
        padding: EdgeInsets.all(AppDimensions.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dateFormat.format(data.timestamp),
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: riskColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: riskColor),
                  ),
                  child: Text(
                    data.getRiskLevelString().toUpperCase(),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: riskColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            Divider(height: 20),

            // Vitals
            Row(
              children: [
                Expanded(
                  child: _VitalItem(
                    icon: Icons.favorite,
                    color: Colors.red,
                    label: 'Heart Rate',
                    value: '${data.heartRate} bpm',
                  ),
                ),
                Expanded(
                  child: _VitalItem(
                    icon: Icons.air,
                    color: Colors.blue,
                    label: 'SpO2',
                    value: '${data.spo2Level}%',
                  ),
                ),
              ],
            ),

            SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _VitalItem(
                    icon: Icons.monitor_heart,
                    color: Colors.orange,
                    label: 'BP (S/D)',
                    value: '${data.systolicBP}/${data.diastolicBP}',
                  ),
                ),
                Expanded(
                  child: _VitalItem(
                    icon: Icons.thermostat,
                    color: Colors.pink,
                    label: 'Temp',
                    value: '${data.temperature}°C',
                  ),
                ),
              ],
            ),

            // ✅ CHANGED: Use the new MLConfidenceWidget
            if (data.mlOutputProbabilities != null) ...[
              SizedBox(height: 12),
              MLConfidenceWidget(
                probabilities: data.mlOutputProbabilities!,
                predictedRiskLevel: data.riskLevel ?? 0,
              ),
            ],

            // Notes
            if (data.additionalNotes != null && data.additionalNotes!.isNotEmpty) ...[
              Divider(height: 20),
              Text('Notes:', style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.bold,
              )),
              SizedBox(height: 4),
              Text(data.additionalNotes!, style: AppTextStyles.bodyMedium),
            ],
          ],
        ),
      ),
    );
  }
}

class _VitalItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const _VitalItem({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            )),
            Text(value, style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
            )),
          ],
        ),
      ],
    );
  }
}