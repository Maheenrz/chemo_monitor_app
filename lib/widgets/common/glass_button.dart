import 'package:flutter/material.dart';
import 'package:chemo_monitor_app/config/app_constants.dart';

class GlassButton extends StatefulWidget {
  final String? text;
  final Widget? child;
  final IconData? icon;
  final VoidCallback? onPressed;
  final ButtonType type;
  final bool isLoading;
  final bool isSelected;
  final double borderRadius;
  final double height;
  final EdgeInsetsGeometry padding;

  const GlassButton({
    super.key,
    this.text,
    this.child,
    this.icon,
    required this.onPressed,
    this.type = ButtonType.primary,
    this.isLoading = false,
    this.isSelected = false,
    this.borderRadius = AppDimensions.radiusLarge,
    this.height = 36.0,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppDimensions.paddingMedium,
      vertical: AppDimensions.paddingSmall,
    ),
  }) : assert(text != null || child != null, 'Either text or child must be provided');

  @override
  State<GlassButton> createState() => _GlassButtonState();
}

enum ButtonType {
  primary,
  secondary,
  success,
  warning,
  danger,
}

class _GlassButtonState extends State<GlassButton> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Color _getBackgroundColor() {
    if (widget.isSelected && widget.type == ButtonType.primary) {
      return AppColors.primaryBlue;
    }
    
    switch (widget.type) {
      case ButtonType.primary:
        return Colors.white.withOpacity(0.7);
      case ButtonType.secondary:
        return Colors.transparent;
      case ButtonType.success:
        return AppColors.softGreen;
      case ButtonType.warning:
        return AppColors.riskModerate;
      case ButtonType.danger:
        return AppColors.riskHigh;
    }
  }

  Color _getTextColor() {
    if (widget.isSelected && widget.type == ButtonType.primary) {
      return Colors.white;
    }
    
    switch (widget.type) {
      case ButtonType.secondary:
        return AppColors.primaryBlue;
      case ButtonType.primary:
        return AppColors.primaryBlue;
      default:
        return Colors.white;
    }
  }

  List<BoxShadow> _getShadows() {
    if (widget.type == ButtonType.secondary || widget.type == ButtonType.primary) {
      return [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ];
    }
    return [
      BoxShadow(
        color: _getBackgroundColor().withOpacity(0.3),
        blurRadius: 20,
        offset: const Offset(0, 10),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _animationController.forward(),
      onTapUp: (_) => _animationController.reverse(),
      onTapCancel: () => _animationController.reverse(),
      onTap: widget.isLoading ? null : widget.onPressed,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: _getBackgroundColor(),
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: widget.type == ButtonType.secondary || 
                   (widget.type == ButtonType.primary && !widget.isSelected)
                ? Border.all(color: AppColors.primaryBlue.withOpacity(0.3), width: 1)
                : null,
            boxShadow: _getShadows(),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            child: InkWell(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              onTap: widget.isLoading ? null : widget.onPressed,
              child: Padding(
                padding: widget.padding,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Button Content
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 150),
                      opacity: widget.isLoading ? 0.0 : 1.0,
                      child: widget.child ?? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (widget.icon != null) ...[
                            Icon(
                              widget.icon,
                              color: _getTextColor(),
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                          ],
                          Text(
                            widget.text!,
                            style: TextStyle(
                              color: _getTextColor(),
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Loading Indicator
                    if (widget.isLoading)
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(_getTextColor()),
                        ),
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
}