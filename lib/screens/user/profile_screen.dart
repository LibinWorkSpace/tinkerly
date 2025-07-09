import 'package:flutter/material.dart';
import 'package:tinkerly/models/user_model.dart';
import 'package:tinkerly/screens/user/edit_profile_screen.dart';
import 'package:tinkerly/services/user_service.dart';
import 'package:tinkerly/services/auth_service.dart';
import 'package:tinkerly/screens/auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final AppUser user;
  const ProfileScreen({super.key, required this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTab = 0;
  late AppUser _currentUser;

  // Mock posts and portfolios
  final List<Map<String, dynamic>> posts = List.generate(10, (i) => {
    'id': i,
    'image': 'https://picsum.photos/seed/$i/200',
    'category': i % 2 == 0 ? 'Drawing' : 'Music',
    'title': 'Post $i',
  });
  final List<Map<String, dynamic>> portfolios = [
    {
      'name': 'Music',
      'badge': '🎵',
      'description': 'All my music works',
      'posts': [1, 3, 5, 7, 9],
    },
    {
      'name': 'Drawing',
      'badge': '🎨',
      'description': 'Sketches and digital art',
      'posts': [0, 2, 4, 6, 8],
    },
    {
      'name': 'Art works',
      'badge': '🖼️',
      'description': 'Other creative works',
      'posts': [2, 5, 8],
    },
  ];

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTab = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refreshUserData() async {
    final updatedUser = await UserService.getUserByUid(_currentUser.uid);
    if (updatedUser != null && mounted) {
      setState(() {
        _currentUser = updatedUser;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = const Color(0xFF6C63FF); // Use your login accent color
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Profile Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Pic
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: accentColor.withOpacity(0.1),
                    backgroundImage: _currentUser.profileImageUrl != null ? NetworkImage(_currentUser.profileImageUrl!) : null,
                    child: _currentUser.profileImageUrl == null
                        ? Text(
                            _currentUser.name.isNotEmpty ? _currentUser.name[0].toUpperCase() : '?',
                            style: TextStyle(fontSize: 32, color: accentColor, fontWeight: FontWeight.bold),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  // Name and stats
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Username
                        Text(
                          '@${_currentUser.username}',
                          style: TextStyle(color: Colors.grey[600], fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        // Name
                        Text(
                          _currentUser.name,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _currentUser.bio ?? '',
                          style: TextStyle(color: Colors.grey[700], fontSize: 14),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 36,
                          child: ElevatedButton(
                            onPressed: () async {
                              final updatedUser = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => EditProfileScreen(user: _currentUser),
                                ),
                              );
                              if (updatedUser != null && mounted) {
                                setState(() {
                                  _currentUser = updatedUser;
                                });
                                // Also refresh from Firestore to ensure consistency
                                await _refreshUserData();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.yellow,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            child: const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Logout menu button
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) async {
                      if (value == 'logout') {
                        await AuthService().signOut();
                        if (mounted) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                            (route) => false,
                          );
                        }
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem<String>(
                        value: 'logout',
                        child: Row(
                          children: [
                            Icon(Icons.logout, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Logout'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Tab Bar
            Container(
              color: Colors.grey[100],
              child: TabBar(
                controller: _tabController,
                indicatorColor: accentColor,
                labelColor: accentColor,
                unselectedLabelColor: Colors.grey[500],
                tabs: const [
                  Tab(icon: Icon(Icons.grid_on)),
                  Tab(icon: Icon(Icons.folder_special)),
                ],
              ),
            ),
            // Tab Views
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshUserData,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Posts Grid
                    _buildPostsGrid(posts, accentColor),
                    // Portfolios List
                    _buildPortfoliosList(accentColor),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostsGrid(List<Map<String, dynamic>> posts, Color accentColor) {
    if (posts.isEmpty) {
      return Center(
        child: Text('No posts yet', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: posts.length,
      itemBuilder: (context, i) {
        return GestureDetector(
          onTap: () {}, // Open post detail
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: accentColor.withOpacity(0.08),
              image: DecorationImage(
                image: NetworkImage(posts[i]['image']),
                fit: BoxFit.cover,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPortfoliosList(Color accentColor) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: portfolios.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final p = portfolios[i];
        return ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          tileColor: Colors.grey[100],
          leading: CircleAvatar(
            backgroundColor: accentColor.withOpacity(0.15),
            child: Text(p['badge'], style: const TextStyle(fontSize: 20)),
          ),
          title: Text(p['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(p['description'], maxLines: 1, overflow: TextOverflow.ellipsis),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PortfolioDetailPage(
                  portfolio: p,
                  posts: posts.where((post) => p['posts'].contains(post['id'])).toList(),
                  accentColor: accentColor,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class PortfolioDetailPage extends StatelessWidget {
  final Map<String, dynamic> portfolio;
  final List<Map<String, dynamic>> posts;
  final Color accentColor;
  const PortfolioDetailPage({super.key, required this.portfolio, required this.posts, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: accentColor),
        title: Text(portfolio['name'], style: TextStyle(color: accentColor, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: accentColor.withOpacity(0.15),
                  child: Text(portfolio['badge'], style: const TextStyle(fontSize: 20)),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(portfolio['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    Text('${posts.length} posts', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              portfolio['description'],
              style: TextStyle(color: Colors.grey[700], fontSize: 15),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: posts.isEmpty
                ? Center(child: Text('No posts in this portfolio', style: TextStyle(color: Colors.grey[600], fontSize: 16)))
                : GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: posts.length,
                    itemBuilder: (context, i) {
                      return Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: accentColor.withOpacity(0.08),
                          image: DecorationImage(
                            image: NetworkImage(posts[i]['image']),
                            fit: BoxFit.cover,
                          ),
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