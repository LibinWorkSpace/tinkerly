import 'package:flutter/material.dart';
import 'profile_screen.dart';
import 'package:tinkerly/screens/user/create_post_screen.dart'; // Add this import
import 'package:tinkerly/services/user_service.dart';
import 'package:video_player/video_player.dart';
import '../../widgets/main_bottom_nav_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'portfolio_profile_screen.dart';
import 'package:http/http.dart' as http;
import 'package:tinkerly/constants/api_constants.dart';
import 'dart:convert';


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
    // Use the new /feed endpoint that includes portfolio info
    _postsFuture = _fetchFeedWithPortfolio();
  }

  Future<List<dynamic>> _fetchFeedWithPortfolio() async {
    final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/feed'),
      headers: {'Authorization': 'Bearer $idToken'},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch feed');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Color(0xFF0A0A0A),
        elevation: 0,
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
              ),
              child: Icon(Icons.auto_awesome, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              "Tinkerly",
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              icon: Icon(Icons.notifications_outlined, color: Colors.white, size: 22),
              onPressed: () {
                // TODO: Implement notifications
              },
            ),
          ),
          Container(
            margin: EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              icon: Icon(Icons.search, color: Colors.white, size: 22),
              onPressed: () {
                // TODO: Implement search
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
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 2,
              ),
            );
          }
          final posts = snapshot.data ?? [];
          if (posts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.photo_camera_outlined,
                    size: 80,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Posts Yet',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start following people to see their posts',
                    style: GoogleFonts.poppins(
                      color: Colors.grey[400],
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _postsFuture = _fetchFeedWithPortfolio();
              });
              await _postsFuture;
            },
            color: Colors.white,
            backgroundColor: Colors.grey[800],
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: posts.length,
              physics: const AlwaysScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                final post = posts[index];
                return _InstagramPostCard(
                  post: post,
                  allPosts: posts,
                  onCommentCountChanged: () {
                    // Refresh the specific post data
                    setState(() {
                      _postsFuture = _fetchFeedWithPortfolio();
                    });
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _InstagramPostCard extends StatefulWidget {
  final dynamic post;
  final List<dynamic> allPosts;
  final VoidCallback? onCommentCountChanged;

  const _InstagramPostCard({
    Key? key,
    required this.post,
    required this.allPosts,
    this.onCommentCountChanged,
  }) : super(key: key);

  @override
  State<_InstagramPostCard> createState() => _InstagramPostCardState();
}

class _InstagramPostCardState extends State<_InstagramPostCard> {
  late int likeCount;
  late bool isLiked;
  late String? currentUid;
  late int commentCount;
  bool likeLoading = false;
  bool showComments = false;
  List<dynamic> comments = [];
  bool commentsLoading = false;
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    likeCount = widget.post['likes'] ?? 0;
    commentCount = (widget.post['comments'] ?? []).length;
    currentUid = FirebaseAuth.instance.currentUser?.uid;
    isLiked = (widget.post['likedBy'] ?? []).contains(currentUid);
  }

  Future<void> _fetchComments() async {
    if (commentsLoading) return;
    setState(() { commentsLoading = true; });
    try {
      final user = FirebaseAuth.instance.currentUser;
      final idToken = await user?.getIdToken();
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/post/${widget.post['_id']}/comments'),
        headers: {'Authorization': 'Bearer $idToken'},
      );
      if (response.statusCode == 200) {
        setState(() {
          comments = jsonDecode(response.body);
          commentCount = comments.length;
        });
      }
    } catch (e) {
      print('Error fetching comments: $e');
    } finally {
      setState(() { commentsLoading = false; });
    }
  }

  void _toggleComments() async {
    setState(() {
      showComments = !showComments;
    });
    if (showComments && comments.isEmpty) {
      await _fetchComments();
    }
  }

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      final idToken = await user?.getIdToken();
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/post/${widget.post['_id']}/comment'),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'comment': _commentController.text.trim(),
        }),
      );
      if (response.statusCode == 200) {
        _commentController.clear();
        await _fetchComments(); // Refresh comments
        if (widget.onCommentCountChanged != null) {
          widget.onCommentCountChanged!();
        }
      }
    } catch (e) {
      print('Error adding comment: $e');
    }
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

  String _formatCommentTime(dynamic commentedAt) {
    if (commentedAt == null) return '';
    try {
      final date = commentedAt is DateTime
          ? commentedAt
          : DateTime.tryParse(commentedAt.toString()) ?? DateTime.now();
      final now = DateTime.now();
      final diff = now.difference(date);
      if (diff.inMinutes < 1) return 'now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m';
      if (diff.inHours < 24) return '${diff.inHours}h';
      if (diff.inDays < 7) return '${diff.inDays}d';
      return '${date.day}/${date.month}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final portfolio = post['portfolio'];
    final mediaType = (post['mediaType'] ?? '').toString().toLowerCase();
    final isImage = mediaType == 'image';
    final isVideo = mediaType == 'video';
    
    return Container(
      margin: EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Color(0xFF2A2A2A), width: 1),
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
                    gradient: LinearGradient(
                      colors: [Color(0xFF6C63FF), Color(0xFFFF6B9D)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF6C63FF).withAlpha(76),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.all(2),
                  child: CircleAvatar(
                    backgroundColor: Color(0xFF1A1A1A),
                    backgroundImage: (portfolio != null && (portfolio['profileImageUrl'] ?? '').isNotEmpty)
                        ? NetworkImage(portfolio['profileImageUrl'])
                        : null,
                    radius: 20,
                    child: (portfolio == null || portfolio['profileImageUrl'] == null || (portfolio['profileImageUrl'] ?? '').isEmpty)
                        ? Icon(Icons.person, color: Colors.white, size: 22)
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (portfolio != null && portfolio['_id'] != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PortfolioProfileScreen(portfolioId: portfolio['_id']),
                              ),
                            );
                          }
                        },
                        child: Text(
                          portfolio != null ? portfolio['profilename'] ?? 'Portfolio' : 'Portfolio',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Text(
                        _formatPostTime(post['createdAt']),
                        style: GoogleFonts.poppins(
                          color: Colors.grey[500],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (post['userId'] != FirebaseAuth.instance.currentUser?.uid)
                  _FollowButton(userId: post['userId']),
                const SizedBox(width: 8),
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.more_vert, color: Colors.white, size: 18),
                ),
              ],
            ),
          ),
          // Media
          Container(
            margin: EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Color(0xFF2A2A2A), width: 1),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: double.infinity,
                height: 350,
                child: isImage
                    ? Image.network(
                        post['url'],
                        width: double.infinity,
                        height: 350,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) => progress == null
                            ? child
                            : Container(
                                width: double.infinity,
                                height: 350,
                                color: Color(0xFF2A2A2A),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6C63FF)),
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: double.infinity,
                          height: 350,
                          color: Color(0xFF2A2A2A),
                          child: Icon(Icons.broken_image, size: 60, color: Colors.grey[600]),
                        ),
                      )
                    : isVideo
                        ? _FeedVideoPlayerWithFallback(url: post['url'])
                        : Container(
                            height: 350,
                            width: double.infinity,
                            color: Color(0xFF2A2A2A),
                            child: Icon(Icons.image, size: 60, color: Colors.grey[600]),
                          ),
              ),
            ),
          ),
          // Action buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Like button
                GestureDetector(
                  onTap: _toggleLike,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isLiked ? Color(0xFFFF6B9D).withAlpha(30) : Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isLiked ? Color(0xFFFF6B9D) : Color(0xFF3A3A3A),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isLiked ? Icons.favorite : Icons.favorite_border,
                          color: isLiked ? Color(0xFFFF6B9D) : Colors.white,
                          size: 18,
                        ),
                        if (likeCount > 0) ...[
                          const SizedBox(width: 6),
                          Text(
                            '$likeCount',
                            style: GoogleFonts.poppins(
                              color: isLiked ? Color(0xFFFF6B9D) : Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Comment button
                GestureDetector(
                  onTap: _toggleComments,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: showComments ? Color(0xFF6C63FF).withAlpha(30) : Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: showComments ? Color(0xFF6C63FF) : Color(0xFF3A3A3A),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.mode_comment_outlined,
                          color: showComments ? Color(0xFF6C63FF) : Colors.white,
                          size: 18,
                        ),
                        if (commentCount > 0) ...[
                          const SizedBox(width: 6),
                          Text(
                            '$commentCount',
                            style: GoogleFonts.poppins(
                              color: showComments ? Color(0xFF6C63FF) : Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                Spacer(),
                // Share button
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.share_outlined,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
          // Description
          if (post['description'] != null && post['description'].toString().isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Color(0xFF3A3A3A), width: 1),
              ),
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '${portfolio != null ? portfolio['profilename'] ?? 'Portfolio' : 'Portfolio'} ',
                      style: GoogleFonts.poppins(
                        color: Color(0xFF6C63FF),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    TextSpan(
                      text: post['description'] ?? '',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // Time
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              _formatPostTime(post['createdAt']),
              style: GoogleFonts.poppins(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
          ),

          // Comments Section
          if (showComments) ...[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Color(0xFF3A3A3A), width: 1),
              ),
              child: Column(
                children: [
                  // Comments List
                  if (commentsLoading)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 2,
                      ),
                    )
                  else if (comments.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'No comments yet',
                        style: GoogleFonts.poppins(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: comments.length,
                      itemBuilder: (context, index) {
                        final comment = comments[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: Colors.grey[700],
                                backgroundImage: comment['user']?['profileImageUrl'] != null && comment['user']['profileImageUrl'].isNotEmpty
                                    ? NetworkImage(comment['user']['profileImageUrl'])
                                    : null,
                                child: comment['user']?['profileImageUrl'] == null || comment['user']['profileImageUrl'].isEmpty
                                    ? Text(
                                        comment['user']?['name']?.isNotEmpty == true
                                            ? comment['user']['name'][0].toUpperCase()
                                            : 'U',
                                        style: TextStyle(fontSize: 10, color: Colors.white),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    RichText(
                                      text: TextSpan(
                                        children: [
                                          TextSpan(
                                            text: '${comment['user']?['username'] ?? 'Unknown'} ',
                                            style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                              color: Colors.white,
                                            ),
                                          ),
                                          TextSpan(
                                            text: comment['comment'] ?? '',
                                            style: GoogleFonts.poppins(
                                              fontSize: 13,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _formatCommentTime(comment['commentedAt']),
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                  // Add Comment Input
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Color(0xFF3A3A3A), width: 1),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Color(0xFF1A1A1A),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Color(0xFF3A3A3A), width: 1),
                            ),
                            child: TextField(
                              controller: _commentController,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Add a comment...',
                                hintStyle: GoogleFonts.poppins(
                                  color: Colors.grey[500],
                                  fontSize: 14,
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                              maxLines: null,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: _addComment,
                          child: Container(
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF6C63FF), Color(0xFFFF6B9D)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Icon(
                              Icons.send,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),
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

class _FollowButton extends StatefulWidget {
  final String userId;

  const _FollowButton({Key? key, required this.userId}) : super(key: key);

  @override
  State<_FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends State<_FollowButton> {
  bool isFollowing = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkFollowStatus();
  }

  Future<void> _checkFollowStatus() async {
    try {
      final status = await UserService.getFollowStatus(widget.userId);
      if (status != null && mounted) {
        setState(() {
          isFollowing = status['isFollowing'] ?? false;
        });
      }
    } catch (e) {
      print('Error checking follow status: $e');
    }
  }

  Future<void> _toggleFollow() async {
    if (isLoading) return;

    setState(() { isLoading = true; });

    try {
      bool success;
      if (isFollowing) {
        success = await UserService.unfollowUser(widget.userId);
      } else {
        success = await UserService.followUser(widget.userId);
      }

      if (success && mounted) {
        setState(() {
          isFollowing = !isFollowing;
        });
      }
    } catch (e) {
      print('Error toggling follow: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to ${isFollowing ? 'unfollow' : 'follow'} user')),
        );
      }
    } finally {
      if (mounted) {
        setState(() { isLoading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleFollow,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isFollowing ? Colors.grey[800] : Colors.blue,
          borderRadius: BorderRadius.circular(6),
          border: isFollowing ? Border.all(color: Colors.grey[600]!) : null,
        ),
        child: isLoading
            ? SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                isFollowing ? 'Following' : 'Follow',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}

class _FeedVideoPlayerWithFallback extends StatefulWidget {
  final String url;
  const _FeedVideoPlayerWithFallback({Key? key, required this.url}) : super(key: key);
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
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
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
                                            if (user['uid'] != null) {
                                              await Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) => PublicProfileScreen(uid: user['uid']),
                                                ),
                                              );
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

class PortfolioProfileModal extends StatelessWidget {
  final Map<String, dynamic> user;
  final String category;
  final List<Map<String, dynamic>> posts;

  const PortfolioProfileModal({
    Key? key,
    required this.user,
    required this.category,
    required this.posts,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Portfolio header
            CircleAvatar(
              radius: 40,
              backgroundColor: Color(0xFF6C63FF),
              child: Icon(Icons.folder_special_rounded, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 16),
            Text(
              category,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.black),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatColumn("Posts", posts.length.toString()),
                _buildStatColumn("Followers", "0"),
                _buildStatColumn("Following", "0"),
              ],
            ),
            const SizedBox(height: 16),
            posts.isEmpty
                ? Text('No posts in this portfolio yet', style: TextStyle(fontSize: 16, color: Colors.black54))
                : SizedBox(
                    height: 200,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: posts.length,
                      itemBuilder: (context, index) {
                        final post = posts[index];
                        return Card(
                          child: Image.network(post['url'], width: 120, height: 120, fit: BoxFit.cover),
                        );
                      },
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.black54)),
      ],
    );
  }
} 