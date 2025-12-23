import 'package:flutter/material.dart';
import 'package:chemo_monitor_app/config/app_constants.dart';
import 'dart:ui';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double borderRadius;
  final double blurSigma;
  final Color color;
  final bool withShadow;
  final VoidCallback? onTap;
  final Border? border; // Made optional with ?

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppDimensions.paddingMedium),
    this.margin = EdgeInsets.zero,
    this.borderRadius = AppDimensions.radiusLarge,
    this.blurSigma = 10.0,
    this.color = Colors.white,
    this.withShadow = true,
    this.onTap,
    this.border, // Removed 'required' keyword
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: color.withOpacity(0.7),
        borderRadius: BorderRadius.circular(borderRadius),
        border: border ?? Border.all( // Use provided border or default
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: withShadow ? AppShadows.glassShadow : [],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(borderRadius),
        child: InkWell(
          borderRadius: BorderRadius.circular(borderRadius),
          onTap: onTap,
          child: card,
        ),
      );
    }

    return card;
  }
}