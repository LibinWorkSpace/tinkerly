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
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

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

  // Add dark mode state and toggle
  bool _isDark = false;
  void _toggleTheme() {
    setState(() {
      _isDark = !_isDark;
    });
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

  void _register() async {
    if (!_formKey.currentState!.validate() || _selectedCategories.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      print('Starting registration...');
      final authService = AuthService();
      final user = await authService.registerWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
      );
      print('Firebase user: ' + user.toString());
      if (user != null) {
        String? imageUrl;
        if (_profileImageFileOrBytes != null) {
          print('Uploading profile image...');
          final url = await UserService.uploadFile((_profileImageFileOrBytes as File).path);
          print('Image upload result: ' + url.toString());
          imageUrl = url;
        }
        print('Saving user profile to backend...');
        await UserService.saveUserProfile(
          _nameController.text.trim(),
          _emailController.text.trim(),
          imageUrl,
          _selectedCategories,
          _usernameController.text.trim(),
          null,
        );
        print('Registration successful!');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration successful! Please login.')),
        );
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        print('Registration failed: user is null');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration failed.')),
        );
      }
    } catch (e, st) {
      print('Registration error: ' + e.toString());
      print(st);
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
        // Save user profile to backend
        await UserService.saveUserProfile(
          user.displayName ?? '',
          user.email ?? '',
          user.photoURL,
          [], // categories
          user.displayName ?? '', // username
          null, // bio
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Successfully signed in with Google!')),
        );
        Navigator.pushReplacementNamed(context, '/');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Google sign-in failed. Please try again.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() => _isGoogleLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;
    final backgroundGradient = _isDark
        ? const LinearGradient(
            colors: [Color(0xFF181A20), Color(0xFF23242B)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          )
        : const LinearGradient(
            colors: [Color(0xFFF5F7FA), Color(0xFFE3F2FD)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          );
    final textColor = _isDark ? Colors.white : Colors.black87;
    final accentColor = _isDark ? const Color(0xFF90CAF9) : const Color(0xFF1976D2);
    final inputFillColor = Colors.white;
    final inputBorderColor = _isDark ? const Color(0xFF90CAF9).withOpacity(0.3) : const Color(0xFF1976D2).withOpacity(0.18);
    final buttonColor = accentColor;
    final googleButtonColor = Colors.white;
    final googleTextColor = accentColor;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: backgroundGradient,
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Logo
                      Animate(
                        effects: [
                          FadeEffect(duration: 600.ms),
                          MoveEffect(duration: 600.ms, begin: const Offset(0, 40)),
                        ],
                        child: Text(
                          "Tinkerly",
                          style: GoogleFonts.pacifico(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: accentColor,
                            letterSpacing: 1.5,
                            shadows: [
                              Shadow(
                                blurRadius: 16,
                                color: accentColor.withOpacity(0.18),
                                offset: const Offset(2, 2),
                              ),
                            ],
                          ),
                        ).animate().scaleXY(begin: 0.8, end: 1.0, duration: 900.ms, curve: Curves.easeOutBack, delay: 100.ms).fade(duration: 500.ms),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        "Join Tinkerly Today! 🚀",
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          color: textColor.withOpacity(0.85),
                          fontWeight: FontWeight.w600,
                        ),
                      ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
                      const SizedBox(height: 20),
                      GestureDetector(
                        onTap: _pickProfileImage,
                        child: CircleAvatar(
                          radius: 45,
                          backgroundColor: accentColor.withOpacity(0.08),
                          backgroundImage: _profileImageFileOrBytes != null
                              ? (kIsWeb
                                  ? MemoryImage(_profileImageFileOrBytes)
                                  : FileImage(_profileImageFileOrBytes) as ImageProvider)
                              : null,
                          child: _profileImageFileOrBytes == null
                              ? Icon(Icons.camera_alt, size: 32, color: accentColor)
                              : null,
                        ),
                      ).animate().fadeIn(duration: 400.ms, delay: 300.ms),
                      const SizedBox(height: 18),
                      // Name
                      CustomTextField(
                        controller: _nameController,
                        label: 'Full Name',
                        icon: Icons.person,
                        validator: (value) => value!.isEmpty ? 'Enter your name' : null,
                        fillColor: Colors.white,
                        borderColor: inputBorderColor,
                      ).animate().fadeIn(duration: 400.ms, delay: 400.ms),
                      const SizedBox(height: 14),
                      // Username
                      CustomTextField(
                        controller: _usernameController,
                        label: 'Username',
                        icon: Icons.alternate_email,
                        validator: (value) => value!.isEmpty ? 'Enter a username' : null,
                        fillColor: Colors.white,
                        borderColor: inputBorderColor,
                      ).animate().fadeIn(duration: 400.ms, delay: 450.ms),
                      const SizedBox(height: 14),
                      // Email
                      CustomTextField(
                        controller: _emailController,
                        label: 'Email',
                        icon: Icons.email,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) => value!.contains('@') ? null : 'Enter a valid email',
                        fillColor: Colors.white,
                        borderColor: inputBorderColor,
                      ).animate().fadeIn(duration: 400.ms, delay: 500.ms),
                      const SizedBox(height: 14),
                      // Password
                      CustomTextField(
                        controller: _passwordController,
                        label: 'Password',
                        icon: Icons.lock,
                        isPassword: true,
                        validator: (value) => value!.length < 6 ? 'Password must be at least 6 characters' : null,
                        fillColor: Colors.white,
                        borderColor: inputBorderColor,
                      ).animate().fadeIn(duration: 400.ms, delay: 550.ms),
                      const SizedBox(height: 18),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Select Skill Categories",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            color: textColor.withOpacity(0.85),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      MultiSelectDialogField<String>(
                        items: skillCategories.map((e) => MultiSelectItem(e, e)).toList(),
                        title: const Text("Categories"),
                        selectedColor: accentColor,
                        decoration: BoxDecoration(
                          color: accentColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: accentColor.withOpacity(0.2), width: 1),
                        ),
                        buttonIcon: Icon(
                          Icons.arrow_drop_down,
                          color: accentColor,
                        ),
                        buttonText: Text(
                          "Select Categories",
                          style: GoogleFonts.poppins(
                            color: Colors.black54,
                            fontSize: 16,
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
                          chipColor: accentColor.withOpacity(0.15),
                          textStyle: TextStyle(color: accentColor),
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
                      ).animate().fadeIn(duration: 400.ms, delay: 600.ms),
                      const SizedBox(height: 24),
                      // Register Button
                      CustomButton(
                        text: "Register",
                        isLoading: _isLoading,
                        onPressed: _isLoading ? null : _register,
                        color: accentColor,
                        textColor: Colors.white,
                        elevation: 8,
                        borderRadius: 32,
                        gradient: null,
                        iconWidget: Icon(Icons.app_registration, color: Colors.white),
                      ).animate().fadeIn(duration: 400.ms, delay: 700.ms),
                      const SizedBox(height: 14),
                      // Google Button
                      CustomButton(
                        text: "Sign up with Google",
                        color: googleButtonColor,
                        textColor: googleTextColor,
                        isLoading: _isGoogleLoading,
                        onPressed: _isGoogleLoading ? null : _handleGoogleSignIn,
                        elevation: 4,
                        borderRadius: 32,
                        gradient: null,
                        iconWidget: Icon(Icons.g_mobiledata, color: accentColor),
                        // No border for this button
                      ).animate().fadeIn(duration: 400.ms, delay: 800.ms),
                      const SizedBox(height: 18),
                      // Login link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Already have an account?",
                            style: GoogleFonts.poppins(
                              color: _isDark ? Colors.white70 : Colors.black54,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/login');
                            },
                            child: Text(
                              "Login",
                              style: GoogleFonts.poppins(
                                color: accentColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ).animate().fadeIn(duration: 400.ms, delay: 900.ms),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: Animate(
        effects: [FadeEffect(duration: 400.ms), ScaleEffect(duration: 400.ms)],
        child: FloatingActionButton(
          onPressed: _toggleTheme,
          backgroundColor: Colors.white,
          elevation: 6,
          child: Icon(
            _isDark ? Icons.wb_sunny : Icons.nightlight_round,
            color: accentColor,
          ),
          tooltip: _isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
        ),
      ),
    );
  }
}
