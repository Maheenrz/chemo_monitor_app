import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chemo_monitor_app/models/health_data_model.dart';
import 'package:uuid/uuid.dart';
import 'package:chemo_monitor_app/services/ml_prediction_service.dart';
import 'package:chemo_monitor_app/services/notification_service.dart'; // 🔔 NEW
import 'package:chemo_monitor_app/services/notification_service.dart';

class HealthDataService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String healthDataCollection = 'health_data';
  final MLPredictionService _mlService = MLPredictionService();
  final NotificationService _notificationService = NotificationService(); // 🔔 NEW

  // Initialize ML model
  Future<void> initializeMLModel() async {
    try {
      await _mlService.loadModel();
      print('✅ ML model initialized in HealthDataService');
    } catch (e) {
      print('⚠️ ML model failed to load: $e');
    }
  }

  /// Add new health data entry WITH ML prediction AND automatic notifications
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
      
      // Initialize ML model if not loaded
      if (!_mlService.isModelLoaded) {
        await _mlService.loadModel();
      }

      // Prepare input for ML model
      List<double> mlInput = [
        heartRate.toDouble(),
        spo2Level.toDouble(),
        systolicBP.toDouble(),
        diastolicBP.toDouble(),
        temperature,
      ];

      // Get ML prediction
      int riskLevel;
      List<double>? mlProbabilities;

      try {
        print('🤖 Running ML prediction...');
        final prediction = await _mlService.predict(mlInput);
        riskLevel = prediction['riskLevel'];
        mlProbabilities = prediction['probabilities'];
        print('✅ ML prediction successful: Risk Level $riskLevel');
      } catch (e) {
        print('⚠️ ML prediction failed, using rule-based fallback: $e');
        riskLevel = _calculateBasicRisk(
          heartRate,
          spo2Level,
          systolicBP,
          temperature,
        );
        mlProbabilities = null;
      }

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
        riskLevel: riskLevel,
        mlOutputProbabilities: mlProbabilities,
      );

      // Save to Firestore
      await _firestore
          .collection(healthDataCollection)
          .doc(id)
          .set(healthData.toMap());

      print('💾 Health data saved with ML prediction');

      // 🔔 STEP: Check risk level and send notifications
      await _handleRiskNotifications(patientId, healthData);

      return id;
    } catch (e) {
      throw Exception('Failed to save health data: $e');
    }
  }

  /// 🚨 Handle risk-based notifications
  Future<void> _handleRiskNotifications(String patientId, HealthDataModel healthData) async {
    try {
      // Get patient info
      final patientDoc = await _firestore.collection('users').doc(patientId).get();
      if (!patientDoc.exists) return;

      final patientData = patientDoc.data()!;
      final String? doctorId = patientData['assignedDoctorId'];
      final String patientName = patientData['name'] ?? 'Patient';

      if (doctorId == null) {
        print('⚠️ No doctor assigned to this patient');
        return;
      }

      // Send notification based on risk level
      if (healthData.riskLevel == 2) {
        // HIGH RISK - Critical Alert
        print('🚨 HIGH RISK DETECTED - Sending alert to doctor');
        await _notificationService.sendHighRiskAlert(
          doctorId: doctorId,
          patientId: patientId,
          patientName: patientName,
          healthData: healthData,
        );
      } else if (healthData.riskLevel == 1) {
        // MODERATE RISK - Warning notification
        print('⚠️ MODERATE RISK DETECTED - Sending notification to doctor');
        await _notificationService.sendModerateRiskNotification(
          doctorId: doctorId,
          patientId: patientId,
          patientName: patientName,
          healthData: healthData,
        );
      } else {
        print('✅ LOW RISK - No notification needed');
      }
    } catch (e) {
      print('❌ Error handling risk notifications: $e');
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

  /// 📊 Get health data for chart (last N days)
  Future<List<HealthDataModel>> getHealthDataForChart(String patientId, {int days = 7}) async {
    try {
      final DateTime startDate = DateTime.now().subtract(Duration(days: days));
      
      final snapshot = await _firestore
          .collection(healthDataCollection)
          .where('patientId', isEqualTo: patientId)
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .orderBy('timestamp', descending: false)
          .get();

      return snapshot.docs
          .map((doc) => HealthDataModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting chart data: $e');
      return [];
    }
  }

  /// 📈 Get health statistics
  Future<Map<String, dynamic>> getHealthStatistics(String patientId) async {
    try {
      final healthData = await getHealthDataForChart(patientId, days: 30);
      
      if (healthData.isEmpty) {
        return {
          'totalEntries': 0,
          'avgHeartRate': 0,
          'avgSpO2': 0,
          'avgSystolicBP': 0,
          'avgTemperature': 0,
          'highRiskCount': 0,
          'moderateRiskCount': 0,
          'lowRiskCount': 0,
        };
      }

      int highRiskCount = healthData.where((d) => d.riskLevel == 2).length;
      int moderateRiskCount = healthData.where((d) => d.riskLevel == 1).length;
      int lowRiskCount = healthData.where((d) => d.riskLevel == 0).length;

      return {
        'totalEntries': healthData.length,
        'avgHeartRate': healthData.map((d) => d.heartRate).reduce((a, b) => a + b) / healthData.length,
        'avgSpO2': healthData.map((d) => d.spo2Level).reduce((a, b) => a + b) / healthData.length,
        'avgSystolicBP': healthData.map((d) => d.systolicBP).reduce((a, b) => a + b) / healthData.length,
        'avgTemperature': healthData.map((d) => d.temperature).reduce((a, b) => a + b) / healthData.length,
        'highRiskCount': highRiskCount,
        'moderateRiskCount': moderateRiskCount,
        'lowRiskCount': lowRiskCount,
      };
    } catch (e) {
      print('Error calculating statistics: $e');
      return {};
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