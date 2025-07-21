import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/user_service.dart';
import '../../constants/categories.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:video_player/video_player.dart';
// Web video preview support
import 'package:universal_html/html.dart' as html;
import 'dart:async'; // Added for Completer
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class Url {
  static String createObjectUrlFromBlob(html.Blob blob) => html.Url.createObjectUrlFromBlob(blob);
}

class CreatePostScreen extends StatefulWidget {
  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  File? _mediaFile;
  Uint8List? _webImageBytes;
  String? _mediaType; // 'image' or 'video'
  String? _webVideoUrl; // For web video preview
  html.Blob? _webVideoBlob; // To release URL later
  final _descController = TextEditingController();
  String? _selectedCategory;
  String? _selectedSubCategory;
  final _customSubCategoryController = TextEditingController();
  bool _isLoading = false;
  List<String> _registeredCategories = [];
  VideoPlayerController? _videoController;

  @override
  void initState() {
    super.initState();
    _fetchRegisteredCategories();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    if (kIsWeb && _webVideoUrl != null) {
      html.Url.revokeObjectUrl(_webVideoUrl!);
    }
    _customSubCategoryController.dispose();
    super.dispose();
  }

  Future<void> _fetchRegisteredCategories() async {
    final profile = await UserService.fetchUserProfile();
    setState(() {
      _registeredCategories = List<String>.from(profile?["categories"] ?? []);
    });
  }

  Future<void> _pickMedia() async {
    final picker = ImagePicker();
    final picked = await showModalBottomSheet<XFile?>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF667EEA), // Purple-blue
              Color(0xFF764BA2), // Deep purple
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  'Select Media',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: ListTile(
                    leading: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF6C63FF), Color(0xFFFF6B9D)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.photo, color: Colors.white, size: 20),
                    ),
                    title: Text(
                      'Pick Image',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    subtitle: Text(
                      'Choose from gallery',
                      style: GoogleFonts.poppins(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                    onTap: () async {
                      final file = await picker.pickImage(source: ImageSource.gallery);
                      Navigator.pop(context, file);
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: ListTile(
                    leading: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF6C63FF), Color(0xFFFF6B9D)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.videocam, color: Colors.white, size: 20),
                    ),
                    title: Text(
                      'Pick Video',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    subtitle: Text(
                      'Choose from gallery',
                      style: GoogleFonts.poppins(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                    onTap: () async {
                      final file = await picker.pickVideo(source: ImageSource.gallery);
                      Navigator.pop(context, file);
                    },
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
    
    if (picked != null) {
      bool isVideo = false;
      if (kIsWeb) {
        final mimeType = picked.mimeType ?? '';
        isVideo = mimeType.startsWith('video/');
        debugPrint('Picked file: ${picked.path}, mimeType: $mimeType, isVideo: $isVideo');
        final bytes = await picked.readAsBytes();
        if (isVideo) {
          // For web video, create a blob URL
          final blob = html.Blob([bytes], 'video/mp4');
          final url = Url.createObjectUrlFromBlob(blob);
          setState(() {
            _webVideoUrl = url;
            _webVideoBlob = blob;
            _webImageBytes = null;
            _mediaFile = null;
            _mediaType = 'video';
          });
          debugPrint('Set _mediaType to video');
          _videoController?.dispose();
          _videoController = VideoPlayerController.network(_webVideoUrl!)
            ..initialize().then((_) {
              setState(() {});
              _videoController?.setLooping(true);
            }).catchError((e) {
              debugPrint('VideoPlayer initialization error: $e');
            });
        } else {
          setState(() {
            _webImageBytes = bytes;
            _webVideoUrl = null;
            _webVideoBlob = null;
            _mediaFile = null;
            _mediaType = 'image';
          });
          debugPrint('Set _mediaType to image');
        }
      } else {
        final path = picked.path.toLowerCase();
        isVideo = path.endsWith('.mp4') || path.endsWith('.mov') || path.endsWith('.webm');
        debugPrint('Picked file: ${picked.path}, isVideo: $isVideo');
        if (isVideo) {
          setState(() {
            _mediaFile = File(picked.path);
            _webImageBytes = null;
            _webVideoUrl = null;
            _webVideoBlob = null;
            _mediaType = 'video';
          });
          debugPrint('Set _mediaType to video');
          _videoController?.dispose();
          _videoController = VideoPlayerController.file(_mediaFile!)
            ..initialize().then((_) {
              setState(() {});
              _videoController?.setLooping(true);
            }).catchError((e) {
              debugPrint('VideoPlayer initialization error: $e');
            });
        } else {
          setState(() {
            _mediaFile = File(picked.path);
            _webImageBytes = null;
            _webVideoUrl = null;
            _webVideoBlob = null;
            _mediaType = 'image';
          });
          debugPrint('Set _mediaType to image');
        }
      }
    }
  }

  Future<void> _submitPost() async {
    if ((kIsWeb && _mediaType == 'image' && _webImageBytes == null) || (!kIsWeb && _mediaType == 'image' && _mediaFile == null) || _selectedCategory == null || _descController.text.isEmpty) return;
    setState(() { _isLoading = true; });
    try {
      String? url;
      if (kIsWeb && _mediaType == 'image' && _webImageBytes != null) {
        url = await UserService.uploadBytes(_webImageBytes!, 'post_image.jpg');
      } else if (!kIsWeb && _mediaType == 'image' && _mediaFile != null) {
        url = await UserService.uploadFile(_mediaFile!.path);
      } else if (kIsWeb && _mediaType == 'video' && _webVideoBlob != null) {
        // For web video, convert blob to bytes
        final reader = html.FileReader();
        final completer = Completer<Uint8List>();
        reader.readAsArrayBuffer(_webVideoBlob!);
        reader.onLoadEnd.listen((event) {
          completer.complete(reader.result as Uint8List);
        });
        final bytes = await completer.future;
        url = await UserService.uploadBytes(bytes, 'post_video.mp4');
      } else if (!kIsWeb && _mediaType == 'video' && _mediaFile != null) {
        url = await UserService.uploadFile(_mediaFile!.path);
      }
      if (url == null) throw Exception('Upload failed');
      final user = FirebaseAuth.instance.currentUser;
      final idToken = await user?.getIdToken();
      final userId = user?.uid;
      // Determine subcategory
      String? subCategory;
      if (_selectedSubCategory == 'custom') {
        subCategory = _customSubCategoryController.text.trim();
      } else {
        subCategory = _selectedSubCategory;
      }
      await UserService.createPost(
        url: url,
        description: _descController.text,
        category: _selectedCategory!,
        mediaType: _mediaType!,
        idToken: idToken,
        userId: userId,
        subCategory: subCategory,
      );
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to post: $e')));
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  Widget _buildStepHeader(String text, {bool done = false}) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(4),
          decoration: BoxDecoration(
            gradient: done
                ? LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFFFF6B9D)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                : null,
            color: done ? null : Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(
              color: done ? Colors.transparent : Colors.white.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Icon(
            done ? Icons.check : Icons.radio_button_unchecked,
            color: done ? Colors.white : Color(0xFF718096),
            size: 16,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Color(0xFF2D3748),
          ),
        ),
      ],
    );
  }

  Widget _buildMediaPreview() {
    if ((kIsWeb && _mediaType == 'image' && _webImageBytes != null)) {
      return Image.memory(_webImageBytes!, height: 200, width: double.infinity, fit: BoxFit.cover);
    } else if (!kIsWeb && _mediaType == 'image' && _mediaFile != null) {
      return Image.file(_mediaFile!, height: 200, width: double.infinity, fit: BoxFit.cover);
    } else if (_mediaType == 'video' && _videoController != null) {
      if (_videoController!.value.isInitialized) {
        return Stack(
          children: [
            AspectRatio(
              aspectRatio: _videoController!.value.aspectRatio,
              child: VideoPlayer(_videoController!),
            ),
            Positioned(
              bottom: 12,
              right: 12,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFFFF6B9D)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: () {
                    setState(() {
                      if (_videoController!.value.isPlaying) {
                        _videoController!.pause();
                      } else {
                        _videoController!.play();
                      }
                    });
                  },
                  icon: Icon(
                    _videoController!.value.isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        );
      } else if (_videoController!.value.hasError) {
        return Container(
          height: 200,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.videocam_off, size: 48, color: Colors.white.withOpacity(0.7)),
                const SizedBox(height: 8),
                Text(
                  'Video failed to load',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        return Container(
          height: 200,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
                const SizedBox(height: 16),
                Text(
                  'Loading video...',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } else {
      return const SizedBox.shrink();
    }
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
                      color: Colors.black.withOpacity(0.05),
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
                            color: primaryColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(Icons.add_photo_alternate, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Create Post',
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
                child: _isLoading
                    ? Center(
                        child: Container(
                          padding: EdgeInsets.all(24),
                          margin: EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6C63FF)),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Creating your post...',
                                style: GoogleFonts.poppins(
                                  color: Color(0xFF2D3748),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : SingleChildScrollView(
                        physics: BouncingScrollPhysics(),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Step 1: Media Selection
                            Container(
                              padding: EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    spreadRadius: 0,
                                    offset: Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildStepHeader(
                                    '1. Select Media',
                                    done: kIsWeb ? (_webImageBytes != null || _webVideoUrl != null) : (_mediaFile != null),
                                  ),
                                  const SizedBox(height: 16),
                                  GestureDetector(
                                    onTap: _pickMedia,
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 300),
                                      height: 200,
                                      decoration: BoxDecoration(
                                        color: Color(0xFFF7FAFC),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: (kIsWeb ? (_webImageBytes == null && _webVideoUrl == null) : _mediaFile == null) 
                                              ? Color(0xFFE2E8F0) 
                                              : primaryColor,
                                          width: 2,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: primaryColor.withOpacity(0.2),
                                            blurRadius: 15,
                                            spreadRadius: 0,
                                            offset: Offset(0, 8),
                                          ),
                                        ],
                                      ),
                                      child: (kIsWeb ? (_webImageBytes == null && _webVideoUrl == null) : _mediaFile == null)
                                          ? Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Container(
                                                  padding: EdgeInsets.all(16),
                                                  decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                      colors: [primaryColor, secondaryColor],
                                                      begin: Alignment.topLeft,
                                                      end: Alignment.bottomRight,
                                                    ),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: Icon(
                                                    Icons.add_photo_alternate,
                                                    color: Colors.white,
                                                    size: 32,
                                                  ),
                                                ),
                                                const SizedBox(height: 16),
                                                Text(
                                                  'Tap to select image or video',
                                                  style: GoogleFonts.poppins(
                                                    color: Colors.white.withOpacity(0.8),
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  'Share your creativity with the world',
                                                  style: GoogleFonts.poppins(
                                                    color: Colors.white.withOpacity(0.6),
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            )
                                          : ClipRRect(
                                              borderRadius: BorderRadius.circular(14),
                                              child: _buildMediaPreview(),
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            ).animate().fadeIn(duration: 400.ms, delay: 100.ms),
                            
                            const SizedBox(height: 24),
                            
                            // Step 2: Category Selection
                            Container(
                              padding: EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    spreadRadius: 0,
                                    offset: Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildStepHeader('2. Choose Category', done: _selectedCategory != null),
                                  const SizedBox(height: 16),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.2),
                                        width: 1,
                                      ),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: _selectedCategory,
                                        hint: Text(
                                          'Select category',
                                          style: GoogleFonts.poppins(
                                            color: Colors.black.withOpacity(0.7),
                                          ),
                                        ),
                                        isExpanded: true,
                                        dropdownColor: Color(0xFF764BA2),
                                        style: GoogleFonts.poppins(color: Colors.black),
                                        icon: Icon(Icons.keyboard_arrow_down, color: Colors.black),
                                        items: _registeredCategories
                                            .map((cat) => DropdownMenuItem(
                                                  value: cat,
                                                  child: Text(
                                                    cat,
                                                    style: GoogleFonts.poppins(color: Colors.black),
                                                  ),
                                                ))
                                            .toList(),
                                        onChanged: (val) {
                                          setState(() {
                                            _selectedCategory = val;
                                            _selectedSubCategory = null;
                                            _customSubCategoryController.clear();
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                  if (_selectedCategory != null && subCategorySuggestions[_selectedCategory!] != null) ...[
                                    const SizedBox(height: 16),
                                    Text(
                                      'Subcategories',
                                      style: GoogleFonts.poppins(
                                        color: Colors.black,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        ...subCategorySuggestions[_selectedCategory!]!.map((sub) => 
                                          GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                _selectedSubCategory = _selectedSubCategory == sub ? null : sub;
                                                _customSubCategoryController.clear();
                                              });
                                            },
                                            child: Container(
                                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                              decoration: BoxDecoration(
                                                gradient: _selectedSubCategory == sub
                                                    ? LinearGradient(
                                                        colors: [primaryColor, secondaryColor],
                                                        begin: Alignment.centerLeft,
                                                        end: Alignment.centerRight,
                                                      )
                                                    : null,
                                                color: _selectedSubCategory == sub 
                                                    ? null 
                                                    : Colors.white.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: _selectedSubCategory == sub 
                                                      ? Colors.transparent 
                                                      : Colors.white.withOpacity(0.3),
                                                  width: 1,
                                                ),
                                              ),
                                              child: Text(
                                                sub,
                                                style: GoogleFonts.poppins(
                                                  color: Colors.black,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _selectedSubCategory = _selectedSubCategory == 'custom' ? null : 'custom';
                                              if (_selectedSubCategory != 'custom') _customSubCategoryController.clear();
                                            });
                                          },
                                          child: Container(
                                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            decoration: BoxDecoration(
                                              gradient: _selectedSubCategory == 'custom'
                                                  ? LinearGradient(
                                                      colors: [primaryColor, secondaryColor],
                                                      begin: Alignment.centerLeft,
                                                      end: Alignment.centerRight,
                                                    )
                                                  : null,
                                              color: _selectedSubCategory == 'custom' 
                                                  ? null 
                                                  : Colors.white.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: _selectedSubCategory == 'custom' 
                                                    ? Colors.transparent 
                                                    : Colors.white.withOpacity(0.3),
                                                width: 1,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.add, size: 14, color: Colors.black),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'Custom',
                                                  style: GoogleFonts.poppins(
                                                    color: Colors.black,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                  if (_selectedSubCategory == 'custom') ...[
                                    const SizedBox(height: 12),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.2),
                                          width: 1,
                                        ),
                                      ),
                                      child: TextField(
                                        controller: _customSubCategoryController,
                                        style: GoogleFonts.poppins(color: Colors.black),
                                        decoration: InputDecoration(
                                          hintText: 'Enter custom subcategory',
                                          hintStyle: GoogleFonts.poppins(
                                            color: Colors.black.withOpacity(0.7),
                                          ),
                                          border: InputBorder.none,
                                          contentPadding: EdgeInsets.all(16),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
                            
                            const SizedBox(height: 24),
                            
                            // Step 3: Description
                            Container(
                              padding: EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    spreadRadius: 0,
                                    offset: Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildStepHeader('3. Add Description', done: _descController.text.isNotEmpty),
                                  const SizedBox(height: 16),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.2),
                                        width: 1,
                                      ),
                                    ),
                                    child: TextField(
                                      controller: _descController,
                                      maxLines: 4,
                                      style: GoogleFonts.poppins(
                                        color: Colors.black,
                                        fontSize: 15,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: 'Describe your post... (max 300 chars)',
                                        hintStyle: GoogleFonts.poppins(
                                          color: Colors.black.withOpacity(0.7),
                                        ),
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.all(16),
                                        counterText: '',
                                      ),
                                      maxLength: 300,
                                      onChanged: (_) => setState(() {}),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${_descController.text.length}/300 characters',
                                    style: GoogleFonts.poppins(
                                      color: Colors.black.withOpacity(0.6),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ).animate().fadeIn(duration: 400.ms, delay: 300.ms),
                            
                            const SizedBox(height: 32),
                            
                            // Post Button
                            Container(
                              width: double.infinity,
                              height: 56,
                              decoration: BoxDecoration(
                                gradient: ((kIsWeb && (_webImageBytes != null || _webVideoUrl != null)) || (!kIsWeb && _mediaFile != null)) && _selectedCategory != null && _descController.text.isNotEmpty
                                    ? LinearGradient(
                                        colors: [primaryColor, secondaryColor],
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                      )
                                    : null,
                                color: ((kIsWeb && (_webImageBytes != null || _webVideoUrl != null)) || (!kIsWeb && _mediaFile != null)) && _selectedCategory != null && _descController.text.isNotEmpty
                                    ? null
                                    : Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: ((kIsWeb && (_webImageBytes != null || _webVideoUrl != null)) || (!kIsWeb && _mediaFile != null)) && _selectedCategory != null && _descController.text.isNotEmpty
                                    ? [
                                        BoxShadow(
                                          color: primaryColor.withOpacity(0.4),
                                          blurRadius: 20,
                                          spreadRadius: 0,
                                          offset: Offset(0, 10),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: ElevatedButton(
                                onPressed: ((kIsWeb && (_webImageBytes != null || _webVideoUrl != null)) || (!kIsWeb && _mediaFile != null)) && _selectedCategory != null && _descController.text.isNotEmpty && !_isLoading
                                    ? _submitPost
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.publish, size: 24),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Share Post',
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ).animate().fadeIn(duration: 400.ms, delay: 400.ms),
                            
                            const SizedBox(height: 16),
                            
                            if (((kIsWeb && _webImageBytes == null && _webVideoUrl == null) || (!kIsWeb && _mediaFile == null)) || _selectedCategory == null || _descController.text.isEmpty)
                              Container(
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.orange.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.info_outline, color: Colors.orange, size: 20),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Please complete all steps to enable posting.',
                                        style: GoogleFonts.poppins(
                                          color: Colors.orange,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ).animate().fadeIn(duration: 400.ms, delay: 500.ms),
                            
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 