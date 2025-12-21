import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chemo_monitor_app/services/notification_service.dart';
import 'package:chemo_monitor_app/screens/doctor/patient_detail_screen.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(body: Center(child: Text('Not logged in')));
    }

    return Scaffold(
      backgroundColor: Color(0xFFE8F1FC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          'Notifications',
          style: TextStyle(
            color: Color(0xFF2D3E50),
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Color(0xFFE8F1FC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.arrow_back, size: 20, color: Color(0xFF7BA3D6)),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Mark all as read button
          StreamBuilder<int>(
            stream: _notificationService.getUnreadCount(user.uid),
            builder: (context, snapshot) {
              final unreadCount = snapshot.data ?? 0;
              if (unreadCount == 0) return SizedBox.shrink();
              
              return IconButton(
                icon: Icon(Icons.done_all_rounded, color: Color(0xFF6FD195)),
                onPressed: () async {
                  await _notificationService.markAllAsRead(user.uid);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('All notifications marked as read'),
                      backgroundColor: Color(0xFF6FD195),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                tooltip: 'Mark all as read',
              );
            },
          ),
          
          // Clear read notifications
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: Color(0xFF7BA3D6)),
            onSelected: (value) async {
              if (value == 'clear') {
                await _notificationService.clearReadNotifications(user.uid);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Cleared read notifications'),
                    backgroundColor: Color(0xFF6FD195),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep, color: Colors.grey[700]),
                    SizedBox(width: 12),
                    Text('Clear Read'),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _notificationService.getNotifications(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7BA3D6)),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Error loading notifications'),
                ],
              ),
            );
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.notifications_none_rounded,
                      size: 60,
                      color: Color(0xFF7BA3D6),
                    ),
                  ),
                  SizedBox(height: 24),
                  Text(
                    'No Notifications',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3E50),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'You\'re all caught up!',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF8E9AAF),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              return NotificationCard(
                notification: notifications[index],
                notificationService: _notificationService,
              );
            },
          );
        },
      ),
    );
  }
}

class NotificationCard extends StatelessWidget {
  final Map<String, dynamic> notification;
  final NotificationService notificationService;

  const NotificationCard({
    super.key,
    required this.notification,
    required this.notificationService,
  });

  Color _getBackgroundColor() {
    final type = notification['type'];
    final isRead = notification['read'] ?? false;
    
    if (type == 'high_risk') {
      return isRead ? Color(0xFFFFEEF1).withOpacity(0.5) : Color(0xFFFFEEF1);
    } else {
      return isRead ? Color(0xFFFFF4EC).withOpacity(0.5) : Color(0xFFFFF4EC);
    }
  }

  Color _getBorderColor() {
    final type = notification['type'];
    return type == 'high_risk' ? Color(0xFFF08B9C) : Color(0xFFFAB87F);
  }

  IconData _getIcon() {
    final type = notification['type'];
    return type == 'high_risk' ? Icons.error_rounded : Icons.warning_amber_rounded;
  }

  Color _getIconColor() {
    final type = notification['type'];
    return type == 'high_risk' ? Color(0xFFF08B9C) : Color(0xFFFAB87F);
  }

  String _formatTimestamp() {
    try {
      final timestamp = notification['timestamp'];
      if (timestamp == null) return 'Just now';
      
      final dateTime = timestamp.toDate();
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      
      if (difference.inMinutes < 1) return 'Just now';
      if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
      if (difference.inHours < 24) return '${difference.inHours}h ago';
      if (difference.inDays < 7) return '${difference.inDays}d ago';
      
      return DateFormat('MMM dd, hh:mm a').format(dateTime);
    } catch (e) {
      return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRead = notification['read'] ?? false;
    final patientName = notification['patientName'] ?? 'Unknown Patient';
    final message = notification['message'] ?? 'No message';
    final vitals = notification['vitals'];

    return Dismissible(
      key: Key(notification['id']),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20),
        margin: EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        notificationService.deleteNotification(notification['id']);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Notification deleted'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: _getBackgroundColor(),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _getBorderColor().withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () async {
              // Mark as read
              if (!isRead) {
                await notificationService.markAsRead(notification['id']);
              }
              
              // Navigate to patient detail
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PatientDetailScreen(
                    patientId: notification['patientId'],
                    patientEmail: '', // You might want to store this
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(_getIcon(), color: _getIconColor(), size: 24),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    patientName,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2D3E50),
                                    ),
                                  ),
                                ),
                                if (!isRead)
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: _getIconColor(),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                            SizedBox(height: 4),
                            Text(
                              _formatTimestamp(),
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF8E9AAF),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 12),
                  
                  // Message
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF2D3E50),
                    ),
                  ),
                  
                  // Vitals (if available)
                  if (vitals != null) ...[
                    SizedBox(height: 12),
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _VitalChip('${vitals['heartRate']} bpm', Icons.favorite),
                          _VitalChip('${vitals['spo2']}%', Icons.air),
                          _VitalChip('${vitals['temperature']}°C', Icons.thermostat),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _VitalChip extends StatelessWidget {
  final String value;
  final IconData icon;

  const _VitalChip(this.value, this.icon);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Color(0xFF8E9AAF)),
        SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2D3E50),
          ),
        ),
      ],
    );
  }
}