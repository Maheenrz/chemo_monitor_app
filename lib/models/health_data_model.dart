import 'package:cloud_firestore/cloud_firestore.dart';

class HealthDataModel {
  final String id;
  final String patientId;
  
  // 5 ML Model Inputs (exact match with your model)
  final int heartRate; // bpm
  final int spo2Level; // %
  final int systolicBP; // mmHg
  final int diastolicBP; // mmHg
  final double temperature; // Celsius
  
  final String? additionalNotes;
  final DateTime timestamp;
  
  // ML Prediction Results (will be populated after ML runs)
  final int? riskLevel; // 0 = Low, 1 = Moderate, 2 = High
  final List<double>? mlOutputProbabilities; // [prob_low, prob_moderate, prob_high]

  HealthDataModel({
    required this.id,
    required this.patientId,
    required this.heartRate,
    required this.spo2Level,
    required this.systolicBP,
    required this.diastolicBP,
    required this.temperature,
    this.additionalNotes,
    required this.timestamp,
    this.riskLevel,
    this.mlOutputProbabilities,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patientId': patientId,
      'heartRate': heartRate,
      'spo2Level': spo2Level,
      'systolicBP': systolicBP,
      'diastolicBP': diastolicBP,
      'temperature': temperature,
      'additionalNotes': additionalNotes,
      'timestamp': Timestamp.fromDate(timestamp),
      'riskLevel': riskLevel,
      'mlOutputProbabilities': mlOutputProbabilities,
    };
  }

  // Create from Firestore document
  factory HealthDataModel.fromMap(Map<String, dynamic> map) {
    return HealthDataModel(
      id: map['id'] ?? '',
      patientId: map['patientId'] ?? '',
      heartRate: map['heartRate'] ?? 0,
      spo2Level: map['spo2Level'] ?? 0,
      systolicBP: map['systolicBP'] ?? 0,
      diastolicBP: map['diastolicBP'] ?? 0,
      temperature: (map['temperature'] ?? 0.0).toDouble(),
      additionalNotes: map['additionalNotes'],
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      riskLevel: map['riskLevel'],
      mlOutputProbabilities: map['mlOutputProbabilities'] != null
          ? List<double>.from(map['mlOutputProbabilities'])
          : null,
    );
  }

  // Get risk level as string
  String getRiskLevelString() {
    switch (riskLevel) {
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

  // Get risk color
  String getRiskColor() {
    switch (riskLevel) {
      case 0:
        return 'green';
      case 1:
        return 'orange';
      case 2:
        return 'red';
      default:
        return 'grey';
    }
  }

  // Check if any vital is concerning (basic rules before ML)
  bool isConcerning() {
    return heartRate > 100 ||
        heartRate < 60 ||
        spo2Level < 92 ||
        systolicBP > 140 ||
        systolicBP < 90 ||
        temperature > 38.0 ||
        temperature < 36.0;
  }

  // Get input array for ML model (exact format needed)
  List<double> getMLInputArray() {
    return [
      heartRate.toDouble(),
      spo2Level.toDouble(),
      systolicBP.toDouble(),
      diastolicBP.toDouble(),
      temperature,
    ];
  }

  // Add these methods to your existing HealthDataModel class:

/// Get specific concerns based on vitals
List<String> getSpecificConcerns() {
  final concerns = <String>[];
  
  if (temperature > 37.5) concerns.add('Elevated temperature');
  if (temperature > 38.0) concerns.add('Fever detected');
  if (spo2Level < 95) concerns.add('Low oxygen saturation');
  if (spo2Level < 92) concerns.add('Severely low oxygen');
  if (heartRate > 100) concerns.add('Elevated heart rate');
  if (heartRate > 120) concerns.add('Very high heart rate');
  if (systolicBP > 140) concerns.add('High blood pressure');
  
  return concerns;
}

/// Get risk description
String getRiskDescription() {
  switch (riskLevel) {
    case 0:
      return 'Low Risk\nYour vitals are within safe ranges. Continue monitoring as usual.';
    case 1:
      return 'Moderate Risk\nSome vitals are elevated. Rest and recheck in 1-2 hours.';
    case 2:
      return 'High Risk\nMedical attention recommended. Contact your healthcare team.';
    default:
      return 'Risk assessment pending';
  }
}

/// Get recommended action
String getRecommendedAction() {
  if (riskLevel == 2) {
    return '• Contact your oncology team immediately\n• Rest and avoid exertion\n• Drink plenty of fluids\n• Monitor temperature hourly';
  } else if (riskLevel == 1) {
    return '• Rest for 1-2 hours\n• Recheck vitals\n• Stay hydrated\n• Report if symptoms worsen';
  } else {
    return '• Continue normal activities\n• Maintain hydration\n• Record next reading as scheduled';
  }
}
}