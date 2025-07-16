import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/user_service.dart';

class UserPostsFeedScreen extends StatefulWidget {
  final List<dynamic> posts;
  final String initialPostId;
  const UserPostsFeedScreen({Key? key, required this.posts, required this.initialPostId}) : super(key: key);

  @override
  State<UserPostsFeedScreen> createState() => _UserPostsFeedScreenState();
}

class _UserPostsFeedScreenState extends State<UserPostsFeedScreen> {
  late List<dynamic> _posts;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _posts = List.from(widget.posts);
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToInitialPost());
  }

  void _scrollToInitialPost() {
    final idx = _posts.indexWhere((p) => p['_id'] == widget.initialPostId);
    if (idx != -1) {
      _scrollController.jumpTo(idx * 420.0); // Approximate post height
    }
  }

  void _deletePost(String postId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Post'),
        content: Text('Are you sure you want to delete this post?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Delete')),
        ],
      ),
    );
    if (confirmed == true) {
      final success = await UserService.deletePost(postId);
      if (success) {
        setState(() {
          _posts.removeWhere((p) => p['_id'] == postId);
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Post deleted')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete post')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Posts')),
      body: ListView.builder(
        controller: _scrollController,
        itemCount: _posts.length,
        itemBuilder: (context, index) {
          final post = _posts[index];
          final isImage = post['mediaType'] == 'image';
          final isVideo = post['mediaType'] == 'video';
          final currentUid = FirebaseAuth.instance.currentUser?.uid;
          final bool isLiked = (post['likedBy'] ?? []).contains(currentUid);
          int likeCount = post['likes'] ?? 0;
          return StatefulBuilder(
            builder: (context, setState) {
              Future<void> _toggleLike() async {
                if (isLiked) {
                  final success = await UserService.unlikePost(post['_id']);
                  if (success) {
                    setState(() {
                      post['likedBy'].remove(currentUid);
                      post['likes'] = (post['likes'] ?? 1) - 1;
                    });
                  }
                } else {
                  final success = await UserService.likePost(post['_id']);
                  if (success) {
                    setState(() {
                      post['likedBy'].add(currentUid);
                      post['likes'] = (post['likes'] ?? 0) + 1;
                    });
                  }
                }
              }
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      title: Text(post['username'] ?? ''),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'delete') _deletePost(post['_id']);
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(value: 'delete', child: Text('Delete')),
                        ],
                      ),
                    ),
                    isImage
                        ? Image.network(post['url'], width: double.infinity, fit: BoxFit.cover)
                        : isVideo
                            ? Container(
                                height: 320,
                                color: Colors.black12,
                                child: Center(child: Icon(Icons.videocam, size: 60)),
                              )
                            : Container(height: 320, color: Colors.grey[200]),
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: _toggleLike,
                            child: Row(
                              children: [
                                Icon(
                                  isLiked ? Icons.favorite : Icons.favorite_border,
                                  size: 22,
                                  color: isLiked ? Colors.pinkAccent : Colors.grey[700],
                                ),
                                const SizedBox(width: 4),
                                Text('${post['likes'] ?? 0}'),
                              ],
                            ),
                          ),
                          const SizedBox(width: 18),
                          Expanded(child: Text(post['description'] ?? '', style: TextStyle(fontSize: 15))),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
} 