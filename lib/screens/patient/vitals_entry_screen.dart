import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chemo_monitor_app/config/app_constants.dart';
import 'package:chemo_monitor_app/services/health_data_service.dart';
import 'package:chemo_monitor_app/services/vitals_validator.dart';
import 'package:chemo_monitor_app/widgets/common/glass_card.dart';
import 'package:chemo_monitor_app/widgets/common/glass_button.dart';
import 'package:chemo_monitor_app/screens/patient/vitals_result_screen.dart';

class VitalsEntryScreen extends StatefulWidget {
  const VitalsEntryScreen({super.key});

  @override
  State<VitalsEntryScreen> createState() => _VitalsEntryScreenState();
}

class _VitalsEntryScreenState extends State<VitalsEntryScreen>
    with SingleTickerProviderStateMixin {
  final HealthDataService _healthDataService = HealthDataService();
  final PageController _pageController = PageController();

  // Form Controllers
  final TextEditingController _heartRateController = TextEditingController();
  final TextEditingController _spo2Controller = TextEditingController();
  final TextEditingController _systolicBPController = TextEditingController();
  final TextEditingController _diastolicBPController = TextEditingController();
  final TextEditingController _temperatureController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  // State
  int _currentStep = 0;
  bool _isSubmitting = false;
  final List<String> _steps = [
    'Heart Rate',
    'SpO2',
    'Blood Pressure',
    'Temperature',
    'Review'
  ];

  // Validation state
  final Map<String, bool> _fieldValid = {
    'heartRate': false,
    'spo2': false,
    'systolicBP': false,
    'diastolicBP': false,
    'temperature': false,
  };

  // Animation
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: AppAnimations.normal,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack,
      ),
    );

    _animationController.forward();
    
    // Initialize ML model
    _initializeML();
  }

  Future<void> _initializeML() async {
    try {
      await _healthDataService.initializeMLModel();
    } catch (e) {
      print('⚠️ ML initialization warning: $e');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    _heartRateController.dispose();
    _spo2Controller.dispose();
    _systolicBPController.dispose();
    _diastolicBPController.dispose();
    _temperatureController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _steps.length - 1) {
      _pageController.nextPage(
        duration: Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep++);
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep--);
    }
  }

  Future<void> _submitVitals() async {
    // 1. Validate all fields are filled
    if (!_validateForm()) {
      _showSnackBar('Please fill all required fields', AppColors.riskModerate);
      return;
    }

    // 2. Parse values
    final heartRate = int.tryParse(_heartRateController.text);
    final spo2 = int.tryParse(_spo2Controller.text);
    final systolicBP = int.tryParse(_systolicBPController.text);
    final diastolicBP = int.tryParse(_diastolicBPController.text);
    final temperature = double.tryParse(_temperatureController.text);

    if (heartRate == null || spo2 == null || systolicBP == null || 
        diastolicBP == null || temperature == null) {
      _showSnackBar('Please enter valid numbers', AppColors.riskModerate);
      return;
    }

    // 3. Run advanced validation
    final validation = VitalsValidator.validate(
      heartRate: heartRate,
      spo2: spo2,
      systolicBP: systolicBP,
      diastolicBP: diastolicBP,
      temperature: temperature,
    );

    if (!validation.isValid) {
      _showValidationDialog(validation);
      return;
    }

    // 4. Check for emergency values
    if (VitalsValidator.isInEmergencyRange(
      heartRate: heartRate,
      spo2: spo2,
      systolicBP: systolicBP,
      diastolicBP: diastolicBP,
      temperature: temperature,
    )) {
      _showEmergencyAlert(heartRate, spo2, systolicBP, diastolicBP, temperature);
      return;
    }

    // 5. Show warnings if any
    if (validation.hasWarnings || validation.hasAlerts) {
      await _showWarningDialog(validation);
    }

    // 6. Proceed with submission
    _proceedWithSubmission(
      heartRate, spo2, systolicBP, diastolicBP, temperature
    );
  }

  void _proceedWithSubmission(
  int heartRate, 
  int spo2, 
  int systolicBP, 
  int diastolicBP, 
  double temperature
) async {
  setState(() => _isSubmitting = true);

  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Not logged in');

    // Submit to health data service (includes ML)
    final healthDataId = await _healthDataService.addHealthData(
      patientId: user.uid,
      heartRate: heartRate,
      spo2Level: spo2,
      systolicBP: systolicBP,
      diastolicBP: diastolicBP,
      temperature: temperature,
      additionalNotes:
          _notesController.text.isEmpty ? null : _notesController.text,
    );

    print('✅ Health data submitted successfully: $healthDataId');

    // Get the newly created health data
    final latestData = await _healthDataService.getLatestHealthData(user.uid);
    
    if (latestData != null && mounted) {
      // Navigate to results screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => VitalsResultScreen(healthData: latestData),
        ),
      );
    } else {
      if (mounted) {
        _showSnackBar('Vitals submitted! Analysis complete.', AppColors.softGreen);
        Navigator.pop(context, true);
      }
    }
  } catch (e) {
    print('❌ Error submitting vitals: $e');
    if (mounted) {
      _showSnackBar('Error: ${e.toString()}', AppColors.riskHigh);
      setState(() => _isSubmitting = false);
    }
  }
}

  bool _validateForm() {
    return _heartRateController.text.isNotEmpty &&
        _spo2Controller.text.isNotEmpty &&
        _systolicBPController.text.isNotEmpty &&
        _diastolicBPController.text.isNotEmpty &&
        _temperatureController.text.isNotEmpty;
  }

  void _showValidationDialog(ValidationResult validation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('❌ Validation Errors'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Please correct the following:'),
            SizedBox(height: 10),
            ...validation.errors.map((error) => 
              Text('• $error', style: TextStyle(color: AppColors.riskHigh))
            ).toList(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showEmergencyAlert(
    int heartRate, int spo2, int systolicBP, int diastolicBP, double temperature
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 10),
            Text('🚨 EMERGENCY ALERT'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('CRITICAL VITAL SIGNS DETECTED:', 
                  style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 15),
              if (spo2 < 90) Text('• Oxygen critically low: $spo2%'),
              if (heartRate > 150) Text('• Heart rate dangerously high: $heartRate bpm'),
              if (heartRate < 40) Text('• Heart rate dangerously low: $heartRate bpm'),
              if (temperature > 39.0) Text('• High fever: ${temperature.toStringAsFixed(1)}°C'),
              if (temperature < 35.5) Text('• Dangerously low temperature: ${temperature.toStringAsFixed(1)}°C'),
              if (systolicBP > 180) Text('• Severely high blood pressure: $systolicBP mmHg'),
              if (diastolicBP > 120) Text('• Severely high diastolic pressure: $diastolicBP mmHg'),
              SizedBox(height: 15),
              Text('RECOMMENDED ACTION:', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              Text('1. Contact your oncology team IMMEDIATELY\n'
                  '2. If unavailable, call emergency services\n'
                  '3. Rest and avoid exertion\n'
                  '4. Have someone stay with you'),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: Text('CANCEL'),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: Text('PROCEED ANYWAY'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              _proceedWithSubmission(
                heartRate, spo2, systolicBP, diastolicBP, temperature
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showWarningDialog(ValidationResult validation) async {
    if (!validation.hasWarnings && !validation.hasAlerts) return;
    
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(validation.hasAlerts ? '⚠️ Alerts' : 'ℹ️ Notices'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (validation.hasAlerts) ...[
                Text('Medical alerts detected:'),
                SizedBox(height: 10),
                ...validation.alerts.map((alert) => 
                  Text('• $alert', style: TextStyle(color: Colors.orange))
                ).toList(),
                SizedBox(height: 15),
              ],
              if (validation.hasWarnings) ...[
                Text('Warning signs:'),
                SizedBox(height: 10),
                ...validation.warnings.map((warning) => 
                  Text('• $warning', style: TextStyle(color: Colors.blue))
                ).toList(),
              ],
              SizedBox(height: 15),
              Text('Would you like to continue with submission?'),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: Text('EDIT VALUES'),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: Text('CONTINUE'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mainBackground,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Container(
            padding: EdgeInsets.all(AppDimensions.spaceS),
            decoration: BoxDecoration(
              color: AppColors.lightBlue,
              borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
            ),
            child: Icon(
              Icons.arrow_back_rounded,
              size: AppDimensions.iconS,
              color: AppColors.primaryBlue,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Enter Vitals',
          style: AppTextStyles.heading3.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnimation.value,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: child,
            ),
          );
        },
        child: Column(
          children: [
            // Progress Bar
            _buildProgressBar(),

            // Content Area
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: NeverScrollableScrollPhysics(),
                children: [
                  _buildHeartRateStep(),
                  _buildSpO2Step(),
                  _buildBloodPressureStep(),
                  _buildTemperatureStep(),
                  _buildReviewStep(),
                ],
              ),
            ),

            // Navigation Buttons
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: EdgeInsets.all(AppDimensions.paddingMedium),
      child: Column(
        children: [
          LinearProgressIndicator(
            value: (_currentStep + 1) / _steps.length,
            backgroundColor: AppColors.lightBlue,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
            minHeight: 4,
            borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
          ),
          SizedBox(height: AppDimensions.spaceS),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _steps[_currentStep],
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${_currentStep + 1}/${_steps.length}',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Step 1: Heart Rate
  Widget _buildHeartRateStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(AppDimensions.paddingXL),
      child: Column(
        children: [
          GlassCard(
            padding: EdgeInsets.all(AppDimensions.paddingLarge),
            child: Column(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.riskHighBg,
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusXXL),
                  ),
                  child: Icon(
                    Icons.favorite_rounded,
                    size: AppDimensions.iconXXL,
                    color: AppColors.riskHigh,
                  ),
                ),

                SizedBox(height: AppDimensions.spaceXXXL),

                Text(
                  'Heart Rate',
                  style: AppTextStyles.heading2.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),

                SizedBox(height: AppDimensions.spaceM),

                Text(
                  'Measure your resting heart rate in beats per minute (bpm)',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: AppDimensions.spaceXXXL),

                _buildNumberInput(
                  key: 'heartRate',
                  controller: _heartRateController,
                  label: 'Heart Rate (bpm)',
                  icon: Icons.favorite_border_rounded,
                  min: 40,
                  max: 200,
                  unit: 'bpm',
                ),

                SizedBox(height: AppDimensions.spaceXXXL),

                // Reference Ranges
                _buildReferenceRanges(
                  title: 'Normal Range: 60-100 bpm',
                  items: [
                    'Below 60: Bradycardia',
                    '60-100: Normal',
                    '100-120: Tachycardia',
                    'Above 120: High',
                    'Above 150: Emergency',
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Step 2: SpO2
  Widget _buildSpO2Step() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(AppDimensions.paddingXL),
      child: Column(
        children: [
          GlassCard(
            padding: EdgeInsets.all(AppDimensions.paddingLarge),
            child: Column(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.1),
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusXXL),
                  ),
                  child: Icon(
                    Icons.air_rounded,
                    size: AppDimensions.iconXXL,
                    color: AppColors.primaryBlue,
                  ),
                ),
                SizedBox(height: AppDimensions.spaceXXXL),
                Text(
                  'Oxygen Saturation (SpO2)',
                  style: AppTextStyles.heading2.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: AppDimensions.spaceM),
                Text(
                  'Measure your blood oxygen level using a pulse oximeter',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppDimensions.spaceXXXL),
                _buildNumberInput(
                  key: 'spo2',
                  controller: _spo2Controller,
                  label: 'SpO2 Level (%)',
                  icon: Icons.air_outlined,
                  min: 70,
                  max: 100,
                  unit: '%',
                ),
                SizedBox(height: AppDimensions.spaceXXXL),
                _buildReferenceRanges(
                  title: 'Oxygen Levels:',
                  items: [
                    '95-100%: Normal',
                    '94%: Low',
                    '90-93%: Very Low',
                    'Below 90%: Emergency',
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Step 3: Blood Pressure
  Widget _buildBloodPressureStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(AppDimensions.paddingXL),
      child: Column(
        children: [
          GlassCard(
            padding: EdgeInsets.all(AppDimensions.paddingLarge),
            child: Column(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.softPurple.withOpacity(0.1),
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusXXL),
                  ),
                  child: Icon(
                    Icons.monitor_heart_rounded,
                    size: AppDimensions.iconXXL,
                    color: AppColors.softPurple,
                  ),
                ),
                SizedBox(height: AppDimensions.spaceXXXL),
                Text(
                  'Blood Pressure',
                  style: AppTextStyles.heading2.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: AppDimensions.spaceM),
                Text(
                  'Enter your systolic and diastolic blood pressure readings',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppDimensions.spaceXXXL),
                Row(
                  children: [
                    Expanded(
                      child: _buildNumberInput(
                        key: 'systolicBP',
                        controller: _systolicBPController,
                        label: 'Systolic',
                        icon: Icons.arrow_upward_rounded,
                        min: 70,
                        max: 250,
                        unit: 'mmHg',
                        centered: false,
                      ),
                    ),
                    SizedBox(width: AppDimensions.spaceL),
                    Expanded(
                      child: _buildNumberInput(
                        key: 'diastolicBP',
                        controller: _diastolicBPController,
                        label: 'Diastolic',
                        icon: Icons.arrow_downward_rounded,
                        min: 40,
                        max: 150,
                        unit: 'mmHg',
                        centered: false,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppDimensions.spaceXXXL),
                _buildReferenceRanges(
                  title: 'Blood Pressure Categories:',
                  items: [
                    'Normal: <120/<80 mmHg',
                    'Elevated: 120-129/<80 mmHg',
                    'Stage 1: 130-139/80-89 mmHg',
                    'Stage 2: ≥140/≥90 mmHg',
                    'Emergency: >180/>120 mmHg',
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Step 4: Temperature
  Widget _buildTemperatureStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(AppDimensions.paddingXL),
      child: Column(
        children: [
          GlassCard(
            padding: EdgeInsets.all(AppDimensions.paddingLarge),
            child: Column(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.riskModerateBg,
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusXXL),
                  ),
                  child: Icon(
                    Icons.thermostat_rounded,
                    size: AppDimensions.iconXXL,
                    color: AppColors.riskModerate,
                  ),
                ),
                SizedBox(height: AppDimensions.spaceXXXL),
                Text(
                  'Body Temperature',
                  style: AppTextStyles.heading2.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: AppDimensions.spaceM),
                Text(
                  'Measure your body temperature in Celsius',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppDimensions.spaceXXXL),
                _buildNumberInput(
                  key: 'temperature',
                  controller: _temperatureController,
                  label: 'Temperature (°C)',
                  icon: Icons.thermostat_outlined,
                  min: 35.0,
                  max: 42.0,
                  isDecimal: true,
                  unit: '°C',
                ),
                SizedBox(height: AppDimensions.spaceXXXL),
                _buildReferenceRanges(
                  title: 'Temperature Ranges:',
                  items: [
                    'Normal: 36.1-37.2°C',
                    'Elevated: 37.3-37.9°C',
                    'Fever: 38.0-38.9°C',
                    'High Fever: 39.0-40.0°C',
                    'Emergency: >40.0°C',
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Step 5: Review
  Widget _buildReviewStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(AppDimensions.paddingXL),
      child: Column(
        children: [
          GlassCard(
            padding: EdgeInsets.all(AppDimensions.paddingLarge),
            child: Column(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.softGreen.withOpacity(0.1),
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusXXL),
                  ),
                  child: Icon(
                    Icons.checklist_rounded,
                    size: AppDimensions.iconXXL,
                    color: AppColors.softGreen,
                  ),
                ),

                SizedBox(height: AppDimensions.spaceXXXL),

                Text(
                  'Review Your Vitals',
                  style: AppTextStyles.heading2.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),

                SizedBox(height: AppDimensions.spaceM),

                Text(
                  'Confirm all information is correct before submitting',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: AppDimensions.spaceXXXL),

                // Vitals Summary
                _buildVitalSummaryItem(
                  icon: Icons.favorite_rounded,
                  label: 'Heart Rate',
                  value: '${_heartRateController.text} bpm',
                  isValid: _fieldValid['heartRate'] ?? true,
                ),

                _buildVitalSummaryItem(
                  icon: Icons.air_rounded,
                  label: 'SpO2 Level',
                  value: '${_spo2Controller.text}%',
                  isValid: _fieldValid['spo2'] ?? true,
                ),

                _buildVitalSummaryItem(
                  icon: Icons.monitor_heart_rounded,
                  label: 'Blood Pressure',
                  value:
                      '${_systolicBPController.text}/${_diastolicBPController.text} mmHg',
                  isValid: (_fieldValid['systolicBP'] ?? true) && 
                          (_fieldValid['diastolicBP'] ?? true),
                ),

                _buildVitalSummaryItem(
                  icon: Icons.thermostat_rounded,
                  label: 'Temperature',
                  value: '${_temperatureController.text}°C',
                  isValid: _fieldValid['temperature'] ?? true,
                ),

                SizedBox(height: AppDimensions.spaceXXXL),

                // Notes Section
                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Additional Notes (Optional)',
                    labelStyle: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusMedium),
                      borderSide: BorderSide(color: AppColors.lightBlue),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusMedium),
                      borderSide: BorderSide(color: AppColors.primaryBlue),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberInput({
    required String key,
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required double min,
    required double max,
    required String unit,
    bool isDecimal = false,
    bool centered = true,
  }) {
    String? errorText;
    bool isValid = _fieldValid[key] ?? true;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: isValid ? AppColors.textPrimary : AppColors.riskHigh,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: AppDimensions.spaceS),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
            boxShadow: AppShadows.elevation1,
            border: !isValid 
              ? Border.all(color: AppColors.riskHigh, width: 2)
              : null,
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: TextInputType.numberWithOptions(decimal: isDecimal),
            style: AppTextStyles.heading3.copyWith(
              color: isValid ? AppColors.textPrimary : AppColors.riskHigh,
            ),
            textAlign: centered ? TextAlign.center : TextAlign.left,
            onChanged: (value) {
              if (value.isNotEmpty) {
                final numValue = isDecimal ? double.tryParse(value) : int.tryParse(value);
                if (numValue != null) {
                  final newIsValid = numValue >= min && numValue <= max;
                  setState(() {
                    _fieldValid[key] = newIsValid;
                  });
                  
                  if (!newIsValid) {
                    errorText = 'Must be between $min and $max $unit';
                  } else {
                    errorText = null;
                  }
                }
              }
            },
            decoration: InputDecoration(
              prefixIcon: Icon(icon, 
                  color: isValid ? AppColors.primaryBlue : AppColors.riskHigh),
              suffixText: unit,
              suffixStyle: AppTextStyles.bodyMedium.copyWith(
                color: isValid ? AppColors.textSecondary : AppColors.riskHigh,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: EdgeInsets.symmetric(
                horizontal: AppDimensions.spaceL,
                vertical: AppDimensions.spaceXL,
              ),
              errorText: errorText,
              errorStyle: AppTextStyles.caption.copyWith(color: AppColors.riskHigh),
            ),
          ),
        ),
        SizedBox(height: AppDimensions.spaceS),
        Text(
          'Range: $min-$max $unit',
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildReferenceRanges({
    required String title,
    required List<String> items,
  }) {
    return GlassCard(
      padding: EdgeInsets.all(AppDimensions.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: AppDimensions.spaceM),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: items.map((item) {
              return Padding(
                padding: EdgeInsets.only(bottom: AppDimensions.spaceXS),
                child: Row(
                  children: [
                    Icon(
                      Icons.circle_rounded,
                      size: 6,
                      color: AppColors.textSecondary,
                    ),
                    SizedBox(width: AppDimensions.spaceS),
                    Expanded(
                      child: Text(
                        item,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildVitalSummaryItem({
    required IconData icon,
    required String label,
    required String value,
    required bool isValid,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: AppDimensions.spaceL),
      padding: EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        boxShadow: AppShadows.elevation1,
        border: !isValid 
          ? Border.all(color: AppColors.riskHigh, width: 2)
          : null,
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(AppDimensions.spaceM),
            decoration: BoxDecoration(
              color: isValid 
                ? AppColors.primaryBlue.withOpacity(0.1)
                : AppColors.riskHigh.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            ),
            child: Icon(
              icon,
              color: isValid ? AppColors.primaryBlue : AppColors.riskHigh,
              size: AppDimensions.iconM,
            ),
          ),
          SizedBox(width: AppDimensions.spaceL),
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
                Text(
                  value,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: isValid ? AppColors.textPrimary : AppColors.riskHigh,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (!isValid)
            Icon(Icons.warning, color: AppColors.riskHigh),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
  final bool allValid = _fieldValid.values.every((valid) => valid);
  final bool isReviewStep = _currentStep == _steps.length - 1;
  
  return Padding(
    padding: EdgeInsets.all(AppDimensions.paddingMedium),
    child: Row(
      children: [
        if (_currentStep > 0)
          Expanded(
            child: GlassButton(
              text: 'Back',
              type: ButtonType.secondary,
              onPressed: _previousStep,
            ),
          ),
        if (_currentStep > 0) SizedBox(width: AppDimensions.spaceL),
        Expanded(
          child: GlassButton(
            text: isReviewStep
                ? (_isSubmitting ? 'Analyzing...' : 'Submit & Analyze')
                : 'Next',
            type: ButtonType.primary,
            onPressed: () {
              if (isReviewStep) {
                if (_isSubmitting) return;
                if (!allValid) {
                  _showSnackBar('Please fix invalid values', AppColors.riskHigh);
                  return;
                }
                _submitVitals();
              } else {
                _nextStep();
              }
            },
            isLoading: _isSubmitting,
          ),
        ),
      ],
    ),
  );
}
}