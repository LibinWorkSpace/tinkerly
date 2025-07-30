import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../constants/app_theme.dart';

enum ModernButtonStyle {
  primary,
  secondary,
  outline,
  ghost,
  gradient,
}

enum ModernButtonSize {
  small,
  medium,
  large,
}

class ModernButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final ModernButtonStyle style;
  final ModernButtonSize size;
  final IconData? icon;
  final Widget? iconWidget;
  final Color? color;
  final double? width;
  final bool fullWidth;

  const ModernButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.style = ModernButtonStyle.primary,
    this.size = ModernButtonSize.medium,
    this.icon,
    this.iconWidget,
    this.color,
    this.width,
    this.fullWidth = false,
  }) : super(key: key);

  @override
  State<ModernButton> createState() => _ModernButtonState();
}

class _ModernButtonState extends State<ModernButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Size configurations
    double height;
    double fontSize;
    EdgeInsets padding;
    
    switch (widget.size) {
      case ModernButtonSize.small:
        height = 36;
        fontSize = 12;
        padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
        break;
      case ModernButtonSize.medium:
        height = 44;
        fontSize = 14;
        padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 12);
        break;
      case ModernButtonSize.large:
        height = 52;
        fontSize = 16;
        padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 16);
        break;
    }
    
    // Style configurations
    Color backgroundColor;
    Color textColor;
    Color borderColor;
    List<BoxShadow>? boxShadow;
    Gradient? gradient;
    
    final primaryColor = widget.color ?? AppTheme.primaryColor;
    
    switch (widget.style) {
      case ModernButtonStyle.primary:
        backgroundColor = primaryColor;
        textColor = Colors.white;
        borderColor = primaryColor;
        boxShadow = [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ];
        break;
      case ModernButtonStyle.secondary:
        backgroundColor = isDark ? AppTheme.darkSurfaceColor : AppTheme.backgroundColor;
        textColor = isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
        borderColor = isDark ? AppTheme.darkTextSecondary.withOpacity(0.3) : AppTheme.dividerColor;
        boxShadow = AppTheme.cardShadow;
        break;
      case ModernButtonStyle.outline:
        backgroundColor = Colors.transparent;
        textColor = primaryColor;
        borderColor = primaryColor;
        boxShadow = null;
        break;
      case ModernButtonStyle.ghost:
        backgroundColor = primaryColor.withOpacity(0.1);
        textColor = primaryColor;
        borderColor = Colors.transparent;
        boxShadow = null;
        break;
      case ModernButtonStyle.gradient:
        backgroundColor = Colors.transparent;
        textColor = Colors.white;
        borderColor = Colors.transparent;
        gradient = AppTheme.primaryGradient;
        boxShadow = AppTheme.primaryShadow;
        break;
    }
    
    return AnimatedScale(
      scale: _isPressed ? 0.95 : 1.0,
      duration: const Duration(milliseconds: 100),
      child: Container(
        width: widget.fullWidth ? double.infinity : widget.width,
        height: height,
        decoration: BoxDecoration(
          color: gradient == null ? backgroundColor : null,
          gradient: gradient,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(color: borderColor, width: 1),
          boxShadow: boxShadow,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          child: InkWell(
            onTap: widget.isLoading ? null : widget.onPressed,
            onTapDown: (_) => setState(() => _isPressed = true),
            onTapUp: (_) => setState(() => _isPressed = false),
            onTapCancel: () => setState(() => _isPressed = false),
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            child: Padding(
              padding: padding,
              child: widget.isLoading
                  ? Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(textColor),
                        ),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.iconWidget != null) ...[
                          widget.iconWidget!,
                          const SizedBox(width: 8),
                        ] else if (widget.icon != null) ...[
                          Icon(
                            widget.icon,
                            color: textColor,
                            size: fontSize + 2,
                          ),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          widget.text,
                          style: AppTheme.labelLarge.copyWith(
                            color: textColor,
                            fontSize: fontSize,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ).animate().fadeIn(duration: 300.ms),
    );
  }
}