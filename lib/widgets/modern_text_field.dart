import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../constants/app_theme.dart';

class ModernTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? prefixIcon;
  final Widget? prefixWidget;
  final IconData? suffixIcon;
  final Widget? suffixWidget;
  final bool isPassword;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final FocusNode? focusNode;
  final VoidCallback? onTap;
  final Function(String)? onChanged;
  final bool readOnly;
  final int? maxLines;
  final int? minLines;
  final bool filled;
  final Color? fillColor;
  final bool enabled;

  const ModernTextField({
    Key? key,
    required this.controller,
    required this.label,
    this.hint,
    this.prefixIcon,
    this.prefixWidget,
    this.suffixIcon,
    this.suffixWidget,
    this.isPassword = false,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.focusNode,
    this.onTap,
    this.onChanged,
    this.readOnly = false,
    this.maxLines = 1,
    this.minLines,
    this.filled = true,
    this.fillColor,
    this.enabled = true,
  }) : super(key: key);

  @override
  State<ModernTextField> createState() => _ModernTextFieldState();
}

class _ModernTextFieldState extends State<ModernTextField> {
  bool _obscureText = true;
  bool _isFocused = false;
  FocusNode? _internalFocusNode;
  
  FocusNode get _focusNode => widget.focusNode ?? _internalFocusNode!;

  @override
  void initState() {
    super.initState();
    if (widget.focusNode == null) {
      _internalFocusNode = FocusNode();
    }
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _internalFocusNode?.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : AppTheme.cardShadow,
          ),
          child: TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            obscureText: widget.isPassword ? _obscureText : false,
            validator: widget.validator,
            keyboardType: widget.keyboardType,
            onTap: widget.onTap,
            onChanged: widget.onChanged,
            readOnly: widget.readOnly,
            maxLines: widget.isPassword ? 1 : widget.maxLines,
            minLines: widget.minLines,
            enabled: widget.enabled,
            style: AppTheme.bodyLarge.copyWith(
              color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
            ),
            decoration: InputDecoration(
              labelText: widget.label,
              hintText: widget.hint,
              labelStyle: AppTheme.bodyMedium.copyWith(
                color: _isFocused 
                    ? AppTheme.primaryColor 
                    : (isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary),
                fontWeight: _isFocused ? FontWeight.w600 : FontWeight.w400,
              ),
              hintStyle: AppTheme.bodyMedium.copyWith(
                color: isDark ? AppTheme.darkTextSecondary.withOpacity(0.7) : AppTheme.textTertiary,
              ),
              prefixIcon: widget.prefixWidget ?? (widget.prefixIcon != null 
                  ? Icon(
                      widget.prefixIcon,
                      color: _isFocused 
                          ? AppTheme.primaryColor 
                          : (isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary),
                    )
                  : null),
              suffixIcon: widget.suffixWidget ?? _buildSuffixIcon(),
              filled: widget.filled,
              fillColor: widget.fillColor ?? (isDark ? AppTheme.darkSurfaceColor : AppTheme.surfaceColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                borderSide: BorderSide(
                  color: isDark ? AppTheme.darkTextSecondary.withOpacity(0.3) : AppTheme.dividerColor,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                borderSide: BorderSide(
                  color: isDark ? AppTheme.darkTextSecondary.withOpacity(0.3) : AppTheme.dividerColor,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                borderSide: const BorderSide(
                  color: AppTheme.primaryColor,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                borderSide: const BorderSide(
                  color: AppTheme.errorColor,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                borderSide: const BorderSide(
                  color: AppTheme.errorColor,
                  width: 2,
                ),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                borderSide: BorderSide(
                  color: (isDark ? AppTheme.darkTextSecondary : AppTheme.textTertiary).withOpacity(0.3),
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spaceMedium,
                vertical: AppTheme.spaceMedium,
              ),
            ),
          ),
        ).animate().fadeIn(duration: 300.ms),
      ],
    );
  }

  Widget? _buildSuffixIcon() {
    if (widget.isPassword) {
      return IconButton(
        icon: Icon(
          _obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          color: Theme.of(context).brightness == Brightness.dark 
              ? AppTheme.darkTextSecondary 
              : AppTheme.textSecondary,
        ),
        onPressed: () => setState(() => _obscureText = !_obscureText),
      );
    }
    
    if (widget.suffixIcon != null) {
      return Icon(
        widget.suffixIcon,
        color: _isFocused 
            ? AppTheme.primaryColor 
            : (Theme.of(context).brightness == Brightness.dark 
                ? AppTheme.darkTextSecondary 
                : AppTheme.textSecondary),
      );
    }
    
    return null;
  }
}