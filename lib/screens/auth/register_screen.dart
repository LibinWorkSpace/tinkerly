// lib/screens/auth/register_screen.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../constants/categories.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../models/user_model.dart';
import '../../utils/password_validator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<String> _selectedCategories = [];
  dynamic _profileImageFileOrBytes; // File for mobile, Uint8List for web
  String? _profileImageUrl;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  // Add dark mode state and toggle
  bool _isDark = false;
  void _toggleTheme() {
    setState(() {
      _isDark = !_isDark;
    });
  }

  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _usernameFocusNode = FocusNode();
  final FocusNode _phoneFocusNode = FocusNode();
  String? _emailErrorText;
  String? _usernameErrorText;
  String? _phoneErrorText;
  bool _isEmailVerified = false;
  TextEditingController _otpController = TextEditingController();

  // Add state for phone verification
  String? _phoneVerificationId;
  bool _isPhoneVerified = false;

  // Show verification method dialog
  Future<String?> _showVerificationMethodDialog() async {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Verify your account'),
        content: const Text('Choose how you want to verify your account:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'email'),
            child: const Text('Via Gmail'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'phone'),
            child: const Text('Via Phone'),
          ),
        ],
      ),
    );
  }

  // Show attractive OTP entry dialog
  Future<bool> _showOtpDialog({required String method, required Future<bool> Function(String otp) onVerify}) async {
    final TextEditingController otpController = TextEditingController();
    bool verified = false;
    final primaryColor = _isDark ? Color(0xFF00D4AA) : Color(0xFF6C63FF);
    final secondaryColor = _isDark ? Color(0xFF64FFDA) : Color(0xFFFF6B9D);
    
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _isDark 
                  ? [Color(0xFF1B263B), Color(0xFF415A77)]
                  : [Color(0xFF667EEA), Color(0xFF764BA2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                spreadRadius: 0,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryColor, secondaryColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.verified_user,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Verify Your Account',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                method == 'email'
                    ? 'An OTP has been sent to your email address.'
                    : 'An OTP has been sent to your phone number.',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.8),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              // OTP Input
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: TextField(
                  controller: otpController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    letterSpacing: 8,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: '000000',
                    hintStyle: GoogleFonts.poppins(
                      letterSpacing: 8,
                      color: Colors.white.withOpacity(0.5),
                    ),
                    counterText: '',
                  ),
                  maxLength: 6,
                ),
              ),
              const SizedBox(height: 32),
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [primaryColor, secondaryColor],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.4),
                            blurRadius: 10,
                            spreadRadius: 0,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextButton(
                        onPressed: () async {
                          final otp = otpController.text.trim();
                          if (otp.isEmpty) return;
                          verified = await onVerify(otp);
                          if (verified) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Verification successful! ✅'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Invalid OTP. Please try again.'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        child: Text(
                          'Verify',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    return verified;
  }

  @override
  void initState() {
    super.initState();
    _emailFocusNode.addListener(() async {
      if (!_emailFocusNode.hasFocus) {
        final email = _emailController.text.trim();
        if (email.isEmpty || !email.contains('@')) {
          setState(() {
            _emailErrorText = 'Please enter a valid email address.';
          });
          return;
        }
        // Call backend to check if email is already registered
        final exists = await UserService.checkEmailExists(email);
        setState(() {
          _emailErrorText = exists ? 'Email is already registered.' : null;
        });
      }
    });

    _usernameFocusNode.addListener(() async {
      if (!_usernameFocusNode.hasFocus) {
        final username = _usernameController.text.trim();
        if (username.isEmpty || username.length < 3) {
          setState(() {
            _usernameErrorText = 'Username must be at least 3 characters.';
          });
          return;
        }
        if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username)) {
          setState(() {
            _usernameErrorText = 'Username can only contain letters, numbers, and underscores.';
          });
          return;
        }
        // Call backend to check if username is already taken
        final exists = await UserService.checkUsernameExists(username);
        setState(() {
          _usernameErrorText = exists ? 'Username is already taken.' : null;
        });
      }
    });

    _phoneFocusNode.addListener(() async {
      if (!_phoneFocusNode.hasFocus) {
        final phone = _phoneController.text.trim();
        if (phone.isEmpty) {
          setState(() {
            _phoneErrorText = 'Please enter your phone number';
          });
          return;
        }
        // Validate E.164 format
        if (!RegExp(r'^\+\d{10,15}$').hasMatch(phone)) {
          setState(() {
            _phoneErrorText = 'Enter phone as +<countrycode><number>';
          });
          return;
        }
        // Call backend to check if phone number is already registered
        final exists = await UserService.checkPhoneExists(phone);
        setState(() {
          _phoneErrorText = exists ? 'Phone number is already registered.' : null;
        });
      }
    });
  }

  @override
  void dispose() {
    _emailFocusNode.dispose();
    _usernameFocusNode.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  Future<void> _pickProfileImage() async {
    if (kIsWeb) {
      final result = await FilePicker.platform.pickFiles(type: FileType.image);
      if (result != null && result.files.single.bytes != null) {
        setState(() {
          _profileImageFileOrBytes = result.files.single.bytes;
        });
      }
    } else {
      final ImagePicker picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _profileImageFileOrBytes = File(image.path);
        });
      }
    }
  }

  Future<bool> _sendAndVerifyOtpOnRegister() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() { _emailErrorText = 'Please enter a valid email address.'; });
      return false;
    }
    final sent = await UserService.sendRegistrationOtp(email);
    if (!sent) {
      setState(() { _emailErrorText = 'Failed to send OTP. Try another email.'; });
      return false;
    }
    bool verified = false;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Verify Email'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('An OTP has been sent to $email.'),
            const SizedBox(height: 12),
            TextField(
              controller: _otpController,
              decoration: const InputDecoration(labelText: 'Enter OTP'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final otp = _otpController.text.trim();
              if (otp.isEmpty) return;
              verified = await UserService.verifyRegistrationOtp(email, otp);
              if (verified) {
                setState(() { _isEmailVerified = true; });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Email verified!')),
                );
              } else {
                setState(() { _isEmailVerified = false; });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invalid OTP. Try again.')),
                );
              }
            },
            child: const Text('Verify'),
          ),
        ],
      ),
    );
    return verified;
  }

  // Store form data for registration
  Map<String, dynamic>? _pendingRegistrationData;
  String? _pendingOtpMethod;

  // Refactored registration flow
  void _register() async {
    if (!_formKey.currentState!.validate() || _selectedCategories.isEmpty) return;

    // Check for any validation errors
    if (_emailErrorText != null || _usernameErrorText != null || _phoneErrorText != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fix the validation errors before proceeding.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Store form data
    _pendingRegistrationData = {
      'name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'phone': _phoneController.text.trim(),
      'password': _passwordController.text,
      'categories': _selectedCategories,
      'username': _usernameController.text.trim(),
      'bio': null,
      'profileImageUrl': _profileImageUrl,
    };

    // Ask for OTP method
    final method = await _showVerificationMethodDialog();
    if (method == null) {
      setState(() => _isLoading = false);
      return;
    }
    _pendingOtpMethod = method;
    bool sent = false;
    if (method == 'email') {
      sent = await UserService.sendRegistrationOtp(_pendingRegistrationData!['email']);
    } else if (method == 'phone') {
      sent = await UserService.sendSmsOtp(_pendingRegistrationData!['phone'], requireAuth: false);
    }
    if (!sent) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send OTP. Please try again.')),
      );
      setState(() => _isLoading = false);
      return;
    }
    // Show OTP dialog
    bool verified = await _showOtpDialog(
      method: method,
      onVerify: (otp) async {
        if (method == 'email') {
          return await UserService.verifyRegistrationOtp(_pendingRegistrationData!['email'], otp);
        } else {
          return await UserService.verifySmsOtp(_pendingRegistrationData!['phone'], otp, requireAuth: false);
        }
      },
    );
    if (!verified) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid OTP. Registration cancelled.')),
      );
      setState(() => _isLoading = false);
      return;
    }
    // Proceed with registration
    try {
      final authService = AuthService();
      final user = await authService.registerWithEmail(
        _pendingRegistrationData!['email'],
        _pendingRegistrationData!['password'],
      );
      if (user != null) {
        String? imageUrl;
        if (_profileImageFileOrBytes != null) {
          final url = await UserService.uploadFile((_profileImageFileOrBytes as File).path);
          imageUrl = url;
        }
        try {
          await UserService.saveUserProfile(
            _pendingRegistrationData!['name'],
            _pendingRegistrationData!['email'],
            imageUrl,
            _pendingRegistrationData!['categories'],
            _pendingRegistrationData!['username'],
            null,
            phone: _pendingRegistrationData!['phone'],
            isPhoneVerified: _pendingOtpMethod == 'phone',
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Registration successful! Please login.')),
          );
          Navigator.pushReplacementNamed(context, '/login');
        } catch (e) {
          // Rollback: delete Firebase user if backend registration fails
          try {
            await user.delete();
          } catch (deleteError) {
            print('Failed to delete Firebase user after backend failure: $deleteError');
          }
          print('Registration error: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Registration failed: $e')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration failed.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ' + e.toString())),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _handleGoogleSignIn() async {
    setState(() => _isGoogleLoading = true);
    try {
      final user = await _authService.signInWithGoogle();
      if (user != null) {
        try {
          // Generate proper username from display name and email
          final username = UserService.generateUsername(
            user.displayName ?? 'User',
            user.email ?? ''
          );
          await UserService.saveUserProfile(
            user.displayName ?? 'User',
            user.email ?? '',
            user.photoURL,
            [], // categories
            username, // generated username
            null, // bio
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Successfully signed in with Google!')),
          );
          setState(() => _isGoogleLoading = false); // Ensure loading is reset before navigation
          Navigator.pushReplacementNamed(context, '/');
        } catch (e) {
          setState(() => _isGoogleLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save profile: ${e.toString()}')),
          );
        }
      } else {
        setState(() => _isGoogleLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Google sign-in failed. Please try again.')),
        );
      }
    } catch (e) {
      setState(() => _isGoogleLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // Modern color schemes matching login screen
    final backgroundGradient = _isDark
        ? LinearGradient(
            colors: [
              Color(0xFF0D1B2A), // Deep navy
              Color(0xFF1B263B), // Dark blue-gray
              Color(0xFF415A77), // Medium blue-gray
              Color(0xFF778DA9), // Light blue-gray
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.0, 0.3, 0.7, 1.0],
          )
        : LinearGradient(
            colors: [
              Color(0xFF667EEA), // Purple-blue
              Color(0xFF764BA2), // Deep purple
              Color(0xFFF093FB), // Light purple
              Color(0xFFF5576C), // Coral pink
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.0, 0.3, 0.7, 1.0],
          );
    
    final textColor = _isDark ? Colors.white : Colors.white;
    final primaryColor = _isDark ? Color(0xFF00D4AA) : Color(0xFF6C63FF);
    final secondaryColor = _isDark ? Color(0xFF64FFDA) : Color(0xFFFF6B9D);
    final cardColor = _isDark 
        ? Colors.white.withOpacity(0.1) 
        : Colors.white.withOpacity(0.25);
    final inputFillColor = _isDark 
        ? Colors.white.withOpacity(0.08) 
        : Colors.white.withOpacity(0.3);
    final inputBorderColor = _isDark 
        ? Color(0xFF00D4AA).withOpacity(0.3) 
        : Colors.white.withOpacity(0.6);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: backgroundGradient,
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Floating background elements
              Positioned(
                top: -80,
                right: -80,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: primaryColor.withOpacity(0.1),
                  ),
                ),
              ),
              Positioned(
                bottom: -120,
                left: -80,
                child: Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: secondaryColor.withOpacity(0.1),
                  ),
                ),
              ),
              Positioned(
                top: screenHeight * 0.3,
                right: -60,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: primaryColor.withOpacity(0.05),
                  ),
                ),
              ),
              // Main content
              Center(
                child: SingleChildScrollView(
                  physics: BouncingScrollPhysics(),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 64 : 24, 
                      vertical: 32
                    ),
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: isTablet ? 450 : double.infinity,
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Header Section with Glassmorphism Card
                            Container(
                              padding: EdgeInsets.all(28),
                              margin: EdgeInsets.only(bottom: 32),
                              decoration: BoxDecoration(
                                color: cardColor,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 20,
                                    spreadRadius: 0,
                                    offset: Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  // Animated Logo
                                  Container(
                                    padding: EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [primaryColor, secondaryColor],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: primaryColor.withOpacity(0.4),
                                          blurRadius: 20,
                                          spreadRadius: 0,
                                          offset: Offset(0, 8),
                                        )
                                      ],
                                    ),
                                    child: Text(
                                      "⚡",
                                      style: TextStyle(
                                        fontSize: 40,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ).animate().scaleXY(begin: 0.8, end: 1.0, duration: 900.ms, curve: Curves.easeOutBack, delay: 100.ms).fade(duration: 500.ms),
                                  const SizedBox(height: 16),
                                  Text(
                                    "Tinkerly",
                                    style: GoogleFonts.poppins(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                      letterSpacing: 2,
                                    ),
                                  ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
                                  const SizedBox(height: 8),
                                ],
                              ),
                            ),
                            // Profile Image Section
                            Container(
                              padding: EdgeInsets.all(24),
                              margin: EdgeInsets.only(bottom: 24),
                              decoration: BoxDecoration(
                                color: cardColor,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 15,
                                    spreadRadius: 0,
                                    offset: Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    'Profile Picture',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      color: textColor.withOpacity(0.9),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  GestureDetector(
                                    onTap: _pickProfileImage,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: _profileImageFileOrBytes == null 
                                            ? LinearGradient(
                                                colors: [primaryColor.withOpacity(0.2), secondaryColor.withOpacity(0.2)],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              )
                                            : null,
                                        boxShadow: [
                                          BoxShadow(
                                            color: primaryColor.withOpacity(0.3),
                                            blurRadius: 15,
                                            spreadRadius: 0,
                                            offset: Offset(0, 8),
                                          ),
                                        ],
                                      ),
                                      child: CircleAvatar(
                                        radius: 50,
                                        backgroundColor: Colors.transparent,
                                        backgroundImage: _profileImageFileOrBytes != null
                                            ? (kIsWeb
                                                ? MemoryImage(_profileImageFileOrBytes)
                                                : FileImage(_profileImageFileOrBytes) as ImageProvider)
                                            : null,
                                        child: _profileImageFileOrBytes == null
                                            ? Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(Icons.camera_alt, size: 28, color: primaryColor),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    'Tap to add',
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 10,
                                                      color: primaryColor,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              )
                                            : null,
                                      ),
                                    ),
                                  ).animate().fadeIn(duration: 400.ms, delay: 500.ms),
                                ],
                              ),
                            ),
                            // Personal Information Form
                            Container(
                              padding: EdgeInsets.all(24),
                              margin: EdgeInsets.only(bottom: 24),
                              decoration: BoxDecoration(
                                color: cardColor,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 15,
                                    spreadRadius: 0,
                                    offset: Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Personal Information',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      color: textColor.withOpacity(0.9),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  // Name
                                  CustomTextField(
                                    controller: _nameController,
                                    label: 'Full Name',
                                    icon: Icons.person_outline,
                                    validator: (value) => value!.isEmpty ? 'Enter your name' : null,
                                    fillColor: inputFillColor,
                                    borderColor: inputBorderColor,
                                  ).animate().fadeIn(duration: 400.ms, delay: 600.ms),
                                  const SizedBox(height: 16),
                                  // Username
                                  CustomTextField(
                                    controller: _usernameController,
                                    label: 'Username',
                                    icon: Icons.alternate_email,
                                    validator: (value) => _usernameErrorText ?? (value!.isEmpty ? 'Enter a username' : null),
                                    fillColor: inputFillColor,
                                    borderColor: inputBorderColor,
                                  ).animate().fadeIn(duration: 400.ms, delay: 650.ms),
                                  const SizedBox(height: 16),
                                  // Email
                                  CustomTextField(
                                    controller: _emailController,
                                    label: 'Email Address',
                                    icon: Icons.email_outlined,
                                    keyboardType: TextInputType.emailAddress,
                                    validator: (value) => _emailErrorText ?? (value!.contains('@') ? null : 'Enter a valid email'),
                                    fillColor: inputFillColor,
                                    borderColor: inputBorderColor,
                                  ).animate().fadeIn(duration: 400.ms, delay: 700.ms),
                                  const SizedBox(height: 16),
                                  // Password
                                  CustomTextField(
                                    controller: _passwordController,
                                    label: 'Password',
                                    icon: Icons.lock_outline,
                                    isPassword: true,
                                    validator: PasswordValidator.validatePassword,
                                    fillColor: inputFillColor,
                                    borderColor: inputBorderColor,
                                  ).animate().fadeIn(duration: 400.ms, delay: 750.ms),
                                  const SizedBox(height: 16),
                                  // Phone
                                  CustomTextField(
                                    controller: _phoneController,
                                    label: 'Phone Number',
                                    icon: Icons.phone_outlined,
                                    keyboardType: TextInputType.phone,
                                    validator: (value) => _phoneErrorText ?? (value!.isEmpty ? 'Please enter your phone number' : (!RegExp(r'^\+\d{10,15}$').hasMatch(value) ? 'Enter phone as +<countrycode><number>' : null)),
                                    fillColor: inputFillColor,
                                    borderColor: inputBorderColor,
                                  ).animate().fadeIn(duration: 400.ms, delay: 800.ms),
                                  const SizedBox(height: 8),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8.0),
                                    child: Text(
                                      'Enter your phone number in international format, e.g. +918590282958',
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        color: textColor.withOpacity(0.6),
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Skills & Categories Section
                            Container(
                              padding: EdgeInsets.all(24),
                              margin: EdgeInsets.only(bottom: 24),
                              decoration: BoxDecoration(
                                color: cardColor,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 15,
                                    spreadRadius: 0,
                                    offset: Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [primaryColor.withOpacity(0.2), secondaryColor.withOpacity(0.2)],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          Icons.category_outlined,
                                          color: primaryColor,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        "Skills & Categories",
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          color: textColor.withOpacity(0.9),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    "Select your areas of expertise to help others find you",
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: textColor.withOpacity(0.7),
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: inputFillColor,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: inputBorderColor,
                                        width: 1,
                                      ),
                                    ),
                                    child: MultiSelectDialogField<String>(
                                      items: skillCategories.map((e) => MultiSelectItem(e, e)).toList(),
                                      title: Text(
                                        "Select Categories",
                                        style: GoogleFonts.poppins(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: primaryColor,
                                        ),
                                      ),
                                      selectedColor: primaryColor,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: Colors.transparent),
                                      ),
                                      buttonIcon: Icon(
                                        Icons.keyboard_arrow_down,
                                        color: primaryColor,
                                        size: 24,
                                      ),
                                      buttonText: Text(
                                        _selectedCategories.isEmpty 
                                            ? "Tap to select categories"
                                            : "${_selectedCategories.length} categories selected",
                                        style: GoogleFonts.poppins(
                                          color: textColor.withOpacity(0.8),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      initialValue: _selectedCategories,
                                      onConfirm: (values) {
                                        setState(() {
                                          _selectedCategories.clear();
                                          _selectedCategories.addAll(values);
                                        });
                                      },
                                      chipDisplay: MultiSelectChipDisplay(
                                        chipColor: primaryColor.withOpacity(0.15),
                                        textStyle: GoogleFonts.poppins(
                                          color: primaryColor,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                            color: primaryColor.withOpacity(0.3),
                                            width: 1,
                                          ),
                                        ),
                                        onTap: (value) {
                                          setState(() {
                                            _selectedCategories.remove(value);
                                          });
                                        },
                                      ),
                                      validator: (values) {
                                        if (values == null || values.isEmpty) {
                                          return 'Please select at least one category';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ).animate().fadeIn(duration: 400.ms, delay: 850.ms),
                            // Action Buttons Section
                            Container(
                              padding: EdgeInsets.all(24),
                              margin: EdgeInsets.only(bottom: 24),
                              decoration: BoxDecoration(
                                color: cardColor,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 15,
                                    spreadRadius: 0,
                                    offset: Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  // Register Button
                                  Container(
                                    width: double.infinity,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [primaryColor, secondaryColor],
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: primaryColor.withOpacity(0.4),
                                          blurRadius: 15,
                                          spreadRadius: 0,
                                          offset: Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: CustomButton(
                                      text: "Create Account",
                                      isLoading: _isLoading,
                                      onPressed: _isLoading ? null : _register,
                                      color: Colors.transparent,
                                      textColor: Colors.white,
                                      elevation: 0,
                                      borderRadius: 16,
                                      gradient: null,
                                      iconWidget: Icon(Icons.person_add, color: Colors.white, size: 20),
                                    ),
                                  ).animate().fadeIn(duration: 400.ms, delay: 900.ms),
                                  const SizedBox(height: 20),
                                  // Divider
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          height: 1,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Colors.transparent,
                                                textColor.withOpacity(0.3),
                                                Colors.transparent,
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16),
                                        child: Text(
                                          'or continue with',
                                          style: GoogleFonts.poppins(
                                            color: textColor.withOpacity(0.6),
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Container(
                                          height: 1,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Colors.transparent,
                                                textColor.withOpacity(0.3),
                                                Colors.transparent,
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ).animate().fadeIn(duration: 400.ms, delay: 950.ms),
                                  const SizedBox(height: 20),
                                  // Google Button
                                  Container(
                                    width: double.infinity,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: Colors.grey.withOpacity(0.2),
                                        width: 1,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 10,
                                          spreadRadius: 0,
                                          offset: Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: CustomButton(
                                      text: "Sign up with Google",
                                      color: Colors.transparent,
                                      textColor: Colors.grey[700]!,
                                      isLoading: _isGoogleLoading,
                                      onPressed: _isGoogleLoading ? null : _handleGoogleSignIn,
                                      elevation: 0,
                                      borderRadius: 16,
                                      gradient: null,
                                      iconWidget: Container(
                                        padding: EdgeInsets.all(2),
                                        child: Image.asset(
                                          'assets/images/google_logo.png',
                                          width: 20,
                                          height: 20,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Icon(Icons.g_mobiledata, color: Colors.red, size: 24);
                                          },
                                        ),
                                      ),
                                    ),
                                  ).animate().fadeIn(duration: 400.ms, delay: 1000.ms),
                                ],
                              ),
                            ),
                            // Bottom Link
                            Container(
                              padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Already have an account? ",
                                    style: GoogleFonts.poppins(
                                      color: textColor.withOpacity(0.8),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.pushNamed(context, '/login');
                                    },
                                    child: Text(
                                      "Sign In",
                                      style: GoogleFonts.poppins(
                                        color: primaryColor,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ).animate().fadeIn(duration: 400.ms, delay: 1050.ms),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Animate(
        effects: [FadeEffect(duration: 600.ms), ScaleEffect(duration: 600.ms)],
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryColor, secondaryColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withOpacity(0.3),
                blurRadius: 15,
                spreadRadius: 0,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: FloatingActionButton(
            onPressed: _toggleTheme,
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Icon(
              _isDark ? Icons.wb_sunny : Icons.nightlight_round,
              color: Colors.white,
              size: 24,
            ),
            tooltip: _isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
          ),
        ),
      ),
    );
  }
}
