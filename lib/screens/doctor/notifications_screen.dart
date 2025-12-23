import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chemo_monitor_app/config/app_constants.dart';
import 'package:chemo_monitor_app/services/notification_service.dart';
import 'package:chemo_monitor_app/widgets/common/glass_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<NotificationModel> _notifications = [];
  bool _isLoading = true;
  String _selectedFilter = 'All';
  StreamSubscription? _notificationSubscription;

  @override
  void initState() {
    super.initState();
    _setupNotificationStream();
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }

  // Replace _setupNotificationStream() in notifications_screen.dart

  void _setupNotificationStream() {
    final user = _auth.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    // Set a timeout to prevent infinite loading
    Future.delayed(Duration(seconds: 10), () {
      if (_isLoading && mounted) {
        print('⏱️ Stream timeout - falling back to direct query');
        setState(() => _isLoading = false);
        _loadNotifications(); // Fallback to direct query
      }
    });

    try {
      print('🔔 Setting up notification stream for doctor: ${user.uid}');

      _notificationSubscription = FirebaseFirestore.instance
          .collection('notifications')
          .where('doctorId', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true)
          .limit(50)
          .snapshots()
          .timeout(
        Duration(seconds: 10),
        onTimeout: (sink) {
          print('⏱️ Stream timeout!');
          sink.close();
        },
      ).listen(
        (snapshot) {
          print('📨 Received ${snapshot.docs.length} notifications');

          if (mounted) {
            try {
              final notifications = snapshot.docs
                  .map((doc) {
                    try {
                      final data = doc.data();
                      data['id'] = doc.id;

                      // Debug: Print each notification
                      print('  - Notification: ${doc.id} (${data['type']})');

                      return NotificationModel.fromMap(data);
                    } catch (e) {
                      print('❌ Error parsing notification ${doc.id}: $e');
                      return null;
                    }
                  })
                  .whereType<NotificationModel>()
                  .toList();

              setState(() {
                _notifications = notifications;
                _isLoading = false;
              });
            } catch (e) {
              print('❌ Error processing notifications: $e');
              setState(() => _isLoading = false);
            }
          }
        },
        onError: (error) {
          print('❌ Stream error: $error');
          if (mounted) {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error loading notifications: $error'),
                backgroundColor: AppColors.riskHigh,
              ),
            );
          }
        },
        onDone: () {
          print('✅ Stream completed');
        },
      );
    } catch (e) {
      print('❌ Error setting up stream: $e');
      setState(() => _isLoading = false);
      _loadNotifications(); // Fallback
    }
  }

// Also update _loadNotifications() to be more robust
  Future<void> _loadNotifications() async {
    final user = _auth.currentUser;
    if (user == null) return;

    print('📥 Loading notifications directly for doctor: ${user.uid}');

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('notifications')
          .where('doctorId', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get()
          .timeout(Duration(seconds: 10));

      print('📊 Found ${snapshot.docs.length} notifications');

      final notifications = snapshot.docs
          .map((doc) {
            try {
              final data = doc.data();
              data['id'] = doc.id;
              print('  - Processing: ${doc.id}');
              return NotificationModel.fromMap(data);
            } catch (e) {
              print('❌ Error parsing notification ${doc.id}: $e');
              print('   Data: ${doc.data()}');
              return null;
            }
          })
          .whereType<NotificationModel>()
          .toList();

      if (mounted) {
        setState(() {
          _notifications = notifications;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading notifications: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.riskHigh,
          ),
        );
      }
    }
  }

  List<NotificationModel> get _filteredNotifications {
    if (_selectedFilter == 'All') return _notifications;
    if (_selectedFilter == 'Unread') {
      return _notifications.where((n) => !n.read).toList();
    }
    if (_selectedFilter == 'High Risk') {
      return _notifications.where((n) => n.type == 'high_risk').toList();
    }
    if (_selectedFilter == 'Moderate Risk') {
      return _notifications.where((n) => n.type == 'moderate_risk').toList();
    }
    return _notifications;
  }

  Map<String, dynamic> _getNotificationStyle(String type, int riskLevel) {
    switch (type) {
      case 'high_risk':
        return {
          'color': AppColors.riskHigh,
          'bgColor': AppColors.riskHighBg,
          'icon': Icons.error_rounded,
          'title': 'High Risk Alert',
        };
      case 'moderate_risk':
        return {
          'color': AppColors.riskModerate,
          'bgColor': AppColors.riskModerateBg,
          'icon': Icons.warning_amber_rounded,
          'title': 'Moderate Risk Alert',
        };
      default:
        return {
          'color': AppColors.textSecondary,
          'bgColor': AppColors.lightBlue,
          'icon': Icons.notifications_rounded,
          'title': 'Notification',
        };
    }
  }

  String _getTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return DateFormat('MMM dd').format(timestamp);
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      await _notificationService.markAsRead(notificationId);
      // The stream will update automatically
    } catch (e) {
      print('Error marking as read: $e');
    }
  }

  Future<void> _markAllAsRead() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _notificationService.markAllAsRead(user.uid);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('All notifications marked as read'),
          backgroundColor: AppColors.softGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          ),
        ),
      );
    } catch (e) {
      print('Error marking all as read: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.riskHigh,
        ),
      );
    }
  }

  Future<void> _clearReadNotifications() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _notificationService.clearReadNotifications(user.uid);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Read notifications cleared'),
          backgroundColor: AppColors.primaryBlue,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          ),
        ),
      );
    } catch (e) {
      print('Error clearing notifications: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.riskHigh,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mainBackground,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          'Notifications',
          style: AppTextStyles.heading3.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          if (_notifications.any((n) => !n.read))
            IconButton(
              icon: Container(
                padding: EdgeInsets.all(AppDimensions.spaceS),
                decoration: BoxDecoration(
                  color: AppColors.lightBlue,
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusCircle),
                ),
                child: Icon(
                  Icons.done_all_rounded,
                  size: AppDimensions.iconS,
                  color: AppColors.primaryBlue,
                ),
              ),
              onPressed: _markAllAsRead,
              tooltip: 'Mark all as read',
            ),
          IconButton(
            icon: Container(
              padding: EdgeInsets.all(AppDimensions.spaceS),
              decoration: BoxDecoration(
                color: AppColors.lightBlue,
                borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
              ),
              child: Icon(
                Icons.delete_sweep_rounded,
                size: AppDimensions.iconS,
                color: AppColors.primaryBlue,
              ),
            ),
            onPressed: _clearReadNotifications,
            tooltip: 'Clear read notifications',
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
              ),
            )
          : Column(
              children: [
                // Filter Chips
                Padding(
                  padding: EdgeInsets.all(AppDimensions.paddingMedium),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('All', Icons.all_inbox_rounded),
                        SizedBox(width: AppDimensions.spaceS),
                        _buildFilterChip('Unread', Icons.markunread_rounded),
                        SizedBox(width: AppDimensions.spaceS),
                        _buildFilterChip(
                            'High Risk', Icons.error_outline_rounded),
                        SizedBox(width: AppDimensions.spaceS),
                        _buildFilterChip(
                            'Moderate', Icons.warning_amber_outlined),
                      ],
                    ),
                  ),
                ),

                // Unread Count Badge
                if (_notifications.any((n) => !n.read))
                  Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: AppDimensions.paddingMedium),
                    child: Row(
                      children: [
                        Icon(
                          Icons.circle,
                          size: 8,
                          color: AppColors.primaryBlue,
                        ),
                        SizedBox(width: 6),
                        Text(
                          '${_notifications.where((n) => !n.read).length} unread',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.primaryBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Notifications List
                Expanded(
                  child: _filteredNotifications.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: EdgeInsets.all(AppDimensions.paddingMedium),
                          itemCount: _filteredNotifications.length,
                          itemBuilder: (context, index) {
                            final notification = _filteredNotifications[index];
                            return _buildNotificationCard(notification);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildFilterChip(String label, IconData icon) {
    final isSelected = _selectedFilter == label;

    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: AppDimensions.iconXS,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
          SizedBox(width: AppDimensions.spaceXS),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _selectedFilter = label);
      },
      backgroundColor: Colors.white,
      selectedColor: AppColors.primaryBlue,
      labelStyle: AppTextStyles.caption.copyWith(
        color: isSelected ? Colors.white : AppColors.textSecondary,
        fontWeight: FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
        side: BorderSide(
          color: isSelected ? Colors.transparent : AppColors.lightBlue,
        ),
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    final style =
        _getNotificationStyle(notification.type, notification.riskLevel);
    final isUnread = !notification.read;

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        decoration: BoxDecoration(
          color: AppColors.riskHighBg,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        ),
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: AppDimensions.paddingLarge),
        child: Icon(
          Icons.delete_rounded,
          color: AppColors.riskHigh,
          size: AppDimensions.iconL,
        ),
      ),
      onDismissed: (direction) async {
        try {
          await _notificationService.deleteNotification(notification.id);
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting: $e'),
              backgroundColor: AppColors.riskHigh,
            ),
          );
          // Reload on error
          _loadNotifications();
        }
      },
      child: Container(
        margin: EdgeInsets.only(bottom: AppDimensions.spaceL),
        child: GlassCard(
          padding: EdgeInsets.all(AppDimensions.paddingMedium),
          borderRadius: AppDimensions.radiusLarge,
          onTap: () => _markAsRead(notification.id),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Notification Icon
              Container(
                padding: EdgeInsets.all(AppDimensions.spaceM),
                decoration: BoxDecoration(
                  color: style['bgColor'],
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusMedium),
                ),
                child: Icon(
                  style['icon'],
                  color: style['color'],
                  size: AppDimensions.iconM,
                ),
              ),

              SizedBox(width: AppDimensions.spaceL),

              // Notification Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            style['title'],
                            style: AppTextStyles.bodyLarge.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: isUnread
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isUnread)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppColors.primaryBlue,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: AppDimensions.spaceXS),
                    Text(
                      notification.message,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (notification.vitals != null) ...[
                      SizedBox(height: AppDimensions.spaceM),
                      Container(
                        padding: EdgeInsets.all(AppDimensions.paddingSmall),
                        decoration: BoxDecoration(
                          color: style['bgColor'],
                          borderRadius:
                              BorderRadius.circular(AppDimensions.radiusMedium),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            if (notification.vitals!['heartRate'] != null)
                              _buildVitalItem(
                                icon: Icons.favorite_rounded,
                                value: '${notification.vitals!['heartRate']}',
                                unit: 'bpm',
                              ),
                            if (notification.vitals!['spo2'] != null)
                              _buildVitalItem(
                                icon: Icons.air_rounded,
                                value: '${notification.vitals!['spo2']}',
                                unit: '%',
                              ),
                            if (notification.vitals!['temperature'] != null)
                              _buildVitalItem(
                                icon: Icons.thermostat_rounded,
                                value: '${notification.vitals!['temperature']}',
                                unit: '°C',
                              ),
                            if (notification.vitals!['systolicBP'] != null &&
                                notification.vitals!['diastolicBP'] != null)
                              _buildVitalItem(
                                icon: Icons.monitor_heart_rounded,
                                value:
                                    '${notification.vitals!['systolicBP']}/${notification.vitals!['diastolicBP']}',
                                unit: 'mmHg',
                              ),
                          ],
                        ),
                      ),
                    ],
                    SizedBox(height: AppDimensions.spaceS),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _getTimeAgo(notification.timestamp),
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          'Patient: ${notification.patientName}',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVitalItem({
    required IconData icon,
    required String value,
    required String unit,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          size: AppDimensions.iconS,
          color: AppColors.textSecondary,
        ),
        SizedBox(height: AppDimensions.spaceXS),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: value,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextSpan(
                text: ' $unit',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppDimensions.paddingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: AppColors.lightBlue,
                borderRadius: BorderRadius.circular(AppDimensions.radiusXXL),
              ),
              child: Icon(
                Icons.notifications_off_rounded,
                size: AppDimensions.iconXXL,
                color: AppColors.primaryBlue,
              ),
            ),
            SizedBox(height: AppDimensions.spaceXXXL),
            Text(
              'No notifications',
              style: AppTextStyles.heading2.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: AppDimensions.spaceM),
            Text(
              'You\'re all caught up! New alerts will appear here.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
