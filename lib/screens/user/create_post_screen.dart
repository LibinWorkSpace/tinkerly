import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
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
import '../../services/portfolio_service.dart';
import '../../models/portfolio_model.dart';
import 'package:tinkerly/constants/api_constants.dart';

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
  String? _mediaType; // 'image', 'video', or 'audio'
  String? _webVideoUrl; // For web video preview
  html.Blob? _webVideoBlob; // To release URL later
  String? _webAudioUrl; // For web audio preview
  html.Blob? _webAudioBlob; // To release URL later
  String? _audioFileName; // Store audio file name
  final _descController = TextEditingController();
  String? _selectedCategory;
  String? _selectedSubCategory;
  final _customSubCategoryController = TextEditingController();
  bool _isLoading = false;
  List<String> _registeredCategories = [];
  VideoPlayerController? _videoController;
  // AudioPlayer? _audioPlayer; // Will add when package is installed
  List<Portfolio> _userPortfolios = [];
  Portfolio? _selectedPortfolio;

  @override
  void initState() {
    super.initState();
    _fetchRegisteredCategories();
    _fetchUserPortfolios();
    _ensurePortfoliosExist();
  }

  Future<void> _refreshData() async {
    await _fetchRegisteredCategories();
    await _fetchUserPortfolios();
    await _ensurePortfoliosExist();
  }

  // Method to ensure portfolios exist for all user categories
  Future<void> _ensurePortfoliosExist() async {
    try {
      final profile = await UserService.fetchUserProfile();
      final userId = profile?["uid"];
      final userCategories = List<String>.from(profile?["categories"] ?? []);
      
      if (userId != null && userCategories.isNotEmpty) {
        final existingPortfolios = await PortfolioService.fetchUserPortfolios(userId);
        final existingCategories = existingPortfolios.map((p) => p.category).toSet();
        final missingCategories = userCategories.where((cat) => !existingCategories.contains(cat));
        
        print('User categories: $userCategories');
        print('Existing portfolio categories: $existingCategories');
        print('Missing categories: $missingCategories');
        
        for (final cat in missingCategories) {
          try {
            await PortfolioService.createPortfolio({
              'userId': userId,
              'profilename': cat,
              'category': cat,
              'description': '',
              'profileImageUrl': null,
            });
            print('Created portfolio for category: $cat');
          } catch (e) {
            print('Failed to create portfolio for category $cat: $e');
          }
        }
        
        // Refresh portfolios after creating missing ones
        if (missingCategories.isNotEmpty) {
          await Future.delayed(Duration(milliseconds: 300));
          await _fetchUserPortfolios();
        }
      }
    } catch (e) {
      print('Error ensuring portfolios exist: $e');
    }
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

  Future<void> _fetchUserPortfolios() async {
    try {
      final profile = await UserService.fetchUserProfile();
      final userId = profile?["uid"]; // Use uid directly since that's what the backend returns
      print('Fetching portfolios for userId: $userId'); // Debug log
      
      if (userId != null) {
        final portfolios = await PortfolioService.fetchUserPortfolios(userId);
        print('Fetched ${portfolios.length} portfolios'); // Debug log
        setState(() {
          _userPortfolios = portfolios;
        });
      } else {
        print('No userId found in profile'); // Debug log
      }
    } catch (e) {
      print('Error fetching user portfolios: $e'); // Debug log
    }
  }

  bool _isFileSizeValid(int fileSizeBytes) {
    const maxSizeBytes = 100 * 1024 * 1024; // 100MB
    return fileSizeBytes <= maxSizeBytes;
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  void _showFileSizeError(int fileSizeBytes) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'File too large (${_formatFileSize(fileSizeBytes)}). Maximum size is 100MB.',
        ),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 4),
      ),
    );
  }

  Future<void> _pickMedia() async {
    final picker = ImagePicker();
    final picked = await showModalBottomSheet<dynamic>(
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
                      child: Icon(Icons.music_note, color: Colors.white, size: 20),
                    ),
                    title: Text(
                      'Pick Music',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    subtitle: Text(
                      'Choose audio file',
                      style: GoogleFonts.poppins(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                    onTap: () async {
                      final result = await FilePicker.platform.pickFiles(
                        type: FileType.audio,
                        allowMultiple: false,
                      );
                      Navigator.pop(context, result);
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

    if (picked != null && picked is XFile) {
      // Handle XFile (image/video)
      bool isVideo = false;
      if (kIsWeb) {
        final mimeType = picked.mimeType ?? '';
        isVideo = mimeType.startsWith('video/');
        debugPrint('Picked file: ${picked.path}, mimeType: $mimeType, isVideo: $isVideo');
        final bytes = await picked.readAsBytes();

        // Check file size
        if (!_isFileSizeValid(bytes.length)) {
          _showFileSizeError(bytes.length);
          return;
        }
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

        // Check file size for non-web platforms
        final file = File(picked.path);
        final fileSize = await file.length();
        if (!_isFileSizeValid(fileSize)) {
          _showFileSizeError(fileSize);
          return;
        }
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
    } else if (picked is FilePickerResult) {
      // Handle audio file selection
      final file = picked.files.first;
      if (file.bytes != null || file.path != null) {
        // Check file size for audio files
        int fileSize = 0;
        if (kIsWeb && file.bytes != null) {
          fileSize = file.bytes!.length;
        } else if (!kIsWeb && file.path != null) {
          final audioFile = File(file.path!);
          fileSize = await audioFile.length();
        }

        if (fileSize > 0 && !_isFileSizeValid(fileSize)) {
          _showFileSizeError(fileSize);
          return;
        }
        setState(() {
          _audioFileName = file.name;
          _mediaType = 'audio';
          _webImageBytes = null;
          _webVideoUrl = null;
          _webVideoBlob = null;
          _mediaFile = null;
        });

        if (kIsWeb && file.bytes != null) {
          // For web, create blob URL for audio preview
          final extension = file.extension?.toLowerCase() ?? 'mp3';
          final mimeType = extension == 'mp3' ? 'audio/mp3' :
                          extension == 'wav' ? 'audio/wav' :
                          extension == 'aac' ? 'audio/aac' :
                          extension == 'ogg' ? 'audio/ogg' : 'audio/mp3';
          final blob = html.Blob([file.bytes!], mimeType);
          final url = Url.createObjectUrlFromBlob(blob);
          setState(() {
            _webAudioUrl = url;
            _webAudioBlob = blob;
          });
        } else if (!kIsWeb && file.path != null) {
          // For mobile, store the file
          setState(() {
            _mediaFile = File(file.path!);
          });
        }

        debugPrint('Audio file selected: ${file.name}, size: ${file.size}');
      }
    }
  }

  Future<void> _submitPost() async {
    if (_mediaType == null || _selectedPortfolio == null || _descController.text.isEmpty) return;

    // Check if media is properly selected based on type
    bool hasValidMedia = false;
    if (_mediaType == 'image') {
      hasValidMedia = (kIsWeb && _webImageBytes != null) || (!kIsWeb && _mediaFile != null);
    } else if (_mediaType == 'video') {
      hasValidMedia = (kIsWeb && _webVideoBlob != null) || (!kIsWeb && _mediaFile != null);
    } else if (_mediaType == 'audio') {
      hasValidMedia = (kIsWeb && _webAudioBlob != null) || (!kIsWeb && _mediaFile != null);
    }

    if (!hasValidMedia) return;

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
      } else if (kIsWeb && _mediaType == 'audio' && _webAudioBlob != null) {
        // For web audio, convert blob to bytes
        final reader = html.FileReader();
        final completer = Completer<Uint8List>();
        reader.readAsArrayBuffer(_webAudioBlob!);
        reader.onLoadEnd.listen((event) {
          completer.complete(reader.result as Uint8List);
        });
        final bytes = await completer.future;
        url = await UserService.uploadBytes(bytes, _audioFileName ?? 'post_audio.mp3');
      } else if (!kIsWeb && _mediaType == 'audio' && _mediaFile != null) {
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
        category: _selectedPortfolio!.category,
        mediaType: _mediaType!,
        idToken: idToken,
        userId: userId,
        subCategory: subCategory,
        portfolioId: _selectedPortfolio!.id,
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
    } else if (_mediaType == 'audio') {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6C63FF).withOpacity(0.8), Color(0xFFFF6B9D).withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.music_note,
                size: 48,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _audioFileName ?? 'Audio File',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Audio ready for upload',
              style: GoogleFonts.poppins(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),
            // Simple audio controls placeholder
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: () {
                      // TODO: Implement audio preview playback when audioplayers package is installed
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Audio preview will be available after installing audio player')),
                      );
                    },
                    icon: Icon(Icons.play_arrow, color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
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
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Step 1: Media Selection
                            Container(
                              padding: EdgeInsets.all(16),
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
                                    done: kIsWeb ? (_webImageBytes != null || _webVideoUrl != null || _webAudioUrl != null) : (_mediaFile != null),
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
                                          color: (kIsWeb ? (_webImageBytes == null && _webVideoUrl == null && _webAudioUrl == null) : _mediaFile == null)
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
                                      child: (kIsWeb ? (_webImageBytes == null && _webVideoUrl == null && _webAudioUrl == null) : _mediaFile == null)
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
                                                  'Tap to select image, video, or music',
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
                            
                            const SizedBox(height: 20),

                            // Step 2: Portfolio Selection
                            Container(
                              padding: EdgeInsets.all(16),
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
                                  _buildStepHeader('2. Choose Category', done: _selectedPortfolio != null),
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
                                      child: DropdownButton<Portfolio>(
                                        value: _selectedPortfolio,
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
                                        items: _userPortfolios.isEmpty
                                            ? [
                                                DropdownMenuItem(
                                                  value: null,
                                                  child: Text(
                                                    'No categories available',
                                                    style: GoogleFonts.poppins(color: Colors.grey),
                                                  ),
                                                )
                                              ]
                                            : _userPortfolios
                                                .map((portfolio) => DropdownMenuItem(
                                                      value: portfolio,
                                                      child: Text(
                                                        portfolio.category, // Changed from portfolio.profilename to portfolio.category
                                                        style: GoogleFonts.poppins(color: Colors.black),
                                                      ),
                                                    ))
                                                .toList(),
                                        onChanged: (val) {
                                          setState(() {
                                            _selectedPortfolio = val;
                                            _selectedCategory = val?.category;
                                            _selectedSubCategory = null;
                                            _customSubCategoryController.clear();
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                  if (_userPortfolios.isEmpty) ...[
                                    const SizedBox(height: 16),
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
                                      child: Column(
                                        children: [
                                          Row(
                                            children: [
                                              Icon(Icons.info_outline, color: Colors.orange, size: 20),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  'No categories found',
                                                  style: GoogleFonts.poppins(
                                                    color: Colors.orange[800],
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Add categories to your profile first, then refresh this page to see them here.',
                                            style: GoogleFonts.poppins(
                                              color: Colors.orange[700],
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          ElevatedButton.icon(
                                            onPressed: _refreshData,
                                            icon: Icon(Icons.refresh, size: 16),
                                            label: Text('Refresh'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.orange,
                                              foregroundColor: Colors.white,
                                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                              textStyle: GoogleFonts.poppins(fontSize: 12),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ).animate().fadeIn(duration: 400.ms, delay: 150.ms),
                            
                            const SizedBox(height: 20),

                            // Step 3: Description
                            Container(
                              padding: EdgeInsets.all(16),
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
                                gradient: ((kIsWeb && (_webImageBytes != null || _webVideoUrl != null)) || (!kIsWeb && _mediaFile != null)) && _selectedPortfolio != null && _descController.text.isNotEmpty
                                    ? LinearGradient(
                                        colors: [primaryColor, secondaryColor],
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                      )
                                    : null,
                                color: ((kIsWeb && (_webImageBytes != null || _webVideoUrl != null)) || (!kIsWeb && _mediaFile != null)) && _selectedPortfolio != null && _descController.text.isNotEmpty
                                    ? null
                                    : Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: ((kIsWeb && (_webImageBytes != null || _webVideoUrl != null || _webAudioUrl != null)) || (!kIsWeb && _mediaFile != null)) && _selectedPortfolio != null && _descController.text.isNotEmpty
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
                                onPressed: ((kIsWeb && (_webImageBytes != null || _webVideoUrl != null || _webAudioUrl != null)) || (!kIsWeb && _mediaFile != null)) && _selectedPortfolio != null && _descController.text.isNotEmpty && !_isLoading
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
                            
                            if (((kIsWeb && _webImageBytes == null && _webVideoUrl == null && _webAudioUrl == null) || (!kIsWeb && _mediaFile == null)) || _selectedPortfolio == null || _descController.text.isEmpty)
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
                            
                            const SizedBox(height: 16),
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