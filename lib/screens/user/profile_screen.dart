import 'package:flutter/material.dart';
import '../../services/user_service.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';
import 'edit_profile_screen.dart';
import '../../models/user_model.dart';
import 'portfolio_screen.dart'; // Added import for PortfolioScreen
import '../../constants/categories.dart';
import 'package:video_player/video_player.dart';
import 'user_posts_feed_screen.dart';
import '../../widgets/main_bottom_nav_bar.dart';
import 'home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

final GlobalKey<_ProfileScreenState> profileScreenKey = GlobalKey<_ProfileScreenState>();

class ProfileScreen extends StatefulWidget {
  ProfileScreen({Key? key}) : super(key: profileScreenKey);
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  Map<String, dynamic>? userProfile;
  List<dynamic> allPosts = [];
  TabController? _tabController;
  List<String> categories = [];
  bool _hasError = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    loadProfileAndPosts();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> loadProfileAndPosts() async {
    try {
      final profile = await UserService.fetchUserProfile();
      final posts = await UserService.fetchPosts();
      if (!mounted) return;
      final newCategories = _extractCategories(posts);
      if (_tabController == null || _tabController!.length != 2) {
        _tabController?.dispose();
        _tabController = TabController(length: 2, vsync: this);
      }
      setState(() {
        userProfile = profile;
        allPosts = posts;
        categories = newCategories;
        _hasError = false;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  List<String> _extractCategories(List<dynamic> posts) {
    final Set<String> cats = {};
    for (var post in posts) {
      if (post['category'] != null) cats.add(post['category']);
    }
    return cats.toList();
  }

  void _logout() async {
    await AuthService().signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  void _editProfile() async {
    final updated = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(
          user: AppUser.fromMap(userProfile!),
        ),
      ),
    );
    if (updated == true) {
      await loadProfileAndPosts();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }
    if (_hasError) {
      return Center(child: Text('Failed to load profile. Please try again.'));
    }
    if (userProfile == null || _tabController == null) {
      return Center(child: Text('No profile data.'));
    }
    final brandColor = Color(0xFF4267B2); // Modern blue
    // Debug print for profile image URL
    print('Profile image URL:  [32m${userProfile!["profileImageUrl"]} [0m');
    // Only show follower/following counts if this is the logged-in user's profile
    final isOwnProfile = true; // This screen is only for the logged-in user
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(56),
        child: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false,
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.black),
              onSelected: (value) {
                if (value == 'logout') {
                  _logout();
                } else if (value == 'add_categories') {
                  _showAddCategoriesDialog();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'add_categories',
                  child: Text('Add Categories'),
                ),
                const PopupMenuItem(
                  value: 'logout',
                  child: Text('Logout'),
                ),
              ],
            ),
          ],
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Container(
              color: Colors.grey.shade200,
              height: 1,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),
            Center(
              child: CircleAvatar(
                radius: 44,
                backgroundColor: brandColor.withOpacity(0.1),
                child: (userProfile!["profileImageUrl"] == null || userProfile!["profileImageUrl"].isEmpty)
                    ? Text(
                        userProfile!["name"] != null && userProfile!["name"].isNotEmpty
                            ? userProfile!["name"][0].toUpperCase()
                            : "N",
                        style: TextStyle(fontSize: 40, color: brandColor, fontWeight: FontWeight.bold),
                      )
                    : ClipOval(
                        child: Image.network(
                          userProfile!["profileImageUrl"],
                          width: 88,
                          height: 88,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 88,
                              height: 88,
                              color: brandColor.withOpacity(0.1),
                              child: Icon(Icons.broken_image, color: brandColor, size: 40),
                            );
                          },
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                userProfile!["name"] ?? '',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.black),
              ),
            ),
            Center(
              child: Text(
                "@${userProfile!["username"] ?? "username"}",
                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15, color: Colors.black54),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStatColumn("Posts", allPosts.length.toString()),
                if (isOwnProfile) ...[
                  _verticalDivider(),
                  _buildStatColumn("Followers", (userProfile!["followerCount"] ?? 0).toString()),
                  _verticalDivider(),
                  _buildStatColumn("Following", (userProfile!["followingCount"] ?? 0).toString()),
                ],
              ],
            ),
            const SizedBox(height: 12),
            if (userProfile!["bio"] != null && userProfile!["bio"].toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Text(
                  userProfile!["bio"],
                  style: const TextStyle(fontSize: 15, color: Colors.black87),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _editProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TabBar(
              controller: _tabController!,
              indicatorColor: brandColor,
              indicatorWeight: 3,
              labelColor: brandColor,
              unselectedLabelColor: Colors.black26,
              tabs: const [
                Tab(icon: Icon(Icons.grid_on)),
                Tab(icon: Icon(Icons.category)),
              ],
            ),
            SizedBox(
              height: 420, // Fixed height for grid, adjust as needed
              child: TabBarView(
                controller: _tabController!,
                children: [
                  _buildProfileGrid(brandColor),
                  _buildPortfolioCategoryList(),
                ],
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

  Widget _verticalDivider() {
    return Container(
      height: 28,
      width: 1.5,
      color: Colors.grey.shade300,
      margin: const EdgeInsets.symmetric(horizontal: 18),
    );
  }

  Widget _buildProfileGrid(Color brandColor) {
    if (allPosts.isEmpty) {
      return Center(child: Text('No posts yet'));
    }
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: allPosts.length,
      itemBuilder: (context, index) {
        final post = allPosts[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => UserPostsFeedScreen(
                  posts: allPosts,
                  initialPostId: post['_id'],
                ),
              ),
            );
          },
          child: _buildPostGridCard(post, brandColor),
        );
      },
    );
  }

  Widget _buildPostGridCard(dynamic post, Color brandColor) {
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
        return Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          elevation: 2,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                isImage
                    ? Image.network(post['url'], fit: BoxFit.cover, width: double.infinity, height: double.infinity)
                    : isVideo
                        ? _VideoGridPreview(url: post['url'])
                        : Container(color: brandColor.withOpacity(0.08)),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    color: Colors.black.withOpacity(0.5),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: _toggleLike,
                          child: Row(
                            children: [
                              Icon(
                                isLiked ? Icons.favorite : Icons.favorite_border,
                                size: 18,
                                color: isLiked ? Colors.pinkAccent : Colors.white,
                              ),
                              const SizedBox(width: 2),
                              Text('${post['likes'] ?? 0}', style: const TextStyle(color: Colors.white, fontSize: 12)),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Text(
                          post['description'] ?? '',
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPortfolioGrid(String category) {
    final posts = category == 'All'
        ? allPosts
        : allPosts.where((p) => p['category'] == category).toList();

    if (posts.isEmpty) {
      return _buildEmptyState(category);
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.8,
        ),
        itemCount: posts.length,
        itemBuilder: (context, index) {
          return _buildPortfolioCard(posts[index]);
        },
      ),
    );
  }

  Widget _buildPortfolioCard(dynamic post) {
    return GestureDetector(
      onTap: () => _showPostDetails(post),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  image: DecorationImage(
                    image: NetworkImage(post['imageUrl']),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Stack(
                  children: [
                    // Category Badge
                    if (post['category'] != null)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            post['category'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // Content Section
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post['title'] ?? '',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      post['description'] ?? '',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6C7B7F),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String category) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFF6C63FF).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.photo_library_outlined,
              size: 60,
              color: Color(0xFF6C63FF),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No posts in $category yet',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Start sharing your work to build your portfolio',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF6C7B7F),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showPostDetails(dynamic post) {
    // Implement as needed
  }

  Widget _buildPortfolioCategoryList() {
    final registeredCategories = List<String>.from(userProfile?['categories'] ?? []);
    if (registeredCategories.isEmpty) {
      return Center(child: Text('No portfolios yet'));
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      itemCount: registeredCategories.length,
      separatorBuilder: (context, index) => const SizedBox(height: 18),
      itemBuilder: (context, index) {
        final category = registeredCategories[index];
        return InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () async {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => _buildAttractivePortfolioModal(category),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.85),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Color(0xFFE0E0E0), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: ListTile(
              leading: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.10),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(8),
                child: Icon(Icons.folder_special_rounded, color: Color(0xFF4FC3F7), size: 28),
              ),
              title: Text(
                category,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Color(0xFF263238),
                  letterSpacing: 0.5,
                ),
              ),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFB0BEC5), size: 20),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAttractivePortfolioModal(String category) {
    return FutureBuilder<List<dynamic>>(
      future: UserService.fetchPostsByCategory(category),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final posts = snapshot.data ?? [];
        return Container(
          height: MediaQuery.of(context).size.height * 0.82,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            color: Colors.white.withOpacity(0.95),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.10),
                blurRadius: 32,
                offset: Offset(0, 12),
              ),
            ],
            border: Border.all(color: Color(0xFFE0E0E0), width: 1.2),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.folder_special_rounded, color: Color(0xFF4FC3F7), size: 28),
                        const SizedBox(width: 10),
                        Text(
                          '$category Portfolio',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                            color: Color(0xFF263238),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Color(0xFFB0BEC5)),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: posts.isEmpty
                    ? _buildEmptyState(category)
                    : GridView.builder(
                        padding: const EdgeInsets.all(18),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 18,
                          mainAxisSpacing: 18,
                          childAspectRatio: 0.78,
                        ),
                        itemCount: posts.length,
                        itemBuilder: (context, idx) => _buildAttractivePortfolioCard(posts[idx]),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAttractivePortfolioCard(dynamic post) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: Colors.white.withOpacity(0.92),
        border: Border.all(color: Color(0xFFE0E0E0), width: 1.1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () => _showPostDetails(post),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                child: post['mediaType'] == 'image'
                    ? Image.network(post['url'], height: 120, width: double.infinity, fit: BoxFit.cover)
                    : Container(
                        height: 120,
                        width: double.infinity,
                        color: Color(0xFFB0BEC5).withOpacity(0.12),
                        child: Icon(Icons.videocam_rounded, color: Color(0xFF4FC3F7), size: 48),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Color(0xFF4FC3F7).withOpacity(0.10),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            post['category'] ?? '',
                            style: const TextStyle(
                              color: Color(0xFF4FC3F7),
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Icon(Icons.favorite, color: Colors.pinkAccent, size: 16),
                        const SizedBox(width: 4),
                        Text('${post['likes'] ?? 0}', style: TextStyle(color: Color(0xFF263238), fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      post['title'] ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF263238),
                        letterSpacing: 0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      post['description'] ?? '',
                      style: const TextStyle(
                        color: Color(0xFF607D8B),
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddCategoriesDialog() async {
    final currentCategories = List<String>.from(userProfile?["categories"] ?? []);
    final availableCategories = skillCategories.where((cat) => !currentCategories.contains(cat)).toList();
    List<String> selected = [];
    if (availableCategories.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('No More Categories'),
          content: const Text('You have already added all available categories.'),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
        ),
      );
      return;
    }
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add Categories'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView(
                  shrinkWrap: true,
                  children: availableCategories.map((cat) {
                    return CheckboxListTile(
                      title: Text(cat),
                      value: selected.contains(cat),
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            selected.add(cat);
                          } else {
                            selected.remove(cat);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: selected.isEmpty
                      ? null
                      : () async {
                          final updatedCategories = [...currentCategories, ...selected];
                          // Save to backend
                          await UserService.saveUserProfile(
                            userProfile!["name"],
                            userProfile!["email"],
                            userProfile!["profileImageUrl"],
                            updatedCategories,
                            userProfile!["username"],
                            userProfile!["bio"],
                          );
                          // Refresh profile from backend
                          await loadProfileAndPosts();
                          Navigator.pop(context);
                        },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class PublicProfileScreen extends StatefulWidget {
  final String uid;
  const PublicProfileScreen({Key? key, required this.uid}) : super(key: key);

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> with SingleTickerProviderStateMixin {
  Map<String, dynamic>? userProfile;
  List<dynamic> allPosts = [];
  TabController? _tabController;
  bool isLoading = true;
  bool isError = false;
  bool isFollowing = false;
  int _selectedIndex = -1; // -1 means not from navbar

  @override
  void initState() {
    super.initState();
    loadProfileAndPosts();
  }

  Future<void> loadProfileAndPosts() async {
    try {
      final profile = await UserService.fetchPublicProfile(widget.uid);
      final posts = await UserService.fetchPostsForUser(widget.uid);
      // Check if the current user is following this user
      final currentUser = await UserService.fetchUserProfile();
      final followingList = currentUser != null && currentUser['following'] != null
          ? List<String>.from(currentUser['following'])
          : <String>[];
      final isUserFollowing = followingList.contains(widget.uid);
      if (!mounted) return;
      if (_tabController == null || _tabController!.length != 2) {
        _tabController?.dispose();
        _tabController = TabController(length: 2, vsync: this);
      }
      setState(() {
        userProfile = profile;
        allPosts = posts;
        isFollowing = isUserFollowing;
        isError = false;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isError = true;
        isLoading = false;
      });
    }
  }

  Future<void> _toggleFollow() async {
    setState(() { isLoading = true; });
    bool success;
    if (isFollowing) {
      success = await UserService.unfollowUser(widget.uid);
    } else {
      success = await UserService.followUser(widget.uid);
    }
    if (success) {
      setState(() {
        isFollowing = !isFollowing;
        // Update follower count in UI
        if (userProfile != null) {
          int count = userProfile!["followerCount"] ?? 0;
          userProfile!["followerCount"] = isFollowing ? count + 1 : (count - 1).clamp(0, 999999);
        }
        isLoading = false;
      });
      // Do NOT pop the screen
      return;
    }
    setState(() { isLoading = false; });
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  void _onNavTap(int index) {
    // Pop to root and pass the tab index to HomeScreen
    Navigator.of(context).popUntil((route) => route.isFirst);
    Future.delayed(Duration.zero, () {
      HomeScreen.switchToTab(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final brandColor = Color(0xFF4267B2);
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Profile'), backgroundColor: Colors.white, elevation: 0, iconTheme: IconThemeData(color: Colors.black)),
        body: Center(child: CircularProgressIndicator()),
        bottomNavigationBar: MainBottomNavBar(currentIndex: 4, onTap: _onNavTap),
      );
    }
    if (isError || userProfile == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Profile'), backgroundColor: Colors.white, elevation: 0, iconTheme: IconThemeData(color: Colors.black)),
        body: Center(child: Text('Failed to load profile.')),
        bottomNavigationBar: MainBottomNavBar(currentIndex: 4, onTap: _onNavTap),
      );
    }
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(userProfile!["name"] ?? ''),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),
            Center(
              child: CircleAvatar(
                radius: 44,
                backgroundColor: brandColor.withOpacity(0.1),
                child: (userProfile!["profileImageUrl"] == null || userProfile!["profileImageUrl"].isEmpty)
                    ? Text(
                        userProfile!["name"] != null && userProfile!["name"].isNotEmpty
                            ? userProfile!["name"][0].toUpperCase()
                            : "N",
                        style: TextStyle(fontSize: 40, color: brandColor, fontWeight: FontWeight.bold),
                      )
                    : ClipOval(
                        child: Image.network(
                          userProfile!["profileImageUrl"],
                          width: 88,
                          height: 88,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 88,
                              height: 88,
                              color: brandColor.withOpacity(0.1),
                              child: Icon(Icons.broken_image, color: brandColor, size: 40),
                            );
                          },
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                userProfile!["name"] ?? '',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.black),
              ),
            ),
            Center(
              child: Text(
                "@${userProfile!["username"] ?? "username"}",
                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15, color: Colors.black54),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStatColumn("Posts", allPosts.length.toString()),
                // Remove follower/following counts for public profile
                // _verticalDivider(),
                // _buildStatColumn("Followers", (userProfile!["followerCount"] ?? 0).toString()),
                // _verticalDivider(),
                // _buildStatColumn("Following", (userProfile!["followingCount"] ?? 0).toString()),
              ],
            ),
            const SizedBox(height: 12),
            if (userProfile!["bio"] != null && userProfile!["bio"].toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Text(
                  userProfile!["bio"],
                  style: const TextStyle(fontSize: 15, color: Colors.black87),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: isLoading ? null : _toggleFollow,
              style: ElevatedButton.styleFrom(
                backgroundColor: isFollowing ? Colors.grey[300] : brandColor,
                foregroundColor: isFollowing ? Colors.black : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: Text(isFollowing ? 'Unfollow' : 'Follow', style: const TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 16),
            TabBar(
              controller: _tabController!,
              indicatorColor: brandColor,
              indicatorWeight: 3,
              labelColor: brandColor,
              unselectedLabelColor: Colors.black26,
              tabs: const [
                Tab(icon: Icon(Icons.grid_on)),
                Tab(icon: Icon(Icons.category)),
              ],
            ),
            SizedBox(
              height: 420,
              child: TabBarView(
                controller: _tabController!,
                children: [
                  _buildProfileGrid(brandColor),
                  _buildPortfolioCategoryList(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: MainBottomNavBar(currentIndex: 4, onTap: _onNavTap),
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

  Widget _verticalDivider() {
    return Container(
      height: 28,
      width: 1.5,
      color: Colors.grey.shade300,
      margin: const EdgeInsets.symmetric(horizontal: 18),
    );
  }

  Widget _buildProfileGrid(Color brandColor) {
    if (allPosts.isEmpty) {
      return Center(child: Text('No posts yet'));
    }
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: allPosts.length,
      itemBuilder: (context, index) {
        final post = allPosts[index];
        return _buildPostGridCard(post, brandColor);
      },
    );
  }

  Widget _buildPostGridCard(dynamic post, Color brandColor) {
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
        return Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          elevation: 2,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                isImage
                    ? Image.network(post['url'], fit: BoxFit.cover, width: double.infinity, height: double.infinity)
                    : isVideo
                        ? _VideoGridPreview(url: post['url'])
                        : Container(color: brandColor.withOpacity(0.08)),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    color: Colors.black.withOpacity(0.5),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: _toggleLike,
                          child: Row(
                            children: [
                              Icon(
                                isLiked ? Icons.favorite : Icons.favorite_border,
                                size: 18,
                                color: isLiked ? Colors.pinkAccent : Colors.white,
                              ),
                              const SizedBox(width: 2),
                              Text('${post['likes'] ?? 0}', style: const TextStyle(color: Colors.white, fontSize: 12)),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Text(
                          post['description'] ?? '',
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPortfolioCategoryList() {
    // You can implement this similar to your own profile, or show a message
    return Center(child: Text('Portfolio categories coming soon...'));
  }
}

class _VideoGridPreview extends StatefulWidget {
  final String url;
  const _VideoGridPreview({required this.url});
  @override
  State<_VideoGridPreview> createState() => _VideoGridPreviewState();
}

class _VideoGridPreviewState extends State<_VideoGridPreview> {
  late VideoPlayerController _controller;
  bool _initialized = false;

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
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _initialized
        ? AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: VideoPlayer(_controller),
          )
        : Container(color: Colors.black12);
  }
}