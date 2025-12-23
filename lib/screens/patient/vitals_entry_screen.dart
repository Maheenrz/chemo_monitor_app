// lib/screens/patient/vitals_entry_screen.dart (FIXED VERSION)
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chemo_monitor_app/config/app_constants.dart';
import 'package:chemo_monitor_app/services/health_data_service.dart';
import 'package:chemo_monitor_app/widgets/common/glass_card.dart';
import 'package:chemo_monitor_app/widgets/common/glass_button.dart';

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
    if (!_validateForm()) {
      _showSnackBar('Please fill all required fields', AppColors.riskModerate);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not logged in');

      // ✅ PROPERLY SUBMIT TO HEALTH DATA SERVICE (which has ML integrated!)
      final healthDataId = await _healthDataService.addHealthData(
        patientId: user.uid,
        heartRate: int.parse(_heartRateController.text),
        spo2Level: int.parse(_spo2Controller.text),
        systolicBP: int.parse(_systolicBPController.text),
        diastolicBP: int.parse(_diastolicBPController.text),
        temperature: double.parse(_temperatureController.text),
        additionalNotes:
            _notesController.text.isEmpty ? null : _notesController.text,
      );

      print('✅ Health data submitted successfully: $healthDataId');

      if (mounted) {
        _showSnackBar('Vitals submitted successfully! ML prediction complete.',
            AppColors.softGreen);

        // Wait a moment then return to home
        await Future.delayed(Duration(seconds: 2));

        if (mounted) {
          Navigator.pop(context, true); // Return true to reload home screen
        }
      }
    } catch (e) {
      print('❌ Error submitting vitals: $e');
      if (mounted) {
        _showSnackBar('Error: ${e.toString()}', AppColors.riskHigh);
      }
    } finally {
      if (mounted) {
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
          Text(
            _steps[_currentStep],
            style: AppTextStyles.caption.copyWith(
              color: AppColors.primaryBlue,
              fontWeight: FontWeight.w600,
            ),
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
                    '40-59: Low',
                    '60-100: Normal',
                    '101-120: Elevated',
                    '120+: High',
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
                    '90-94%: Mild Hypoxia',
                    '85-89%: Moderate Hypoxia',
                    'Below 85%: Severe Hypoxia',
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
                        controller: _systolicBPController,
                        label: 'Systolic',
                        icon: Icons.arrow_upward_rounded,
                        min: 70,
                        max: 200,
                        unit: 'mmHg',
                        centered: false, // ✅ Add this parameter
                      ),
                    ),
                    SizedBox(width: AppDimensions.spaceL),
                    Expanded(
                      child: _buildNumberInput(
                        controller: _diastolicBPController,
                        label: 'Diastolic',
                        icon: Icons.arrow_downward_rounded,
                        min: 40,
                        max: 130,
                        unit: 'mmHg',
                        centered: false, // ✅ Add this parameter
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
                    'Fever: 37.3-38.0°C',
                    'High Fever: 38.1-40.0°C',
                    'Hyperpyrexia: >40.0°C',
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
                  color: AppColors.riskHigh,
                ),

                _buildVitalSummaryItem(
                  icon: Icons.air_rounded,
                  label: 'SpO2 Level',
                  value: '${_spo2Controller.text}%',
                  color: AppColors.primaryBlue,
                ),

                _buildVitalSummaryItem(
                  icon: Icons.monitor_heart_rounded,
                  label: 'Blood Pressure',
                  value:
                      '${_systolicBPController.text}/${_diastolicBPController.text} mmHg',
                  color: AppColors.softPurple,
                ),

                _buildVitalSummaryItem(
                  icon: Icons.thermostat_rounded,
                  label: 'Temperature',
                  value: '${_temperatureController.text}°C',
                  color: AppColors.riskModerate,
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
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required double min,
    required double max,
    required String unit,
    bool isDecimal = false,
    bool centered = true, // ✅ New parameter with default true
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: AppDimensions.spaceS),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
            boxShadow: AppShadows.elevation1,
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: TextInputType.numberWithOptions(decimal: isDecimal),
            style: AppTextStyles.heading3.copyWith(
              color: AppColors.textPrimary,
            ),
            textAlign: centered
                ? TextAlign.center
                : TextAlign.left, // ✅ Conditional alignment
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: AppColors.primaryBlue),
              suffixText: unit,
              suffixStyle: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
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
            ),
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
    required Color color,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: AppDimensions.spaceL),
      padding: EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        boxShadow: AppShadows.elevation1,
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(AppDimensions.spaceM),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            ),
            child: Icon(
              icon,
              color: color,
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
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
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
              text: _currentStep == _steps.length - 1
                  ? (_isSubmitting ? 'Analyzing...' : 'Submit & Analyze')
                  : 'Next',
              type: ButtonType.primary,
              onPressed: _currentStep == _steps.length - 1
                  ? (_isSubmitting ? null : _submitVitals)
                  : _nextStep,
              isLoading: _isSubmitting,
            ),
          ),
        ],
      ),
    );
  }
}
