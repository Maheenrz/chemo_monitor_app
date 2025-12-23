import 'package:flutter/material.dart';
import 'package:chemo_monitor_app/config/app_constants.dart';

class AnimatedCircularProgress extends StatefulWidget {
  final double value;
  final double size;
  final double strokeWidth;
  final Color color;
  final Color backgroundColor;
  final String? label;
  final String? subtitle;
  final Duration duration;
  final Curve curve;

  const AnimatedCircularProgress({
    super.key,
    required this.value,
    this.size = 150,
    this.strokeWidth = 12,
    this.color = AppColors.primaryBlue,
    this.backgroundColor = AppColors.lightBlue,
    this.label,
    this.subtitle,
    this.duration = AppAnimations.slow,
    this.curve = Curves.easeOutCubic,
  });

  @override
  State<AnimatedCircularProgress> createState() => _AnimatedCircularProgressState();
}

class _AnimatedCircularProgressState extends State<AnimatedCircularProgress>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: widget.value).animate(
      CurvedAnimation(
        parent: _controller,
        curve: widget.curve,
      ),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedCircularProgress oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _animation = Tween<double>(begin: oldWidget.value, end: widget.value).animate(
        CurvedAnimation(
          parent: _controller,
          curve: widget.curve,
        ),
      );
      _controller
        ..value = 0
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Circle
          Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.color.withOpacity(0.1),
            ),
          ),

          // Animated Progress
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return SizedBox(
                width: widget.size,
                height: widget.size,
                child: CircularProgressIndicator(
                  value: _animation.value / 100,
                  strokeWidth: widget.strokeWidth,
                  backgroundColor: widget.backgroundColor,
                  valueColor: AlwaysStoppedAnimation<Color>(widget.color),
                ),
              );
            },
          ),

          // Center Content
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.label != null)
                AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    return Text(
                      '${(_animation.value).toInt()}',
                      style: TextStyle(
                        fontSize: widget.size * 0.28,
                        fontWeight: FontWeight.bold,
                        color: widget.color,
                      ),
                    );
                  },
                ),
              if (widget.subtitle != null)
                Text(
                  widget.subtitle!,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}