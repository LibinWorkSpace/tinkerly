import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/user_service.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/password_strength_indicator.dart';
import '../../utils/password_validator.dart';

class SetPasswordScreen extends StatefulWidget {
  const SetPasswordScreen({super.key});

  @override
  State<SetPasswordScreen> createState() => _SetPasswordScreenState();
}

class _SetPasswordScreenState extends State<SetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Add listener to update password strength indicator in real-time
    _passwordController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _setPassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You must be logged in.')),
        );
        return;
      }
      await user.updatePassword(_passwordController.text.trim());
      // Optionally update backend user profile (if you want to track password set)
      final username = UserService.generateUsername(
        user.displayName ?? 'User',
        user.email ?? ''
      );
      await UserService.saveUserProfile(
        user.displayName ?? 'User',
        user.email ?? '',
        user.photoURL,
        [],
        username,
        null,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password set successfully!')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Set Password')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              CustomTextField(
                controller: _passwordController,
                label: 'New Password',
                icon: Icons.lock,
                isPassword: true,
                validator: PasswordValidator.validatePassword,
              ),

              // Password Strength Indicator
              PasswordStrengthIndicator(
                password: _passwordController.text,
                isDark: Theme.of(context).brightness == Brightness.dark,
              ),

              const SizedBox(height: 16),
              CustomTextField(
                controller: _confirmController,
                label: 'Confirm Password',
                icon: Icons.lock_outline,
                isPassword: true,
                validator: (value) {
                  if (value != _passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              CustomButton(
                text: _isLoading ? 'Setting...' : 'Set Password',
                onPressed: _isLoading ? null : _setPassword,
              ),

              const SizedBox(height: 24),

              // Security Tips
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.security, color: Colors.blue, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Password Security Tips',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• Use a unique password you don\'t use elsewhere\n'
                      '• Include uppercase, lowercase, numbers, and symbols\n'
                      '• Avoid personal information or common words\n'
                      '• Consider using a password manager',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 