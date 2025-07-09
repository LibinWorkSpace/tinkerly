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
    final accentColor = const Color(0xFF6C63FF);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: accentColor),
        title: Text('Edit Profile',
            style: TextStyle(
                color: accentColor, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          children: [
            // Profile Image
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: accentColor.withOpacity(0.1),
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
                                fontSize: 36,
                                color: accentColor,
                                fontWeight: FontWeight.bold),
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _pickProfileImage,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: accentColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt,
                            color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Name
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Name',
                prefixIcon: Icon(Icons.person, color: accentColor),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
            const SizedBox(height: 16),
            // Username
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: 'Username',
                prefixIcon:
                    Icon(Icons.alternate_email, color: accentColor),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
            const SizedBox(height: 16),
            // Bio
            TextField(
              controller: _bioController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Bio',
                prefixIcon: Icon(Icons.info_outline, color: accentColor),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
            const SizedBox(height: 32),
            // Categories
            Wrap(
              spacing: 8,
              runSpacing: 8,
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
            const SizedBox(height: 16),
            // Save Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text('Save Changes',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
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
