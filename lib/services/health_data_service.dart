import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chemo_monitor_app/models/health_data_model.dart';
import 'package:uuid/uuid.dart';

class HealthDataService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String healthDataCollection = 'healthData';

  /// Add new health data entry
  Future<String> addHealthData({
    required String patientId,
    required int heartRate,
    required int spo2Level,
    required int systolicBP,
    required int diastolicBP,
    required double temperature,
    String? additionalNotes,
  }) async {
    try {
      final String id = const Uuid().v4();
      
      final healthData = HealthDataModel(
        id: id,
        patientId: patientId,
        heartRate: heartRate,
        spo2Level: spo2Level,
        systolicBP: systolicBP,
        diastolicBP: diastolicBP,
        temperature: temperature,
        additionalNotes: additionalNotes,
        timestamp: DateTime.now(),
        // ML prediction will be added later
        riskLevel: _calculateBasicRisk(
          heartRate,
          spo2Level,
          systolicBP,
          temperature,
        ),
        mlOutputProbabilities: null,
      );

      await _firestore
          .collection(healthDataCollection)
          .doc(id)
          .set(healthData.toMap());

      return id;
    } catch (e) {
      throw Exception('Failed to save health data: $e');
    }
  }

  /// Get all health data for a patient (sorted by date)
  Stream<List<HealthDataModel>> getPatientHealthData(String patientId) {
    return _firestore
        .collection(healthDataCollection)
        .where('patientId', isEqualTo: patientId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => HealthDataModel.fromMap(doc.data()))
          .toList();
    });
  }

  /// Get latest health data entry
  Future<HealthDataModel?> getLatestHealthData(String patientId) async {
    try {
      final snapshot = await _firestore
          .collection(healthDataCollection)
          .where('patientId', isEqualTo: patientId)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      return HealthDataModel.fromMap(snapshot.docs.first.data());
    } catch (e) {
      print('Error getting latest health data: $e');
      return null;
    }
  }

  /// Update health data with ML prediction result
  Future<void> updateWithMLPrediction({
    required String healthDataId,
    required int riskLevel,
    required List<double> probabilities,
  }) async {
    try {
      await _firestore
          .collection(healthDataCollection)
          .doc(healthDataId)
          .update({
        'riskLevel': riskLevel,
        'mlOutputProbabilities': probabilities,
      });
    } catch (e) {
      throw Exception('Failed to update ML prediction: $e');
    }
  }

  /// Delete health data entry
  Future<void> deleteHealthData(String id) async {
    try {
      await _firestore.collection(healthDataCollection).doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete health data: $e');
    }
  }

  /// Calculate basic risk before ML prediction
  /// This matches your ML model's logic
  int _calculateBasicRisk(
    int heartRate,
    int spo2Level,
    int systolicBP,
    double temperature,
  ) {
    // High Risk (2): Fever or Low Oxygen
    if (temperature > 38 || spo2Level < 92) {
      return 2;
    }
    // Moderate Risk (1): High heart rate or High BP
    else if (heartRate > 100 || systolicBP > 140) {
      return 1;
    }
    // Low Risk (0): All normal
    else {
      return 0;
    }
  }

  /// Get health data count for patient
  Future<int> getHealthDataCount(String patientId) async {
    try {
      final snapshot = await _firestore
          .collection(healthDataCollection)
          .where('patientId', isEqualTo: patientId)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }
}