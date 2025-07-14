import 'package:flutter/material.dart';
import 'profile_screen.dart';
import 'package:tinkerly/screens/user/create_post_screen.dart'; // Add this import
import 'package:tinkerly/services/user_service.dart';
import 'package:video_player/video_player.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    HomeFeed(),
    UserSearchScreen(),
    Center(child: Text('Add', style: TextStyle(fontSize: 24))),
    Center(child: Text('Portfolio', style: TextStyle(fontSize: 24))),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.add_box), label: 'Add'),
          BottomNavigationBarItem(icon: Icon(Icons.folder_special), label: 'Portfolio'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
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
    return FutureBuilder<List<dynamic>>(
      future: _postsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final posts = snapshot.data ?? [];
        if (posts.isEmpty) {
          return const Center(child: Text('No posts yet'));
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 12),
          itemCount: posts.length,
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          cacheExtent: 2000,
          itemBuilder: (context, index) {
            final post = posts[index];
            return _InstagramPostCard(post: post);
          },
        );
      },
    );
  }
}

class _InstagramPostCard extends StatelessWidget {
  final dynamic post;
  const _InstagramPostCard({required this.post});

  @override
  Widget build(BuildContext context) {
    final mediaType = (post['mediaType'] ?? '').toString().toLowerCase();
    final isImage = mediaType == 'image';
    final isVideo = mediaType == 'video';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.grey[200],
                backgroundImage: post['profileImageUrl'] != null && post['profileImageUrl'].isNotEmpty
                    ? NetworkImage(post['profileImageUrl'])
                    : null,
                child: (post['profileImageUrl'] == null || post['profileImageUrl'].isEmpty)
                    ? Icon(Icons.person, color: Colors.grey[600])
                    : null,
                radius: 22,
              ),
              const SizedBox(width: 12),
              Text(
                post['name'] ?? post['username'] ?? 'User',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
        ),
        // Media
        isImage
            ? Image.network(
                post['url'],
                width: double.infinity,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) => progress == null
                    ? child
                    : Container(
                        width: double.infinity,
                        height: 320,
                        color: Colors.grey[200],
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                errorBuilder: (context, error, stackTrace) => Container(
                  width: double.infinity,
                  height: 320,
                  color: Colors.grey[200],
                  child: const Icon(Icons.broken_image, size: 60, color: Colors.grey),
                ),
              )
            : isVideo
                ? _FeedVideoPlayerWithFallback(url: post['url'])
                : Container(height: 320, width: double.infinity, color: Colors.grey[200]),
        // Like/Comment/Time Row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.favorite_border, size: 26, color: Colors.grey[700]),
              const SizedBox(width: 18),
              Icon(Icons.mode_comment_outlined, size: 26, color: Colors.grey[700]),
              const Spacer(),
              Text(
                _formatPostTime(post['createdAt']),
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ],
          ),
        ),
        // Description
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(
            post['description'] ?? '',
            style: const TextStyle(fontSize: 15),
          ),
        ),
        const SizedBox(height: 8),
      ],
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
    final brandColor = Color(0xFF4267B2);
    return Scaffold(
      appBar: AppBar(
        title: Text('Search Users', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _controller,
              onChanged: _search,
              decoration: InputDecoration(
                hintText: 'Search by name or username',
                prefixIcon: Icon(Icons.search, color: brandColor),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (_error.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(_error, style: TextStyle(color: Colors.red)),
            ),
          if (!_isLoading && _results.isEmpty && _controller.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text('No users found.', style: TextStyle(color: Colors.grey)),
            ),
          if (_results.isNotEmpty)
            Expanded(
              child: ListView.separated(
                itemCount: _results.length,
                separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey[200]),
                itemBuilder: (context, index) {
                  final user = _results[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: brandColor.withOpacity(0.1),
                      backgroundImage: user['profileImageUrl'] != null && user['profileImageUrl'].isNotEmpty
                          ? NetworkImage(user['profileImageUrl'])
                          : null,
                      child: (user['profileImageUrl'] == null || user['profileImageUrl'].isEmpty)
                          ? Text(
                              user['name'] != null && user['name'].isNotEmpty
                                  ? user['name'][0].toUpperCase()
                                  : 'N',
                              style: TextStyle(fontWeight: FontWeight.bold, color: brandColor),
                            )
                          : null,
                    ),
                    title: Text(user['name'] ?? '', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('@${user['username'] ?? ''}', style: TextStyle(color: Colors.black54)),
                    trailing: ElevatedButton(
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
                        backgroundColor: brandColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        padding: EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                        elevation: 0,
                      ),
                      child: Text('View', style: TextStyle(fontSize: 14)),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
} 