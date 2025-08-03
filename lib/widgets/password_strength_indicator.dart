import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/password_validator.dart';

class PasswordStrengthIndicator extends StatelessWidget {
  final String password;
  final bool isDark;

  const PasswordStrengthIndicator({
    super.key,
    required this.password,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final strength = PasswordValidator.getPasswordStrength(password);
    final strengthText = PasswordValidator.getStrengthText(strength);
    final strengthColor = PasswordValidator.getStrengthColor(strength);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: isDark ? Colors.grey[700] : Colors.grey[300],
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: strength,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: strengthColor,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              strengthText,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: strengthColor,
              ),
            ),
          ],
        ),
        if (password.isNotEmpty) ...[
          const SizedBox(height: 8),
          _buildRequirements(),
        ],
      ],
    );
  }

  Widget _buildRequirements() {
    final requirements = [
      {
        'text': 'At least 8 characters',
        'met': password.length >= 8,
      },
      {
        'text': 'Contains uppercase letter',
        'met': password.contains(RegExp(r'[A-Z]')),
      },
      {
        'text': 'Contains lowercase letter',
        'met': password.contains(RegExp(r'[a-z]')),
      },
      {
        'text': 'Contains number',
        'met': password.contains(RegExp(r'[0-9]')),
      },
      {
        'text': 'Contains special character',
        'met': password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]')),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: requirements.map((req) {
        final met = req['met'] as bool;
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              Icon(
                met ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 16,
                color: met ? Colors.green : (isDark ? Colors.grey[600] : Colors.grey[400]),
              ),
              const SizedBox(width: 8),
              Text(
                req['text'] as String,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: met 
                    ? Colors.green 
                    : (isDark ? Colors.grey[400] : Colors.grey[600]),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
