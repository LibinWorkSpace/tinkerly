import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import '../../services/user_service.dart';
import '../../services/auth_service.dart';
import '../user/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  final AuthService _authService = AuthService();

  void _loginUser() async {
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
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handleGoogleSignIn() async {
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
      setState(() => _isGoogleLoading = false);
    }
  }

  void _goToRegister() {
    Navigator.pushNamed(context, '/register');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF44336), Color(0xFFFFCDD2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Card(
              elevation: 10,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 10),
                    Text(
                      "Tinkerly",
                      style: TextStyle(
                        fontFamily: 'Pacifico',
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade400,
                        letterSpacing: 1.5,
                        shadows: [
                          Shadow(
                            blurRadius: 8,
                            color: Colors.red.shade100,
                            offset: Offset(2, 2),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Welcome Back 👋",
                      style: TextStyle(fontSize: 20, color: Colors.grey[700], fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Login to your Tinkerly account',
                      style: TextStyle(fontSize: 15, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 24),
                    CustomTextField(
                      controller: _emailController,
                      label: 'Email',
                      icon: Icons.email,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 18),
                    CustomTextField(
                      controller: _passwordController,
                      label: 'Password',
                      icon: Icons.lock,
                      isPassword: true,
                    ),
                    const SizedBox(height: 24),
                    CustomButton(
                      text: "Login",
                      isLoading: _isLoading,
                      onPressed: _isLoading ? null : _loginUser,
                    ),
                    const SizedBox(height: 12),
                    CustomButton(
                      text: "Sign in with Google",
                      color: Colors.white,
                      textColor: Colors.black87,
                      isLoading: _isGoogleLoading,
                      onPressed: _isGoogleLoading ? null : _handleGoogleSignIn,
                      icon: Icons.g_mobiledata,
                    ),
                    const SizedBox(height: 18),
                    TextButton(
                      onPressed: _goToRegister,
                      child: const Text("Don't have an account? Register"),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
