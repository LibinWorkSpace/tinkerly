import 'dart:io';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:tinkerly/models/user_model.dart';
import 'package:tinkerly/constants/categories.dart';
import 'package:tinkerly/widgets/category_chip.dart';
import 'package:tinkerly/services/user_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/portfolio_service.dart';
import '../../models/portfolio_model.dart';

class EditProfileScreen extends StatefulWidget {
  final AppUser user;

  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _usernameController;
  late TextEditingController _bioController;
  final FocusNode _usernameFocusNode = FocusNode();
  late List<String> _selectedCategories;
  String? _profileImageUrl;
  dynamic _profileImageFileOrBytes;
  String? _usernameErrorText;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _usernameController = TextEditingController(
        text: widget.user.name.toLowerCase().replaceAll(' ', '_'));
    _bioController = TextEditingController(text: widget.user.bio ?? '');
    _selectedCategories = List.from(widget.user.categories);
    _profileImageUrl = widget.user.profileImageUrl;

    // Add validation listener for username
    _usernameFocusNode.addListener(() async {
      if (!_usernameFocusNode.hasFocus) {
        final username = _usernameController.text.trim();
        final originalUsername = widget.user.name.toLowerCase().replaceAll(' ', '_');

        // Skip validation if username hasn't changed
        if (username == originalUsername) {
          setState(() {
            _usernameErrorText = null;
          });
          return;
        }

        if (username.isEmpty || username.length < 3) {
          setState(() {
            _usernameErrorText = 'Username must be at least 3 characters.';
          });
          return;
        }

        if (username.length > 30) {
          setState(() {
            _usernameErrorText = 'Username must be less than 30 characters.';
          });
          return;
        }

        if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username)) {
          setState(() {
            _usernameErrorText = 'Username can only contain letters, numbers, and underscores.';
          });
          return;
        }

        // Check if username already exists
        final exists = await UserService.checkUsernameExists(username);
        if (exists) {
          setState(() {
            _usernameErrorText = 'Username is already taken.';
          });
          return;
        }

        setState(() {
          _usernameErrorText = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    _usernameFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Color(0xFF6C63FF);
    final secondaryColor = Color(0xFFFF6B9D);
    
    return Scaffold(
      backgroundColor: Color(0xFFFAFAFA),
      body: Container(
        color: Color(0xFFFAFAFA),
        child: SafeArea(
          child: Column(
            children: [
              // Custom App Bar
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(5),
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Color(0xFFF7FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Color(0xFFE2E8F0),
                          width: 1,
                        ),
                      ),
                      child: IconButton(
                        icon: Icon(Icons.arrow_back, color: Color(0xFF6C63FF)),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [primaryColor, secondaryColor],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withAlpha(77),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(Icons.edit, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Edit Profile',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms),
              
              // Main Content
              Expanded(
                child: SingleChildScrollView(
                  physics: BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Container(
                    constraints: BoxConstraints(maxWidth: 420),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(5),
                          blurRadius: 15,
                          spreadRadius: 0,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Profile Image Section
                        Center(
                          child: Stack(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withAlpha(77),
                                    width: 3,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: primaryColor.withAlpha(77),
                                      blurRadius: 20,
                                      spreadRadius: 0,
                                      offset: Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: CircleAvatar(
                                  radius: 60,
                                  backgroundColor: Colors.white.withAlpha(51),
                                  backgroundImage: _profileImageFileOrBytes != null
                                      ? (kIsWeb
                                          ? MemoryImage(_profileImageFileOrBytes)
                                          : FileImage(_profileImageFileOrBytes)
                                              as ImageProvider)
                                      : (_profileImageUrl != null
                                          ? NetworkImage(_profileImageUrl!)
                                          : null),
                                  child: _profileImageFileOrBytes == null &&
                                          _profileImageUrl == null
                                      ? Text(
                                          _nameController.text.isNotEmpty
                                              ? _nameController.text[0].toUpperCase()
                                              : '?',
                                          style: GoogleFonts.poppins(
                                            fontSize: 40,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                      : null,
                                ),
                              ),
                              Positioned(
                                bottom: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: _pickProfileImage,
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [primaryColor, secondaryColor],
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                      ),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: primaryColor.withAlpha(102),
                                          blurRadius: 12,
                                          spreadRadius: 0,
                                          offset: Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(Icons.camera_alt,
                                        color: Colors.white, size: 20),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ).animate().scaleXY(begin: 0.8, end: 1.0, duration: 600.ms, curve: Curves.easeOutBack),
                        
                        const SizedBox(height: 32),
                        
                        // Name Field
                        Container(
                          decoration: BoxDecoration(
                            color: Color(0xFFF7FAFC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Color(0xFFE2E8F0),
                              width: 1,
                            ),
                          ),
                          child: TextField(
                            controller: _nameController,
                            style: GoogleFonts.poppins(color: Color(0xFF2D3748)),
                            decoration: InputDecoration(
                              labelText: 'Name',
                              labelStyle: GoogleFonts.poppins(
                                color: Color(0xFF718096),
                              ),
                              prefixIcon: Icon(Icons.person, color: Color(0xFF6C63FF)),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.all(16),
                              floatingLabelBehavior: FloatingLabelBehavior.auto,
                            ),
                          ),
                        ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
                        
                        const SizedBox(height: 20),
                        
                        // Username Field
                        Container(
                          decoration: BoxDecoration(
                            color: Color(0xFFF7FAFC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Color(0xFFE2E8F0),
                              width: 1,
                            ),
                          ),
                          child: TextField(
                            controller: _usernameController,
                            focusNode: _usernameFocusNode,
                            style: GoogleFonts.poppins(color: Color(0xFF2D3748)),
                            decoration: InputDecoration(
                              labelText: 'Username',
                              labelStyle: GoogleFonts.poppins(
                                color: Color(0xFF718096),
                              ),
                              errorText: _usernameErrorText,
                              errorStyle: GoogleFonts.poppins(
                                color: Colors.red.shade600,
                                fontSize: 12,
                              ),
                              prefixIcon: Icon(Icons.alternate_email, color: Color(0xFF6C63FF)),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.all(16),
                              floatingLabelBehavior: FloatingLabelBehavior.auto,
                            ),
                          ),
                        ).animate().fadeIn(duration: 400.ms, delay: 300.ms),
                        
                        const SizedBox(height: 20),
                        
                        // Bio Field
                        Container(
                          decoration: BoxDecoration(
                            color: Color(0xFFF7FAFC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Color(0xFFE2E8F0),
                              width: 1,
                            ),
                          ),
                          child: TextField(
                            controller: _bioController,
                            maxLines: 3,
                            style: GoogleFonts.poppins(color: Color(0xFF2D3748)),
                            decoration: InputDecoration(
                              labelText: 'Bio',
                              labelStyle: GoogleFonts.poppins(
                                color: Color(0xFF718096),
                              ),
                              prefixIcon: Icon(Icons.description, color: Color(0xFF6C63FF)),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.all(16),
                              floatingLabelBehavior: FloatingLabelBehavior.auto,
                            ),
                          ),
                        ).animate().fadeIn(duration: 400.ms, delay: 400.ms),
                        
                        const SizedBox(height: 32),
                        
                        // Categories Section
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Skills & Categories',
                            style: GoogleFonts.poppins(
                              color: Color(0xFF2D3748),
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ).animate().fadeIn(duration: 400.ms, delay: 500.ms),
                        
                        const SizedBox(height: 16),
                        
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Color(0xFFF7FAFC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Color(0xFFE2E8F0),
                              width: 1,
                            ),
                          ),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: skillCategories.map((cat) {
                              final isSelected = _selectedCategories.contains(cat);
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    if (_selectedCategories.contains(cat)) {
                                      _selectedCategories.remove(cat);
                                    } else {
                                      _selectedCategories.add(cat);
                                    }
                                  });
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    gradient: isSelected
                                        ? LinearGradient(
                                            colors: [primaryColor, secondaryColor],
                                            begin: Alignment.centerLeft,
                                            end: Alignment.centerRight,
                                          )
                                        : null,
                                    color: isSelected ? null : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected 
                                          ? Colors.transparent 
                                          : Color(0xFFE2E8F0),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    cat,
                                    style: GoogleFonts.poppins(
                                      color: isSelected ? Colors.white : Color(0xFF2D3748),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ).animate().fadeIn(duration: 400.ms, delay: 600.ms),
                        
                        const SizedBox(height: 32),
                        
                        // Save Button
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
                                color: primaryColor.withAlpha(102),
                                blurRadius: 20,
                                spreadRadius: 0,
                                offset: Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _saveProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.save, size: 24),
                                const SizedBox(width: 12),
                                Text(
                                  'Save Changes',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ).animate().fadeIn(duration: 400.ms, delay: 700.ms),
                        
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickProfileImage() async {
    if (kIsWeb) {
      final result = await FilePicker.platform.pickFiles(type: FileType.image);
      if (result != null && result.files.single.bytes != null) {
        if (!mounted) return;
        setState(() {
          _profileImageFileOrBytes = result.files.single.bytes!;
        });
      }
    } else {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        if (!mounted) return;
        setState(() {
          _profileImageFileOrBytes = File(picked.path);
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    // Check for validation errors before saving
    if (_usernameErrorText != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_usernameErrorText!),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final username = _usernameController.text.trim();
    if (username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Username cannot be empty'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    String? url;

    if (_profileImageFileOrBytes != null) {
      if (kIsWeb && _profileImageFileOrBytes is Uint8List) {
        url = await UserService.uploadBytes(
            _profileImageFileOrBytes, 'profile.jpg');
      } else if (!kIsWeb && _profileImageFileOrBytes is File) {
        url = await UserService.uploadFile(_profileImageFileOrBytes.path);
      }

      if (url != null) {
        if (!mounted) return;
        setState(() {
          _profileImageUrl = url;
        });
      }
    }

    bool success = false;
    try {
      success = await UserService.saveUserProfile(
        _nameController.text.trim(),
        widget.user.email, // still required for registration, ignored for edit
        _profileImageUrl,
        _selectedCategories,
        _usernameController.text.trim(),
        _bioController.text.trim(),
        isEdit: true,
      );
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Failed to update profile';

        // Parse specific error messages
        if (e.toString().contains('Username is already taken') ||
            e.toString().contains('username already exists')) {
          errorMessage = 'Username is already taken';
        } else if (e.toString().contains('409')) {
          errorMessage = 'Username is already taken';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Auto-create portfolios for new categories
    if (success && mounted) {
      try {
        final userId = widget.user.uid;
        final existingPortfolios = await PortfolioService.fetchUserPortfolios(userId);
        final existingCategories = existingPortfolios.map((p) => p.category).toSet();
        final newCategories = _selectedCategories.where((cat) => !existingCategories.contains(cat));
        
        for (final cat in newCategories) {
          try {
            await PortfolioService.createPortfolio({
              'userId': userId,
              'profilename': cat,
              'category': cat,
              'description': '',
              'profileImageUrl': null,
              // Don't send followers and posts arrays, let the backend handle defaults
            });
          } catch (e) {
            print('Failed to create portfolio for category $cat: $e');
            // Continue with other categories even if one fails
          }
        }
      } catch (e) {
        print('Failed to fetch existing portfolios: $e');
        // Show a warning but don't prevent navigation
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Profile updated, but portfolio sync failed. Please try again later.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
      Navigator.pop(context, true);
    } else if (!success) {
      // Optionally show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile.')),
      );
    }
  }
}
