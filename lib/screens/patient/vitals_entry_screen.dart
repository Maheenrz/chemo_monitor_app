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

  // Controllers for the 5 ML model inputs
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Health data saved successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
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
        title: Text('Enter Health Data'),
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
              // Instructions
              Container(
                padding: EdgeInsets.all(AppDimensions.paddingMedium),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                  border: Border.all(color: AppColors.info),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.info),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Enter your vitals accurately. These will be analyzed by AI.',
                        style: AppTextStyles.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 24),

              // 1. Heart Rate
              Text('Heart Rate (bpm)', style: AppTextStyles.heading3),
              SizedBox(height: 8),
              TextFormField(
                controller: _heartRateController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'e.g., 75',
                  prefixIcon: Icon(Icons.favorite, color: Colors.red),
                  suffixText: 'bpm',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  final rate = int.tryParse(value);
                  if (rate == null || rate < 40 || rate > 200) {
                    return 'Valid range: 40-200';
                  }
                  return null;
                },
              ),

              SizedBox(height: 20),

              // 2. SpO2 Level
              Text('SpO2 Level (%)', style: AppTextStyles.heading3),
              SizedBox(height: 8),
              TextFormField(
                controller: _spo2Controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'e.g., 98',
                  prefixIcon: Icon(Icons.air, color: Colors.blue),
                  suffixText: '%',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  final spo2 = int.tryParse(value);
                  if (spo2 == null || spo2 < 70 || spo2 > 100) {
                    return 'Valid range: 70-100';
                  }
                  return null;
                },
              ),

              SizedBox(height: 20),

              // 3. Systolic BP
              Text('Systolic Blood Pressure', style: AppTextStyles.heading3),
              SizedBox(height: 8),
              TextFormField(
                controller: _systolicBPController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'e.g., 120',
                  prefixIcon: Icon(Icons.monitor_heart, color: Colors.orange),
                  suffixText: 'mmHg',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  final bp = int.tryParse(value);
                  if (bp == null || bp < 70 || bp > 200) {
                    return 'Valid range: 70-200';
                  }
                  return null;
                },
              ),

              SizedBox(height: 20),

              // 4. Diastolic BP
              Text('Diastolic Blood Pressure', style: AppTextStyles.heading3),
              SizedBox(height: 8),
              TextFormField(
                controller: _diastolicBPController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'e.g., 80',
                  prefixIcon: Icon(Icons.monitor_heart_outlined, color: Colors.purple),
                  suffixText: 'mmHg',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  final bp = int.tryParse(value);
                  if (bp == null || bp < 40 || bp < 130) {
                    return 'Valid range: 40-130';
                  }
                  return null;
                },
              ),

              SizedBox(height: 20),

              // 5. Temperature
              Text('Body Temperature (°C)', style: AppTextStyles.heading3),
              SizedBox(height: 8),
              TextFormField(
                controller: _temperatureController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  hintText: 'e.g., 37.0',
                  prefixIcon: Icon(Icons.thermostat, color: Colors.pink),
                  suffixText: '°C',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  final temp = double.tryParse(value);
                  if (temp == null || temp < 35.0 || temp > 42.0) {
                    return 'Valid range: 35-42';
                  }
                  return null;
                },
              ),

              SizedBox(height: 24),

              // Additional Notes
              Text('Additional Notes (Optional)', style: AppTextStyles.heading3),
              SizedBox(height: 8),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Any symptoms or observations...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                  ),
                ),
              ),

              SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitHealthData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                    ),
                  ),
                  child: _isSubmitting
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Submit & Analyze',
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}