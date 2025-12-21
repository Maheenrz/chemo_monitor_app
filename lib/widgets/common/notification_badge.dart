import 'package:flutter/material.dart';

/// ✅ Simple Notification Badge Widget
/// Shows red badge with unread count
class NotificationBadge extends StatelessWidget {
  final int count;
  final VoidCallback onTap;
  final Color? badgeColor;
  final Color? iconColor;
  final double? iconSize;

  const NotificationBadge({
    super.key,
    required this.count,
    required this.onTap,
    this.badgeColor,
    this.iconColor,
    this.iconSize = 24,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(8),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Bell Icon
            Icon(
              Icons.notifications_rounded,
              color: iconColor ?? Color(0xFF7BA3D6),
              size: iconSize,
            ),
            
            // Badge (only show if count > 0)
            if (count > 0)
              Positioned(
                right: -4,
                top: -4,
                child: Container(
                  padding: EdgeInsets.all(count > 9 ? 4 : 6),
                  decoration: BoxDecoration(
                    color: badgeColor ?? Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  constraints: BoxConstraints(
                    minWidth: 20,
                    minHeight: 20,
                  ),
                  child: Center(
                    child: Text(
                      count > 99 ? '99+' : count.toString(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// ✅ Animated Notification Badge (with pulse effect for urgent)
class AnimatedNotificationBadge extends StatefulWidget {
  final int count;
  final int urgentCount; // Number of urgent notifications
  final VoidCallback onTap;

  const AnimatedNotificationBadge({
    super.key,
    required this.count,
    this.urgentCount = 0,
    required this.onTap,
  });

  @override
  State<AnimatedNotificationBadge> createState() => _AnimatedNotificationBadgeState();
}

class _AnimatedNotificationBadgeState extends State<AnimatedNotificationBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    // Pulse animation for urgent notifications
    if (widget.urgentCount > 0) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(AnimatedNotificationBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.urgentCount > 0 && oldWidget.urgentCount == 0) {
      _controller.repeat(reverse: true);
    } else if (widget.urgentCount == 0 && oldWidget.urgentCount > 0) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: EdgeInsets.all(8),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Bell Icon
            Icon(
              Icons.notifications_rounded,
              color: widget.urgentCount > 0 ? Colors.red[400] : Color(0xFF7BA3D6),
              size: 24,
            ),
            
            // Badge
            if (widget.count > 0)
              Positioned(
                right: -4,
                top: -4,
                child: AnimatedBuilder(
                  animation: _scaleAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: widget.urgentCount > 0 ? _scaleAnimation.value : 1.0,
                      child: Container(
                        padding: EdgeInsets.all(widget.count > 9 ? 4 : 6),
                        decoration: BoxDecoration(
                          color: widget.urgentCount > 0 ? Colors.red : Colors.orange,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: widget.urgentCount > 0
                              ? [
                                  BoxShadow(
                                    color: Colors.red.withOpacity(0.5),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  )
                                ]
                              : null,
                        ),
                        constraints: BoxConstraints(
                          minWidth: 20,
                          minHeight: 20,
                        ),
                        child: Center(
                          child: Text(
                            widget.count > 99 ? '99+' : widget.count.toString(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}