import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chemo_monitor_app/config/app_constants.dart';
import 'package:chemo_monitor_app/services/health_data_service.dart';

class VitalsEntryScreen extends StatefulWidget {
  const VitalsEntryScreen({super.key});

  @override
  State<VitalsEntryScreen> createState() => _VitalsEntryScreenState();
}

class _VitalsEntryScreenState extends State<VitalsEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final HealthDataService _healthDataService = HealthDataService();

  final TextEditingController _heartRateController = TextEditingController();
  final TextEditingController _spo2Controller = TextEditingController();
  final TextEditingController _systolicBPController = TextEditingController();
  final TextEditingController _diastolicBPController = TextEditingController();
  final TextEditingController _temperatureController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _heartRateController.dispose();
    _spo2Controller.dispose();
    _systolicBPController.dispose();
    _diastolicBPController.dispose();
    _temperatureController.dispose();
    _notesController.dispose();
    super.dispose();
  }

 Future<void> _submitHealthData() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() => _isSubmitting = true);

  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Not logged in');

    // Show loading with ML processing message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(width: 16),
            Text('Analyzing with AI...'),
          ],
        ),
        duration: Duration(seconds: 3),
        backgroundColor: AppColors.info,
      ),
    );

    await _healthDataService.addHealthData(
      patientId: user.uid,
      heartRate: int.parse(_heartRateController.text),
      spo2Level: int.parse(_spo2Controller.text),
      systolicBP: int.parse(_systolicBPController.text),
      diastolicBP: int.parse(_diastolicBPController.text),
      temperature: double.parse(_temperatureController.text),
      additionalNotes: _notesController.text.isEmpty 
          ? null 
          : _notesController.text,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('✅ AI Analysis Complete!'),
            ],
          ),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 2),
        ),
      );
      
      // Navigate back with success
      Navigator.pop(context, true);
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  } finally {
    setState(() => _isSubmitting = false);
  }
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enter Health Data'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppDimensions.paddingLarge),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(AppDimensions.paddingMedium),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusMedium),
                  border: Border.all(color: AppColors.info),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.info),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Enter your vitals accurately. These will be analyzed by AI.',
                        style: AppTextStyles.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              _buildNumberField(
                title: 'Heart Rate (bpm)',
                controller: _heartRateController,
                icon: Icons.favorite,
                suffix: 'bpm',
                min: 40,
                max: 200,
              ),

              _buildNumberField(
                title: 'SpO2 Level (%)',
                controller: _spo2Controller,
                icon: Icons.air,
                suffix: '%',
                min: 70,
                max: 100,
              ),

              _buildNumberField(
                title: 'Systolic BP',
                controller: _systolicBPController,
                icon: Icons.monitor_heart,
                suffix: 'mmHg',
                min: 70,
                max: 200,
              ),

              _buildNumberField(
                title: 'Diastolic BP',
                controller: _diastolicBPController,
                icon: Icons.monitor_heart_outlined,
                suffix: 'mmHg',
                min: 40,
                max: 130,
              ),

              _buildTemperatureField(),

              const SizedBox(height: 24),

              Text('Additional Notes (Optional)',
                  style: AppTextStyles.heading3),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusMedium),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitHealthData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Submit & Analyze',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumberField({
    required String title,
    required TextEditingController controller,
    required IconData icon,
    required String suffix,
    required int min,
    required int max,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.heading3),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            prefixIcon: Icon(icon),
            suffixText: suffix,
            border: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(AppDimensions.radiusMedium),
            ),
          ),
          validator: (value) {
            final val = int.tryParse(value ?? '');
            if (val == null || val < min || val > max) {
              return 'Valid range: $min-$max';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildTemperatureField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Body Temperature (°C)', style: AppTextStyles.heading3),
        const SizedBox(height: 8),
        TextFormField(
          controller: _temperatureController,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.thermostat),
            suffixText: '°C',
            border: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(AppDimensions.radiusMedium),
            ),
          ),
          validator: (value) {
            final temp = double.tryParse(value ?? '');
            if (temp == null || temp < 35 || temp > 42) {
              return 'Valid range: 35–42';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
