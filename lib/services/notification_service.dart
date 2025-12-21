import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chemo_monitor_app/models/health_data_model.dart';
import 'package:flutter/material.dart';
/// ✅ SIMPLE Notification Service - Uses only Firestore
/// No complex FCM setup needed - works immediately!
class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  /// 🚨 Send HIGH RISK alert to doctor
  Future<void> sendHighRiskAlert({
    required String doctorId,
    required String patientId,
    required String patientName,
    required HealthDataModel healthData,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'type': 'high_risk',
        'doctorId': doctorId,
        'patientId': patientId,
        'patientName': patientName,
        'riskLevel': healthData.riskLevel,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
        'priority': 'urgent', // For sorting
        'message': '$patientName has HIGH RISK vitals that need immediate attention!',
        'vitals': {
          'heartRate': healthData.heartRate,
          'spo2': healthData.spo2Level,
          'temperature': healthData.temperature,
          'systolicBP': healthData.systolicBP,
          'diastolicBP': healthData.diastolicBP,
        },
      });

      print('✅ HIGH RISK alert sent to doctor');
    } catch (e) {
      print('❌ Error sending high-risk alert: $e');
    }
  }

  /// ⚠️ Send MODERATE RISK notification to doctor
  Future<void> sendModerateRiskNotification({
    required String doctorId,
    required String patientId,
    required String patientName,
    required HealthDataModel healthData,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'type': 'moderate_risk',
        'doctorId': doctorId,
        'patientId': patientId,
        'patientName': patientName,
        'riskLevel': healthData.riskLevel,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
        'priority': 'normal',
        'message': '$patientName\'s vitals show moderate risk and need monitoring.',
        'vitals': {
          'heartRate': healthData.heartRate,
          'spo2': healthData.spo2Level,
          'temperature': healthData.temperature,
          'systolicBP': healthData.systolicBP,
          'diastolicBP': healthData.diastolicBP,
        },
      });

      print('✅ MODERATE RISK notification sent');
    } catch (e) {
      print('❌ Error sending moderate-risk notification: $e');
    }
  }

  /// 📊 Get UNREAD notification count (for badge)
  Stream<int> getUnreadCount(String doctorId) {
    return _firestore
        .collection('notifications')
        .where('doctorId', isEqualTo: doctorId)
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// 📋 Get ALL notifications for doctor (with real-time updates)
  Stream<List<Map<String, dynamic>>> getNotifications(String doctorId) {
    return _firestore
        .collection('notifications')
        .where('doctorId', isEqualTo: doctorId)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            Map<String, dynamic> data = doc.data();
            data['id'] = doc.id; // Add document ID
            return data;
          }).toList();
        });
  }

  /// 🚨 Get URGENT notifications only
  Stream<List<Map<String, dynamic>>> getUrgentNotifications(String doctorId) {
    return _firestore
        .collection('notifications')
        .where('doctorId', isEqualTo: doctorId)
        .where('priority', isEqualTo: 'urgent')
        .where('read', isEqualTo: false)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            Map<String, dynamic> data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList();
        });
  }

  /// ✅ Mark notification as READ
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'read': true});
      print('✅ Notification marked as read');
    } catch (e) {
      print('❌ Error marking as read: $e');
    }
  }

  /// ✅ Mark ALL notifications as READ
  Future<void> markAllAsRead(String doctorId) async {
    try {
      final snapshot = await _firestore
          .collection('notifications')
          .where('doctorId', isEqualTo: doctorId)
          .where('read', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'read': true});
      }
      await batch.commit();

      print('✅ All notifications marked as read');
    } catch (e) {
      print('❌ Error marking all as read: $e');
    }
  }

  /// 🗑️ Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
      print('✅ Notification deleted');
    } catch (e) {
      print('❌ Error deleting notification: $e');
    }
  }

  /// 🧹 Clear ALL READ notifications
  Future<void> clearReadNotifications(String doctorId) async {
    try {
      final snapshot = await _firestore
          .collection('notifications')
          .where('doctorId', isEqualTo: doctorId)
          .where('read', isEqualTo: true)
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      print('✅ Cleared ${snapshot.docs.length} read notifications');
    } catch (e) {
      print('❌ Error clearing notifications: $e');
    }
  }

  /// 🔔 Show in-app alert dialog (call this when urgent notification arrives)
  static void showAlertDialog(BuildContext context, Map<String, dynamic> notification) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning_rounded, color: Colors.red, size: 32),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'URGENT ALERT',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification['message'] ?? 'Patient needs attention',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            if (notification['vitals'] != null) ...[
              Text(
                'Current Vitals:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              _buildVitalRow('Heart Rate', '${notification['vitals']['heartRate']} bpm'),
              _buildVitalRow('SpO2', '${notification['vitals']['spo2']}%'),
              _buildVitalRow('Temperature', '${notification['vitals']['temperature']}°C'),
              _buildVitalRow('BP', '${notification['vitals']['systolicBP']}/${notification['vitals']['diastolicBP']} mmHg'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Dismiss', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to patient detail screen
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('View Patient'),
          ),
        ],
      ),
    );
  }

  static Widget _buildVitalRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[700])),
          Text(value, style: TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}