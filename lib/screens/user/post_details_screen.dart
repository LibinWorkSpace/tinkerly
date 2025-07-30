import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/user_service.dart';
import 'package:video_player/video_player.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../constants/api_constants.dart';

class PostDetailsScreen extends StatefulWidget {
  final dynamic post;
  final List<dynamic> allPosts;

  const PostDetailsScreen({
    Key? key,
    required this.post,
    required this.allPosts,
  }) : super(key: key);

  @override
  State<PostDetailsScreen> createState() => _PostDetailsScreenState();
}

class _PostDetailsScreenState extends State<PostDetailsScreen> {
  late int likeCount;
  late bool isLiked;
  late String? currentUid;
  bool likeLoading = false;
  List<dynamic> comments = [];
  List<dynamic> likedByUsers = [];
  bool commentsLoading = false;
  bool likesLoading = false;
  final TextEditingController _commentController = TextEditingController();
  bool isSubmittingComment = false;

  @override
  void initState() {
    super.initState();
    likeCount = widget.post['likes'] ?? 0;
    currentUid = FirebaseAuth.instance.currentUser?.uid;
    isLiked = (widget.post['likedBy'] ?? []).contains(currentUid);
    comments = List.from(widget.post['comments'] ?? []);
    _fetchLikedByUsers();
    _fetchComments();
  }

  Future<void> _fetchLikedByUsers() async {
    if (widget.post['userId'] != currentUid) return; // Only show to post owner
    
    setState(() { likesLoading = true; });
    try {
      final user = FirebaseAuth.instance.currentUser;
      final idToken = await user?.getIdToken();
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/post/${widget.post['_id']}/likes'),
        headers: {'Authorization': 'Bearer $idToken'},
      );
      if (response.statusCode == 200) {
        setState(() {
          likedByUsers = jsonDecode(response.body);
        });
      }
    } catch (e) {
      print('Error fetching liked by users: $e');
    } finally {
      setState(() { likesLoading = false; });
    }
  }

  Future<void> _fetchComments() async {
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
        });
      }
    } catch (e) {
      print('Error fetching comments: $e');
    } finally {
      setState(() { commentsLoading = false; });
    }
  }

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) return;
    
    setState(() { isSubmittingComment = true; });
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
      }
    } catch (e) {
      print('Error adding comment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add comment')),
      );
    } finally {
      setState(() { isSubmittingComment = false; });
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
        _fetchLikedByUsers(); // Refresh liked by users
      }
    } else {
      final success = await UserService.likePost(widget.post['_id']);
      if (success) {
        setState(() {
          isLiked = true;
          likeCount = likeCount + 1;
        });
        _fetchLikedByUsers(); // Refresh liked by users
      }
    }
    setState(() { likeLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final portfolio = post['portfolio'];
    final mediaType = (post['mediaType'] ?? '').toString().toLowerCase();
    final isImage = mediaType == 'image';
    final isVideo = mediaType == 'video';
    final isOwner = post['userId'] == currentUid;

    return Scaffold(
      backgroundColor: Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        shadowColor: Colors.black.withAlpha(25),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Color(0xFF2D3748)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Post Details',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3748),
          ),
        ),
        actions: [
          if (isOwner)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'delete') {
                  _showDeleteDialog();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Text('Delete Post'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Post Content
            Container(
              margin: const EdgeInsets.all(16),
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
                            backgroundImage: (portfolio != null && (portfolio['profileImageUrl'] ?? '').isNotEmpty)
                                ? NetworkImage(portfolio['profileImageUrl'])
                                : null,
                            child: (portfolio == null || portfolio['profileImageUrl'] == null || (portfolio['profileImageUrl'] ?? '').isEmpty)
                                ? Icon(Icons.folder_special_rounded, color: Color(0xFF6C63FF), size: 20)
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
                                portfolio != null ? portfolio['profilename'] ?? 'Portfolio' : 'Portfolio',
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
                            portfolio != null ? portfolio['category'] ?? 'General' : 'General',
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
                              ? _PostVideoPlayer(url: post['url'])
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
                  // Description
                  if (post['description'] != null && post['description'].toString().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        post['description'] ?? '',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Color(0xFF2D3748),
                          height: 1.4,
                        ),
                      ),
                    ),
                  // Like/Comment Actions
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
                                '${comments.length} Comments',
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
                ],
              ),
            ),

            // Liked By Section (only for post owner)
            if (isOwner && likedByUsers.isNotEmpty)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Liked by',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                    ),
                    if (likesLoading)
                      Center(child: CircularProgressIndicator())
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: likedByUsers.length,
                        itemBuilder: (context, index) {
                          final user = likedByUsers[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: user['profileImageUrl'] != null && user['profileImageUrl'].isNotEmpty
                                  ? NetworkImage(user['profileImageUrl'])
                                  : null,
                              child: user['profileImageUrl'] == null || user['profileImageUrl'].isEmpty
                                  ? Text(user['name']?.isNotEmpty == true ? user['name'][0].toUpperCase() : 'U')
                                  : null,
                            ),
                            title: Text(
                              user['name'] ?? 'Unknown User',
                              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              '@${user['username'] ?? 'username'}',
                              style: GoogleFonts.poppins(color: Color(0xFF718096)),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),

            // Comments Section
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Comments',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                  ),
                  if (commentsLoading)
                    Center(child: CircularProgressIndicator())
                  else if (comments.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'No comments yet. Be the first to comment!',
                        style: GoogleFonts.poppins(
                          color: Color(0xFF718096),
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
                                radius: 16,
                                backgroundImage: comment['user']?['profileImageUrl'] != null && comment['user']['profileImageUrl'].isNotEmpty
                                    ? NetworkImage(comment['user']['profileImageUrl'])
                                    : null,
                                child: comment['user']?['profileImageUrl'] == null || comment['user']['profileImageUrl'].isEmpty
                                    ? Text(
                                        comment['user']?['name']?.isNotEmpty == true
                                            ? comment['user']['name'][0].toUpperCase()
                                            : 'U',
                                        style: TextStyle(fontSize: 12),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          comment['user']?['username'] ?? 'Unknown',
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                            color: Color(0xFF2D3748),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _formatCommentTime(comment['commentedAt']),
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: Color(0xFF718096),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      comment['comment'] ?? '',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: Color(0xFF2D3748),
                                        height: 1.3,
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
                ],
              ),
            ),

            const SizedBox(height: 80), // Space for comment input
          ],
        ),
      ),

      // Comment Input
      bottomSheet: Container(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          bottom: MediaQuery.of(context).viewInsets.bottom + 12,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Color(0xFFF7FAFC),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Color(0xFFE2E8F0),
                    width: 1,
                  ),
                ),
                child: TextField(
                  controller: _commentController,
                  decoration: InputDecoration(
                    hintText: 'Add a comment...',
                    hintStyle: GoogleFonts.poppins(
                      color: Color(0xFF718096),
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Color(0xFF2D3748),
                  ),
                  maxLines: null,
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: isSubmittingComment ? null : _addComment,
              child: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFFFF6B9D)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: isSubmittingComment
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 20,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
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

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Post'),
        content: Text('Are you sure you want to delete this post?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await UserService.deletePost(widget.post['_id']);
              if (success) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Post deleted successfully')),
                );
              }
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
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

class _PostVideoPlayer extends StatefulWidget {
  final String url;
  const _PostVideoPlayer({required this.url});
  @override
  State<_PostVideoPlayer> createState() => _PostVideoPlayerState();
}

class _PostVideoPlayerState extends State<_PostVideoPlayer> {
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
