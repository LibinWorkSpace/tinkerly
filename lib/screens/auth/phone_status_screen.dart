import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/user_service.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';

class PhoneStatusScreen extends StatefulWidget {
  final String? currentPhone;
  final bool isVerified;
  const PhoneStatusScreen({super.key, this.currentPhone, required this.isVerified});

  @override
  State<PhoneStatusScreen> createState() => _PhoneStatusScreenState();
}

class _PhoneStatusScreenState extends State<PhoneStatusScreen> {
  bool _changing = false;
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  bool _isLoading = false;
  bool _otpSent = false;
  String? _newPhone;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final phone = _phoneController.text.trim();
      final sent = await UserService.sendSmsOtp(phone);
      if (sent) {
        setState(() {
          _otpSent = true;
          _newPhone = phone;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OTP sent to new phone!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send OTP.')),
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

  Future<void> _verifyOtpAndChange() async {
    if (_otpController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the OTP')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final success = await UserService.changePhone(_newPhone!, _otpController.text.trim());
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Phone number changed and verified!')),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid OTP. Try again.')),
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
      appBar: AppBar(title: const Text('Phone Number Status')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: !_changing ? _buildStatusView() : _buildChangeView(),
      ),
    );
  }

  Widget _buildStatusView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 32),
        Row(
          children: [
            Icon(
              widget.isVerified ? Icons.verified : Icons.warning,
              color: widget.isVerified ? Colors.green : Colors.orange,
              size: 28,
            ),
            const SizedBox(width: 12),
            Text(
              widget.isVerified ? 'Phone Verified' : 'Phone Not Verified',
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'Current Phone Number:',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Text(
          widget.currentPhone ?? 'No phone number',
          style: GoogleFonts.poppins(fontSize: 18, color: Colors.black87),
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: () => setState(() => _changing = true),
          child: const Text('Change Phone Number'),
        ),
      ],
    );
  }

  Widget _buildChangeView() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          CustomTextField(
            controller: _phoneController,
            label: 'New Phone Number',
            icon: Icons.phone,
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your phone number';
              }
              if (!RegExp(r'^\+\d{10,15}$').hasMatch(value)) {
                return 'Enter phone as +<countrycode><number>'; // e.g. +918590282958
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          if (!_otpSent) ...[
            CustomButton(
              text: _isLoading ? 'Sending OTP...' : 'Send OTP',
              onPressed: _isLoading ? null : _sendOtp,
            ),
          ] else ...[
            CustomTextField(
              controller: _otpController,
              label: 'Enter OTP',
              icon: Icons.lock,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            CustomButton(
              text: _isLoading ? 'Verifying...' : 'Verify & Change',
              onPressed: _isLoading ? null : _verifyOtpAndChange,
            ),
          ],
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => setState(() {
              _changing = false;
              _otpSent = false;
              _otpController.clear();
              _phoneController.clear();
            }),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
} 