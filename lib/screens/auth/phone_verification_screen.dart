import 'package:flutter/material.dart';
import '../../services/user_service.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PhoneVerificationScreen extends StatefulWidget {
  const PhoneVerificationScreen({super.key});

  @override
  State<PhoneVerificationScreen> createState() => _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState extends State<PhoneVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  bool _isLoading = false;
  bool _otpSent = false;
  String? _currentPhone;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    // Ensure user is signed in
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be signed in to verify your phone. Please log in.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      final phone = _phoneController.text.trim();
      final success = await UserService.sendSmsOtp(phone);
      
      if (success) {
        setState(() {
          _otpSent = true;
          _currentPhone = phone;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OTP sent successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send OTP. Please try again.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyOtp() async {
    if (_otpController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the OTP')),
      );
      return;
    }

    // Ensure user is signed in
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be signed in to verify your phone. Please log in.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      // Use authenticated endpoint for profile phone verification
      final success = await UserService.verifySmsOtpAuth(_currentPhone!, _otpController.text.trim());
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Phone verified successfully!')),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid OTP. Please try again.')),
        );
      }
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
      appBar: AppBar(
        title: Text(
          'Phone Verification',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              
              // Icon
              Icon(
                Icons.phone_android,
                size: 80,
                color: Colors.blue.shade400,
              ),
              
              const SizedBox(height: 24),
              
              // Title
              Text(
                'Verify Your Phone Number',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 12),
              
              // Subtitle
              Text(
                'We\'ll send you a verification code via SMS',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 32),
              
              if (!_otpSent) ...[
                // Phone input
                CustomTextField(
                  controller: _phoneController,
                  label: 'Phone Number',
                  icon: Icons.phone,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your phone number';
                    }
                    if (!RegExp(r'^\+?[0-9]{7,15}').hasMatch(value.trim())) {
                      return 'Please enter a valid phone number';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 24),
                
                // Send OTP button
                CustomButton(
                  text: _isLoading ? 'Sending...' : 'Send OTP',
                  onPressed: _isLoading ? null : _sendOtp,
                ),
              ] else ...[
                // OTP input
                CustomTextField(
                  controller: _otpController,
                  label: 'Enter OTP',
                  icon: Icons.lock,
                  keyboardType: TextInputType.number,
                ),
                
                const SizedBox(height: 16),
                
                // Resend OTP option
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Didn\'t receive the code? ',
                      style: GoogleFonts.poppins(color: Colors.grey.shade600),
                    ),
                    TextButton(
                      onPressed: _isLoading ? null : _sendOtp,
                      child: Text(
                        'Resend',
                        style: GoogleFonts.poppins(
                          color: Colors.blue.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Verify OTP button
                CustomButton(
                  text: _isLoading ? 'Verifying...' : 'Verify OTP',
                  onPressed: _isLoading ? null : _verifyOtp,
                ),
                
                const SizedBox(height: 16),
                
                // Change phone option
                TextButton(
                  onPressed: () {
                    setState(() {
                      _otpSent = false;
                      _otpController.clear();
                    });
                  },
                  child: Text(
                    'Change Phone Number',
                    style: GoogleFonts.poppins(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
} 