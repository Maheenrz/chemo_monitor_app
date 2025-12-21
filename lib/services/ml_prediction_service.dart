import 'package:tflite_flutter/tflite_flutter.dart';

class MLPredictionService {
  Interpreter? _interpreter;
  bool _isModelLoaded = false;

  /// Load the TFLite model
  Future<void> loadModel() async {
    try {
      print('🔄 Loading ML model...');
      
      // Load model from assets
      _interpreter = await Interpreter.fromAsset(
        'assets/models/model.tflite',
      );

      _isModelLoaded = true;
      print('✅ ML model loaded successfully!');
      print('📊 Input shape: ${_interpreter!.getInputTensor(0).shape}');
      print('📊 Output shape: ${_interpreter!.getOutputTensor(0).shape}');
    } catch (e) {
      print('❌ Error loading ML model: $e');
      _isModelLoaded = false;
      rethrow;
    }
  }

  /// Check if model is loaded
  bool get isModelLoaded => _isModelLoaded;

  /// Predict risk level from health data
  /// 
  /// Input: [heartRate, spo2, systolicBP, diastolicBP, temperature]
  /// Output: [prob_low, prob_moderate, prob_high]
  /// Returns: {riskLevel: 0/1/2, probabilities: [0.x, 0.y, 0.z]}
  Future<Map<String, dynamic>> predict(List<double> inputData) async {
    if (!_isModelLoaded || _interpreter == null) {
      throw Exception('Model not loaded. Call loadModel() first.');
    }

    if (inputData.length != 5) {
      throw Exception('Input must have exactly 5 values: [HR, SpO2, SysBP, DiaBP, Temp]');
    }

    try {
      print('🔮 Running ML prediction...');
      print('📥 Input: $inputData');

      // Prepare input tensor (shape: [1, 5])
      var input = [inputData];

      // Prepare output tensor (shape: [1, 3])
      var output = List.filled(1 * 3, 0.0).reshape([1, 3]);

      // Run inference
      _interpreter!.run(input, output);

      // Extract probabilities
      List<double> probabilities = [
        output[0][0], // Probability of Low risk (class 0)
        output[0][1], // Probability of Moderate risk (class 1)
        output[0][2], // Probability of High risk (class 2)
      ];

      // Find risk level (argmax)
      int riskLevel = _getMaxIndex(probabilities);

      print('📤 Output probabilities: $probabilities');
      print('🎯 Predicted risk level: $riskLevel (${_getRiskLevelString(riskLevel)})');

      return {
        'riskLevel': riskLevel,
        'probabilities': probabilities,
        'confidence': probabilities[riskLevel], // Confidence of prediction
      };
    } catch (e) {
      print('❌ Prediction error: $e');
      rethrow;
    }
  }

  /// Get index of maximum value (argmax)
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
        return 'Low';
      case 1:
        return 'Moderate';
      case 2:
        return 'High';
      default:
        return 'Unknown';
    }
  }

  /// Normalize input data (if needed)
  /// Your model was trained with StandardScaler, but for inference
  /// we use raw values since the model handles it internally
  List<double> normalizeInput(
    int heartRate,
    int spo2,
    int systolicBP,
    int diastolicBP,
    double temperature,
  ) {
    return [
      heartRate.toDouble(),
      spo2.toDouble(),
      systolicBP.toDouble(),
      diastolicBP.toDouble(),
      temperature,
    ];
  }

  /// Close interpreter and free resources
  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isModelLoaded = false;
    print('🗑️ ML model disposed');
  }
}