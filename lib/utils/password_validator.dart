import 'package:flutter/material.dart';

class PasswordValidator {
  static const int minLength = 8;
  static const int maxLength = 128;
  
  static String? validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return 'Password is required';
    }
    
    if (password.length < minLength) {
      return 'Password must be at least $minLength characters';
    }
    
    if (password.length > maxLength) {
      return 'Password must be less than $maxLength characters';
    }
    
    if (!password.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }
    
    if (!password.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter';
    }
    
    if (!password.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }
    
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Password must contain at least one special character';
    }
    
    // Check for common weak patterns
    if (_containsCommonPatterns(password)) {
      return 'Password contains common patterns. Please choose a stronger password';
    }
    
    return null;
  }
  
  static bool _containsCommonPatterns(String password) {
    final commonPatterns = [
      'password', '123456', 'qwerty', 'abc123', 
      'password123', '12345678', 'admin'
    ];
    
    final lowerPassword = password.toLowerCase();
    return commonPatterns.any((pattern) => lowerPassword.contains(pattern));
  }
  
  static double getPasswordStrength(String password) {
    if (password.isEmpty) return 0.0;
    
    double strength = 0.0;
    
    // Length score (0-0.25)
    strength += (password.length / 20).clamp(0.0, 0.25);
    
    // Character variety score (0-0.75)
    if (password.contains(RegExp(r'[a-z]'))) strength += 0.15;
    if (password.contains(RegExp(r'[A-Z]'))) strength += 0.15;
    if (password.contains(RegExp(r'[0-9]'))) strength += 0.15;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength += 0.15;
    if (password.contains(RegExp(r'[^\w\s]'))) strength += 0.15;
    
    // Penalty for common patterns
    if (_containsCommonPatterns(password)) strength -= 0.3;
    
    return strength.clamp(0.0, 1.0);
  }
  
  static String getStrengthText(double strength) {
    if (strength < 0.3) return 'Weak';
    if (strength < 0.6) return 'Fair';
    if (strength < 0.8) return 'Good';
    return 'Strong';
  }
  
  static Color getStrengthColor(double strength) {
    if (strength < 0.3) return Colors.red;
    if (strength < 0.6) return Colors.orange;
    if (strength < 0.8) return Colors.blue;
    return Colors.green;
  }
}
