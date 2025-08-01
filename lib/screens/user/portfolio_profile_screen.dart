import 'package:flutter/material.dart';
import '../../models/portfolio_model.dart';
import '../../services/portfolio_service.dart';
import '../../models/product_model.dart';
import '../../services/product_service.dart';
import '../../widgets/main_bottom_nav_bar.dart';
import '../../widgets/enhanced_music_player_widget.dart';
import 'package:google_fonts/google_fonts.dart';
import 'edit_portfolio_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PortfolioProfileScreen extends StatefulWidget {
  final String portfolioId;
  const PortfolioProfileScreen({Key? key, required this.portfolioId}) : super(key: key);

  @override
  State<PortfolioProfileScreen> createState() => _PortfolioProfileScreenState();
}

class _PortfolioProfileScreenState extends State<PortfolioProfileScreen> with SingleTickerProviderStateMixin {
  Portfolio? portfolio;
  List<dynamic> posts = [];
  List<Product> products = [];
  List<dynamic> followers = [];
  TabController? _tabController;
  bool _isLoading = true;
  bool _hasError = false;
  bool _isFollowing = false;
  bool _isFollowLoading = false;

  @override
  void initState() {
    super.initState();
    loadPortfolioData();
  }

  Future<void> loadPortfolioData() async {
    setState(() { _isLoading = true; _hasError = false; });
    try {
      print('Loading portfolio data for ID: ${widget.portfolioId}'); // Debug log
      final fullData = await PortfolioService.fetchPortfolioFull(widget.portfolioId);
      print('Full data received: $fullData'); // Debug log

      portfolio = Portfolio.fromMap(fullData);
      posts = fullData['posts'] ?? [];
      products = (fullData['products'] as List?)?.map((e) => Product.fromMap(e)).toList() ?? [];
      followers = await PortfolioService.fetchPortfolioFollowers(widget.portfolioId);

      // Check if current user is following this portfolio
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        _isFollowing = followers.any((follower) => follower['_id'] == currentUser.uid || follower['uid'] == currentUser.uid);
      }

      print('Portfolio loaded: ${portfolio?.profilename}'); // Debug log
      print('Posts count: ${posts.length}'); // Debug log
      print('Products count: ${products.length}'); // Debug log
      print('Is following: $_isFollowing'); // Debug log

      _tabController ??= TabController(length: 2, vsync: this);
      setState(() { _isLoading = false; });
    } catch (e) {
      print('Error loading portfolio data: $e'); // Debug log
      setState(() { _isLoading = false; _hasError = true; });
    }
  }

  bool _isCurrentUserOwner() {
    final currentUser = FirebaseAuth.instance.currentUser;
    return currentUser != null && portfolio != null && portfolio!.userId == currentUser.uid;
  }

  Future<void> _toggleFollow() async {
    if (_isFollowLoading) return;

    setState(() { _isFollowLoading = true; });

    try {
      // TODO: Implement portfolio follow/unfollow API calls
      // For now, just toggle the state locally
      setState(() {
        _isFollowing = !_isFollowing;
        if (_isFollowing) {
          // Add current user to followers list (simplified)
          // In real implementation, this should be handled by the backend
        } else {
          // Remove current user from followers list (simplified)
          // In real implementation, this should be handled by the backend
        }
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isFollowing ? 'Following portfolio' : 'Unfollowed portfolio'),
          backgroundColor: _isFollowing ? Colors.green : Colors.orange,
        ),
      );
    } catch (e) {
      print('Error toggling follow: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to ${_isFollowing ? 'unfollow' : 'follow'} portfolio'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() { _isFollowLoading = false; });
    }
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
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Color(0xFF6C63FF);
    final secondaryColor = Color(0xFFFF6B9D);
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Color(0xFFFAFAFA),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_hasError || portfolio == null) {
      return Scaffold(
        backgroundColor: Color(0xFFFAFAFA),
        body: Center(child: Text('Failed to load portfolio.')),
      );
    }
    return Scaffold(
      backgroundColor: Color(0xFFFAFAFA),
      appBar: AppBar(
        title: Text(portfolio!.profilename),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Portfolio Header (same as profile header)
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
                        backgroundImage: (portfolio!.profileImageUrl ?? '').isNotEmpty
                            ? NetworkImage(portfolio!.profileImageUrl!)
                            : null,
                        child: (portfolio!.profileImageUrl == null || (portfolio!.profileImageUrl ?? '').isEmpty)
                            ? Text(
                                portfolio!.profilename.isNotEmpty ? portfolio!.profilename[0].toUpperCase() : "P",
                                style: GoogleFonts.poppins(
                                  fontSize: 36,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Name and Category
                    Text(
                      portfolio!.profilename,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "@${portfolio!.category}",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                        color: Colors.black.withAlpha((0.8 * 255).toInt()),
                      ),
                    ),
                    if (portfolio!.description.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        portfolio!.description,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[600],
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 20),
                    // Stats Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatColumn("Posts", posts.length.toString()),
                        // Only show follower count for portfolio owner
                        if (_isCurrentUserOwner())
                          _buildStatColumn("Followers", followers.length.toString()),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Edit Portfolio Button (for owner) or Follow Button (for others)
                    Container(
                      width: double.infinity,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _isCurrentUserOwner()
                              ? [Color(0xFF6C63FF), Color(0xFFFF6B9D)]
                              : _isFollowing
                                  ? [Colors.grey[400]!, Colors.grey[500]!]
                                  : [Color(0xFF4CAF50), Color(0xFF45A049)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: (_isCurrentUserOwner() ? Color(0xFF6C63FF) : Color(0xFF4CAF50)).withOpacity(0.3),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: _isCurrentUserOwner()
                            ? () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => EditPortfolioScreen(portfolio: portfolio!),
                                  ),
                                );
                                if (result == true) {
                                  // Refresh portfolio data after editing
                                  await loadPortfolioData();
                                }
                              }
                            : _isFollowLoading ? null : _toggleFollow,
                        icon: _isFollowLoading
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(
                                _isCurrentUserOwner()
                                    ? Icons.edit
                                    : _isFollowing
                                        ? Icons.person_remove
                                        : Icons.person_add,
                                color: Colors.white,
                                size: 20,
                              ),
                        label: Text(
                          _isCurrentUserOwner()
                              ? 'Edit Portfolio'
                              : _isFollowing
                                  ? 'Unfollow'
                                  : 'Follow',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
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
                        unselectedLabelColor: Color(0xFF6C63FF).withOpacity(0.6),
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
                                Icon(Icons.shopping_bag, size: 20),
                                const SizedBox(width: 8),
                                Text('Products', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
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
                          _buildPostsGrid(primaryColor),
                          _buildProductsGrid(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
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

  Widget _buildPostsGrid(Color brandColor) {
    print('Building posts grid with ${posts.length} posts'); // Debug log

    if (posts.isEmpty) {
      return Center(
        child: Container(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.photo_library_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'No posts yet',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Posts will appear here when you create them',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        print('Building post item $index: ${post['_id']}'); // Debug log

        return GestureDetector(
          onTap: () {
            if (post['mediaType'] == 'audio') {
              // Show enhanced audio player dialog
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                isScrollControlled: true,
                builder: (context) => EnhancedMusicPlayerWidget(
                  track: post,
                  onClose: () => Navigator.pop(context),
                ),
              );
            }
            // Handle other media types if needed
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
            child: Column(
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    width: double.infinity,
                    child: post['mediaType'] == 'image'
                        ? Image.network(
                            post['url'],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[300],
                                child: Icon(Icons.broken_image, color: Colors.grey[600]),
                              );
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                color: Colors.grey[200],
                                child: Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                ),
                              );
                            },
                          )
                        : post['mediaType'] == 'audio'
                            ? Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Color(0xFF1DB954), Color(0xFF1ED760)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.music_note, color: Colors.white, size: 40),
                                    SizedBox(height: 8),
                                    Text(
                                      'Audio Track',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.play_arrow, color: Colors.white, size: 16),
                                          SizedBox(width: 4),
                                          Text(
                                            'Play',
                                            style: GoogleFonts.poppins(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : Container(
                                color: brandColor.withOpacity(0.2),
                                child: Icon(Icons.videocam, color: brandColor, size: 32),
                              ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: EdgeInsets.all(8),
                    width: double.infinity,
                    child: Text(
                      post['description'] ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProductsGrid() {
    if (products.isEmpty) {
      return Center(child: Text('No products yet'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return Card(
          child: ListTile(
            leading: Icon(Icons.shopping_bag, color: Color(0xFF6C63FF)),
            title: Text('₹${product.price.toStringAsFixed(2)}'),
            subtitle: Text(product.licenseInfo),
          ),
        );
      },
    );
  }
}