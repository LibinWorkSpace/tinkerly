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
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Icon(Icons.photo, color: Color(0xFF6C63FF)),
                title: Text('Pick Image', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () async {
                  final file = await picker.pickImage(source: ImageSource.gallery);
                  Navigator.pop(context, file);
                },
              ),
              ListTile(
                leading: Icon(Icons.videocam, color: Color(0xFF6C63FF)),
                title: Text('Pick Video', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () async {
                  final file = await picker.pickVideo(source: ImageSource.gallery);
                  Navigator.pop(context, file);
                },
              ),
            ],
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
        Icon(done ? Icons.check_circle : Icons.radio_button_unchecked, color: done ? Color(0xFF6C63FF) : Colors.grey, size: 20),
        SizedBox(width: 8),
        Text(text, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: done ? Color(0xFF6C63FF) : Colors.black87)),
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
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: AspectRatio(
                aspectRatio: _videoController!.value.aspectRatio,
                child: VideoPlayer(_videoController!),
              ),
            ),
            Positioned(
              bottom: 12,
              right: 12,
              child: FloatingActionButton(
                mini: true,
                backgroundColor: Colors.black54,
                onPressed: () {
                  setState(() {
                    if (_videoController!.value.isPlaying) {
                      _videoController!.pause();
                    } else {
                      _videoController!.play();
                    }
                  });
                },
                child: Icon(
                  _videoController!.value.isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      } else if (_videoController!.value.hasError) {
        return Container(
          height: 200,
          color: Colors.black12,
          child: const Center(child: Icon(Icons.videocam_off, size: 60, color: Colors.grey)),
        );
      } else {
        return Container(
          height: 200,
          color: Colors.black12,
          child: const Center(child: CircularProgressIndicator()),
        );
      }
    } else {
      return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Create Post', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF6C63FF),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Step 1: Media
                  _buildStepHeader('1. Select Image or Video', done: kIsWeb ? (_webImageBytes != null || _webVideoUrl != null) : (_mediaFile != null)),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _pickMedia,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(
                          color: (kIsWeb ? (_webImageBytes == null && _webVideoUrl == null) : _mediaFile == null) ? Colors.grey[300]! : Color(0xFF6C63FF),
                          width: 2,
                        ),
                      ),
                      child: _buildMediaPreview(),
                    ),
                  ),
                  const SizedBox(height: 28),
                  // Step 2: Category
                  _buildStepHeader('2. Choose Category', done: _selectedCategory != null),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedCategory,
                            hint: const Text('Select category'),
                            isExpanded: true,
                            items: _registeredCategories
                                .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
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
                        if (_selectedCategory != null && subCategorySuggestions[_selectedCategory!] != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 12.0),
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                ...subCategorySuggestions[_selectedCategory!]!.map((sub) => ChoiceChip(
                                      label: Text(sub),
                                      selected: _selectedSubCategory == sub,
                                      onSelected: (selected) {
                                        setState(() {
                                          _selectedSubCategory = selected ? sub : null;
                                          _customSubCategoryController.clear();
                                        });
                                      },
                                    )),
                                ChoiceChip(
                                  label: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Icon(Icons.add, size: 16),
                                      SizedBox(width: 4),
                                      Text('Custom'),
                                    ],
                                  ),
                                  selected: _selectedSubCategory == 'custom',
                                  onSelected: (selected) {
                                    setState(() {
                                      _selectedSubCategory = selected ? 'custom' : null;
                                      if (!selected) _customSubCategoryController.clear();
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        if (_selectedSubCategory == 'custom')
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: TextField(
                              controller: _customSubCategoryController,
                              decoration: const InputDecoration(
                                hintText: 'Enter custom subcategory',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  // Step 3: Description
                  _buildStepHeader('3. Add Description', done: _descController.text.isNotEmpty),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: TextField(
                      controller: _descController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'Describe your post... (max 300 chars)',
                        border: InputBorder.none,
                        counterText: '',
                      ),
                      maxLength: 300,
                      style: const TextStyle(fontSize: 15),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(height: 36),
                  // Post Button
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    child: ElevatedButton(
                      onPressed: ((kIsWeb && (_webImageBytes != null || _webVideoUrl != null)) || (!kIsWeb && _mediaFile != null)) && _selectedCategory != null && _descController.text.isNotEmpty && !_isLoading
                          ? _submitPost
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ((kIsWeb && (_webImageBytes != null || _webVideoUrl != null)) || (!kIsWeb && _mediaFile != null)) && _selectedCategory != null && _descController.text.isNotEmpty
                            ? const Color(0xFF6C63FF)
                            : Colors.grey[300],
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        elevation: 4,
                        shadowColor: const Color(0xFF6C63FF).withOpacity(0.2),
                      ),
                      child: const Text('Post', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, letterSpacing: 1)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (((kIsWeb && _webImageBytes == null && _webVideoUrl == null) || (!kIsWeb && _mediaFile == null)) || _selectedCategory == null || _descController.text.isEmpty)
                    const Text(
                      'Please complete all steps to enable posting.',
                      style: TextStyle(color: Colors.redAccent, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                ],
              ),
            ),
    );
  }
} 