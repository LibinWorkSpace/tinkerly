import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color color;
  final Color? textColor;
  final IconData? icon;
  final double? height;
  final double? borderRadius;
  final double? elevation;
  final Gradient? gradient;
  final Widget? iconWidget;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.color = Colors.redAccent,
    this.textColor,
    this.icon,
    this.height,
    this.borderRadius,
    this.elevation,
    this.gradient,
    this.iconWidget,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height ?? 50,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: gradient,
          color: gradient == null ? color : null, // Always fill with color if no gradient
          borderRadius: BorderRadius.circular(borderRadius ?? 16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.18),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          // No border for white (Google) button
          border: null,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(borderRadius ?? 16),
          child: InkWell(
            borderRadius: BorderRadius.circular(borderRadius ?? 16),
            splashColor: (textColor ?? Colors.white).withOpacity(0.15),
            highlightColor: (textColor ?? Colors.white).withOpacity(0.08),
            onTap: isLoading ? null : onPressed,
            child: AnimatedOpacity(
              duration: 200.ms,
              opacity: (isLoading || onPressed == null) ? 0.7 : 1.0,
              child: Center(
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (iconWidget != null) ...[
                            iconWidget!,
                            const SizedBox(width: 8),
                          ] else if (icon != null) ...[
                            Icon(icon, color: textColor ?? Colors.white),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            text,
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textColor ?? Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ).animate().fadeIn(duration: 300.ms),
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