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
                        "Join Tinkerly Today! 🚀",
                        style: TextStyle(fontSize: 18, color: Colors.grey[700], fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      GestureDetector(
                        onTap: _pickProfileImage,
                        child: CircleAvatar(
                          radius: 45,
                          backgroundColor: Colors.red.shade50,
                          backgroundImage: _profileImageFileOrBytes != null
                              ? (kIsWeb
                                  ? MemoryImage(_profileImageFileOrBytes)
                                  : FileImage(_profileImageFileOrBytes) as ImageProvider)
                              : null,
                          child: _profileImageFileOrBytes == null
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
                        textColor: Colors.black87,
                        isLoading: _isGoogleLoading,
                        onPressed: _isGoogleLoading ? null : _handleGoogleSignIn,
                        icon: Icons.g_mobiledata,
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
