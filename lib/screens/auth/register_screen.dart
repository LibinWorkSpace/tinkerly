// lib/screens/auth/register_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../constants/categories.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import '../../services/auth_service.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../services/user_service.dart';
import '../../models/user_model.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:google_sign_in_web/google_sign_in_web.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<String> _selectedCategories = [];
  XFile? _profileImage;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      // Try to sign in silently on web
      GoogleSignIn().signInSilently();
    }
  }

  Future<void> _pickProfileImage() async {
    final ImagePicker picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _profileImage = image;
      });
    }
  }

  void _register() async {
    if (!_formKey.currentState!.validate() || _selectedCategories.isEmpty) return;
    setState(() => _isLoading = true);
    final authService = AuthService();
    final user = await authService.registerWithEmail(
      _emailController.text.trim(),
      _passwordController.text,
    );
    if (user != null) {
      final appUser = AppUser(
        uid: user.uid,
        email: user.email!,
        categories: _selectedCategories,
        name: _nameController.text.trim(),
        username: _usernameController.text.trim(),
      );
      await _userService.saveUser(appUser);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration successful! Please login.')),
      );
      Navigator.pushReplacementNamed(context, '/login');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration failed.')),
      );
    }
    setState(() => _isLoading = false);
  }

  void _handleGoogleSignIn() async {
    setState(() => _isGoogleLoading = true);
    final user = await _authService.signInWithGoogle();
    if (user != null) {
      final appUser = AppUser(
        uid: user.uid,
        email: user.email ?? '',
        categories: _selectedCategories,
        name: _nameController.text.trim(),
        username: _usernameController.text.trim(),
      );
      await _userService.saveUser(appUser);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Signed in with Google! Please login.')),
      );
      Navigator.pushReplacementNamed(context, '/login');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Google sign-in failed.')),
      );
    }
    setState(() => _isGoogleLoading = false);
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
                child: Form(
                  key: _formKey,
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
                        "Create your account",
                        style: TextStyle(fontSize: 18, color: Colors.grey[700]),
                      ),
                      const SizedBox(height: 20),
                      GestureDetector(
                        onTap: _pickProfileImage,
                        child: CircleAvatar(
                          radius: 45,
                          backgroundColor: Colors.red.shade50,
                          backgroundImage: _profileImage != null
                              ? FileImage(File(_profileImage!.path))
                              : null,
                          child: _profileImage == null
                              ? const Icon(Icons.camera_alt, size: 32, color: Colors.redAccent)
                              : null,
                        ),
                      ),
                      const SizedBox(height: 18),
                      CustomTextField(
                        controller: _nameController,
                        label: 'Full Name',
                        icon: Icons.person,
                        validator: (value) => value!.isEmpty ? 'Enter your name' : null,
                      ),
                      const SizedBox(height: 14),
                      CustomTextField(
                        controller: _usernameController,
                        label: 'Username',
                        icon: Icons.alternate_email,
                        validator: (value) => value!.isEmpty ? 'Enter a username' : null,
                      ),
                      const SizedBox(height: 14),
                      CustomTextField(
                        controller: _emailController,
                        label: 'Email',
                        icon: Icons.email,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) => value!.contains('@') ? null : 'Enter a valid email',
                      ),
                      const SizedBox(height: 14),
                      CustomTextField(
                        controller: _passwordController,
                        label: 'Password',
                        icon: Icons.lock,
                        isPassword: true,
                        validator: (value) => value!.length < 6 ? 'Password must be at least 6 characters' : null,
                      ),
                      const SizedBox(height: 18),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Select Skill Categories",
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      const SizedBox(height: 8),
                      MultiSelectDialogField<String>(
                        items: skillCategories.map((e) => MultiSelectItem(e, e)).toList(),
                        title: const Text("Categories"),
                        selectedColor: Colors.redAccent,
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade200, width: 1),
                        ),
                        buttonIcon: const Icon(
                          Icons.arrow_drop_down,
                          color: Colors.redAccent,
                        ),
                        buttonText: const Text(
                          "Select Categories",
                          style: TextStyle(
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
                          chipColor: Colors.red.shade100,
                          textStyle: const TextStyle(color: Colors.redAccent),
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
                      const SizedBox(height: 24),
                      CustomButton(
                        text: "Register",
                        isLoading: _isLoading,
                        onPressed: _isLoading ? null : _register,
                      ),
                      const SizedBox(height: 12),
                      CustomButton(
                        text: "Sign up with Google",
                        color: Colors.white,
                        isLoading: _isGoogleLoading,
                        onPressed: kIsWeb ? null : (_isGoogleLoading ? null : _handleGoogleSignIn),
                        // Add a Google logo if you want, or keep it simple
                      ),
                      if (kIsWeb)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: SizedBox(
                            width: 220,
                            height: 50,
                            child: GoogleSignInPlatform.instance is GoogleSignInPlugin
                                ? (GoogleSignInPlatform.instance as GoogleSignInPlugin).renderButton()
                                : const SizedBox.shrink(),
                          ),
                        ),
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Already have an account?"),
                          TextButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/login');
                            },
                            child: const Text("Login"),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
