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
    final accentColor = const Color(0xFF4FC3F7);
    final bgColor = const Color(0xFFF7FBFC);
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        iconTheme: IconThemeData(color: accentColor),
        title: Text('Edit Profile',
            style: TextStyle(
                color: accentColor, fontWeight: FontWeight.bold)),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 20),
          child: Container(
            constraints: BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.85),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.07),
                  blurRadius: 32,
                  offset: Offset(0, 12),
                ),
              ],
              border: Border.all(color: Color(0xFFE0E0E0), width: 1.2),
            ),
            child: Column(
              children: [
                // Profile Image
                Center(
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: accentColor.withOpacity(0.18),
                              blurRadius: 18,
                              offset: Offset(0, 6),
                            ),
                          ],
                          border: Border.all(color: accentColor, width: 3),
                        ),
                        child: CircleAvatar(
                          radius: 54,
                          backgroundColor: accentColor.withOpacity(0.08),
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
                                  style: TextStyle(
                                      fontSize: 38,
                                      color: accentColor,
                                      fontWeight: FontWeight.bold),
                                )
                              : null,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _pickProfileImage,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: accentColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: accentColor.withOpacity(0.25),
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.camera_alt,
                                color: Colors.white, size: 22),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                // Name
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    prefixIcon: Icon(Icons.person, color: accentColor),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
                    filled: true,
                    fillColor: Colors.white,
                    floatingLabelBehavior: FloatingLabelBehavior.auto,
                  ),
                ),
                const SizedBox(height: 18),
                // Username
                TextField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    prefixIcon: Icon(Icons.alternate_email, color: accentColor),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
                    filled: true,
                    fillColor: Colors.white,
                    floatingLabelBehavior: FloatingLabelBehavior.auto,
                  ),
                ),
                const SizedBox(height: 18),
                // Bio
                TextField(
                  controller: _bioController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Bio',
                    prefixIcon: Icon(Icons.info_outline, color: accentColor),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
                    filled: true,
                    fillColor: Colors.white,
                    floatingLabelBehavior: FloatingLabelBehavior.auto,
                  ),
                ),
                const SizedBox(height: 28),
                // Categories
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Skills & Categories',
                      style: TextStyle(
                          color: accentColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 15)),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: skillCategories.map((cat) {
                    return CategoryChip(
                      label: cat,
                      isSelected: _selectedCategories.contains(cat),
                      onTap: () {
                        setState(() {
                          if (_selectedCategories.contains(cat)) {
                            _selectedCategories.remove(cat);
                          } else {
                            _selectedCategories.add(cat);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 28),
                // Save Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18)),
                      elevation: 6,
                      shadowColor: accentColor.withOpacity(0.18),
                    ),
                    child: const Text('Save Changes',
                        style:
                            TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                  ),
                ),
              ],
            ),
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
