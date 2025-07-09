import 'package:flutter/material.dart';
import '../../services/user_service.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';
import 'edit_profile_screen.dart';
import '../../models/user_model.dart';
import 'portfolio_screen.dart'; // Added import for PortfolioScreen

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  Map<String, dynamic>? userProfile;
  List<dynamic> portfolioPosts = [];
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
      final posts = await UserService.fetchMedia();
      if (!mounted) return;
      final newCategories = _extractCategories(posts);
      // Only recreate TabController if needed
      if (_tabController == null || _tabController!.length != 2) {
        _tabController?.dispose();
        _tabController = TabController(length: 2, vsync: this);
      }
      setState(() {
        userProfile = profile;
        portfolioPosts = posts;
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(56),
        child: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.more_vert, color: Colors.black),
              onPressed: () {},
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
                _buildStatColumn("Posts", portfolioPosts.length.toString()),
                _verticalDivider(),
                _buildStatColumn("Followers", "0"),
                _verticalDivider(),
                _buildStatColumn("Following", "0"),
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
                Tab(icon: Icon(Icons.star_border)),
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
    if (portfolioPosts.isEmpty) {
      return Center(child: Text('No posts yet'));
    }
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: portfolioPosts.length,
      itemBuilder: (context, index) {
        final post = portfolioPosts[index];
        return Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          elevation: 2,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: post['imageUrl'] != null
                ? Image.network(post['imageUrl'], fit: BoxFit.cover)
                : Container(color: brandColor.withOpacity(0.08)),
          ),
        );
      },
    );
  }

  Widget _buildPortfolioGrid(String category) {
    final posts = category == 'All'
        ? portfolioPosts
        : portfolioPosts.where((p) => p['category'] == category).toList();

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
    if (categories.isEmpty) {
      return Center(child: Text('No portfolios yet'));
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      itemCount: categories.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final category = categories[index];
        return ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          tileColor: Colors.white,
          leading: const Icon(Icons.folder_open, color: Color(0xFF6C63FF)),
          title: Text(category, style: const TextStyle(fontWeight: FontWeight.w600)),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PortfolioScreen(
                  user: AppUser.fromMap(userProfile!),
                  // You may want to pass the category as well if PortfolioScreen supports it
                ),
              ),
            );
          },
        );
      },
    );
  }
}