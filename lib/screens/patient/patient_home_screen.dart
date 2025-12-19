import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chemo_monitor_app/config/app_constants.dart';
import 'package:chemo_monitor_app/services/auth_service.dart';
import 'package:chemo_monitor_app/services/health_data_service.dart';
import 'package:chemo_monitor_app/models/health_data_model.dart';
import 'package:chemo_monitor_app/screens/patient/vitals_entry_screen.dart';
import 'package:chemo_monitor_app/screens/patient/health_history_screen.dart';
import 'package:intl/intl.dart';

class PatientHomeScreen extends StatefulWidget {
  const PatientHomeScreen({super.key});

  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> {
  final AuthService _authService = AuthService();
  final HealthDataService _healthDataService = HealthDataService();

  Future<void> _logout() async {
    await _authService.signOut();
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  void _navigateToVitalsEntry() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => VitalsEntryScreen()),
    );

    if (result == true) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text('Patient Dashboard'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: user == null
          ? Center(child: Text('Not logged in'))
          : RefreshIndicator(
              onRefresh: () async {
                setState(() {});
              },
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(AppDimensions.paddingLarge),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Card
                    Card(
                      color: AppColors.primary,
                      child: Padding(
                        padding: EdgeInsets.all(AppDimensions.paddingLarge),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome back,',
                              style: AppTextStyles.bodyLarge.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              user.email ?? 'Patient',
                              style: AppTextStyles.heading2.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 24),

                    // Latest Health Status
                    Text('Latest Health Status', style: AppTextStyles.heading3),
                    SizedBox(height: 12),
                    
                    FutureBuilder<HealthDataModel?>(
                      future: _healthDataService.getLatestHealthData(user.uid),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Center(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        final latestData = snapshot.data;

                        if (latestData == null) {
                          return Card(
                            child: Padding(
                              padding: EdgeInsets.all(AppDimensions.paddingLarge),
                              child: Column(
                                children: [
                                  Icon(Icons.add_chart, size: 60, color: Colors.grey),
                                  SizedBox(height: 16),
                                  Text('No health data yet', style: AppTextStyles.heading3),
                                  SizedBox(height: 8),
                                  Text(
                                    'Start tracking by entering your vitals',
                                    textAlign: TextAlign.center,
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        Color riskColor = AppColors.success;
                        if (latestData.riskLevel == 1) riskColor = AppColors.warning;
                        if (latestData.riskLevel == 2) riskColor = AppColors.danger;

                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: riskColor, width: 2),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(AppDimensions.paddingMedium),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      DateFormat('MMM dd, hh:mm a').format(latestData.timestamp),
                                      style: AppTextStyles.bodySmall,
                                    ),
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: riskColor.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: riskColor),
                                      ),
                                      child: Text(
                                        latestData.getRiskLevelString().toUpperCase(),
                                        style: AppTextStyles.bodySmall.copyWith(
                                          color: riskColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    _QuickStat(
                                      icon: Icons.favorite,
                                      label: 'Heart',
                                      value: '${latestData.heartRate}',
                                      color: Colors.red,
                                    ),
                                    _QuickStat(
                                      icon: Icons.air,
                                      label: 'SpO2',
                                      value: '${latestData.spo2Level}%',
                                      color: Colors.blue,
                                    ),
                                    _QuickStat(
                                      icon: Icons.thermostat,
                                      label: 'Temp',
                                      value: '${latestData.temperature}°',
                                      color: Colors.pink,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    SizedBox(height: 24),

                    // Quick Actions
                    Text('Quick Actions', style: AppTextStyles.heading3),
                    SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: _ActionCard(
                            icon: Icons.add_chart,
                            label: 'Enter Vitals',
                            color: AppColors.primary,
                            onTap: _navigateToVitalsEntry,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _ActionCard(
                            icon: Icons.history,
                            label: 'View History',
                            color: AppColors.accent,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => HealthHistoryScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: _ActionCard(
                            icon: Icons.chat,
                            label: 'AI Assistant',
                            color: Colors.purple,
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Coming soon!')),
                              );
                            },
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _ActionCard(
                            icon: Icons.message,
                            label: 'Message Doctor',
                            color: Colors.green,
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Coming soon!')),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _QuickStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _QuickStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        SizedBox(height: 4),
        Text(value, style: AppTextStyles.heading3.copyWith(color: color)),
        Text(label, style: AppTextStyles.bodySmall),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(AppDimensions.paddingMedium),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 40),
              SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}