import 'dart:typed_data';
import 'package:tflite_flutter/tflite_flutter.dart';

class MLService {
  Interpreter? _interpreter;

  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/model/side_effect_model.tflite');
      print("ML Model Loaded Successfully");
    } catch (e) {
      print("Error loading ML model: $e");
    }
  }

  // Prediction Logic
  // Input: List of 5 numbers (e.g. [Age, Gender, Dose, BP, HeartRate])
  // Output: List of 3 probabilities (Low, Medium, High)
  List<double>? predict(List<double> inputValues) {
    if (_interpreter == null) {
      print("Interpreter not initialized");
      return null;
    }

    // 1. Prepare Input: Shape [1, 5]
    // Convert generic list to Float32List for the model
    var input = [inputValues]; 
    
    // 2. Prepare Output: Shape [1, 3]
    var output = List.filled(1 * 3, 0.0).reshape([1, 3]);

    // 3. Run Inference
    _interpreter!.run(input, output);

    // 4. Return the result (the first row)
    return List<double>.from(output[0]);
  }
  
  void dispose() {
    _interpreter?.close();
  }
}