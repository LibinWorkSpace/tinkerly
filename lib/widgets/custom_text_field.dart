import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class CustomTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool isPassword;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final bool? filled;
  final Color? fillColor;
  final Color? borderColor;
  final FocusNode? focusNode;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.isPassword = false,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.filled,
    this.fillColor,
    this.borderColor,
    this.focusNode,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _obscure = true;
  bool _isFocused = false;
  FocusNode? _internalFocusNode;
  FocusNode get _focusNode => widget.focusNode ?? _internalFocusNode!;

  @override
  void initState() {
    super.initState();
    if (widget.focusNode == null) {
      _internalFocusNode = FocusNode();
      _internalFocusNode!.addListener(_handleFocusChange);
    } else {
      widget.focusNode!.addListener(_handleFocusChange);
    }
  }

  void _handleFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  void dispose() {
    if (_internalFocusNode != null) {
      _internalFocusNode!.dispose();
    } else if (widget.focusNode != null) {
      widget.focusNode!.removeListener(_handleFocusChange);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: 250.ms,
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        boxShadow: _isFocused
            ? [
                BoxShadow(
                  color: (widget.borderColor ?? Colors.redAccent).withOpacity(0.18),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextFormField(
        focusNode: _focusNode,
        controller: widget.controller,
        obscureText: widget.isPassword ? _obscure : false,
        validator: widget.validator,
        keyboardType: widget.keyboardType,
        style: GoogleFonts.poppins(fontSize: 16),
        decoration: InputDecoration(
          labelText: widget.label,
          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500, color: Colors.grey[700]),
          prefixIcon: Icon(widget.icon, color: Colors.redAccent),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: widget.borderColor ?? Colors.grey.shade300,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: widget.borderColor ?? Colors.grey.shade300,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: widget.borderColor ?? const Color.fromARGB(255, 255, 82, 82),
              width: 2,
            ),
          ),
          suffixIcon: widget.isPassword
              ? IconButton(
                  icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                  onPressed: () => setState(() => _obscure = !_obscure),
                )
              : null,
          filled: widget.filled ?? true,
          fillColor: widget.fillColor ?? Colors.white,
        ),
      ),
    );
  }
}
