import 'package:flutter/material.dart';
import 'profile_screen.dart';
import 'package:tinkerly/screens/user/create_post_screen.dart'; // Add this import
import 'package:tinkerly/services/user_service.dart';
import 'package:video_player/video_player.dart';
import '../../widgets/main_bottom_nav_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class HomeScreen extends StatefulWidget {
  static final GlobalKey<_HomeScreenState> homeScreenKey = GlobalKey<_HomeScreenState>();
  const HomeScreen({super.key});
  static void switchToTab(int index) {
    final state = homeScreenKey.currentState;
    if (state != null) {
      state.switchTab(index);
    }
  }
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    HomeFeed(),
    UserSearchScreen(),
    Center(child: Text('Add', style: TextStyle(fontSize: 24))),
    Center(child: Text('Categories', style: TextStyle(fontSize: 24))),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    if (index == 2) {
      // Open create post screen
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => CreatePostScreen()),
      );
      return;
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  void switchTab(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFAFAFA), // Light gray-white background
      body: Container(
        color: Color(0xFFFAFAFA),
        child: _pages[_selectedIndex],
      ),
      bottomNavigationBar: MainBottomNavBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => CreatePostScreen()),
            );
            return;
          }
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}

class HomeFeed extends StatefulWidget {
  @override
  State<HomeFeed> createState() => _HomeFeedState();
}

class _HomeFeedState extends State<HomeFeed> {
  late Future<List<dynamic>> _postsFuture;

  @override
  void initState() {
    super.initState();
    _postsFuture = UserService.fetchAllPosts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        shadowColor: Colors.black.withAlpha(25),
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFFFF6B9D)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF6C63FF).withAlpha(76),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                "⚡",
                style: TextStyle(fontSize: 20, color: Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              "Tinkerly",
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3748), // Dark text
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Color(0xFFF7FAFC), // Light background
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Color(0xFFE2E8F0),
                width: 1,
              ),
            ),
            child: IconButton(
              icon: Icon(Icons.notifications_outlined, color: Color(0xFF6C63FF)),
              onPressed: () {
                // TODO: Implement notifications
              },
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _postsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Container(
                padding: EdgeInsets.all(24),
                margin: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(5),
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
                      'Loading amazing posts...',
                      style: GoogleFonts.poppins(
                        color: Color(0xFF2D3748),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          final posts = snapshot.data ?? [];
          if (posts.isEmpty) {
            return Center(
              child: Container(
                padding: EdgeInsets.all(32),
                margin: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(5),
                      blurRadius: 15,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF6C63FF), Color(0xFFFF6B9D)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF6C63FF).withAlpha(76),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.photo_library_outlined,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'No Posts Yet',
                      style: GoogleFonts.poppins(
                        color: Color(0xFF2D3748),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Be the first to share something amazing!',
                      style: GoogleFonts.poppins(
                        color: Color(0xFF718096),
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            itemCount: posts.length,
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            cacheExtent: 2000,
            itemBuilder: (context, index) {
              final post = posts[index];
              return _InstagramPostCard(post: post).animate().fadeIn(
                duration: 400.ms,
                delay: (index * 100).ms,
              );
            },
          );
        },
      ),
    );
  }
}

class _InstagramPostCard extends StatefulWidget {
  final dynamic post;
  const _InstagramPostCard({required this.post});

  @override
  State<_InstagramPostCard> createState() => _InstagramPostCardState();
}

class _InstagramPostCardState extends State<_InstagramPostCard> {
  late int likeCount;
  late bool isLiked;
  late String? currentUid;
  bool likeLoading = false;

  @override
  void initState() {
    super.initState();
    likeCount = widget.post['likes'] ?? 0;
    currentUid = FirebaseAuth.instance.currentUser?.uid;
    isLiked = (widget.post['likedBy'] ?? []).contains(currentUid);
  }

  void _toggleLike() async {
    if (likeLoading || currentUid == null) return;
    setState(() { likeLoading = true; });
    if (isLiked) {
      final success = await UserService.unlikePost(widget.post['_id']);
      if (success) {
        setState(() {
          isLiked = false;
          likeCount = (likeCount - 1).clamp(0, 999999);
        });
      }
    } else {
      final success = await UserService.likePost(widget.post['_id']);
      if (success) {
        setState(() {
          isLiked = true;
          likeCount = likeCount + 1;
        });
      }
    }
    setState(() { likeLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final mediaType = (post['mediaType'] ?? '').toString().toLowerCase();
    final isImage = mediaType == 'image';
    final isVideo = mediaType == 'video';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 10,
            spreadRadius: 0,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Color(0xFF6C63FF).withAlpha(76),
                      width: 2,
                    ),
                  ),
                  child: CircleAvatar(
                    backgroundColor: Color(0xFFF7FAFC),
                    backgroundImage: (post['profileImageUrl'] ?? '').isNotEmpty
                        ? NetworkImage(post['profileImageUrl']!)
                        : null,
                    child: (post['profileImageUrl'] == null || (post['profileImageUrl'] ?? '').isEmpty)
                        ? Icon(Icons.person, color: Color(0xFF6C63FF), size: 20)
                        : null,
                    radius: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post['name'] ?? post['username'] ?? 'User',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                      Text(
                        _formatPostTime(post['createdAt']),
                        style: GoogleFonts.poppins(
                          color: Color(0xFF718096),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF6C63FF), Color(0xFFFF6B9D)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    post['category'] ?? 'General',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Media
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(50),
                  blurRadius: 15,
                  spreadRadius: 0,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: isImage
                  ? Image.network(
                      post['url'],
                      width: double.infinity,
                      height: 300,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) => progress == null
                          ? child
                          : Container(
                              width: double.infinity,
                              height: 300,
                              decoration: BoxDecoration(
                                color: Color(0xFFF7FAFC),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6C63FF)),
                                ),
                              ),
                            ),
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: double.infinity,
                        height: 300,
                        decoration: BoxDecoration(
                          color: Color(0xFFF7FAFC),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(Icons.broken_image, size: 60, color: Color(0xFF718096)),
                      ),
                    )
                  : isVideo
                      ? _FeedVideoPlayerWithFallback(url: post['url'])
                      : Container(
                          height: 300,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Color(0xFFF7FAFC),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(Icons.image, size: 60, color: Color(0xFF718096)),
                        ),
            ),
          ),
          // Like/Comment Row
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _toggleLike,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isLiked 
                          ? Color(0xFFFF6B9D).withAlpha(25)
                          : Color(0xFFF7FAFC),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isLiked 
                            ? Color(0xFFFF6B9D)
                            : Color(0xFFE2E8F0),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isLiked ? Icons.favorite : Icons.favorite_border,
                          size: 20,
                          color: isLiked ? Color(0xFFFF6B9D) : Color(0xFF718096),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$likeCount',
                          style: GoogleFonts.poppins(
                            color: isLiked ? Color(0xFFFF6B9D) : Color(0xFF2D3748),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Color(0xFFF7FAFC),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Color(0xFFE2E8F0),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.mode_comment_outlined, size: 20, color: Color(0xFF718096)),
                      const SizedBox(width: 6),
                      Text(
                        'Comment',
                        style: GoogleFonts.poppins(
                          color: Color(0xFF2D3748),
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Description
          if (post['description'] != null && post['description'].toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                post['description'] ?? '',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Color(0xFF2D3748),
                  height: 1.4,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

String _formatPostTime(dynamic createdAt) {
  if (createdAt == null) return '';
  try {
    final date = createdAt is DateTime
        ? createdAt
        : DateTime.tryParse(createdAt.toString()) ?? DateTime.now();
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
  } catch (_) {
    return '';
  }
}

class _FeedVideoPlayerWithFallback extends StatefulWidget {
  final String url;
  const _FeedVideoPlayerWithFallback({required this.url});
  @override
  State<_FeedVideoPlayerWithFallback> createState() => _FeedVideoPlayerWithFallbackState();
}

class _FeedVideoPlayerWithFallbackState extends State<_FeedVideoPlayerWithFallback> {
  late VideoPlayerController _controller;
  bool _initialized = false;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.url)
      ..initialize().then((_) {
        setState(() {
          _initialized = true;
        });
        _controller.setLooping(true);
        _controller.setVolume(0);
        _controller.play();
      }).catchError((e) {
        setState(() {
          _error = true;
        });
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error) {
      return Container(
        height: 320,
        color: Colors.black12,
        child: const Center(child: Icon(Icons.videocam_off, size: 60, color: Colors.grey)),
      );
    }
    return _initialized
        ? AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: VideoPlayer(_controller),
          )
        : Container(height: 320, color: Colors.black12);
  }
}

class UserSearchScreen extends StatefulWidget {
  @override
  State<UserSearchScreen> createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends State<UserSearchScreen> {
  final TextEditingController _controller = TextEditingController();
  List<dynamic> _results = [];
  bool _isLoading = false;
  String _error = '';

  void _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() { _results = []; _error = ''; });
      return;
    }
    setState(() { _isLoading = true; _error = ''; });
    try {
      final user = await UserService.fetchUserProfile();
      final idToken = user != null ? null : null; // Not used, but can be for auth
      final response = await UserService.searchUsers(query);
      setState(() { _results = response; });
    } catch (e) {
      setState(() { _error = 'Failed to search users.'; });
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Color(0xFF6C63FF);
    final secondaryColor = Color(0xFFFF6B9D);
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.search, color: Colors.black, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              'Discover People',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.black.withAlpha(76),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(25),
                  blurRadius: 15,
                  spreadRadius: 0,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: TextField(
              controller: _controller,
              onChanged: _search,
              style: GoogleFonts.poppins(color: Colors.black),
              decoration: InputDecoration(
                hintText: 'Search by name or username...',
                hintStyle: GoogleFonts.poppins(
                  color: Colors.black.withAlpha(178),
                ),
                prefixIcon: Icon(Icons.search, color: Colors.black.withAlpha(204)),
                filled: false,
                contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                border: InputBorder.none,
              ),
            ),
          ).animate().fadeIn(duration: 400.ms),
          
          // Content
          Expanded(
            child: _isLoading
                ? Center(
                    child: Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(25),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Searching users...',
                            style: GoogleFonts.poppins(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : _error.isNotEmpty
                    ? Center(
                        child: Container(
                          padding: EdgeInsets.all(24),
                          margin: EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.red.withAlpha(25),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.red.withAlpha(76),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.error_outline, color: Colors.red, size: 32),
                              const SizedBox(height: 12),
                              Text(
                                _error,
                                style: GoogleFonts.poppins(
                                  color: Colors.red,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    : !_isLoading && _results.isEmpty && _controller.text.isNotEmpty
                        ? Center(
                            child: Container(
                              padding: EdgeInsets.all(32),
                              margin: EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(25),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withAlpha(51),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.search_off, color: Colors.black.withAlpha(178), size: 48),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No users found',
                                    style: GoogleFonts.poppins(
                                      color: Colors.black,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Try searching with different keywords',
                                    style: GoogleFonts.poppins(
                                      color: Colors.black.withAlpha(178),
                                      fontSize: 14,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          )
                        : _results.isNotEmpty
                            ? ListView.builder(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                itemCount: _results.length,
                                itemBuilder: (context, index) {
                                  final user = _results[index];
                                  return Container(
                                    margin: EdgeInsets.only(bottom: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: Colors.black.withAlpha(51),
                                        width: 1,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withAlpha(25),
                                          blurRadius: 10,
                                          spreadRadius: 0,
                                          offset: Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: ListTile(
                                      contentPadding: EdgeInsets.all(16),
                                      leading: Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.black.withAlpha(76),
                                            width: 2,
                                          ),
                                        ),
                                        child: CircleAvatar(
                                          backgroundColor: primaryColor.withAlpha(51),
                                          backgroundImage: user['profileImageUrl'] != null && user['profileImageUrl'].isNotEmpty
                                              ? NetworkImage(user['profileImageUrl'])
                                              : null,
                                          child: (user['profileImageUrl'] == null || user['profileImageUrl'].isEmpty)
                                              ? Text(
                                                  user['name'] != null && user['name'].isNotEmpty
                                                      ? user['name'][0].toUpperCase()
                                                      : 'N',
                                                  style: GoogleFonts.poppins(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black,
                                                  ),
                                                )
                                              : null,
                                          radius: 24,
                                        ),
                                      ),
                                      title: Text(
                                        user['name'] ?? '',
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                          fontSize: 16,
                                        ),
                                      ),
                                      subtitle: Text(
                                        '@${user['username'] ?? ''}',
                                        style: GoogleFonts.poppins(
                                          color: Colors.black.withAlpha(178),
                                          fontSize: 14,
                                        ),
                                      ),
                                      trailing: Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [primaryColor, secondaryColor],
                                            begin: Alignment.centerLeft,
                                            end: Alignment.centerRight,
                                          ),
                                          borderRadius: BorderRadius.circular(12),
                                          boxShadow: [
                                            BoxShadow(
                                              color: primaryColor.withAlpha(76),
                                              blurRadius: 8,
                                              spreadRadius: 0,
                                              offset: Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: ElevatedButton(
                                          onPressed: () async {
                                            final result = await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => PublicProfileScreen(uid: user['uid']),
                                              ),
                                            );
                                            // Refresh the logged-in user's profile if follow/unfollow happened
                                            if (result == true) {
                                              if (profileScreenKey.currentState != null) {
                                                await profileScreenKey.currentState!.loadProfileAndPosts();
                                              }
                                            }
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.transparent,
                                            foregroundColor: Colors.white,
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                          ),
                                          child: Text(
                                            'View',
                                            style: GoogleFonts.poppins(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ).animate().fadeIn(
                                    duration: 400.ms,
                                    delay: (index * 100).ms,
                                  );
                                },
                              )
                            : Center(
                                child: Container(
                                  padding: EdgeInsets.all(32),
                                  margin: EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withAlpha(25),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.white.withAlpha(51),
                                      width: 1,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.people_outline, color: Colors.black.withAlpha(178), size: 48),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Discover Amazing People',
                                        style: GoogleFonts.poppins(
                                          color: Colors.black,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Search for users by name or username to connect with them',
                                        style: GoogleFonts.poppins(
                                          color: Colors.black.withAlpha(178),
                                          fontSize: 14,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
          ),
        ],
      ),
    );
  }
} 