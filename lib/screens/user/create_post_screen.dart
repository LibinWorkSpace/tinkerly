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

        // Validate media type against category
        final mediaType = isVideo ? 'video' : 'image';
        if (!_getAllowedMediaTypes().contains(mediaType)) {
          _showMediaTypeError(mediaType);
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

        // Validate media type against category
        final mediaType = isVideo ? 'video' : 'image';
        if (!_getAllowedMediaTypes().contains(mediaType)) {
          _showMediaTypeError(mediaType);
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

        // Validate media type against category
        if (!_getAllowedMediaTypes().contains('audio')) {
          _showMediaTypeError('audio');
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

  Widget _buildModernStepHeader(String stepNumber, String title, String subtitle, Color color, {bool done = false}) {
    return Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            gradient: done 
                ? LinearGradient(
                    colors: [color, color.withOpacity(0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : LinearGradient(
                    colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: done ? color : color.withOpacity(0.3),
              width: 2,
            ),
            boxShadow: done ? [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
            ] : null,
          ),
          child: Center(
            child: done
                ? Icon(Icons.check_rounded, color: Colors.white, size: 24)
                : Text(
                    stepNumber,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: done ? color : Color(0xFF1A202C),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Color(0xFF718096),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'digital art':
        return Icons.palette_rounded;
      case 'music & audio':
      case 'music and audio':
        return Icons.music_note_rounded;
      case 'tech & programming':
      case 'tech and programming':
        return Icons.code_rounded;
      case 'photography':
        return Icons.camera_alt_rounded;
      case 'video & animation':
      case 'video and animation':
        return Icons.videocam_rounded;
      case 'writing & literature':
      case 'writing and literature':
        return Icons.edit_rounded;
      case 'design & ui/ux':
      case 'design and ui/ux':
        return Icons.design_services_rounded;
      case 'gaming':
        return Icons.sports_esports_rounded;
      case 'crafts & diy':
      case 'crafts and diy':
        return Icons.handyman_rounded;
      case 'business & entrepreneurship':
      case 'business and entrepreneurship':
        return Icons.business_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  // Media type validation system
  Map<String, List<String>> get _categoryMediaTypes => {
    'Digital Art': ['image'],
    'Music & Audio': ['audio'],
    'Music and Audio': ['audio'],
    'Tech & Programming': ['image', 'video'],
    'Tech and Programming': ['image', 'video'],
    'Photography': ['image'],
    'Video & Animation': ['video'],
    'Video and Animation': ['video'],
    'Writing & Literature': ['image'],
    'Writing and Literature': ['image'],
    'Design & UI/UX': ['image', 'video'],
    'Design and UI/UX': ['image', 'video'],
    'Gaming': ['image', 'video'],
    'Crafts & DIY': ['image', 'video'],
    'Crafts and DIY': ['image', 'video'],
    'Business & Entrepreneurship': ['image', 'video'],
    'Business and Entrepreneurship': ['image', 'video'],
  };

  List<String> _getAllowedMediaTypes() {
    if (_selectedCategory == null) return ['image', 'video', 'audio'];
    return _categoryMediaTypes[_selectedCategory] ?? ['image', 'video', 'audio'];
  }

  bool _isMediaTypeAllowed() {
    if (_selectedCategory == null || _mediaType == null) return true;
    return _getAllowedMediaTypes().contains(_mediaType);
  }

  String _getMediaTypeDescription() {
    final allowedTypes = _getAllowedMediaTypes();
    if (allowedTypes.length == 3) return 'Images, Videos, and Audio';
    if (allowedTypes.length == 2) {
      if (allowedTypes.contains('image') && allowedTypes.contains('video')) {
        return 'Images and Videos only';
      } else if (allowedTypes.contains('image') && allowedTypes.contains('audio')) {
        return 'Images and Audio only';
      } else if (allowedTypes.contains('video') && allowedTypes.contains('audio')) {
        return 'Videos and Audio only';
      }
    }
    if (allowedTypes.contains('image')) return 'Images only';
    if (allowedTypes.contains('video')) return 'Videos only';
    if (allowedTypes.contains('audio')) return 'Audio only';
    return 'No media allowed';
  }

  void _showMediaTypeError(String attemptedType) {
    final allowedTypes = _getMediaTypeDescription();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Invalid media type for $_selectedCategory',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text('You tried to upload: ${attemptedType.toUpperCase()}'),
            Text('Allowed for this category: $allowedTypes'),
          ],
        ),
        backgroundColor: Colors.orange[700],
        duration: Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildSubcategoryChips() {
    if (_selectedCategory == null) return Container();
    
    final subcategories = subCategorySuggestions[_selectedCategory] ?? [];
    final allSubcategories = [...subcategories, 'custom'];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Available subcategories for $_selectedCategory:',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Color(0xFF718096),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: allSubcategories.map((subcategory) {
            final isSelected = _selectedSubCategory == subcategory;
            final isCustom = subcategory == 'custom';
            
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedSubCategory = subcategory;
                  if (subcategory != 'custom') {
                    _customSubCategoryController.clear();
                  }
                });
              },
              child: AnimatedContainer(
                duration: Duration(milliseconds: 300),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          colors: isCustom 
                              ? [Color(0xFF4ECDC4), Color(0xFF6C63FF)]
                              : [Color(0xFF4ECDC4), Color(0xFF44A08D)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        )
                      : LinearGradient(
                          colors: [
                            Color(0xFF4ECDC4).withOpacity(0.1),
                            Color(0xFF6C63FF).withOpacity(0.05),
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected 
                        ? Colors.transparent 
                        : Color(0xFF4ECDC4).withOpacity(0.3),
                    width: 1.5,
                  ),
                  boxShadow: isSelected ? [
                    BoxShadow(
                      color: Color(0xFF4ECDC4).withOpacity(0.4),
                      blurRadius: 12,
                      offset: Offset(0, 6),
                    ),
                  ] : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isCustom) ...[
                      Icon(
                        Icons.add_circle_outline_rounded,
                        color: isSelected ? Colors.white : Color(0xFF4ECDC4),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      isCustom ? 'Custom' : subcategory,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : Color(0xFF1A202C),
                      ),
                    ),
                    if (isSelected && !isCustom) ...[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.check_circle_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  List<DropdownMenuItem<String>> _getSubcategoryItems() {
    if (_selectedCategory == null) return [];
    
    final subcategories = subCategorySuggestions[_selectedCategory] ?? [];
    final items = subcategories.map((subcategory) => 
      DropdownMenuItem<String>(
        value: subcategory,
        child: Text(
          subcategory,
          style: GoogleFonts.poppins(color: Colors.black),
        ),
      ),
    ).toList();
    
    // Add custom option
    items.add(
      DropdownMenuItem<String>(
        value: 'custom',
        child: Text(
          'Custom (Enter your own)',
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
    
    return items;
  }

  bool _isSubcategoryValid() {
    if (_selectedCategory == null) return false;
    if (_selectedSubCategory == null) return false;
    if (_selectedSubCategory == 'custom') {
      return _customSubCategoryController.text.trim().isNotEmpty;
    }
    return true;
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
    final accentColor = Color(0xFF4ECDC4);
    final backgroundColor = Color(0xFFF8FAFF);
    
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              backgroundColor,
              Color(0xFFF0F4FF),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Modern App Bar with Glassmorphism Effect
              Container(
                margin: EdgeInsets.all(16),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.1),
                      blurRadius: 20,
                      spreadRadius: 0,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [primaryColor.withOpacity(0.1), accentColor.withOpacity(0.1)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: primaryColor.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: IconButton(
                        icon: Icon(Icons.arrow_back_ios_new, color: primaryColor, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [primaryColor, secondaryColor],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.4),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(Icons.create_rounded, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Create Post',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A202C),
                            ),
                          ),
                          Text(
                            'Share your creativity',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Color(0xFF718096),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().slideY(begin: -0.3, duration: 600.ms).fadeIn(),
              
              // Main Content
              Expanded(
                child: _isLoading
                    ? Center(
                        child: Container(
                          padding: EdgeInsets.all(32),
                          margin: EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.95),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withOpacity(0.1),
                                blurRadius: 30,
                                spreadRadius: 0,
                                offset: Offset(0, 15),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [primaryColor, secondaryColor],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    strokeWidth: 3,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'Creating your post...',
                                style: GoogleFonts.poppins(
                                  color: Color(0xFF1A202C),
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Please wait while we process your content',
                                style: GoogleFonts.poppins(
                                  color: Color(0xFF718096),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : SingleChildScrollView(
                        physics: BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Step 1: Media Selection - Modern Card Design
                            Container(
                              margin: EdgeInsets.only(bottom: 20),
                              padding: EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.95),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryColor.withOpacity(0.08),
                                    blurRadius: 25,
                                    spreadRadius: 0,
                                    offset: Offset(0, 12),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildModernStepHeader(
                                    '1',
                                    'Select Media',
                                    'Choose your creative content',
                                    primaryColor,
                                    done: kIsWeb ? (_webImageBytes != null || _webVideoUrl != null || _webAudioUrl != null) : (_mediaFile != null),
                                  ),
                                  const SizedBox(height: 20),
                                  GestureDetector(
                                    onTap: _pickMedia,
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 400),
                                      height: 220,
                                      decoration: BoxDecoration(
                                        gradient: (kIsWeb ? (_webImageBytes == null && _webVideoUrl == null && _webAudioUrl == null) : _mediaFile == null)
                                            ? LinearGradient(
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                                colors: [
                                                  primaryColor.withOpacity(0.1),
                                                  accentColor.withOpacity(0.1),
                                                ],
                                              )
                                            : null,
                                        color: (kIsWeb ? (_webImageBytes != null || _webVideoUrl != null || _webAudioUrl != null) : _mediaFile != null)
                                            ? Colors.grey[50]
                                            : null,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: (kIsWeb ? (_webImageBytes == null && _webVideoUrl == null && _webAudioUrl == null) : _mediaFile == null)
                                              ? primaryColor.withOpacity(0.3)
                                              : primaryColor.withOpacity(0.6),
                                          width: 2,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: primaryColor.withOpacity(0.15),
                                            blurRadius: 20,
                                            spreadRadius: 0,
                                            offset: Offset(0, 10),
                                          ),
                                        ],
                                      ),
                                      child: (kIsWeb ? (_webImageBytes == null && _webVideoUrl == null && _webAudioUrl == null) : _mediaFile == null)
                                          ? Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Container(
                                                  width: 80,
                                                  height: 80,
                                                  decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                      colors: [primaryColor, secondaryColor],
                                                      begin: Alignment.topLeft,
                                                      end: Alignment.bottomRight,
                                                    ),
                                                    borderRadius: BorderRadius.circular(24),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: primaryColor.withOpacity(0.4),
                                                        blurRadius: 15,
                                                        offset: Offset(0, 8),
                                                      ),
                                                    ],
                                                  ),
                                                  child: Icon(
                                                    Icons.add_photo_alternate_rounded,
                                                    color: Colors.white,
                                                    size: 36,
                                                  ),
                                                ),
                                                const SizedBox(height: 20),
                                                Text(
                                                  'Tap to select media',
                                                  style: GoogleFonts.poppins(
                                                    color: Color(0xFF1A202C),
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  'Image, Video, or Audio',
                                                  style: GoogleFonts.poppins(
                                                    color: Color(0xFF718096),
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                const SizedBox(height: 12),
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Container(
                                                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                      decoration: BoxDecoration(
                                                        color: accentColor.withOpacity(0.1),
                                                        borderRadius: BorderRadius.circular(16),
                                                        border: Border.all(
                                                          color: accentColor.withOpacity(0.3),
                                                          width: 1,
                                                        ),
                                                      ),
                                                      child: Text(
                                                        'Max 100MB',
                                                        style: GoogleFonts.poppins(
                                                          color: accentColor,
                                                          fontSize: 11,
                                                          fontWeight: FontWeight.w600,
                                                        ),
                                                      ),
                                                    ),
                                                    if (_selectedCategory != null) ...[
                                                      const SizedBox(width: 8),
                                                      Container(
                                                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                        decoration: BoxDecoration(
                                                          color: primaryColor.withOpacity(0.1),
                                                          borderRadius: BorderRadius.circular(16),
                                                          border: Border.all(
                                                            color: primaryColor.withOpacity(0.3),
                                                            width: 1,
                                                          ),
                                                        ),
                                                        child: Text(
                                                          _getMediaTypeDescription(),
                                                          style: GoogleFonts.poppins(
                                                            color: primaryColor,
                                                            fontSize: 11,
                                                            fontWeight: FontWeight.w600,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ],
                                            )
                                          : ClipRRect(
                                              borderRadius: BorderRadius.circular(18),
                                              child: _buildMediaPreview(),
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            ).animate().slideX(begin: -0.3, duration: 600.ms, delay: 100.ms).fadeIn(),
                            
                            const SizedBox(height: 20),

                            // Step 2: Category Selection - Modern Interactive Design
                            Container(
                              margin: EdgeInsets.only(bottom: 20),
                              padding: EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.95),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: secondaryColor.withOpacity(0.08),
                                    blurRadius: 25,
                                    spreadRadius: 0,
                                    offset: Offset(0, 12),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildModernStepHeader(
                                    '2',
                                    'Choose Category',
                                    'Select your creative field',
                                    secondaryColor,
                                    done: _selectedPortfolio != null,
                                  ),
                                  const SizedBox(height: 20),
                                  if (_userPortfolios.isNotEmpty) ...[
                                    // Modern Category Grid
                                    GridView.builder(
                                      shrinkWrap: true,
                                      physics: NeverScrollableScrollPhysics(),
                                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 1,
                                        crossAxisSpacing: 12,
                                        mainAxisSpacing: 12,
                                        childAspectRatio: 4.5,
                                      ),
                                      itemCount: _userPortfolios.length,
                                      itemBuilder: (context, index) {
                                        final portfolio = _userPortfolios[index];
                                        final isSelected = _selectedPortfolio?.id == portfolio.id;
                                        
                                        return GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _selectedPortfolio = portfolio;
                                              _selectedCategory = portfolio.category;
                                              _selectedSubCategory = null;
                                              _customSubCategoryController.clear();
                                              
                                              // Check if current media is still valid for new category
                                              if (_mediaType != null && !_isMediaTypeAllowed()) {
                                                // Clear invalid media
                                                _mediaFile = null;
                                                _webImageBytes = null;
                                                _webVideoUrl = null;
                                                _webAudioUrl = null;
                                                _audioFileName = null;
                                                _mediaType = null;
                                                
                                                // Show warning
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      'Previous media cleared - not allowed for ${portfolio.category}',
                                                    ),
                                                    backgroundColor: Colors.orange,
                                                    duration: Duration(seconds: 3),
                                                  ),
                                                );
                                              }
                                            });
                                          },
                                          child: AnimatedContainer(
                                            duration: Duration(milliseconds: 300),
                                            padding: EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              gradient: isSelected
                                                  ? LinearGradient(
                                                      colors: [secondaryColor, primaryColor],
                                                      begin: Alignment.topLeft,
                                                      end: Alignment.bottomRight,
                                                    )
                                                  : LinearGradient(
                                                      colors: [
                                                        secondaryColor.withOpacity(0.1),
                                                        primaryColor.withOpacity(0.05),
                                                      ],
                                                      begin: Alignment.topLeft,
                                                      end: Alignment.bottomRight,
                                                    ),
                                              borderRadius: BorderRadius.circular(16),
                                              border: Border.all(
                                                color: isSelected 
                                                    ? Colors.transparent 
                                                    : secondaryColor.withOpacity(0.3),
                                                width: 2,
                                              ),
                                              boxShadow: isSelected ? [
                                                BoxShadow(
                                                  color: secondaryColor.withOpacity(0.4),
                                                  blurRadius: 15,
                                                  offset: Offset(0, 8),
                                                ),
                                              ] : null,
                                            ),
                                            child: Row(
                                              children: [
                                                Container(
                                                  width: 32,
                                                  height: 32,
                                                  decoration: BoxDecoration(
                                                    color: isSelected 
                                                        ? Colors.white.withOpacity(0.2)
                                                        : secondaryColor.withOpacity(0.2),
                                                    borderRadius: BorderRadius.circular(10),
                                                  ),
                                                  child: Icon(
                                                    _getCategoryIcon(portfolio.category),
                                                    color: isSelected ? Colors.white : secondaryColor,
                                                    size: 18,
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Text(
                                                    portfolio.category,
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.w600,
                                                      color: isSelected ? Colors.white : Color(0xFF1A202C),
                                                    ),
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                if (isSelected)
                                                  Icon(
                                                    Icons.check_circle_rounded,
                                                    color: Colors.white,
                                                    size: 20,
                                                  ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ] else ...[
                                    // No categories available
                                    Container(
                                      padding: EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.orange.withOpacity(0.1),
                                            Colors.red.withOpacity(0.05),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: Colors.orange.withOpacity(0.3),
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          Container(
                                            width: 60,
                                            height: 60,
                                            decoration: BoxDecoration(
                                              color: Colors.orange.withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: Icon(
                                              Icons.category_outlined,
                                              color: Colors.orange,
                                              size: 28,
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            'No Categories Found',
                                            style: GoogleFonts.poppins(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.orange[800],
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Add categories to your profile first, then refresh this page to see them here.',
                                            style: GoogleFonts.poppins(
                                              fontSize: 13,
                                              color: Colors.orange[700],
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                          const SizedBox(height: 16),
                                          Container(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [Colors.orange, Colors.deepOrange],
                                                begin: Alignment.centerLeft,
                                                end: Alignment.centerRight,
                                              ),
                                              borderRadius: BorderRadius.circular(12),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.orange.withOpacity(0.3),
                                                  blurRadius: 8,
                                                  offset: Offset(0, 4),
                                                ),
                                              ],
                                            ),
                                            child: ElevatedButton.icon(
                                              onPressed: _refreshData,
                                              icon: Icon(Icons.refresh_rounded, size: 18),
                                              label: Text('Refresh Categories'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.transparent,
                                                foregroundColor: Colors.white,
                                                elevation: 0,
                                                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                                textStyle: GoogleFonts.poppins(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
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

                            // Step 3: Subcategory Selection - Modern Interactive Design
                            if (_selectedCategory != null) ...[
                              Container(
                                margin: EdgeInsets.only(bottom: 20),
                                padding: EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.95),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: accentColor.withOpacity(0.08),
                                      blurRadius: 25,
                                      spreadRadius: 0,
                                      offset: Offset(0, 12),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildModernStepHeader(
                                      '3',
                                      'Choose Subcategory',
                                      'Specify your niche area',
                                      accentColor,
                                      done: _selectedSubCategory != null,
                                    ),
                                    const SizedBox(height: 20),
                                    
                                    // Modern Subcategory Chips
                                    _buildSubcategoryChips(),
                                    
                                    // Custom subcategory input
                                    if (_selectedSubCategory == 'custom') ...[
                                      const SizedBox(height: 20),
                                      Container(
                                        padding: EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              accentColor.withOpacity(0.1),
                                              primaryColor.withOpacity(0.05),
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                            color: accentColor.withOpacity(0.3),
                                            width: 2,
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Container(
                                                  width: 40,
                                                  height: 40,
                                                  decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                      colors: [accentColor, primaryColor],
                                                      begin: Alignment.topLeft,
                                                      end: Alignment.bottomRight,
                                                    ),
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: Icon(
                                                    Icons.edit_rounded,
                                                    color: Colors.white,
                                                    size: 20,
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Text(
                                                  'Custom Subcategory',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF1A202C),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 16),
                                            Container(
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(0.8),
                                                borderRadius: BorderRadius.circular(16),
                                                border: Border.all(
                                                  color: accentColor.withOpacity(0.3),
                                                  width: 1.5,
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: accentColor.withOpacity(0.1),
                                                    blurRadius: 10,
                                                    offset: Offset(0, 4),
                                                  ),
                                                ],
                                              ),
                                              child: TextField(
                                                controller: _customSubCategoryController,
                                                style: GoogleFonts.poppins(
                                                  color: Color(0xFF1A202C),
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                decoration: InputDecoration(
                                                  hintText: 'Enter your custom subcategory...',
                                                  hintStyle: GoogleFonts.poppins(
                                                    color: Color(0xFF718096),
                                                    fontSize: 15,
                                                  ),
                                                  border: InputBorder.none,
                                                  contentPadding: EdgeInsets.all(20),
                                                  prefixIcon: Padding(
                                                    padding: EdgeInsets.all(12),
                                                    child: Icon(
                                                      Icons.create_rounded,
                                                      color: accentColor,
                                                      size: 20,
                                                    ),
                                                  ),
                                                ),
                                                onChanged: (_) => setState(() {}),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ).animate().slideX(begin: 0.3, duration: 600.ms, delay: 200.ms).fadeIn(),
                            ],

                            // Step 4: Description - Modern Design
                            Container(
                              margin: EdgeInsets.only(bottom: 32),
                              padding: EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.95),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0xFF9C88FF).withOpacity(0.08),
                                    blurRadius: 25,
                                    spreadRadius: 0,
                                    offset: Offset(0, 12),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildModernStepHeader(
                                    '4',
                                    'Add Description',
                                    'Tell your story and engage your audience',
                                    Color(0xFF9C88FF),
                                    done: _descController.text.isNotEmpty,
                                  ),
                                  const SizedBox(height: 20),
                                  Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Color(0xFF9C88FF).withOpacity(0.1),
                                          Color(0xFF6C63FF).withOpacity(0.05),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Color(0xFF9C88FF).withOpacity(0.3),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: TextField(
                                      controller: _descController,
                                      maxLines: 5,
                                      style: GoogleFonts.poppins(
                                        color: Color(0xFF1A202C),
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        height: 1.5,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: 'Share the story behind your creation...\n\nWhat inspired you? What techniques did you use? What makes this special?',
                                        hintStyle: GoogleFonts.poppins(
                                          color: Color(0xFF718096),
                                          fontSize: 15,
                                          height: 1.4,
                                        ),
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.all(20),
                                        counterText: '',
                                        prefixIcon: Padding(
                                          padding: EdgeInsets.only(left: 20, top: 20, right: 12),
                                          child: Icon(
                                            Icons.description_rounded,
                                            color: Color(0xFF9C88FF),
                                            size: 22,
                                          ),
                                        ),
                                      ),
                                      maxLength: 300,
                                      onChanged: (_) => setState(() {}),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.info_outline_rounded,
                                            color: Color(0xFF718096),
                                            size: 16,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Be descriptive and engaging',
                                            style: GoogleFonts.poppins(
                                              color: Color(0xFF718096),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: _descController.text.length > 250 
                                              ? Colors.orange.withOpacity(0.1)
                                              : Color(0xFF9C88FF).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: _descController.text.length > 250 
                                                ? Colors.orange.withOpacity(0.3)
                                                : Color(0xFF9C88FF).withOpacity(0.3),
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          '${_descController.text.length}/300',
                                          style: GoogleFonts.poppins(
                                            color: _descController.text.length > 250 
                                                ? Colors.orange
                                                : Color(0xFF9C88FF),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ).animate().slideX(begin: -0.3, duration: 600.ms, delay: 300.ms).fadeIn(),
                            
                            const SizedBox(height: 32),
                            
                            // Modern Submit Button
                            Container(
                              width: double.infinity,
                              height: 64,
                              margin: EdgeInsets.symmetric(horizontal: 8),
                              decoration: BoxDecoration(
                                gradient: ((kIsWeb && (_webImageBytes != null || _webVideoUrl != null)) || (!kIsWeb && _mediaFile != null)) && _selectedPortfolio != null && _isSubcategoryValid() && _descController.text.isNotEmpty
                                    ? LinearGradient(
                                        colors: [primaryColor, secondaryColor, accentColor],
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                        stops: [0.0, 0.6, 1.0],
                                      )
                                    : LinearGradient(
                                        colors: [
                                          Color(0xFFE2E8F0),
                                          Color(0xFFCBD5E0),
                                        ],
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                      ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: ((kIsWeb && (_webImageBytes != null || _webVideoUrl != null || _webAudioUrl != null)) || (!kIsWeb && _mediaFile != null)) && _selectedPortfolio != null && _isSubcategoryValid() && _descController.text.isNotEmpty
                                    ? [
                                        BoxShadow(
                                          color: primaryColor.withOpacity(0.4),
                                          blurRadius: 25,
                                          spreadRadius: 0,
                                          offset: Offset(0, 12),
                                        ),
                                        BoxShadow(
                                          color: secondaryColor.withOpacity(0.2),
                                          blurRadius: 15,
                                          spreadRadius: 0,
                                          offset: Offset(0, 6),
                                        ),
                                      ]
                                    : [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 10,
                                          offset: Offset(0, 4),
                                        ),
                                      ],
                              ),
                              child: ElevatedButton(
                                onPressed: ((kIsWeb && (_webImageBytes != null || _webVideoUrl != null || _webAudioUrl != null)) || (!kIsWeb && _mediaFile != null)) && _selectedPortfolio != null && _isSubcategoryValid() && _descController.text.isNotEmpty && !_isLoading
                                    ? _submitPost
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        Icons.rocket_launch_rounded,
                                        color: Colors.white,
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Share Your Creation',
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                            color: ((kIsWeb && (_webImageBytes != null || _webVideoUrl != null || _webAudioUrl != null)) || (!kIsWeb && _mediaFile != null)) && _selectedPortfolio != null && _isSubcategoryValid() && _descController.text.isNotEmpty
                                                ? Colors.white
                                                : Color(0xFF718096),
                                          ),
                                        ),
                                        Text(
                                          'Publish to your portfolio',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: ((kIsWeb && (_webImageBytes != null || _webVideoUrl != null || _webAudioUrl != null)) || (!kIsWeb && _mediaFile != null)) && _selectedPortfolio != null && _isSubcategoryValid() && _descController.text.isNotEmpty
                                                ? Colors.white.withOpacity(0.8)
                                                : Color(0xFF718096).withOpacity(0.7),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ).animate().scale(begin: Offset(0.9, 0.9), duration: 600.ms, delay: 400.ms).fadeIn(),
                            
                            const SizedBox(height: 16),
                            
                            if (((kIsWeb && _webImageBytes == null && _webVideoUrl == null && _webAudioUrl == null) || (!kIsWeb && _mediaFile == null)) || _selectedPortfolio == null || !_isSubcategoryValid() || _descController.text.isEmpty)
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