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
    'heartRate': true,
    'spo2': true,
    'systolicBP': true,
    'diastolicBP': true,
    'temperature': true,
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
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep++);
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 500),
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

    if (heartRate == null ||
        spo2 == null ||
        systolicBP == null ||
        diastolicBP == null ||
        temperature == null) {
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
      _showEmergencyAlert(
          heartRate, spo2, systolicBP, diastolicBP, temperature);
      return;
    }

    // 5. Show warnings if any
    if (validation.hasWarnings || validation.hasAlerts) {
      await _showWarningDialog(validation);
    }

    // 6. Proceed with submission
    _proceedWithSubmission(
        heartRate, spo2, systolicBP, diastolicBP, temperature);
  }

  void _proceedWithSubmission(int heartRate, int spo2, int systolicBP,
      int diastolicBP, double temperature) async {
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
          _showSnackBar(
              'Vitals submitted! Analysis complete.', AppColors.success);
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
        title: const Text('❌ Validation Errors'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Please correct the following:'),
            const SizedBox(height: 10),
            ...validation.errors
                .map((error) => Text('• $error',
                    style: const TextStyle(color: AppColors.riskHigh)))
                .toList(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showEmergencyAlert(int heartRate, int spo2, int systolicBP,
      int diastolicBP, double temperature) {
    // Build list of critical issues
    final List<String> criticalIssues = [];

    if (spo2 < 90) criticalIssues.add('• Oxygen critically low: $spo2%');
    if (heartRate > 150)
      criticalIssues.add('• Heart rate dangerously high: $heartRate bpm');
    if (heartRate < 40)
      criticalIssues.add('• Heart rate dangerously low: $heartRate bpm');
    if (temperature > 39.0)
      criticalIssues.add('• High fever: ${temperature.toStringAsFixed(1)}°C');
    if (temperature < 35.5)
      criticalIssues.add(
          '• Dangerously low temperature: ${temperature.toStringAsFixed(1)}°C');
    if (systolicBP > 180)
      criticalIssues.add('• Severely high blood pressure: $systolicBP mmHg');
    if (diastolicBP > 120)
      criticalIssues.add('• Severely high diastolic: $diastolicBP mmHg');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        ),
        title: Row(
          children: [
            Icon(Icons.warning_rounded, color: AppColors.riskHigh, size: 28),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                '🚨 EMERGENCY ALERT',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.riskHigh,
                ),
              ),
            ),
          ],
        ),
        content: ConstrainedBox(
          // ✅ FIXED: Maximum height to prevent overflow
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.riskHighBg,
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusMedium),
                  ),
                  child: const Text(
                    'CRITICAL VITAL SIGNS DETECTED',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.riskHigh,
                      fontSize: 14,
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                // Critical issues
                ...criticalIssues
                    .map((issue) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            issue,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                            ),
                          ),
                        ))
                    .toList(),

                const SizedBox(height: 15),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.lightBlue,
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusMedium),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'RECOMMENDED ACTION:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '1. Contact your oncology team IMMEDIATELY\n'
                        '2. If unavailable, call emergency services\n'
                        '3. Rest and avoid exertion\n'
                        '4. Have someone stay with you',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 15),

                const Text(
                  'Do you want to record these values anyway?',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            child: const Text(
              'CANCEL',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.riskHigh,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              _proceedWithSubmission(
                  heartRate, spo2, systolicBP, diastolicBP, temperature);
            },
            child: const Text('PROCEED ANYWAY'),
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
                const Text('Medical alerts detected:'),
                const SizedBox(height: 10),
                ...validation.alerts
                    .map((alert) => Text('• $alert',
                        style: const TextStyle(color: Colors.orange)))
                    .toList(),
                const SizedBox(height: 15),
              ],
              if (validation.hasWarnings) ...[
                const Text('Warning signs:'),
                const SizedBox(height: 10),
                ...validation.warnings
                    .map((warning) => Text('• $warning',
                        style: const TextStyle(color: Colors.blue)))
                    .toList(),
              ],
              const SizedBox(height: 15),
              const Text('Would you like to continue with submission?'),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: const Text('EDIT VALUES'),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: const Text('CONTINUE'),
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
            padding: const EdgeInsets.all(AppDimensions.spaceS),
            decoration: BoxDecoration(
              color: AppColors.lightBlue,
              borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
            ),
            child: Icon(
              Icons.arrow_back_rounded,
              size: AppDimensions.iconS,
              color: AppColors.wisteriaBlue,
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
                physics: const NeverScrollableScrollPhysics(),
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
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      child: Column(
        children: [
          LinearProgressIndicator(
            value: (_currentStep + 1) / _steps.length,
            backgroundColor: AppColors.lightBlue,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.wisteriaBlue),
            minHeight: 4,
            borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
          ),
          const SizedBox(height: AppDimensions.spaceS),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _steps[_currentStep],
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.wisteriaBlue,
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
      padding: const EdgeInsets.all(AppDimensions.paddingXL),
      child: Column(
        children: [
          GlassCard(
            padding: const EdgeInsets.all(AppDimensions.paddingLarge),
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

                const SizedBox(height: AppDimensions.spaceXXXL),

                Text(
                  'Heart Rate',
                  style: AppTextStyles.heading2.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: AppDimensions.spaceM),

                Text(
                  'Measure your resting heart rate in beats per minute (bpm)',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: AppDimensions.spaceXXXL),

                _buildNumberInput(
                  key: 'heartRate',
                  controller: _heartRateController,
                  label: 'Heart Rate (bpm)',
                  icon: Icons.favorite_border_rounded,
                  min: 40,
                  max: 200,
                  unit: 'bpm',
                ),

                const SizedBox(height: AppDimensions.spaceXXXL),

                // Reference Ranges
                _buildReferenceRanges(
                  title: 'Normal Range: 60-100 bpm',
                  items: const [
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
      padding: const EdgeInsets.all(AppDimensions.paddingXL),
      child: Column(
        children: [
          GlassCard(
            padding: const EdgeInsets.all(AppDimensions.paddingLarge),
            child: Column(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.wisteriaBlue.withOpacity(0.1),
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusXXL),
                  ),
                  child: Icon(
                    Icons.air_rounded,
                    size: AppDimensions.iconXXL,
                    color: AppColors.wisteriaBlue,
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceXXXL),
                Text(
                  'Oxygen Saturation (SpO2)',
                  style: AppTextStyles.heading2.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceM),
                Text(
                  'Measure your blood oxygen level using a pulse oximeter',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppDimensions.spaceXXXL),
                _buildNumberInput(
                  key: 'spo2',
                  controller: _spo2Controller,
                  label: 'SpO2 Level (%)',
                  icon: Icons.air_outlined,
                  min: 70,
                  max: 100,
                  unit: '%',
                ),
                const SizedBox(height: AppDimensions.spaceXXXL),
                _buildReferenceRanges(
                  title: 'Oxygen Levels:',
                  items: const [
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

  // Step 3: Blood Pressure - FIXED: Changed to Column layout
  Widget _buildBloodPressureStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingXL),
      child: Column(
        children: [
          GlassCard(
            padding: const EdgeInsets.all(AppDimensions.paddingLarge),
            child: Column(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.pastelPetal.withOpacity(0.1),
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusXXL),
                  ),
                  child: Icon(
                    Icons.monitor_heart_rounded,
                    size: AppDimensions.iconXXL,
                    color: AppColors.pastelPetal,
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceXXXL),
                Text(
                  'Blood Pressure',
                  style: AppTextStyles.heading2.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceM),
                Text(
                  'Enter your systolic and diastolic blood pressure readings',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppDimensions.spaceXXXL),

                // FIXED: Changed from Row to Column for BP inputs
                Column(
                  children: [
                    // Systolic BP
                    _buildNumberInput(
                      key: 'systolicBP',
                      controller: _systolicBPController,
                      label: 'Systolic Pressure',
                      icon: Icons.arrow_upward_rounded,
                      min: 70,
                      max: 250,
                      unit: 'mmHg',
                      centered: false,
                    ),

                    const SizedBox(height: AppDimensions.spaceXL),

                    // Diastolic BP
                    _buildNumberInput(
                      key: 'diastolicBP',
                      controller: _diastolicBPController,
                      label: 'Diastolic Pressure',
                      icon: Icons.arrow_downward_rounded,
                      min: 40,
                      max: 150,
                      unit: 'mmHg',
                      centered: false,
                    ),
                  ],
                ),

                const SizedBox(height: AppDimensions.spaceXXXL),
                _buildReferenceRanges(
                  title: 'Blood Pressure Categories:',
                  items: const [
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
      padding: const EdgeInsets.all(AppDimensions.paddingXL),
      child: Column(
        children: [
          GlassCard(
            padding: const EdgeInsets.all(AppDimensions.paddingLarge),
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
                const SizedBox(height: AppDimensions.spaceXXXL),
                Text(
                  'Body Temperature',
                  style: AppTextStyles.heading2.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceM),
                Text(
                  'Measure your body temperature in Celsius',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppDimensions.spaceXXXL),
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
                const SizedBox(height: AppDimensions.spaceXXXL),
                _buildReferenceRanges(
                  title: 'Temperature Ranges:',
                  items: const [
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
      padding: const EdgeInsets.all(AppDimensions.paddingXL),
      child: Column(
        children: [
          GlassCard(
            padding: const EdgeInsets.all(AppDimensions.paddingLarge),
            child: Column(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.frozenWater.withOpacity(0.1),
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusXXL),
                  ),
                  child: Icon(
                    Icons.checklist_rounded,
                    size: AppDimensions.iconXXL,
                    color: AppColors.frozenWater,
                  ),
                ),

                const SizedBox(height: AppDimensions.spaceXXXL),

                Text(
                  'Review Your Vitals',
                  style: AppTextStyles.heading2.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: AppDimensions.spaceM),

                Text(
                  'Confirm all information is correct before submitting',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: AppDimensions.spaceXXXL),

                // Vitals Summary
                _buildVitalSummaryItem(
                  icon: Icons.favorite_rounded,
                  label: 'Heart Rate',
                  value: _heartRateController.text.isNotEmpty
                      ? '${_heartRateController.text} bpm'
                      : 'Not entered',
                  isValid: _fieldValid['heartRate']!,
                ),

                _buildVitalSummaryItem(
                  icon: Icons.air_rounded,
                  label: 'SpO2 Level',
                  value: _spo2Controller.text.isNotEmpty
                      ? '${_spo2Controller.text}%'
                      : 'Not entered',
                  isValid: _fieldValid['spo2']!,
                ),

                _buildVitalSummaryItem(
                  icon: Icons.monitor_heart_rounded,
                  label: 'Blood Pressure',
                  value: _systolicBPController.text.isNotEmpty &&
                          _diastolicBPController.text.isNotEmpty
                      ? '${_systolicBPController.text}/${_diastolicBPController.text} mmHg'
                      : 'Not entered',
                  isValid:
                      _fieldValid['systolicBP']! && _fieldValid['diastolicBP']!,
                ),

                _buildVitalSummaryItem(
                  icon: Icons.thermostat_rounded,
                  label: 'Temperature',
                  value: _temperatureController.text.isNotEmpty
                      ? '${_temperatureController.text}°C'
                      : 'Not entered',
                  isValid: _fieldValid['temperature']!,
                ),

                const SizedBox(height: AppDimensions.spaceXXXL),

                // Notes Section
                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Additional Notes (Optional)',
                    labelStyle: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusMedium),
                      borderSide: const BorderSide(color: AppColors.lightBlue),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusMedium),
                      borderSide:
                          const BorderSide(color: AppColors.wisteriaBlue),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusMedium),
                      borderSide: const BorderSide(color: AppColors.lightBlue),
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
        const SizedBox(height: AppDimensions.spaceS),
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
              color: AppColors.textPrimary,
            ),
            textAlign: centered ? TextAlign.center : TextAlign.left,
            onChanged: (value) {
              if (value.isNotEmpty) {
                final numValue =
                    isDecimal ? double.tryParse(value) : int.tryParse(value);
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
              } else {
                setState(() {
                  _fieldValid[key] = true;
                  errorText = null;
                });
              }
            },
            decoration: InputDecoration(
              prefixIcon: Icon(
                icon,
                // ✅ FIXED: Single consistent color for ALL input fields
                color: isValid ? AppColors.wisteriaBlue : AppColors.riskHigh,
              ),
              suffixText: unit,
              suffixStyle: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
                borderSide: const BorderSide(
                  // ✅ FIXED: Single consistent focus color
                  color: AppColors.wisteriaBlue,
                  width: 2,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
                borderSide: BorderSide.none,
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
                borderSide: const BorderSide(
                  color: AppColors.riskHigh,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spaceL,
                vertical: AppDimensions.spaceXL,
              ),
              errorText: errorText,
              errorStyle:
                  AppTextStyles.caption.copyWith(color: AppColors.riskHigh),
            ),
          ),
        ),
        const SizedBox(height: AppDimensions.spaceS),
        Text(
          'Range: ${min.toString().replaceAll('.0', '')}-${max.toString().replaceAll('.0', '')} $unit',
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
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
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
          const SizedBox(height: AppDimensions.spaceM),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: items.map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AppDimensions.spaceXS),
                child: Row(
                  children: [
                    Icon(
                      Icons.circle_rounded,
                      size: 6,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: AppDimensions.spaceS),
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
      margin: const EdgeInsets.only(bottom: AppDimensions.spaceL),
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        boxShadow: AppShadows.elevation1,
        border:
            !isValid ? Border.all(color: AppColors.riskHigh, width: 2) : null,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimensions.spaceM),
            decoration: BoxDecoration(
              color: isValid
                  ? AppColors.wisteriaBlue.withOpacity(0.1)
                  : AppColors.riskHigh.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            ),
            child: Icon(
              icon,
              color: isValid ? AppColors.wisteriaBlue : AppColors.riskHigh,
              size: AppDimensions.iconM,
            ),
          ),
          const SizedBox(width: AppDimensions.spaceL),
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
          if (!isValid) const Icon(Icons.warning, color: AppColors.riskHigh),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    final bool allValid = _fieldValid.values.every((valid) => valid);
    final bool isReviewStep = _currentStep == _steps.length - 1;

    return Padding(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
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
          if (_currentStep > 0) const SizedBox(width: AppDimensions.spaceL),
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
                    _showSnackBar(
                        'Please fix invalid values', AppColors.riskHigh);
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
