import 'package:flutter/material.dart';
import 'package:chemo_monitor_app/config/app_constants.dart';
import 'package:chemo_monitor_app/models/health_data_model.dart';
import 'package:chemo_monitor_app/services/health_data_service.dart';
import 'package:chemo_monitor_app/screens/shared/chat_screen.dart'; // Import your chat screen
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  String _patientName = 'Loading...';

  @override
  void initState() {
    super.initState();
    _fetchPatientName();
  }

  Future<void> _fetchPatientName() async {
    try {
      var doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.patientId)
          .get();
      if (doc.exists && mounted) {
        setState(() {
          _patientName = doc.data()?['name'] ?? 'Patient';
        });
      }
    } catch (e) {
      if (mounted) setState(() => _patientName = 'Patient');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_patientName, style: TextStyle(fontSize: 18)),
            Text(
              widget.patientEmail,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.message),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatScreen(
                    otherUserId: widget.patientId,
                    otherUserName: _patientName,
                    otherUserRole: 'patient',
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<HealthDataModel>>(
        // We need a method in HealthDataService to stream specific user data
        // If you don't have a stream method, we can use a FutureBuilder or direct Firestore stream
        stream: FirebaseFirestore.instance
            .collection('health_data')
            .where('patientId', isEqualTo: widget.patientId)
            .orderBy('timestamp', descending: true)
            .snapshots()
            .map((snapshot) => snapshot.docs
                .map((doc) => HealthDataModel.fromMap(doc.data()))
                .toList()),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error loading history'));
          }

          final logs = snapshot.data ?? [];

          if (logs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No vitals recorded yet', style: AppTextStyles.heading3),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(AppDimensions.paddingMedium),
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index];
              return _HealthLogCard(log: log);
            },
          );
        },
      ),
    );
  }
}

class _HealthLogCard extends StatelessWidget {
  final HealthDataModel log;

  const _HealthLogCard({required this.log});

  @override
  Widget build(BuildContext context) {
    Color riskColor = AppColors.success;
    String riskText = "Stable";
    
    if (log.riskLevel == 1) {
      riskColor = AppColors.warning;
      riskText = "Moderate";
    } else if (log.riskLevel == 2) {
      riskColor = AppColors.danger;
      riskText = "High Risk";
    }

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: riskColor.withOpacity(0.5)),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('MMM dd, yyyy - hh:mm a').format(log.timestamp),
                  style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: riskColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: riskColor),
                  ),
                  child: Text(
                    riskText,
                    style: TextStyle(color: riskColor, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _DetailItem(icon: Icons.favorite, value: "${log.heartRate}", unit: "bpm", label: "HR"),
                _DetailItem(icon: Icons.air, value: "${log.spo2Level}", unit: "%", label: "SpO2"),
                _DetailItem(icon: Icons.thermostat, value: "${log.temperature}", unit: "°C", label: "Temp"),
              ],
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                 Icon(Icons.speed, size: 16, color: AppColors.textSecondary),
                 SizedBox(width: 4),
                 Text("BP: ${log.systolicBP}/${log.diastolicBP} mmHg", style: AppTextStyles.bodyMedium),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String unit;
  final String label;

  const _DetailItem({
    required this.icon,
    required this.value,
    required this.unit,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        SizedBox(height: 4),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: value,
                style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              TextSpan(
                text: unit,
                style: TextStyle(color: Colors.grey, fontSize: 10),
              ),
            ],
          ),
        ),
        Text(label, style: TextStyle(color: Colors.grey, fontSize: 10)),
      ],
    );
  }
}