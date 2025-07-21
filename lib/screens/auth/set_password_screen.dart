import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/user_service.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';

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
      await UserService.saveUserProfile(
        user.displayName ?? '',
        user.email ?? '',
        user.photoURL,
        [],
        user.displayName ?? '',
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
                validator: (value) {
                  if (value == null || value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
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
            ],
          ),
        ),
      ),
    );
  }
} 