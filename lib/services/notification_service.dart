import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chemo_monitor_app/models/health_data_model.dart';
import 'package:flutter/material.dart';
import 'package:chemo_monitor_app/config/app_constants.dart';
import 'dart:ui';

// Add this class at the top of notification_service.dart
class NotificationModel {
  final String id;
  final String type;
  final String doctorId;
  final String patientId;
  final String patientName;
  final String message;
  final int riskLevel;
  final DateTime timestamp;
  final bool read;
  final String priority;
  final Map<String, dynamic>? vitals;

  NotificationModel({
    required this.id,
    required this.type,
    required this.doctorId,
    required this.patientId,
    required this.patientName,
    required this.message,
    required this.riskLevel,
    required this.timestamp,
    required this.read,
    required this.priority,
    this.vitals,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> data) {
    return NotificationModel(
      id: data['id'] ?? '',
      type: data['type'] ?? '',
      doctorId: data['doctorId'] ?? '',
      patientId: data['patientId'] ?? '',
      patientName: data['patientName'] ?? '',
      message: data['message'] ?? '',
      riskLevel: data['riskLevel'] ?? 0,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      read: data['read'] ?? false,
      priority: data['priority'] ?? 'normal',
      vitals: data['vitals'] is Map
          ? Map<String, dynamic>.from(data['vitals'])
          : null,
    );
  }
}

/// ✅ SIMPLE Notification Service - Uses only Firestore
/// Updated with Glassmorphism UI and AppColors integration
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
        'timestamp': Timestamp
            .now(), // ✅ FIXED: Use Timestamp.now() instead of serverTimestamp()
        'read': false,
        'priority': 'urgent',
        'message':
            '$patientName has HIGH RISK vitals that need immediate attention!',
        'vitals': {
          'heartRate': healthData.heartRate,
          'spo2': healthData.spo2Level,
          'temperature': healthData.temperature,
          'systolicBP': healthData.systolicBP,
          'diastolicBP': healthData.diastolicBP,
        },
        'riskColor': _getRiskColorHex(healthData.riskLevel),
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
        'timestamp': Timestamp
            .now(), // ✅ FIXED: Use Timestamp.now() instead of serverTimestamp()
        'read': false,
        'priority': 'normal',
        'message':
            '$patientName\'s vitals show moderate risk and need monitoring.',
        'vitals': {
          'heartRate': healthData.heartRate,
          'spo2': healthData.spo2Level,
          'temperature': healthData.temperature,
          'systolicBP': healthData.systolicBP,
          'diastolicBP': healthData.diastolicBP,
        },
        'riskColor': _getRiskColorHex(healthData.riskLevel),
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
        data['id'] = doc.id;
        data['timestamp'] = (data['timestamp'] as Timestamp?)?.toDate();
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
        data['timestamp'] = (data['timestamp'] as Timestamp?)?.toDate();
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

  /// 🔔 Show in-app alert dialog (Glassmorphism style)
  static void showAlertDialog(
      BuildContext context, Map<String, dynamic> notification) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.all(20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: AppShadows.elevation3,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Padding(
                padding: EdgeInsets.all(AppDimensions.paddingLarge),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _getRiskColor(notification['riskLevel'] ?? 2)
                                .withOpacity(0.2),
                            borderRadius: BorderRadius.circular(
                                AppDimensions.radiusCircle),
                          ),
                          child: Icon(
                            Icons.warning_rounded,
                            color:
                                _getRiskColor(notification['riskLevel'] ?? 2),
                            size: 32,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'URGENT ALERT',
                            style: AppTextStyles.heading3.copyWith(
                              color:
                                  _getRiskColor(notification['riskLevel'] ?? 2),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppDimensions.spaceL),
                    Text(
                      notification['message'] ?? 'Patient needs attention',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: AppDimensions.spaceL),
                    if (notification['vitals'] != null) ...[
                      Container(
                        padding: EdgeInsets.all(AppDimensions.paddingMedium),
                        decoration: BoxDecoration(
                          color: AppColors.lightBlue.withOpacity(0.3),
                          borderRadius:
                              BorderRadius.circular(AppDimensions.radiusLarge),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Current Vitals:',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: AppDimensions.spaceM),
                            _buildVitalRow('Heart Rate',
                                '${notification['vitals']['heartRate']} bpm'),
                            _buildVitalRow(
                                'SpO2', '${notification['vitals']['spo2']}%'),
                            _buildVitalRow('Temperature',
                                '${notification['vitals']['temperature']}°C'),
                            _buildVitalRow('Blood Pressure',
                                '${notification['vitals']['systolicBP']}/${notification['vitals']['diastolicBP']} mmHg'),
                          ],
                        ),
                      ),
                    ],
                    SizedBox(height: AppDimensions.spaceXL),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.textSecondary,
                          ),
                          child: Text(
                            'Dismiss',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        SizedBox(width: AppDimensions.spaceM),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            // Navigate to patient detail screen would be implemented here
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                _getRiskColor(notification['riskLevel'] ?? 2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  AppDimensions.radiusMedium),
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: AppDimensions.paddingLarge,
                              vertical: AppDimensions.paddingMedium,
                            ),
                          ),
                          child: Text(
                            'View Patient',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Widget _buildVitalRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  static Color _getRiskColor(int? riskLevel) {
    // ✅ Changed int to int?
    switch (riskLevel) {
      case 0:
        return AppColors.riskLow;
      case 1:
        return AppColors.riskModerate;
      case 2:
        return AppColors.riskHigh;
      default:
        return AppColors.textSecondary;
    }
  }

  static String _getRiskColorHex(int? riskLevel) {
    // ✅ Changed int to int?
    switch (riskLevel) {
      case 0:
        return '#6FD195';
      case 1:
        return '#FAB87F';
      case 2:
        return '#F08B9C';
      default:
        return '#8E9AAF';
    }
  }
}
