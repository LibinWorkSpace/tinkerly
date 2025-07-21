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
  late List<String> _selectedCategories;
  String? _profileImageUrl;
  dynamic _profileImageFileOrBytes;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _usernameController = TextEditingController(
        text: widget.user.name.toLowerCase().replaceAll(' ', '_'));
    _bioController = TextEditingController(text: widget.user.bio ?? '');
    _selectedCategories = List.from(widget.user.categories);
    _profileImageUrl = widget.user.profileImageUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
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
                            style: GoogleFonts.poppins(color: Color(0xFF2D3748)),
                            decoration: InputDecoration(
                              labelText: 'Username',
                              labelStyle: GoogleFonts.poppins(
                                color: Color(0xFF718096),
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

    await UserService.saveUserProfile(
      _nameController.text.trim(),
      widget.user.email,
      _profileImageUrl,
      _selectedCategories,
      _usernameController.text.trim(),
      _bioController.text.trim(),
    );

    if (mounted) {
      Navigator.pop(context, true);
    }
  }
}
