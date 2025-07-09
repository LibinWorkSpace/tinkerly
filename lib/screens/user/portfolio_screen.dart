import 'package:flutter/material.dart';
import 'package:tinkerly/models/user_model.dart';
import 'package:tinkerly/widgets/custom_button.dart';

class PortfolioScreen extends StatefulWidget {
  final AppUser user;

  const PortfolioScreen({super.key, required this.user});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Mock data for portfolio posts
  final Map<String, List<PortfolioPost>> _portfolioData = {
    'All': [
      PortfolioPost(
        id: '1',
        title: 'Digital Art Collection',
        description: 'A series of digital illustrations showcasing modern design trends',
        category: 'Digital Art',
        imageUrl: 'https://via.placeholder.com/300x200/6C63FF/FFFFFF?text=Digital+Art',
        likes: 156,
        views: 1200,
        date: DateTime.now().subtract(const Duration(days: 2)),
      ),
      PortfolioPost(
        id: '2',
        title: 'UI/UX Design System',
        description: 'Complete design system for a mobile banking application',
        category: 'UI/UX',
        imageUrl: 'https://via.placeholder.com/300x200/4CAF50/FFFFFF?text=UI+UX+Design',
        likes: 89,
        views: 756,
        date: DateTime.now().subtract(const Duration(days: 5)),
      ),
      PortfolioPost(
        id: '3',
        title: 'Photography Portfolio',
        description: 'Street photography collection from urban landscapes',
        category: 'Photography',
        imageUrl: 'https://via.placeholder.com/300x200/2196F3/FFFFFF?text=Photography',
        likes: 234,
        views: 1890,
        date: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ],
    'Digital Art': [
      PortfolioPost(
        id: '1',
        title: 'Digital Art Collection',
        description: 'A series of digital illustrations showcasing modern design trends',
        category: 'Digital Art',
        imageUrl: 'https://via.placeholder.com/300x200/6C63FF/FFFFFF?text=Digital+Art',
        likes: 156,
        views: 1200,
        date: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ],
    'UI/UX': [
      PortfolioPost(
        id: '2',
        title: 'UI/UX Design System',
        description: 'Complete design system for a mobile banking application',
        category: 'UI/UX',
        imageUrl: 'https://via.placeholder.com/300x200/4CAF50/FFFFFF?text=UI+UX+Design',
        likes: 89,
        views: 756,
        date: DateTime.now().subtract(const Duration(days: 5)),
      ),
    ],
    'Photography': [
      PortfolioPost(
        id: '3',
        title: 'Photography Portfolio',
        description: 'Street photography collection from urban landscapes',
        category: 'Photography',
        imageUrl: 'https://via.placeholder.com/300x200/2196F3/FFFFFF?text=Photography',
        likes: 234,
        views: 1890,
        date: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ],
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: widget.user.categories.length + 1,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'My Portfolio',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF6C63FF),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () {
              // Navigate to add new post screen
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          isScrollable: true,
          tabs: [
            const Tab(text: 'All'),
            ...widget.user.categories.map((category) => Tab(text: category)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPortfolioGrid('All'),
          ...widget.user.categories.map((category) => _buildPortfolioGrid(category)),
        ],
      ),
    );
  }

  Widget _buildPortfolioGrid(String category) {
    final posts = _portfolioData[category] ?? [];
    
    if (posts.isEmpty) {
      return _buildEmptyState(category);
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                category == 'All' ? 'All Posts' : '$category Posts',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              Text(
                '${posts.length} posts',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6C7B7F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Portfolio Grid
          Expanded(
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
          ),
        ],
      ),
    );
  }

  Widget _buildPortfolioCard(PortfolioPost post) {
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
                    image: NetworkImage(post.imageUrl),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Stack(
                  children: [
                    // Category Badge
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
                          post.category,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    // Stats Overlay
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.favorite,
                              color: Colors.white,
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${post.likes}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
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
                      post.title,
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
                      post.description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6C7B7F),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(
                          Icons.visibility,
                          size: 12,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${post.views}',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _formatDate(post.date),
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
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
          const SizedBox(height: 32),
          CustomButton(
            text: 'Add New Post',
            onPressed: () {
              // Navigate to add new post screen
            },
            color: const Color(0xFF6C63FF),
          ),
        ],
      ),
    );
  }

  void _showPostDetails(PortfolioPost post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildPostDetailsSheet(post),
    );
  }

  Widget _buildPostDetailsSheet(PortfolioPost post) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Post Image
          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                image: DecorationImage(
                  image: NetworkImage(post.imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          
          // Post Details
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6C63FF).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          post.category,
                          style: const TextStyle(
                            color: Color(0xFF6C63FF),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          // Edit post
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          // Delete post
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    post.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    post.description,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF6C7B7F),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildStatItem(Icons.favorite, '${post.likes}'),
                      const SizedBox(width: 24),
                      _buildStatItem(Icons.visibility, '${post.views}'),
                      const SizedBox(width: 24),
                      _buildStatItem(Icons.calendar_today, _formatDate(post.date)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: const Color(0xFF6C7B7F),
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF6C7B7F),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

class PortfolioPost {
  final String id;
  final String title;
  final String description;
  final String category;
  final String imageUrl;
  final int likes;
  final int views;
  final DateTime date;

  PortfolioPost({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.imageUrl,
    required this.likes,
    required this.views,
    required this.date,
  });
} 