import 'package:flutter/material.dart';
import '../../services/user_service.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';
import '../auth/phone_verification_screen.dart';
import 'edit_profile_screen.dart';
import '../../models/user_model.dart';
import 'package:video_player/video_player.dart';
import 'post_details_screen.dart';
import '../../widgets/main_bottom_nav_bar.dart';
import 'home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth/set_password_screen.dart'; // Added import for SetPasswordScreen

import '../auth/phone_status_screen.dart'; // Added import for PhoneStatusScreen
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/music_portfolio_widget.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../constants/categories.dart';
import '../../services/portfolio_service.dart';
import 'portfolio_profile_screen.dart';
import 'edit_portfolio_screen.dart';

final GlobalKey<_ProfileScreenState> profileScreenKey = GlobalKey<_ProfileScreenState>();

class ProfileScreen extends StatefulWidget {
  ProfileScreen({Key? key}) : super(key: profileScreenKey);
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
  
  // Static method to refresh portfolios from outside
  static Future<void> refreshPortfoliosFromOutside() async {
    final state = profileScreenKey.currentState;
    if (state != null) {
      await state.refreshPortfolios();
      await state.ensurePortfoliosExist();
    }
  }
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  Map<String, dynamic>? userProfile;
  List<dynamic> allPosts = [];
  List<dynamic> portfolios = [];
  TabController? _tabController;
  List<String> categories = [];
  bool _hasError = false;
  bool _isLoading = true;
  String? _selectedPortfolioId;

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
  
  // Method to refresh portfolios specifically
  Future<void> refreshPortfolios() async {
    if (userProfile != null) {
      try {
        final userId = userProfile!["uid"];
        if (userId != null) {
          final fetchedPortfolios = await PortfolioService.fetchUserPortfolios(userId);
          print('Refreshed portfolios count: ${fetchedPortfolios.length}');
          if (mounted) {
            setState(() {
              portfolios = fetchedPortfolios;
            });
          }
        }
      } catch (e) {
        print('Error refreshing portfolios: $e');
      }
    }
  }
  
  // Method to ensure portfolios exist for all user categories
  Future<void> ensurePortfoliosExist() async {
    if (userProfile != null) {
      try {
        final userId = userProfile!["uid"];
        final userCategories = List<String>.from(userProfile!["categories"] ?? []);
        
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
            await refreshPortfolios();
          }
        }
      } catch (e) {
        print('Error ensuring portfolios exist: $e');
      }
    }
  }

  Future<void> loadProfileAndPosts() async {
    try {
      final profile = await UserService.fetchUserProfile();
      final posts = await UserService.fetchPosts();
      final userId = profile?["uid"]; // Use uid directly since that's what the backend returns
      print('Profile userId: $userId'); // Debug log
      
      final fetchedPortfolios = userId != null ? await PortfolioService.fetchUserPortfolios(userId) : [];
      print('Fetched portfolios count: ${fetchedPortfolios.length}'); // Debug log
      
      if (!mounted) return;
      final newCategories = _extractCategories(posts);
      if (_tabController == null || _tabController!.length != 2) {
        _tabController?.dispose();
        _tabController = TabController(length: 2, vsync: this);
      }
      setState(() {
        userProfile = profile;
        allPosts = posts;
        portfolios = fetchedPortfolios;
        categories = newCategories;
        _hasError = false;
        _isLoading = false;
      });
      
      // Ensure portfolios exist for all user categories
      await ensurePortfoliosExist();
      
    } catch (e) {
      print('Error loading profile and posts: $e'); // Debug log
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
      print('Profile updated, refreshing data...'); // Debug log
      await loadProfileAndPosts();
      // Wait a bit for portfolios to be created, then refresh
      await Future.delayed(Duration(milliseconds: 500));
      await refreshPortfolios();
    }
  }

  void _verifyPhone() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const PhoneVerificationScreen(),
      ),
    );
    if (result == true) {
      await loadProfileAndPosts();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Color(0xFFFAFAFA),
        body: Center(
          child: Container(
            padding: EdgeInsets.all(24),
            margin: EdgeInsets.all(24),
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
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6C63FF)),
                ),
                const SizedBox(height: 16),
                Text(
                  'Loading your profile...',
                  style: GoogleFonts.poppins(
                    color: Color(0xFF2D3748),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    if (_hasError) {
      return Scaffold(
        backgroundColor: Color(0xFFFAFAFA),
        body: Center(
          child: Container(
            padding: EdgeInsets.all(24),
            margin: EdgeInsets.all(24),
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
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Failed to load profile',
                  style: GoogleFonts.poppins(
                    color: Colors.red,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please try again',
                  style: GoogleFonts.poppins(
                    color: Colors.red.withAlpha((0.8 * 255).toInt()),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    if (userProfile == null || _tabController == null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF667EEA),
                Color(0xFF764BA2),
                Color(0xFFF093FB),
                Color(0xFFF5576C),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: [0.0, 0.3, 0.7, 1.0],
            ),
          ),
          child: Center(
            child: Container(
              padding: EdgeInsets.all(24),
              margin: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha((0.1 * 255).toInt()),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withAlpha((0.2 * 255).toInt()),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.person_outline, color: Colors.white.withAlpha((0.7 * 255).toInt()), size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'No profile data',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    
    final primaryColor = Color(0xFF6C63FF);
    final secondaryColor = Color(0xFFFF6B9D);
    // Only show follower/following counts if this is the logged-in user's profile
    final isOwnProfile = true; // This screen is only for the logged-in user
    final bool phoneNotVerified = userProfile!["isPhoneVerified"] != true;
    return Scaffold(
      backgroundColor: Color(0xFFFAFAFA),
      body: Container(
        color: Color(0xFFFAFAFA),
        child: SafeArea(
          child: Column(
            children: [
              // Custom App Bar
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha((0.05 * 255).toInt()),
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [primaryColor, secondaryColor],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withAlpha((0.3 * 255).toInt()),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(Icons.person, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'My Profile',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    Spacer(),
                    Container(
                      decoration: BoxDecoration(
                        color: Color(0xFFF7FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Color(0xFFE2E8F0),
                          width: 1,
                        ),
                      ),
                      child: PopupMenuButton<String>(
                        icon: Stack(
                          children: [
                            Icon(Icons.more_vert, color: Color(0xFF6C63FF)),
                            if (phoneNotVerified)
                              Positioned(
                                right: 0,
                                top: 0,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        onSelected: (value) {
                          if (value == 'logout') {
                            _logout();
                          } else if (value == 'add_categories') {
                            _showAddCategoriesDialog();
                          } else if (value == 'set_password') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const SetPasswordScreen()),
                            );
                          } else if (value == 'verify_phone') {
                            if (userProfile!["isPhoneVerified"] == true) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PhoneStatusScreen(
                                    currentPhone: userProfile!["phone"],
                                    isVerified: true,
                                  ),
                                ),
                              ).then((changed) {
                                if (changed == true) loadProfileAndPosts();
                              });
                            } else {
                              _verifyPhone();
                            }
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'add_categories',
                            child: Row(
                              children: [
                                Icon(Icons.category, color: primaryColor, size: 18),
                                const SizedBox(width: 8),
                                Text('Add Categories'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'verify_phone',
                            child: Row(
                              children: [
                                Icon(
                                  phoneNotVerified ? Icons.phone_disabled : Icons.verified,
                                  color: phoneNotVerified ? Colors.red : Colors.green,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text('Verify Phone'),
                                if (phoneNotVerified) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'set_password',
                            child: Row(
                              children: [
                                Icon(Icons.lock, color: primaryColor, size: 18),
                                const SizedBox(width: 8),
                                Text('Set Password'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'logout',
                            child: Row(
                              children: [
                                Icon(Icons.logout, color: Colors.red, size: 18),
                                const SizedBox(width: 8),
                                Text('Logout'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms),
              
              // Main Profile Content
              Expanded(
                child: SingleChildScrollView(
                  physics: BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      
                      // Profile Header Card
                      Container(
                        margin: EdgeInsets.symmetric(horizontal: 16),
                        padding: EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withAlpha((0.2 * 255).toInt()),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha((0.1 * 255).toInt()),
                              blurRadius: 20,
                              spreadRadius: 0,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Profile Image
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withAlpha((0.3 * 255).toInt()),
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryColor.withAlpha((0.3 * 255).toInt()),
                                    blurRadius: 20,
                                    spreadRadius: 0,
                                    offset: Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 50,
                                backgroundColor: Colors.white.withAlpha((0.2 * 255).toInt()),
                                child: (userProfile!["profileImageUrl"] == null || (userProfile!["profileImageUrl"] ?? '').isEmpty)
                                    ? Text(
                                        userProfile!["name"] != null && userProfile!["name"].isNotEmpty
                                            ? userProfile!["name"][0].toUpperCase()
                                            : "N",
                                        style: GoogleFonts.poppins(
                                          fontSize: 36,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    : ClipOval(
                                        child: Image.network(
                                          userProfile!["profileImageUrl"] ?? '',
                                          width: 100,
                                          height: 100,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Container(
                                              width: 100,
                                              height: 100,
                                              color: Colors.white.withAlpha((0.2 * 255).toInt()),
                                              child: Icon(Icons.broken_image, color: Colors.white, size: 40),
                                            );
                                          },
                                        ),
                                      ),
                              ),
                            ).animate().scaleXY(begin: 0.8, end: 1.0, duration: 600.ms, curve: Curves.easeOutBack),
                            
                            const SizedBox(height: 20),
                            
                            // Name and Username
                            Text(
                              userProfile!["name"] ?? '',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                                color: Colors.black,
                              ),
                            ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
                            
                            const SizedBox(height: 4),
                            
                            Text(
                              "@${userProfile!["username"] ?? "username"}",
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
                                color: Colors.black.withAlpha((0.8 * 255).toInt()),
                              ),
                            ).animate().fadeIn(duration: 400.ms, delay: 300.ms),
                            
                            const SizedBox(height: 20),
                            
                            // Stats Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildStatColumn("Posts", allPosts.length.toString()),
                                if (isOwnProfile) ...[
                                  _buildStatColumn("Followers", (userProfile!["followerCount"] ?? 0).toString()),
                                  _buildStatColumn("Following", (userProfile!["followingCount"] ?? 0).toString()),
                                ],
                              ],
                            ).animate().fadeIn(duration: 400.ms, delay: 400.ms),
                            
                            // Bio
                            if (userProfile!["bio"] != null && (userProfile!["bio"] ?? '').isNotEmpty) ...[
                              const SizedBox(height: 20),
                              Container(
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha((0.1 * 255).toInt()),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withAlpha((0.2 * 255).toInt()),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  userProfile!["bio"],
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.black.withAlpha((0.9 * 255).toInt()),
                                    height: 1.4,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ).animate().fadeIn(duration: 400.ms, delay: 500.ms),
                            ],
                            
                            const SizedBox(height: 24),
                            
                            // Edit Profile Button
                            Container(
                              width: double.infinity,
                              height: 50,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [primaryColor, secondaryColor],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryColor.withAlpha((0.4 * 255).toInt()),
                                    blurRadius: 15,
                                    spreadRadius: 0,
                                    offset: Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: _editProfile,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.edit, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Edit Profile',
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ).animate().fadeIn(duration: 400.ms, delay: 600.ms),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Tabs Section
                      Container(
                        margin: EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha((0.15 * 255).toInt()),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withAlpha((0.2 * 255).toInt()),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha((0.1 * 255).toInt()),
                                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                              ),
                              child: TabBar(
                                controller: _tabController!,
                                indicator: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [primaryColor, secondaryColor],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                indicatorSize: TabBarIndicatorSize.tab,
                                indicatorPadding: EdgeInsets.all(8),
                                labelColor: Color(0xFF6C63FF),
                                unselectedLabelColor: Color(0xFF6C63FF).withAlpha(153),
                                tabs: [
                                  Tab(
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.grid_on, size: 20),
                                        const SizedBox(width: 8),
                                        Text('Posts', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                  ),
                                  Tab(
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.category, size: 20),
                                        const SizedBox(width: 8),
                                        Text('Portfolio', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.black)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              height: 400,
                              child: TabBarView(
                                controller: _tabController!,
                                children: [
                                  _buildProfileGrid(primaryColor),
                                  _buildPortfolioCategoryList(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 400.ms, delay: 700.ms),
                      
                      const SizedBox(height: 24),
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
    // Filter out audio posts - they should only appear in Portfolio section
    final nonAudioPosts = allPosts.where((post) => post['mediaType'] != 'audio').toList();

    if (nonAudioPosts.isEmpty) {
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
      itemCount: nonAudioPosts.length,
      itemBuilder: (context, index) {
        final post = nonAudioPosts[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PostDetailsScreen(
                  post: post,
                  allPosts: allPosts,
                ),
              ),
            );
          },
          child: buildPostGridCard(post, brandColor, null),
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
              color: Colors.black.withAlpha((0.05 * 255).toInt()),
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
                            color: Colors.black.withAlpha((0.7 * 255).toInt()),
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
              color: Color(0xFF6C63FF).withAlpha((0.1 * 255).toInt()),
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PostDetailsScreen(
          post: post,
          allPosts: allPosts,
        ),
      ),
    );
  }

  Widget _buildPortfolioCategoryList() {
    if (_selectedPortfolioId != null) {
      // Navigate to portfolio profile
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PortfolioProfileScreen(portfolioId: _selectedPortfolioId!),
          ),
        ).then((_) {
          setState(() {
            _selectedPortfolioId = null;
          });
        });
      });
      return SizedBox.shrink();
    }
    
    print('Building portfolio list with ${portfolios.length} portfolios'); // Debug log
    
    if (portfolios.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.category_outlined, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              'No portfolios yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Add categories to your profile to create portfolios',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      itemCount: portfolios.length,
      separatorBuilder: (context, index) => const SizedBox(height: 18),
      itemBuilder: (context, index) {
        final portfolio = portfolios[index];
        print('Portfolio ${index}: ${portfolio.category} (ID: ${portfolio.id})'); // Debug log
        return InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            setState(() {
              _selectedPortfolioId = portfolio.id;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withAlpha((0.85 * 255).toInt()),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Color(0xFFE0E0E0), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha((0.08 * 255).toInt()),
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
                      color: Colors.black.withAlpha((0.10 * 255).toInt()),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(8),
                child: portfolio.profileImageUrl != null && portfolio.profileImageUrl!.isNotEmpty
                    ? ClipOval(
                        child: Image.network(
                          portfolio.profileImageUrl!,
                          width: 28,
                          height: 28,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(Icons.folder_special_rounded, color: Color(0xFF4FC3F7), size: 28);
                          },
                        ),
                      )
                    : Icon(Icons.folder_special_rounded, color: Color(0xFF4FC3F7), size: 28),
              ),
              title: Text(
                portfolio.profilename,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Color(0xFF263238),
                  letterSpacing: 0.5,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    portfolio.category,
                    style: TextStyle(
                      color: Color(0xFF6C63FF),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (portfolio.description.isNotEmpty)
                    Text(
                      portfolio.description,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit, color: Color(0xFF6C63FF), size: 20),
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditPortfolioScreen(portfolio: portfolio),
                        ),
                      );
                      if (result == true) {
                        // Refresh portfolios after editing
                        await refreshPortfolios();
                      }
                    },
                  ),
                  Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFB0BEC5), size: 20),
                ],
              ),
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
            color: Colors.white.withAlpha((0.95 * 255).toInt()),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha((0.10 * 255).toInt()),
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
        color: Colors.white.withAlpha((0.92 * 255).toInt()),
        border: Border.all(color: Color(0xFFE0E0E0), width: 1.1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.10 * 255).toInt()),
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
                    : post['mediaType'] == 'video'
                        ? Container(
                            height: 120,
                            width: double.infinity,
                            color: Color(0xFFB0BEC5).withAlpha((0.12 * 255).toInt()),
                            child: Icon(Icons.videocam_rounded, color: Color(0xFF4FC3F7), size: 48),
                          )
                        : post['mediaType'] == 'audio'
                            ? Container(
                                height: 120,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Color(0xFF6C63FF).withOpacity(0.8), Color(0xFFFF6B9D).withOpacity(0.8)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: Icon(Icons.music_note, color: Colors.white, size: 48),
                              )
                            : Container(
                                height: 120,
                                width: double.infinity,
                                color: Color(0xFFB0BEC5).withAlpha((0.12 * 255).toInt()),
                                child: Icon(Icons.image, color: Colors.grey, size: 48),
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
                            color: Color(0xFF4FC3F7).withAlpha((0.10 * 255).toInt()),
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
                            userProfile!["name"] ?? '',
                            userProfile!["email"] ?? '',
                            userProfile!["profileImageUrl"] ?? '',
                            updatedCategories,
                            userProfile!["username"] ?? '',
                            userProfile!["bio"] ?? '',
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

// Extract a reusable profile header widget
class ProfileHeaderCard extends StatelessWidget {
  final Map<String, dynamic> userProfile;
  final int postCount;
  final bool showFollowStats;
  final int? followerCount;
  final int? followingCount;
  final String? buttonText;
  final VoidCallback? onButtonPressed;
  final bool isButtonLoading;
  final bool showButton;

  const ProfileHeaderCard({
    required this.userProfile,
    required this.postCount,
    this.showFollowStats = true,
    this.followerCount,
    this.followingCount,
    this.buttonText,
    this.onButtonPressed,
    this.isButtonLoading = false,
    this.showButton = false,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final primaryColor = Color(0xFF6C63FF);
    final secondaryColor = Color(0xFFFF6B9D);
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withAlpha((0.2 * 255).toInt()),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.1 * 255).toInt()),
            blurRadius: 20,
            spreadRadius: 0,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Profile Image
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withAlpha((0.3 * 255).toInt()),
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withAlpha((0.3 * 255).toInt()),
                  blurRadius: 20,
                  spreadRadius: 0,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 50,
              backgroundColor: Colors.white.withAlpha((0.2 * 255).toInt()),
              child: (userProfile["profileImageUrl"] == null || (userProfile["profileImageUrl"] ?? '').isEmpty)
                  ? Text(
                      userProfile["name"] != null && userProfile["name"].isNotEmpty
                          ? userProfile["name"][0].toUpperCase()
                          : "N",
                      style: GoogleFonts.poppins(
                        fontSize: 36,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : ClipOval(
                      child: Image.network(
                        userProfile["profileImageUrl"] ?? '',
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 100,
                            height: 100,
                            color: Colors.white.withAlpha((0.2 * 255).toInt()),
                            child: Icon(Icons.broken_image, color: Colors.white, size: 40),
                          );
                        },
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 20),
          // Name and Username
          Text(
            userProfile["name"] ?? '',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 24,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "@${userProfile["username"] ?? "username"}",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w500,
              fontSize: 16,
              color: Colors.black.withAlpha((0.8 * 255).toInt()),
            ),
          ),
          const SizedBox(height: 20),
          // Stats Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatColumn("Posts", postCount.toString()),
              if (showFollowStats) ...[
                _buildStatColumn("Followers", (followerCount ?? 0).toString()),
                _buildStatColumn("Following", (followingCount ?? 0).toString()),
              ],
            ],
          ),
          // Bio
          if (userProfile["bio"] != null && (userProfile["bio"] ?? '').isNotEmpty) ...[
            const SizedBox(height: 20),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha((0.1 * 255).toInt()),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withAlpha((0.2 * 255).toInt()),
                  width: 1,
                ),
              ),
              child: Text(
                userProfile["bio"],
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.black.withAlpha((0.9 * 255).toInt()),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
          const SizedBox(height: 24),
          // Follow/Unfollow or Edit Profile Button
          if (showButton)
            Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryColor, secondaryColor],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withAlpha((0.4 * 255).toInt()),
                    blurRadius: 15,
                    spreadRadius: 0,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: isButtonLoading ? null : onButtonPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: isButtonLoading
                    ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (buttonText == 'Edit Profile') Icon(Icons.edit, size: 20),
                          if (buttonText == 'Edit Profile') const SizedBox(width: 8),
                          Text(
                            buttonText ?? '',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
        ],
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

// Move _buildPostGridCard to a shared function
Widget buildPostGridCard(dynamic post, Color brandColor, VoidCallback? onLike) {
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
        if (onLike != null) onLike();
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
                      : Container(color: brandColor.withAlpha((0.08 * 255).toInt())),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  color: Colors.black.withAlpha((0.5 * 255).toInt()),
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

// Refactor PublicProfileScreen to use the same UI as ProfileScreen
class PublicProfileScreen extends StatefulWidget {
  final String uid;
  const PublicProfileScreen({Key? key, required this.uid}) : super(key: key);

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> with SingleTickerProviderStateMixin {
  Map<String, dynamic>? userProfile;
  List<dynamic> allPosts = [];
  List<dynamic> portfolios = [];
  TabController? _tabController;
  bool isLoading = true;
  bool isError = false;
  bool isFollowing = false;
  String? _selectedPortfolioCategory;

  @override
  void initState() {
    super.initState();
    loadProfileAndPosts();
  }

  Future<void> loadProfileAndPosts() async {
    try {
      final profile = await UserService.fetchPublicProfile(widget.uid);
      final posts = await UserService.fetchPostsForUser(widget.uid);
      final fetchedPortfolios = await PortfolioService.fetchUserPortfolios(widget.uid);

      // Check if the current user is following this user using the proper API
      final followStatus = await UserService.getFollowStatus(widget.uid);
      final isUserFollowing = followStatus != null ? (followStatus['isFollowing'] ?? false) : false;

      print('Follow status for ${widget.uid}: $isUserFollowing'); // Debug log

      if (!mounted) return;
      if (_tabController == null || _tabController!.length != 2) {
        _tabController?.dispose();
        _tabController = TabController(length: 2, vsync: this);
      }
      setState(() {
        userProfile = profile;
        allPosts = posts;
        portfolios = fetchedPortfolios;
        isFollowing = isUserFollowing;
        isError = false;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading public profile: $e'); // Debug log
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
      // Refresh the follow status from the server to ensure accuracy
      final followStatus = await UserService.getFollowStatus(widget.uid);
      final newFollowingStatus = followStatus != null ? (followStatus['isFollowing'] ?? false) : !isFollowing;

      setState(() {
        isFollowing = newFollowingStatus;
        // Update follower count in UI
        if (userProfile != null) {
          int count = userProfile!["followerCount"] ?? 0;
          userProfile!["followerCount"] = isFollowing ? count + 1 : (count - 1).clamp(0, 999999);
        }
        isLoading = false;
      });

      print('Follow toggle successful. New status: $isFollowing'); // Debug log
    } else {
      print('Follow toggle failed'); // Debug log
      setState(() { isLoading = false; });
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  void _onNavTap(int index) {
    Navigator.of(context).popUntil((route) => route.isFirst);
    Future.delayed(Duration.zero, () {
      HomeScreen.switchToTab(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading || userProfile == null || _tabController == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Profile'), backgroundColor: Colors.white, elevation: 0, iconTheme: IconThemeData(color: Colors.black)),
        body: Center(child: CircularProgressIndicator()),
        bottomNavigationBar: MainBottomNavBar(currentIndex: 4, onTap: _onNavTap),
      );
    }
    if (isError) {
      return Scaffold(
        appBar: AppBar(title: Text('Profile'), backgroundColor: Colors.white, elevation: 0, iconTheme: IconThemeData(color: Colors.black)),
        body: Center(child: Text('Failed to load profile.')),
        bottomNavigationBar: MainBottomNavBar(currentIndex: 4, onTap: _onNavTap),
      );
    }
    return Scaffold(
      backgroundColor: Color(0xFFFAFAFA),
      appBar: AppBar(
        title: Text(userProfile!["name"] ?? ''),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: Container(
        color: Color(0xFFFAFAFA),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 20),
                ProfileHeaderCard(
                  userProfile: userProfile!,
                  postCount: allPosts.length,
                  showFollowStats: false, // Hide follow/following for public
                  buttonText: isFollowing ? 'Unfollow' : 'Follow',
                  onButtonPressed: _toggleFollow,
                  isButtonLoading: isLoading,
                  showButton: true,
                ),
                const SizedBox(height: 24),
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha((0.15 * 255).toInt()),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: TabBar(
                    controller: _tabController!,
                    indicatorColor: Color(0xFF6C63FF),
                    indicatorWeight: 3,
                    labelColor: Color(0xFF6C63FF),
                    unselectedLabelColor: Colors.black26,
                    tabs: [
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.grid_on, size: 20),
                            const SizedBox(width: 8),
                            Text('Posts', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.category, size: 20),
                            const SizedBox(width: 8),
                            Text('Portfolio', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.black)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Use a SizedBox to constrain TabBarView height, but wrap in LayoutBuilder for responsiveness
                LayoutBuilder(
                  builder: (context, constraints) {
                    final availableHeight = MediaQuery.of(context).size.height - 350; // Adjust as needed
                    return SizedBox(
                      height: availableHeight > 300 ? availableHeight : 300,
                      child: TabBarView(
                        controller: _tabController!,
                        children: [
                          _buildProfileGrid(Color(0xFF6C63FF)),
                          _buildPortfolioCategoryList(),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: MainBottomNavBar(currentIndex: 4, onTap: _onNavTap),
    );
  }

  Widget _buildProfileGrid(Color brandColor) {
    // Filter out audio posts - they should only appear in Portfolio section
    final nonAudioPosts = allPosts.where((post) => post['mediaType'] != 'audio').toList();

    if (nonAudioPosts.isEmpty) {
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
      itemCount: nonAudioPosts.length,
      itemBuilder: (context, index) {
        final post = nonAudioPosts[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PostDetailsScreen(
                  post: post,
                  allPosts: allPosts,
                ),
              ),
            );
          },
          child: buildPostGridCard(post, brandColor, null),
        );
      },
    );
  }

  Widget _buildPortfolioCategoryList() {
    if (_selectedPortfolioCategory != null) {
      final category = _selectedPortfolioCategory!;
      final postsInCategory = allPosts.where((p) => p['category'] == category).toList();
      return SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Back button
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: Icon(Icons.arrow_back, color: Color(0xFF6C63FF)),
                onPressed: () {
                  setState(() {
                    _selectedPortfolioCategory = null;
                  });
                },
              ),
            ),
            // Portfolio header (same style as profile but without follow/following counts)
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withAlpha((0.2 * 255).toInt()),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha((0.08 * 255).toInt()),
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Profile picture
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Color(0xFF6C63FF).withAlpha((0.3 * 255).toInt()),
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF6C63FF).withAlpha((0.2 * 255).toInt()),
                          blurRadius: 15,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      backgroundColor: Color(0xFFF7FAFC),
                      backgroundImage: (userProfile!['profileImageUrl'] ?? '').isNotEmpty
                          ? NetworkImage(userProfile!['profileImageUrl']!)
                          : null,
                      child: (userProfile!['profileImageUrl'] == null || (userProfile!['profileImageUrl'] ?? '').isEmpty)
                          ? Icon(Icons.person, color: Color(0xFF6C63FF), size: 40)
                          : null,
                      radius: 50,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Name
                  Text(
                    userProfile!['name'] ?? 'Unknown',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Category
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF6C63FF), Color(0xFFFF6B9D)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF6C63FF).withAlpha((0.3 * 255).toInt()),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      category,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Posts count for this category
                  Text(
                    '${postsInCategory.length} ${postsInCategory.length == 1 ? 'post' : 'posts'}',
                    style: GoogleFonts.poppins(
                      color: Color(0xFF718096),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Posts grid/list for this portfolio
            postsInCategory.isEmpty
                ? Container(
                    padding: EdgeInsets.all(32),
                    child: Text('No posts in this portfolio yet', style: TextStyle(fontSize: 16, color: Colors.black54)),
                  )
                : GridView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: postsInCategory.length,
                    itemBuilder: (context, index) {
                      final post = postsInCategory[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PostDetailsScreen(
                                post: post,
                                allPosts: postsInCategory,
                              ),
                            ),
                          );
                        },
                        child: buildPostGridCard(post, Color(0xFF6C63FF), null),
                      );
                    },
                  ),
          ],
        ),
      );
    }
    
    // Default: show portfolio list using actual portfolios with navigation to portfolio details
    return PublicPortfolioCategoryList(
      userProfile: userProfile!,
      allPosts: allPosts,
      portfolios: portfolios,
      onPortfolioTap: (portfolioId) {
        // Navigate to portfolio details screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PortfolioProfileScreen(portfolioId: portfolioId),
          ),
        );
      },
      onCategoryTap: (category) {
        setState(() {
          _selectedPortfolioCategory = category;
        });
      },
    );
  }
}

class PortfolioCategoryList extends StatelessWidget {
  final Map<String, dynamic> userProfile;
  final List<dynamic> allPosts;
  final void Function(AppUser user, String category, List<Map<String, dynamic>> posts) onPortfolioTap;
  const PortfolioCategoryList({required this.userProfile, required this.allPosts, required this.onPortfolioTap, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final isOwnProfile = currentUserId == userProfile['uid'];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: Column(
        children: [
          // Music Portfolio Section (Always show at top)
          Container(
            margin: EdgeInsets.only(bottom: 24),
            child: MusicPortfolioWidget(
              userId: userProfile['uid'] ?? '',
              isOwnProfile: isOwnProfile,
            ),
          ),

          // Regular Categories Section
          if (userProfile['categories'] != null && (userProfile['categories'] as List).isNotEmpty) ...[
            // Section Header
            Container(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.category,
                    color: Color(0xFF6C63FF),
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Categories',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                ],
              ),
            ),

            // Categories List
            ...(userProfile['categories'] as List).asMap().entries.map((entry) {
              final index = entry.key;
              final category = entry.value;
              final postsInCategory = allPosts.where((p) => p['category'] == category).toList();

              return Container(
                margin: EdgeInsets.only(bottom: 18),
                child: _buildCategoryCard(category, postsInCategory),
              );
            }).toList(),
          ] else ...[
            // No categories message
            Container(
              padding: EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.category,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: 16),
                  Text(
                    isOwnProfile ? 'No categories yet' : 'No categories shared',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryCard(String category, List<dynamic> postsInCategory) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        // Handle category tap
        final user = AppUser(
          uid: userProfile['uid'] ?? '',
          name: userProfile['name'] ?? '',
          username: userProfile['username'] ?? '',
          email: userProfile['email'] ?? '',
          profileImageUrl: userProfile['profileImageUrl'],
          categories: List<String>.from(userProfile['categories'] ?? []),
        );
        onPortfolioTap(user, category, postsInCategory.cast<Map<String, dynamic>>());
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withAlpha((0.85 * 255).toInt()),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Color(0xFFE0E0E0), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((0.08 * 255).toInt()),
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
                  color: Colors.black.withAlpha((0.10 * 255).toInt()),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(8),
            child: Icon(Icons.category, color: Color(0xFF4FC3F7), size: 28),
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
          subtitle: Text(
            '${postsInCategory.length} ${postsInCategory.length == 1 ? 'post' : 'posts'}',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF718096),
            ),
          ),
          trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFB0BEC5), size: 20),
        ),
      ),
    );
  }
}

// New widget for public profile that shows actual portfolios and enables navigation to portfolio details
class PublicPortfolioCategoryList extends StatelessWidget {
  final Map<String, dynamic> userProfile;
  final List<dynamic> allPosts;
  final List<dynamic> portfolios;
  final void Function(String portfolioId) onPortfolioTap;
  final void Function(String category) onCategoryTap;
  
  const PublicPortfolioCategoryList({
    required this.userProfile,
    required this.allPosts,
    required this.portfolios,
    required this.onPortfolioTap,
    required this.onCategoryTap,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final isOwnProfile = currentUserId == userProfile['uid'];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: Column(
        children: [
          // Music Portfolio Section (Always show at top)
          Container(
            margin: EdgeInsets.only(bottom: 24),
            child: MusicPortfolioWidget(
              userId: userProfile['uid'] ?? '',
              isOwnProfile: isOwnProfile,
            ),
          ),

          // Regular Portfolios Section
          if (portfolios.isNotEmpty) ...[
            // Section Header
            Container(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.folder_special,
                    color: Color(0xFF6C63FF),
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Creative Portfolios',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                ],
              ),
            ),

            // Portfolios List
            ...portfolios.asMap().entries.map((entry) {
              final index = entry.key;
              final portfolio = entry.value;
              return Container(
                margin: EdgeInsets.only(bottom: 18),
                child: _buildPortfolioCard(portfolio),
              );
            }).toList(),
          ] else ...[
            // No portfolios message
            Container(
              padding: EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.folder_open,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: 16),
                  Text(
                    isOwnProfile ? 'No portfolios yet' : 'No portfolios shared',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (isOwnProfile) ...[
                    SizedBox(height: 8),
                    Text(
                      'Create your first portfolio!',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPortfolioCard(dynamic portfolio) {
    final portfolioName = portfolio is Map ? (portfolio['profilename'] ?? portfolio['category'] ?? 'Portfolio') : portfolio.profilename;
    final category = portfolio is Map ? (portfolio['category'] ?? '') : portfolio.category;
    final portfolioId = portfolio is Map ? (portfolio['_id'] ?? portfolio['id'] ?? '') : portfolio.id;
    final profileImageUrl = portfolio is Map ? portfolio['profileImageUrl'] : portfolio.profileImageUrl;
    final postsInCategory = allPosts.where((p) => p['category'] == category).toList();

    return InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => onPortfolioTap(portfolioId ?? ''),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withAlpha((0.85 * 255).toInt()),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Color(0xFFE0E0E0), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha((0.08 * 255).toInt()),
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
                      color: Colors.black.withAlpha((0.10 * 255).toInt()),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(8),
                child: profileImageUrl != null && profileImageUrl.isNotEmpty
                    ? ClipOval(
                        child: Image.network(
                          profileImageUrl,
                          width: 28,
                          height: 28,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(Icons.folder_special_rounded, color: Color(0xFF4FC3F7), size: 28);
                          },
                        ),
                      )
                    : Icon(Icons.folder_special_rounded, color: Color(0xFF4FC3F7), size: 28),
              ),
              title: Text(
                portfolioName ?? 'Portfolio',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Color(0xFF263238),
                  letterSpacing: 0.5,
                ),
              ),
              subtitle: Text(
                '${postsInCategory.length} ${postsInCategory.length == 1 ? 'post' : 'posts'}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF718096),
                ),
              ),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFB0BEC5), size: 20),
            ),
          ),
        );
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
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
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