import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../widgets/modern_text_field.dart';
import '../../widgets/modern_card.dart';
import '../../constants/app_theme.dart';
import '../../services/user_service.dart';
import '../../models/user_model.dart';
import 'package:cached_network_image/cached_network_image.dart';

class UserSearchScreen extends StatefulWidget {
  @override
  State<UserSearchScreen> createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends State<UserSearchScreen> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  List<AppUser> _searchResults = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchUsers(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _hasSearched = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    try {
      final results = await UserService.searchUsers(query);
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _searchResults = [];
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Search failed: ${e.toString()}'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: isDark ? AppTheme.darkSurfaceColor : AppTheme.surfaceColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurfaceColor : AppTheme.surfaceColor,
            boxShadow: AppTheme.cardShadow,
          ),
        ),
        title: Text(
          'Discover People',
          style: AppTheme.headingMedium.copyWith(
            color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
          ),
        ).animate().fadeIn(duration: 400.ms),
      ),
      body: Column(
        children: [
          // Search Header
          Container(
            padding: const EdgeInsets.all(AppTheme.spaceMedium),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurfaceColor : AppTheme.surfaceColor,
              boxShadow: AppTheme.cardShadow,
            ),
            child: ModernTextField(
              controller: _searchController,
              label: 'Search users',
              hint: 'Enter name, username, or email',
              prefixIcon: Icons.search_rounded,
              onChanged: (value) {
                // Debounce search
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (_searchController.text == value) {
                    _searchUsers(value);
                  }
                });
              },
            ).animate().slideY(
              begin: -0.3,
              duration: 600.ms,
              delay: 200.ms,
              curve: Curves.easeOut,
            ),
          ),
          // Search Results
          Expanded(
            child: _buildSearchContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchContent() {
    if (!_hasSearched) {
      return _buildSearchSuggestions();
    }

    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_searchResults.isEmpty) {
      return _buildEmptyState();
    }

    return _buildSearchResults();
  }

  Widget _buildSearchSuggestions() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spaceMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ModernCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.explore_outlined,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Discover Amazing Creators',
                            style: AppTheme.headingSmall.copyWith(
                              color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Find talented people in your field',
                            style: AppTheme.bodyMedium.copyWith(
                              color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Search Tips:',
                  style: AppTheme.labelLarge.copyWith(
                    color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                _buildSearchTip(Icons.person_search, 'Search by name or username'),
                _buildSearchTip(Icons.email_outlined, 'Find users by email'),
                _buildSearchTip(Icons.category_outlined, 'Discover creators by category'),
              ],
            ),
          ).animate().fadeIn(duration: 600.ms, delay: 300.ms),
          const SizedBox(height: 24),
          Text(
            'Popular Categories',
            style: AppTheme.headingSmall.copyWith(
              color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
            ),
          ).animate().fadeIn(duration: 600.ms, delay: 400.ms),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              'Photography', 'Design', 'Art', 'Music', 'Technology', 'Fashion'
            ].asMap().entries.map((entry) {
              return GestureDetector(
                onTap: () {
                  _searchController.text = entry.value;
                  _searchUsers(entry.value);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    entry.value,
                    style: AppTheme.bodyMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ).animate().fadeIn(
                duration: 400.ms,
                delay: Duration(milliseconds: 500 + (entry.key * 100)),
              ).scale(
                begin: const Offset(0.8, 0.8),
                duration: 400.ms,
                delay: Duration(milliseconds: 500 + (entry.key * 100)),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchTip(IconData icon, String text) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: AppTheme.bodySmall.copyWith(
              color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: ModernCard(
        margin: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                gradient: AppTheme.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 3,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Searching...',
              style: AppTheme.bodyLarge,
            ),
          ],
        ),
      ).animate().fadeIn(duration: 300.ms),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Center(
      child: ModernCard(
        margin: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.textTertiary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 48,
                color: AppTheme.textTertiary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Users Found',
              style: AppTheme.headingSmall.copyWith(
                color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try searching with different keywords',
              style: AppTheme.bodyMedium.copyWith(
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ).animate().fadeIn(duration: 400.ms),
    );
  }

  Widget _buildSearchResults() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.spaceMedium),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final user = _searchResults[index];
        return _buildUserCard(user, index);
      },
    );
  }

  Widget _buildUserCard(AppUser user, int index) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return ModernCard(
      margin: const EdgeInsets.only(bottom: 16),
      onTap: () {
        // Navigate to user profile
        // TODO: Implement user profile navigation
      },
      child: Row(
        children: [
          // Profile Image
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: user.profileImageUrl == null 
                  ? AppTheme.primaryGradient 
                  : null,
              border: Border.all(
                color: AppTheme.primaryColor.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: user.profileImageUrl != null
                ? ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: user.profileImageUrl!,
                      fit: BoxFit.cover,
                      width: 60,
                      height: 60,
                      placeholder: (context, url) => Container(
                        decoration: const BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        decoration: const BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ),
                  )
                : const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 30,
                  ),
          ),
          const SizedBox(width: 16),
          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: AppTheme.labelLarge.copyWith(
                    color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
                  ),
                ),
                if (user.username.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    '@${user.username}',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
                if (user.categories.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    user.categories.take(2).join(', '),
                    style: AppTheme.bodySmall.copyWith(
                      color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Follow Button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              'Follow',
              style: AppTheme.bodySmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(
      duration: 400.ms,
      delay: Duration(milliseconds: index * 100),
    ).slideX(
      begin: 0.3,
      duration: 400.ms,
      delay: Duration(milliseconds: index * 100),
    );
  }
}