import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import '../../services/user_service.dart';
import '../../services/auth_service.dart';
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
        Fluttertoast.showToast(msg: "Google Sign-In successful! 🎉");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => HomeScreen()),
        );
      } else {
        Fluttertoast.showToast(msg: "Google sign-in failed. Please try again.");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error: "+e.toString());
    } finally {
      if (!mounted) return;
      setState(() => _isGoogleLoading = false);
    }
  }

  void _goToRegister() {
    Navigator.pushNamed(context, '/register');
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;
    final backgroundGradient = _isDark
        ? LinearGradient(
            colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : LinearGradient(
            colors: [Color(0xFF667EEA), Color(0xFF64B6FF), Color(0xFFA5FECB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );
    final textColor = _isDark ? Colors.white : Colors.white;
    final accentColor = _isDark ? Color(0xFF64FFDA) : Color(0xFFFFD700);
    final inputFillColor = _isDark ? Colors.black.withOpacity(0.2) : Colors.white.withOpacity(0.2);
    final inputBorderColor = _isDark ? Color(0xFF64FFDA).withOpacity(0.5) : Colors.white.withOpacity(0.5);
    final buttonColor = accentColor;
    final googleButtonColor = Colors.white;
    final googleTextColor = Colors.black87;

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
              physics: BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Animated Logo
                    ScaleTransition(
                      scale: _logoAnimation,
                      child: Animate(
                        effects: [
                          FadeEffect(duration: 600.ms),
                          ShimmerEffect(duration: 1200.ms, color: accentColor.withOpacity(0.3)),
                        ],
                        child: Container(
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: _isDark ? Colors.black.withOpacity(0.2) : Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: accentColor.withOpacity(0.2),
                                blurRadius: 20,
                                spreadRadius: 5,
                              )
                            ],
                          ),
                          child: Text(
                            "⚡",
                            style: TextStyle(fontSize: 60),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Tinkerly",
                      style: GoogleFonts.poppins(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                        letterSpacing: 1.5,
                      ),
                    ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
                    const SizedBox(height: 8),
                    Text(
                      'Welcome Back 👋',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        color: textColor.withOpacity(0.9),
                        fontWeight: FontWeight.w600,
                      ),
                    ).animate().fadeIn(duration: 400.ms, delay: 300.ms),
                    const SizedBox(height: 8),
                    Text(
                      'Login to your Tinkerly account',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        color: textColor.withOpacity(0.8),
                      ),
                    ).animate().fadeIn(duration: 400.ms, delay: 400.ms),
                    const SizedBox(height: 32),
                    // Email
                    CustomTextField(
                      controller: _emailController,
                      label: 'Email',
                      icon: Icons.sms,
                      keyboardType: TextInputType.emailAddress,
                      fillColor: Colors.white,
                      borderColor: inputBorderColor,
                    ).animate().fadeIn(duration: 400.ms, delay: 400.ms),
                    const SizedBox(height: 18),
                    // Password
                    CustomTextField(
                      controller: _passwordController,
                      label: 'Password',
                      icon: Icons.lock_outline,
                      isPassword: true,
                      fillColor: Colors.white,
                      borderColor: inputBorderColor,
                    ).animate().fadeIn(duration: 400.ms, delay: 500.ms),
                    const SizedBox(height: 28),
                    // Login Button
                    CustomButton(
                      text: "Login",
                      isLoading: _isLoading,
                      onPressed: _isLoading ? null : _loginUser,
                      color: const Color(0xFF1976D2),
                      textColor: Colors.white,
                      elevation: 8,
                      borderRadius: 32,
                      gradient: null,
                      iconWidget: Icon(Icons.login, color: Colors.white),
                    ).animate().fadeIn(duration: 400.ms, delay: 600.ms),
                    const SizedBox(height: 14),
                    // Divider
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: inputBorderColor,
                            thickness: 0.5,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'or continue with',
                            style: GoogleFonts.poppins(
                              color: textColor.withOpacity(0.7),
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: inputBorderColor,
                            thickness: 0.5,
                          ),
                        ),
                      ],
                    ).animate().fadeIn(duration: 400.ms, delay: 750.ms),
                    const SizedBox(height: 14),
                    // Google Button
                    CustomButton(
                      text: "Sign in with Google",
                      color: Colors.white,
                      textColor: const Color(0xFF1976D2),
                      isLoading: _isGoogleLoading,
                      onPressed: _isGoogleLoading ? null : _handleGoogleSignIn,
                      elevation: 4,
                      borderRadius: 32,
                      gradient: null,
                      iconWidget: Icon(Icons.g_mobiledata, color: const Color(0xFF1976D2)),
                      // No border for this button
                    ).animate().fadeIn(duration: 400.ms, delay: 700.ms),
                    const SizedBox(height: 18),
                    // Register link
                    TextButton(
                      onPressed: _goToRegister,
                      child: Text(
                        "Don't have an account? Register",
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF1976D2),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ).animate().fadeIn(duration: 400.ms, delay: 800.ms),
                    const SizedBox(height: 18),
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
                                  decoration: const InputDecoration(labelText: 'New Password'),
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
                      child: const Text('Forgot Password?'),
                    ).animate().fadeIn(duration: 400.ms, delay: 850.ms),
                  ],
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
            color: const Color(0xFF1976D2),
          ),
          tooltip: _isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
        ),
      ),
    );
  }
}