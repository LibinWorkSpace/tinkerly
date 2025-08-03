import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import '../../services/user_service.dart';
import '../../services/auth_service.dart';
import '../../utils/password_validator.dart';
import '../user/home_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  final AuthService _authService = AuthService();
  late AnimationController _animationController;
  late Animation<double> _logoAnimation;

  // Theme switcher state
  bool _isDark = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _logoAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleTheme() {
    setState(() {
      _isDark = !_isDark;
    });
  }

  void _loginUser() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final user = await _authService.signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
      );
      
      if (user != null) {
        // Print Firebase ID token for Postman use
        String? token = await FirebaseAuth.instance.currentUser?.getIdToken();
        print('FIREBASE_ID_TOKEN: ' + (token ?? 'null'));
        // Ensure user profile exists in backend
        try {
          final profile = await UserService.fetchUserProfile();
          if (profile == null || profile['email'] == null) {
            await UserService.saveUserProfile(
              user.displayName ?? '',
              user.email ?? '',
              user.photoURL,
              [],
              user.displayName ?? '',
              null,
            );
          }
        } catch (e) {
          // If fetch fails, create profile
          await UserService.saveUserProfile(
            user.displayName ?? '',
            user.email ?? '',
            user.photoURL,
            [],
            user.displayName ?? '',
            null,
          );
        }
        Fluttertoast.showToast(msg: "Login successful! 🎉");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => HomeScreen()),
        );
      } else {
        Fluttertoast.showToast(msg: "Login failed. Please check your credentials.");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Login failed: "+e.toString());
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handleGoogleSignIn() async {
    if (!mounted) return;
    setState(() => _isGoogleLoading = true);
    try {
      final user = await _authService.signInWithGoogle();
      if (user != null) {
        try {
          final profile = await UserService.fetchUserProfile();
          if (profile == null || profile['email'] == null) {
            await UserService.saveUserProfile(
              user.displayName ?? '',
              user.email ?? '',
              user.photoURL,
              [],
              user.displayName ?? '',
              null,
            );
          }
          Fluttertoast.showToast(msg: "Google Sign-In successful! 🎉");
          setState(() => _isGoogleLoading = false); // Ensure loading is reset before navigation
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => HomeScreen()),
          );
        } catch (e) {
          setState(() => _isGoogleLoading = false);
          Fluttertoast.showToast(msg: "Failed to save profile: "+e.toString());
        }
      } else {
        setState(() => _isGoogleLoading = false);
        Fluttertoast.showToast(msg: "Google sign-in failed. Please try again.");
      }
    } catch (e) {
      setState(() => _isGoogleLoading = false);
      Fluttertoast.showToast(msg: "Error: "+e.toString());
    }
  }

  void _goToRegister() {
    Navigator.pushNamed(context, '/register');
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // Modern color schemes
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
                top: -100,
                right: -100,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: primaryColor.withOpacity(0.1),
                  ),
                ),
              ),
              Positioned(
                bottom: -150,
                left: -100,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: secondaryColor.withOpacity(0.1),
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
                        maxWidth: isTablet ? 400 : double.infinity,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Header Section with Glassmorphism Card
                          Container(
                            padding: EdgeInsets.all(32),
                            margin: EdgeInsets.only(bottom: 40),
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
                                ScaleTransition(
                                  scale: _logoAnimation,
                                  child: Animate(
                                    effects: [
                                      FadeEffect(duration: 600.ms),
                                      ShimmerEffect(duration: 1500.ms, color: primaryColor.withOpacity(0.4)),
                                    ],
                                    child: Container(
                                      padding: EdgeInsets.all(24),
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
                                            blurRadius: 25,
                                            spreadRadius: 0,
                                            offset: Offset(0, 8),
                                          )
                                        ],
                                      ),
                                      child: Text(
                                        "⚡",
                                        style: TextStyle(
                                          fontSize: 48,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  "Tinkerly",
                                  style: GoogleFonts.poppins(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                    letterSpacing: 2,
                                  ),
                                ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
                                const SizedBox(height: 12),
                                Text(
                                  'Welcome Back! 👋',
                                  style: GoogleFonts.poppins(
                                    fontSize: 20,
                                    color: textColor.withOpacity(0.9),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ).animate().fadeIn(duration: 400.ms, delay: 300.ms),
                                const SizedBox(height: 8),
                                Text(
                                  'Sign in to continue your journey',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: textColor.withOpacity(0.7),
                                    fontWeight: FontWeight.w400,
                                  ),
                                ).animate().fadeIn(duration: 400.ms, delay: 400.ms),
                              ],
                            ),
                          ),
                          // Login Form Container
                          Container(
                            padding: EdgeInsets.all(28),
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
                                  blurRadius: 20,
                                  spreadRadius: 0,
                                  offset: Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                // Email Field
                                CustomTextField(
                                  controller: _emailController,
                                  label: 'Email Address',
                                  icon: Icons.email_outlined,
                                  keyboardType: TextInputType.emailAddress,
                                  fillColor: inputFillColor,
                                  borderColor: inputBorderColor,
                                ).animate().fadeIn(duration: 400.ms, delay: 500.ms),
                                const SizedBox(height: 20),
                                // Password Field
                                CustomTextField(
                                  controller: _passwordController,
                                  label: 'Password',
                                  icon: Icons.lock_outline,
                                  isPassword: true,
                                  fillColor: inputFillColor,
                                  borderColor: inputBorderColor,
                                ).animate().fadeIn(duration: 400.ms, delay: 600.ms),
                                const SizedBox(height: 32),
                                // Login Button
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
                                    text: "Sign In",
                                    isLoading: _isLoading,
                                    onPressed: _isLoading ? null : _loginUser,
                                    color: Colors.transparent,
                                    textColor: Colors.white,
                                    elevation: 0,
                                    borderRadius: 16,
                                    gradient: null,
                                    iconWidget: Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                                  ),
                                ).animate().fadeIn(duration: 400.ms, delay: 700.ms),
                                const SizedBox(height: 24),
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
                                ).animate().fadeIn(duration: 400.ms, delay: 800.ms),
                                const SizedBox(height: 24),
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
                                    text: "Continue with Google",
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
                                ).animate().fadeIn(duration: 400.ms, delay: 850.ms),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                          // Bottom Links
                          Column(
                            children: [
                              // Register Link
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
                                      "Don't have an account? ",
                                      style: GoogleFonts.poppins(
                                        color: textColor.withOpacity(0.8),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: _goToRegister,
                                      child: Text(
                                        "Sign Up",
                                        style: GoogleFonts.poppins(
                                          color: primaryColor,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ).animate().fadeIn(duration: 400.ms, delay: 900.ms),
                              const SizedBox(height: 16),
                              // Forgot Password Link
                              TextButton(
                                onPressed: () async {
                        final email = _emailController.text.trim();
                        if (email.isEmpty || !email.contains('@')) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter a valid email to reset password.')),
                          );
                          return;
                        }
                        // Ask user for OTP delivery method
                        String? method = await showDialog<String>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Send OTP'),
                            content: const Text('How would you like to receive the OTP?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, 'email'),
                                child: const Text('Email'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, 'phone'),
                                child: const Text('Phone Number'),
                              ),
                            ],
                          ),
                        );
                        if (method == null) return;
                        // Send OTP
                        final sent = await UserService.sendPasswordResetOtp(email, method: method);
                        if (!sent) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to send OTP via $method. Please check your email/phone.')),
                          );
                          return;
                        }
                        TextEditingController otpController = TextEditingController();
                        TextEditingController newPasswordController = TextEditingController();
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Reset Password'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('An OTP has been sent to your $method.'),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: otpController,
                                  decoration: const InputDecoration(labelText: 'Enter OTP'),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: newPasswordController,
                                  decoration: const InputDecoration(
                                    labelText: 'New Password',
                                    helperText: 'Must be 8+ chars with uppercase, lowercase, number & symbol',
                                  ),
                                  obscureText: true,
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
                                  final otp = otpController.text.trim();
                                  final newPassword = newPasswordController.text.trim();
                                  if (otp.isEmpty || newPassword.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Please enter OTP and new password.')),
                                    );
                                    return;
                                  }
                                  // Validate password strength
                                  final passwordError = PasswordValidator.validatePassword(newPassword);
                                  if (passwordError != null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(passwordError)),
                                    );
                                    return;
                                  }
                                  final reset = await UserService.resetPasswordWithOtp(method == 'phone' ? email : email, otp, newPassword);
                                  if (reset) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Password reset successful! Please login.')),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Invalid OTP or error. Please try again.')),
                                    );
                                  }
                                },
                                child: const Text('Submit'),
                              ),
                            ],
                          ),
                        );
                                },
                                child: Text(
                                  'Forgot Password?',
                                  style: GoogleFonts.poppins(
                                    color: primaryColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ).animate().fadeIn(duration: 400.ms, delay: 950.ms),
                            ],
                          ),
                        ],
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