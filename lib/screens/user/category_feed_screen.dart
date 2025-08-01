import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../constants/api_constants.dart';
import '../../widgets/main_bottom_nav_bar.dart';
import '../../widgets/audio_player_widget.dart';
import '../../services/user_service.dart';

class CategoryFeedScreen extends StatefulWidget {
  final String category;
  final Color primaryColor;
  final Color secondaryColor;
  final IconData icon;

  const CategoryFeedScreen({
    Key? key,
    required this.category,
    required this.primaryColor,
    required this.secondaryColor,
    required this.icon,
  }) : super(key: key);

  @override
  State<CategoryFeedScreen> createState() => _CategoryFeedScreenState();
}

class _CategoryFeedScreenState extends State<CategoryFeedScreen> {
  List<dynamic> _posts = [];
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchCategoryPosts();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchCategoryPosts() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      final user = FirebaseAuth.instance.currentUser;
      final idToken = await user?.getIdToken();
      
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/posts/category/${widget.category}'),
        headers: {'Authorization': 'Bearer $idToken'},
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> allPosts = jsonDecode(response.body);
        setState(() {
          _posts = allPosts;
          _isLoading = false;
        });
      } else {
        setState(() {
          _hasError = true;
          _errorMessage = 'Failed to load posts';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching category posts: $e');
      setState(() {
        _hasError = true;
        _errorMessage = 'Network error occurred';
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshPosts() async {
    await _fetchCategoryPosts();
  }

  void _onNavTap(int index) {
    Navigator.of(context).popUntil((route) => route.isFirst);
    Future.delayed(Duration.zero, () {
      if (context.mounted) {
        // Navigate to home and switch to the selected tab
        Navigator.of(context).pushReplacementNamed('/home');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFAFAFA),
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [widget.primaryColor, widget.secondaryColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(widget.icon, color: Colors.white, size: 20),
            ),
            SizedBox(width: 12),
            Text(
              widget.category,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3748),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: _buildBody(),
      bottomNavigationBar: MainBottomNavBar(currentIndex: 1, onTap: _onNavTap),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(widget.primaryColor),
            ),
            SizedBox(height: 16),
            Text(
              'Loading ${widget.category} posts...',
              style: GoogleFonts.poppins(
                color: Color(0xFF2D3748),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[400],
            ),
            SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Something went wrong',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.red[600],
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _refreshPosts,
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (_posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    widget.primaryColor.withAlpha((0.1 * 255).toInt()),
                    widget.secondaryColor.withAlpha((0.1 * 255).toInt()),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                widget.icon,
                size: 64,
                color: widget.primaryColor,
              ),
            ),
            SizedBox(height: 24),
            Text(
              'No ${widget.category} posts yet',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3748),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Be the first to share something in ${widget.category}!',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Color(0xFF6C7B7F),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshPosts,
      color: widget.primaryColor,
      child: ListView.builder(
        controller: _scrollController,
        padding: EdgeInsets.symmetric(vertical: 16),
        itemCount: _posts.length,
        itemBuilder: (context, index) {
          final post = _posts[index];
          return _CategoryPostCard(
            post: post,
            primaryColor: widget.primaryColor,
            onCommentCountChanged: () {
              // Refresh posts when comment count changes
              _refreshPosts();
            },
          );
        },
      ),
    );
  }

  Future<void> _handleLike(dynamic post) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final idToken = await user?.getIdToken();
      
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/posts/${post['_id']}/like'),
        headers: {'Authorization': 'Bearer $idToken'},
      );
      
      if (response.statusCode == 200) {
        // Refresh the specific post or update locally
        await _refreshPosts();
      }
    } catch (e) {
      print('Error liking post: $e');
    }
  }

  void _handleComment(dynamic post) {
    // Navigate to post details for commenting
    Navigator.pushNamed(
      context,
      '/post-details',
      arguments: {'post': post, 'allPosts': _posts},
    );
  }

  void _handleShare(dynamic post) {
    // Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Share functionality coming soon!'),
        backgroundColor: widget.primaryColor,
      ),
    );
  }

  void _handleUserTap(dynamic post) {
    // Navigate to user profile
    final userId = post['userId'];
    if (userId != null) {
      Navigator.pushNamed(
        context,
        '/public-profile',
        arguments: {'userId': userId},
      );
    }
  }
}

class _CategoryPostCard extends StatefulWidget {
  final dynamic post;
  final Color primaryColor;
  final VoidCallback? onCommentCountChanged;

  const _CategoryPostCard({
    Key? key,
    required this.post,
    required this.primaryColor,
    this.onCommentCountChanged,
  }) : super(key: key);

  @override
  State<_CategoryPostCard> createState() => _CategoryPostCardState();
}

class _CategoryPostCardState extends State<_CategoryPostCard> {
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

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _toggleLike() async {
    if (likeLoading) return;

    setState(() {
      likeLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      final idToken = await user?.getIdToken();

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/posts/${widget.post['_id']}/like'),
        headers: {'Authorization': 'Bearer $idToken'},
      );

      if (response.statusCode == 200) {
        setState(() {
          if (isLiked) {
            likeCount--;
            isLiked = false;
          } else {
            likeCount++;
            isLiked = true;
          }
        });
      }
    } catch (e) {
      print('Error toggling like: $e');
    } finally {
      setState(() {
        likeLoading = false;
      });
    }
  }

  void _toggleComments() {
    setState(() {
      showComments = !showComments;
    });

    if (showComments && comments.isEmpty) {
      _loadComments();
    }
  }

  Future<void> _loadComments() async {
    setState(() {
      commentsLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      final idToken = await user?.getIdToken();

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/posts/${widget.post['_id']}/comments'),
        headers: {'Authorization': 'Bearer $idToken'},
      );

      if (response.statusCode == 200) {
        setState(() {
          comments = jsonDecode(response.body);
        });
      }
    } catch (e) {
      print('Error loading comments: $e');
    } finally {
      setState(() {
        commentsLoading = false;
      });
    }
  }

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      final idToken = await user?.getIdToken();

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/posts/${widget.post['_id']}/comments'),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'text': _commentController.text.trim(),
        }),
      );

      if (response.statusCode == 200) {
        _commentController.clear();
        await _loadComments();
        setState(() {
          commentCount++;
        });
        widget.onCommentCountChanged?.call();
      }
    } catch (e) {
      print('Error adding comment: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final isImage = post['mediaType'] == 'image';
    final isVideo = post['mediaType'] == 'video';
    final isAudio = post['mediaType'] == 'audio';

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.05 * 255).toInt()),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User header
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: widget.primaryColor,
                  child: post['userProfileImage'] != null
                      ? ClipOval(
                          child: Image.network(
                            post['userProfileImage'],
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(Icons.person, color: Colors.white);
                            },
                          ),
                        )
                      : Icon(Icons.person, color: Colors.white),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post['userName'] ?? post['username'] ?? 'Unknown User',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                      if (post['category'] != null)
                        Text(
                          post['category'],
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: widget.primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Media content
          if (isImage)
            ClipRRect(
              borderRadius: BorderRadius.zero,
              child: Image.network(
                post['url'],
                width: double.infinity,
                height: 300,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 300,
                    color: Colors.grey[200],
                    child: Icon(Icons.broken_image, size: 60, color: Colors.grey),
                  );
                },
              ),
            )
          else if (isVideo)
            Container(
              height: 300,
              width: double.infinity,
              color: Colors.black,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(Icons.play_circle_outline, size: 80, color: Colors.white),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha((0.7 * 255).toInt()),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.videocam, color: Colors.white, size: 16),
                          SizedBox(width: 4),
                          Text('Video', style: TextStyle(color: Colors.white, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            )
          else if (isAudio)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: AudioPlayerWidget(
                audioUrl: post['url'],
                title: post['description'] ?? 'Audio Track',
                height: 160,
                primaryColor: widget.primaryColor,
                showTitle: true,
                autoPlay: false,
              ),
            ),

          // Action buttons
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                // Like button
                GestureDetector(
                  onTap: _toggleLike,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isLiked ? widget.primaryColor.withAlpha(30) : Color(0xFFF7FAFC),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isLiked ? widget.primaryColor : Color(0xFFE2E8F0),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isLiked ? Icons.favorite : Icons.favorite_border,
                          size: 18,
                          color: isLiked ? widget.primaryColor : Color(0xFF6C7B7F),
                        ),
                        SizedBox(width: 6),
                        Text(
                          '$likeCount',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isLiked ? widget.primaryColor : Color(0xFF6C7B7F),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 12),

                // Comment button
                GestureDetector(
                  onTap: _toggleComments,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: showComments ? widget.primaryColor.withAlpha(30) : Color(0xFFF7FAFC),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: showComments ? widget.primaryColor : Color(0xFFE2E8F0),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 18,
                          color: showComments ? widget.primaryColor : Color(0xFF6C7B7F),
                        ),
                        SizedBox(width: 6),
                        Text(
                          '$commentCount',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: showComments ? widget.primaryColor : Color(0xFF6C7B7F),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Description
          if (post['description'] != null && post['description'].toString().isNotEmpty)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                post['description'],
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Color(0xFF2D3748),
                  height: 1.4,
                ),
              ),
            ),

          // Comments section
          if (showComments) ...[
            Divider(height: 24, color: Color(0xFFE2E8F0)),

            // Comments list
            if (commentsLoading)
              Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator(color: widget.primaryColor)),
              )
            else if (comments.isNotEmpty)
              ...comments.map((comment) => Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: widget.primaryColor,
                      child: Icon(Icons.person, color: Colors.white, size: 16),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            comment['userName'] ?? 'Unknown User',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              color: Color(0xFF2D3748),
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            comment['text'] ?? '',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Color(0xFF4A5568),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )).toList(),

            // Add comment input
            Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: InputDecoration(
                        hintText: 'Add a comment...',
                        hintStyle: GoogleFonts.poppins(color: Color(0xFF9CA3AF)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(color: widget.primaryColor),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      style: GoogleFonts.poppins(fontSize: 14),
                    ),
                  ),
                  SizedBox(width: 8),
                  GestureDetector(
                    onTap: _addComment,
                    child: Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: widget.primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.send, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ],

          SizedBox(height: 8),
        ],
      ),
    );
  }
}
