import 'package:flutter/material.dart';
import 'package:tinkerly/models/user_model.dart';
import 'package:tinkerly/widgets/custom_button.dart';

class MyPostsScreen extends StatefulWidget {
  final AppUser user;

  const MyPostsScreen({super.key, required this.user});

  @override
  State<MyPostsScreen> createState() => _MyPostsScreenState();
}

class _MyPostsScreenState extends State<MyPostsScreen> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Published', 'Draft', 'Archived'];

  // Mock data for posts
  final List<Post> _posts = [
    Post(
      id: '1',
      title: 'Digital Art Collection',
      description: 'A series of digital illustrations showcasing modern design trends',
      category: 'Digital Art',
      imageUrl: 'https://via.placeholder.com/300x200/6C63FF/FFFFFF?text=Digital+Art',
      status: PostStatus.published,
      likes: 156,
      views: 1200,
      earnings: 45.50,
      date: DateTime.now().subtract(const Duration(days: 2)),
    ),
    Post(
      id: '2',
      title: 'UI/UX Design System',
      description: 'Complete design system for a mobile banking application',
      category: 'UI/UX',
      imageUrl: 'https://via.placeholder.com/300x200/4CAF50/FFFFFF?text=UI+UX+Design',
      status: PostStatus.published,
      likes: 89,
      views: 756,
      earnings: 32.75,
      date: DateTime.now().subtract(const Duration(days: 5)),
    ),
    Post(
      id: '3',
      title: 'Photography Portfolio',
      description: 'Street photography collection from urban landscapes',
      category: 'Photography',
      imageUrl: 'https://via.placeholder.com/300x200/2196F3/FFFFFF?text=Photography',
      status: PostStatus.draft,
      likes: 0,
      views: 0,
      earnings: 0.0,
      date: DateTime.now().subtract(const Duration(days: 1)),
    ),
    Post(
      id: '4',
      title: 'Animation Showreel',
      description: 'Collection of animated sequences and motion graphics',
      category: 'Animation',
      imageUrl: 'https://via.placeholder.com/300x200/FF9800/FFFFFF?text=Animation',
      status: PostStatus.archived,
      likes: 67,
      views: 432,
      earnings: 18.25,
      date: DateTime.now().subtract(const Duration(days: 10)),
    ),
  ];

  List<Post> get _filteredPosts {
    if (_selectedFilter == 'All') return _posts;
    return _posts.where((post) => post.status.name == _selectedFilter.toLowerCase()).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'My Posts',
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
              // Navigate to create new post screen
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats Cards
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFF6C63FF),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.article,
                    title: 'Total Posts',
                    value: '${_posts.length}',
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.visibility,
                    title: 'Total Views',
                    value: '${_posts.fold(0, (sum, post) => sum + post.views)}',
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.account_balance_wallet,
                    title: 'Total Earnings',
                    value: '\$${_posts.fold(0.0, (sum, post) => sum + post.earnings).toStringAsFixed(2)}',
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          
          // Filter Tabs
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: _filters.map((filter) {
                bool isSelected = _selectedFilter == filter;
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedFilter = filter;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF6C63FF) : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        filter,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isSelected ? Colors.white : const Color(0xFF6C7B7F),
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          
          // Posts List
          Expanded(
            child: _filteredPosts.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredPosts.length,
                    itemBuilder: (context, index) {
                      return _buildPostCard(_filteredPosts[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPostCard(Post post) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
        children: [
          // Post Image and Status
          Stack(
            children: [
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  image: DecorationImage(
                    image: NetworkImage(post.imageUrl),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              // Status Badge
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(post.status).withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    post.status.name.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              // Category Badge
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
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
            ],
          ),
          
          // Post Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        post.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      onSelected: (value) => _handlePostAction(value, post),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 16),
                              SizedBox(width: 8),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'duplicate',
                          child: Row(
                            children: [
                              Icon(Icons.copy, size: 16),
                              SizedBox(width: 8),
                              Text('Duplicate'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'archive',
                          child: Row(
                            children: [
                              Icon(Icons.archive, size: 16),
                              SizedBox(width: 8),
                              Text('Archive'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 16, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Delete', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                Text(
                  post.description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6C7B7F),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 16),
                
                // Stats Row
                Row(
                  children: [
                    _buildStatItem(Icons.favorite, '${post.likes}'),
                    const SizedBox(width: 24),
                    _buildStatItem(Icons.visibility, '${post.views}'),
                    const SizedBox(width: 24),
                    _buildStatItem(Icons.account_balance_wallet, '\$${post.earnings.toStringAsFixed(2)}'),
                    const Spacer(),
                    Text(
                      _formatDate(post.date),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6C7B7F),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        text: 'View Details',
                        onPressed: () => _viewPostDetails(post),
                        color: const Color(0xFF6C63FF),
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (post.status == PostStatus.draft)
                      Expanded(
                        child: CustomButton(
                          text: 'Publish',
                          onPressed: () => _publishPost(post),
                          color: const Color(0xFF4CAF50),
                        ),
                      ),
                  ],
                ),
              ],
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
            fontSize: 12,
            color: Color(0xFF6C7B7F),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
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
              Icons.article_outlined,
              size: 60,
              color: Color(0xFF6C63FF),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No posts in $_selectedFilter',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Start creating content to build your portfolio',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF6C7B7F),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          CustomButton(
            text: 'Create New Post',
            onPressed: () {
              // Navigate to create new post screen
            },
            color: const Color(0xFF6C63FF),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(PostStatus status) {
    switch (status) {
      case PostStatus.published:
        return const Color(0xFF4CAF50);
      case PostStatus.draft:
        return const Color(0xFFFF9800);
      case PostStatus.archived:
        return const Color(0xFF6C7B7F);
    }
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

  void _handlePostAction(String action, Post post) {
    switch (action) {
      case 'edit':
        // Navigate to edit post screen
        break;
      case 'duplicate':
        // Duplicate post
        break;
      case 'archive':
        // Archive post
        break;
      case 'delete':
        _showDeleteConfirmation(post);
        break;
    }
  }

  void _showDeleteConfirmation(Post post) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post'),
        content: Text('Are you sure you want to delete "${post.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Delete post logic
              Navigator.pop(context);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _viewPostDetails(Post post) {
    // Navigate to post details screen
  }

  void _publishPost(Post post) {
    // Publish post logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Post published successfully!'),
        backgroundColor: Color(0xFF4CAF50),
      ),
    );
  }
}

class Post {
  final String id;
  final String title;
  final String description;
  final String category;
  final String imageUrl;
  final PostStatus status;
  final int likes;
  final int views;
  final double earnings;
  final DateTime date;

  Post({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.imageUrl,
    required this.status,
    required this.likes,
    required this.views,
    required this.earnings,
    required this.date,
  });
}

enum PostStatus {
  published,
  draft,
  archived,
} 