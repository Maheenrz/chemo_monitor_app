import 'dart:typed_data';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:chemo_monitor_app/services/vitals_validator.dart';

class MLPredictionService {
  Interpreter? _interpreter;
  bool _isModelLoaded = false;
  
  // Store the model's expected normalization parameters
  final Map<String, Map<String, double>> _normalizationParams = {
    'heartRate': {'mean': 85.0, 'std': 15.0},
    'spo2': {'mean': 95.0, 'std': 3.0},
    'systolicBP': {'mean': 125.0, 'std': 20.0},
    'diastolicBP': {'mean': 80.0, 'std': 10.0},
    'temperature': {'mean': 36.8, 'std': 0.5},
  };

  /// Load the TFLite model with verification
  Future<void> loadModel() async {
    try {
      print('🔄 Loading ML model...');
      
      // Try to load model
      _interpreter = await Interpreter.fromAsset('assets/models/model.tflite');
      
      // VERIFY MODEL
      await _verifyModel();
      
      _isModelLoaded = true;
      print('✅ ML model loaded and verified successfully!');
    } catch (e) {
      print('❌ Error loading ML model: $e');
      _isModelLoaded = false;
      
      // Try alternative path
      try {
        print('🔄 Trying alternative model path...');
        _interpreter = await Interpreter.fromAsset('assets/models/side_effect_model.tflite');
        await _verifyModel();
        _isModelLoaded = true;
        print('✅ Alternative model loaded successfully!');
      } catch (e2) {
        print('❌ Both model paths failed: $e2');
      }
    }
  }

  /// Verify model input/output
  Future<void> _verifyModel() async {
    if (_interpreter == null) return;
    
    print('🔍 Verifying model...');
    print('📊 Input shape: ${_interpreter!.getInputTensor(0).shape}');
    print('📊 Input type: ${_interpreter!.getInputTensor(0).type}');
    print('📊 Output shape: ${_interpreter!.getOutputTensor(0).shape}');
    print('📊 Output type: ${_interpreter!.getOutputTensor(0).type}');
    
    // Run a test prediction
    final testInput = _normalizeInput(70, 95, 120, 80, 37.2);
    final testOutput = await _runInference([testInput]);
    
    print('🧪 Test prediction: $testOutput');
    print('🧪 Predicted class: ${_getMaxIndex(testOutput)}');
  }

  /// Predict risk level with enhanced logic
  Future<Map<String, dynamic>> predict({
    required int heartRate,
    required int spo2,
    required int systolicBP,
    required int diastolicBP,
    required double temperature,
  }) async {
    print('🤖 Starting ML prediction...');
    print('📥 Raw Input: HR=$heartRate, SpO2=$spo2, BP=$systolicBP/$diastolicBP, Temp=$temperature');
    
    // 1. Validate inputs first
    final validation = VitalsValidator.validate(
      heartRate: heartRate,
      spo2: spo2,
      systolicBP: systolicBP,
      diastolicBP: diastolicBP,
      temperature: temperature,
    );
    
    if (!validation.isValid) {
      print('❌ Input validation failed: ${validation.errors.first}');
      return _getRuleBasedPrediction(heartRate, spo2, systolicBP, temperature);
    }
    
    // 2. Check for emergency values (bypass ML)
    if (VitalsValidator.isInEmergencyRange(
      heartRate: heartRate,
      spo2: spo2,
      systolicBP: systolicBP,
      diastolicBP: diastolicBP,
      temperature: temperature,
    )) {
      print('🚨 Emergency values detected - using emergency prediction');
      return _getEmergencyPrediction(heartRate, spo2, systolicBP, temperature);
    }
    
    // 3. Run ML if available
    if (!_isModelLoaded || _interpreter == null) {
      print('⚠️ ML model not loaded, using rule-based prediction');
      return _getRuleBasedPrediction(heartRate, spo2, systolicBP, temperature);
    }
    
    try {
      // 4. Prepare and normalize input
      final normalizedInput = _normalizeInput(
        heartRate, spo2, systolicBP, diastolicBP, temperature
      );
      
      print('📊 Normalized Input: $normalizedInput');
      
      // 5. Run inference
      final rawOutput = await _runInference([normalizedInput]);
      
      // 6. Process output
      final probabilities = List<double>.from(rawOutput);
      final riskLevel = _getMaxIndex(probabilities);
      final confidence = probabilities[riskLevel];
      
      print('📤 ML Output: $probabilities');
      print('🎯 Predicted Risk: $riskLevel (${_getRiskLevelString(riskLevel)})');
      print('🎯 Confidence: ${(confidence * 100).toStringAsFixed(1)}%');
      
      // 7. Sanity check: Compare with rule-based logic
      final ruleBased = _getRuleBasedPrediction(heartRate, spo2, systolicBP, temperature);
      if (ruleBased['riskLevel'] != riskLevel) {
        print('⚠️ ML vs Rule-based mismatch: ML=$riskLevel, Rules=${ruleBased['riskLevel']}');
        
        // If ML confidence is low, use rule-based
        if (confidence < 0.7) {
          print('⚠️ Low confidence, using rule-based result');
          return ruleBased;
        }
      }
      
      return {
        'riskLevel': riskLevel,
        'probabilities': probabilities,
        'confidence': confidence,
        'isMLBased': true,
        'specificConcerns': _getSpecificConcerns(heartRate, spo2, systolicBP, temperature),
      };
    } catch (e) {
      print('❌ ML inference failed: $e');
      return _getRuleBasedPrediction(heartRate, spo2, systolicBP, temperature);
    }
  }

  /// Run inference
  Future<List<double>> _runInference(List<List<double>> input) async {
    try {
      // Prepare output tensor
      final output = List.filled(1 * 3, 0.0).reshape([1, 3]);
      
      // Run inference
      _interpreter!.run(input, output);
      
      // Convert to list and apply softmax if needed
      final rawProbs = List<double>.from(output[0]);
      
      // Ensure probabilities sum to ~1
      final sum = rawProbs.reduce((a, b) => a + b);
      if (sum > 0) {
        return rawProbs.map((p) => p / sum).toList();
      }
      
      return rawProbs;
    } catch (e) {
      throw Exception('Inference failed: $e');
    }
  }

  /// Normalize input based on training parameters
  List<double> _normalizeInput(
    int heartRate,
    int spo2,
    int systolicBP,
    int diastolicBP,
    double temperature,
  ) {
    return [
      (heartRate - _normalizationParams['heartRate']!['mean']!) / 
        _normalizationParams['heartRate']!['std']!,
      (spo2 - _normalizationParams['spo2']!['mean']!) / 
        _normalizationParams['spo2']!['std']!,
      (systolicBP - _normalizationParams['systolicBP']!['mean']!) / 
        _normalizationParams['systolicBP']!['std']!,
      (diastolicBP - _normalizationParams['diastolicBP']!['mean']!) / 
        _normalizationParams['diastolicBP']!['std']!,
      (temperature - _normalizationParams['temperature']!['mean']!) / 
        _normalizationParams['temperature']!['std']!,
    ];
  }

  /// Rule-based prediction (fallback)
  Map<String, dynamic> _getRuleBasedPrediction(
    int heartRate,
    int spo2,
    int systolicBP,
    double temperature,
  ) {
    // Your original rules from notebook
    int riskLevel;
    
    if (temperature > 38 || spo2 < 92) {
      riskLevel = 2; // High Risk
    } else if (heartRate > 100 || systolicBP > 140) {
      riskLevel = 1; // Moderate Risk
    } else {
      riskLevel = 0; // Low Risk
    }
    
    // Generate reasonable probabilities
    final probabilities = _generateProbabilities(riskLevel);
    
    return {
      'riskLevel': riskLevel,
      'probabilities': probabilities,
      'confidence': probabilities[riskLevel],
      'isMLBased': false,
      'specificConcerns': _getSpecificConcerns(heartRate, spo2, systolicBP, temperature),
    };
  }

  /// Emergency prediction (critical values)
  Map<String, dynamic> _getEmergencyPrediction(
    int heartRate,
    int spo2,
    int systolicBP,
    double temperature,
  ) {
    print('🚨 EMERGENCY PREDICTION ACTIVATED');
    
    return {
      'riskLevel': 2, // Always high for emergencies
      'probabilities': [0.05, 0.15, 0.80], // High confidence for high risk
      'confidence': 0.80,
      'isMLBased': false,
      'isEmergency': true,
      'specificConcerns': _getEmergencyConcerns(heartRate, spo2, temperature),
      'emergencyInstructions': _getEmergencyInstructions(),
    };
  }

  /// Get specific concerns based on vitals
  List<String> _getSpecificConcerns(
    int heartRate,
    int spo2,
    int systolicBP,
    double temperature,
  ) {
    final concerns = <String>[];
    
    if (temperature > 37.5) concerns.add('Elevated temperature');
    if (temperature > 38.0) concerns.add('Fever detected');
    if (spo2 < 95) concerns.add('Low oxygen saturation');
    if (spo2 < 92) concerns.add('Severely low oxygen');
    if (heartRate > 100) concerns.add('Elevated heart rate');
    if (heartRate > 120) concerns.add('Very high heart rate');
    if (systolicBP > 140) concerns.add('High blood pressure');
    
    return concerns;
  }

  /// Get emergency concerns
  List<String> _getEmergencyConcerns(
    int heartRate,
    int spo2,
    double temperature,
  ) {
    final concerns = <String>[];
    
    if (spo2 < 90) concerns.add('CRITICAL: Oxygen level dangerously low ($spo2%)');
    if (heartRate > 150) concerns.add('CRITICAL: Heart rate extremely high ($heartRate bpm)');
    if (heartRate < 40) concerns.add('CRITICAL: Heart rate extremely low ($heartRate bpm)');
    if (temperature > 39.0) concerns.add('CRITICAL: High fever (${temperature.toStringAsFixed(1)}°C)');
    if (temperature < 35.5) concerns.add('CRITICAL: Dangerously low body temperature');
    
    return concerns;
  }

  /// Emergency instructions
  String _getEmergencyInstructions() {
    return '''
🚨 IMMEDIATE ACTION REQUIRED:

1. CONTACT your oncology team or emergency services
2. DO NOT wait for symptoms to worsen
3. REST and avoid any physical activity
4. Have someone stay with you
5. Keep your phone nearby
6. Prepare your medication list and ID

Your vital signs indicate a potential medical emergency that requires immediate attention.
''';
  }

  /// Generate probabilities based on risk level
  List<double> _generateProbabilities(int riskLevel) {
    switch (riskLevel) {
      case 0: // Low risk
        return [0.7, 0.2, 0.1];
      case 1: // Moderate risk
        return [0.2, 0.6, 0.2];
      case 2: // High risk
        return [0.1, 0.2, 0.7];
      default:
        return [0.33, 0.33, 0.33];
    }
  }

  /// Get index of maximum value
  int _getMaxIndex(List<double> probabilities) {
    double maxValue = probabilities[0];
    int maxIndex = 0;

    for (int i = 1; i < probabilities.length; i++) {
      if (probabilities[i] > maxValue) {
        maxValue = probabilities[i];
        maxIndex = i;
      }
    }

    return maxIndex;
  }

  /// Convert risk level to string
  String _getRiskLevelString(int level) {
    switch (level) {
      case 0:
        return 'Low Risk';
      case 1:
        return 'Moderate Risk';
      case 2:
        return 'High Risk';
      default:
        return 'Unknown Risk';
    }
  }

  /// Check if model is loaded
  bool get isModelLoaded => _isModelLoaded;

  /// Dispose resources
  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isModelLoaded = false;
    print('🗑️ ML model disposed');
  }
}