import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/modern_text_field.dart';
import '../../widgets/modern_card.dart';
import '../../constants/app_theme.dart';
import '../../services/user_service.dart';
import '../../services/portfolio_service.dart';
import 'profile_screen.dart';
import 'portfolio_profile_screen.dart';

import 'package:cached_network_image/cached_network_image.dart';

class UserSearchScreen extends StatefulWidget {
  @override
  State<UserSearchScreen> createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends State<UserSearchScreen> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  bool _isSearchingUsers = true; // true for users, false for portfolios
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

  Future<void> _performSearch(String query) async {
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
      List<dynamic> results;
      if (_isSearchingUsers) {
        results = await UserService.searchUsers(query);
      } else {
        results = await PortfolioService.searchPortfolios(query);
      }
      
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

  void _toggleSearchType() {
    setState(() {
      _isSearchingUsers = !_isSearchingUsers;
      _searchResults = [];
      _hasSearched = false;
    });
    
    // Re-search if there's a query
    if (_searchController.text.isNotEmpty) {
      _performSearch(_searchController.text);
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
        title: Row(
          children: [
            Expanded(
              child: Text(
                _isSearchingUsers ? 'Discover People' : 'Discover Portfolios',
                style: AppTheme.headingMedium.copyWith(
                  color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
                ),
              ).animate().fadeIn(duration: 400.ms),
            ),
            // Search Type Toggle
            Container(
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(25),
                  onTap: _toggleSearchType,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isSearchingUsers ? Icons.person_rounded : Icons.work_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                        SizedBox(width: 6),
                        Text(
                          _isSearchingUsers ? 'Users' : 'Portfolios',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ).animate().scale(duration: 300.ms),
          ],
        ),
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
              label: _isSearchingUsers ? 'Search users' : 'Search portfolios',
              hint: _isSearchingUsers 
                  ? 'Enter name, username, or email'
                  : 'Enter portfolio name or category',
              prefixIcon: Icons.search_rounded,
              onChanged: (value) {
                // Debounce search
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (_searchController.text == value) {
                    _performSearch(value);
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
          // Hero Section with Enhanced Design
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primaryColor.withOpacity(0.15),
                  AppTheme.accentColor.withOpacity(0.1),
                  Colors.transparent,
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppTheme.primaryColor.withOpacity(0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                // Animated Icon with Glow Effect
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(
                    _isSearchingUsers ? Icons.people_alt_rounded : Icons.dashboard_customize_rounded,
                    size: 40,
                    color: Colors.white,
                  ),
                ).animate(onPlay: (controller) => controller.repeat())
                  .shimmer(duration: 2000.ms, color: Colors.white.withOpacity(0.3))
                  .scale(begin: const Offset(1.0, 1.0), end: const Offset(1.05, 1.05), duration: 1000.ms)
                  .then()
                  .scale(begin: const Offset(1.05, 1.05), end: const Offset(1.0, 1.0), duration: 1000.ms),

                const SizedBox(height: 20),
                Text(
                  _isSearchingUsers ? '🌟 Discover Amazing Creators' : '🎨 Explore Creative Portfolios',
                  style: AppTheme.headingMedium.copyWith(
                    color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  _isSearchingUsers
                      ? 'Connect with talented artists, designers, and professionals from around the world'
                      : 'Browse through stunning portfolios, creative works, and inspiring projects',
                  style: AppTheme.bodyLarge.copyWith(
                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.3, duration: 800.ms),

          const SizedBox(height: 28),

          // Enhanced Search Tips Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurfaceColor : AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.primaryColor.withOpacity(0.15),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: (isDark ? Colors.black : Colors.grey).withOpacity(0.1),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.lightbulb_outline_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Pro Search Tips',
                      style: AppTheme.bodyLarge.copyWith(
                        color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (_isSearchingUsers) ...[
                  _buildEnhancedSearchTip(Icons.person_search_rounded, 'Search by name or username', 'Find specific creators'),
                  _buildEnhancedSearchTip(Icons.alternate_email_rounded, 'Search by email address', 'Connect with colleagues'),
                  _buildEnhancedSearchTip(Icons.category_rounded, 'Browse by category', 'Discover new talents'),
                ] else ...[
                  _buildEnhancedSearchTip(Icons.work_outline_rounded, 'Search portfolio names', 'Find specific projects'),
                  _buildEnhancedSearchTip(Icons.category_rounded, 'Filter by category', 'Explore different fields'),
                  _buildEnhancedSearchTip(Icons.description_rounded, 'Search descriptions', 'Find detailed content'),
                ],
              ],
            ),
          ).animate().fadeIn(duration: 600.ms, delay: 400.ms).slideX(begin: -0.3, duration: 600.ms),

          const SizedBox(height: 28),

          // Popular Categories Section
          Row(
            children: [
              Icon(
                Icons.trending_up_rounded,
                color: AppTheme.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Trending Categories',
                style: AppTheme.headingSmall.copyWith(
                  color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildEnhancedCategoryChips(),
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

  Widget _buildEnhancedSearchTip(IconData icon, String title, String subtitle) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.bodyMedium.copyWith(
                    color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTheme.bodySmall.copyWith(
                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedCategoryChips() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        'Digital Art', 'Music & Audio', 'Tech & Programming',
        'Photography', 'Video & Animation', 'Writing & Literature',
        'Design & UI/UX', 'Gaming', 'Crafts & DIY', 'Business & Entrepreneurship'
      ].asMap().entries.map((entry) {
        return GestureDetector(
          onTap: () {
            _searchController.text = entry.value;
            _performSearch(entry.value);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor,
                  AppTheme.accentColor,
                ],
              ),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getCategoryIcon(entry.value),
                  size: 16,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Text(
                  entry.value,
                  style: AppTheme.bodyMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ).animate().fadeIn(
          duration: 500.ms,
          delay: Duration(milliseconds: 600 + (entry.key * 100)),
        ).scale(
          begin: const Offset(0.8, 0.8),
          duration: 500.ms,
          delay: Duration(milliseconds: 600 + (entry.key * 100)),
        ).slideY(
          begin: 0.3,
          duration: 500.ms,
          delay: Duration(milliseconds: 600 + (entry.key * 100)),
        );
      }).toList(),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Digital Art': return Icons.palette_rounded;
      case 'Music & Audio': return Icons.music_note_rounded;
      case 'Tech & Programming': return Icons.code_rounded;
      case 'Photography': return Icons.camera_alt_rounded;
      case 'Video & Animation': return Icons.videocam_rounded;
      case 'Writing & Literature': return Icons.edit_rounded;
      case 'Design & UI/UX': return Icons.design_services_rounded;
      case 'Gaming': return Icons.sports_esports_rounded;
      case 'Crafts & DIY': return Icons.handyman_rounded;
      case 'Business & Entrepreneurship': return Icons.business_rounded;
      default: return Icons.category_rounded;
    }
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
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Enhanced Empty State Illustration
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primaryColor.withOpacity(0.1),
                    AppTheme.accentColor.withOpacity(0.05),
                    Colors.transparent,
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.primaryColor.withOpacity(0.2),
                  width: 2,
                ),
              ),
              child: Icon(
                _isSearchingUsers ? Icons.person_search_rounded : Icons.search_off_rounded,
                size: 64,
                color: AppTheme.primaryColor,
              ),
            ).animate(onPlay: (controller) => controller.repeat())
              .scale(begin: const Offset(1.0, 1.0), end: const Offset(1.1, 1.1), duration: 2000.ms)
              .then()
              .scale(begin: const Offset(1.1, 1.1), end: const Offset(1.0, 1.0), duration: 2000.ms),

            const SizedBox(height: 32),

            Text(
              _isSearchingUsers ? '🔍 No Users Found' : '📂 No Portfolios Found',
              style: AppTheme.headingMedium.copyWith(
                color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            Text(
              _isSearchingUsers
                  ? 'We couldn\'t find any users matching your search.\nTry different keywords or browse categories below.'
                  : 'We couldn\'t find any portfolios matching your search.\nTry different keywords or explore trending categories.',
              style: AppTheme.bodyLarge.copyWith(
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            // Suggestion Cards
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurfaceColor : AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.tips_and_updates_rounded,
                        color: AppTheme.primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Search Suggestions',
                        style: AppTheme.bodyLarge.copyWith(
                          color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSuggestionItem(Icons.check_circle_outline, 'Check your spelling'),
                  _buildSuggestionItem(Icons.short_text_rounded, 'Try shorter, more general terms'),
                  _buildSuggestionItem(Icons.category_rounded, 'Browse by category instead'),
                  _buildSuggestionItem(Icons.refresh_rounded, 'Try a different search approach'),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Quick Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchResults = [];
                      _hasSearched = false;
                    });
                  },
                  icon: Icon(Icons.refresh_rounded),
                  label: Text('New Search'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _isSearchingUsers = !_isSearchingUsers;
                      _searchResults = [];
                      _hasSearched = false;
                    });
                    _searchController.clear();
                  },
                  icon: Icon(_isSearchingUsers ? Icons.work_outline : Icons.people_outline),
                  label: Text(_isSearchingUsers ? 'Search Portfolios' : 'Search Users'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                    side: BorderSide(color: AppTheme.primaryColor),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.3, duration: 600.ms);
  }

  Widget _buildSuggestionItem(IconData icon, String text) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: AppTheme.bodyMedium.copyWith(
              color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.spaceMedium),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final item = _searchResults[index];
        if (_isSearchingUsers) {
          return _buildUserCard(item, index);
        } else {
          return _buildPortfolioCard(item, index);
        }
      },
    );
  }

  Widget _buildUserCard(dynamic user, int index) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return ModernCard(
      margin: const EdgeInsets.only(bottom: 16),
      onTap: () {
        // Navigate to user profile
        if (user['uid'] != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PublicProfileScreen(uid: user['uid']),
            ),
          );
        }
      },
      child: Row(
        children: [
          // Profile Image
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: user['profileImageUrl'] == null
                  ? AppTheme.primaryGradient
                  : null,
              border: Border.all(
                color: AppTheme.primaryColor.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: user['profileImageUrl'] != null
                ? ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: user['profileImageUrl']!,
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
                  user['name'] ?? 'Unknown User',
                  style: AppTheme.labelLarge.copyWith(
                    color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
                  ),
                ),
                if ((user['username'] ?? '').isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    '@${user['username']}',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
                if ((user['categories'] as List?)?.isNotEmpty == true) ...[
                  const SizedBox(height: 4),
                  Text(
                    (user['categories'] as List).take(2).join(', '),
                    style: AppTheme.bodySmall.copyWith(
                      color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Follow/Open Button
          _buildUserActionButton(user),
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

  Widget _buildUserActionButton(dynamic user) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isOwnProfile = currentUser != null && user['uid'] == currentUser.uid;

    return GestureDetector(
      onTap: () {
        if (isOwnProfile) {
          // Navigate to own profile screen (not public profile)
          Navigator.pushNamed(context, '/profile');
        } else {
          // Handle follow/unfollow logic for other users
          // TODO: Implement follow/unfollow functionality
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Follow functionality coming soon!'),
              backgroundColor: AppTheme.primaryColor,
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: isOwnProfile
              ? LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFFFF6B9D)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isOwnProfile ? Icons.open_in_new : Icons.person_add,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              isOwnProfile ? 'Open' : 'Follow',
              style: AppTheme.bodySmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPortfolioCard(dynamic portfolio, int index) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return ModernCard(
      margin: const EdgeInsets.only(bottom: 16),
      onTap: () {
        // Navigate to portfolio profile
        if (portfolio['_id'] != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PortfolioProfileScreen(portfolioId: portfolio['_id']),
            ),
          );
        }
      },
      child: Row(
        children: [
          // Portfolio Image/Icon
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: portfolio['coverImageUrl'] == null
                  ? AppTheme.primaryGradient
                  : null,
              border: Border.all(
                color: AppTheme.primaryColor.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: portfolio['coverImageUrl'] != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: CachedNetworkImage(
                      imageUrl: portfolio['coverImageUrl']!,
                      fit: BoxFit.cover,
                      width: 60,
                      height: 60,
                      placeholder: (context, url) => Container(
                        decoration: const BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                        ),
                        child: const Icon(
                          Icons.work,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        decoration: const BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                        ),
                        child: const Icon(
                          Icons.work,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ),
                  )
                : const Icon(
                    Icons.work,
                    color: Colors.white,
                    size: 30,
                  ),
          ),
          const SizedBox(width: 16),
          // Portfolio Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  portfolio['profilename'] ?? 'Untitled Portfolio',
                  style: AppTheme.labelLarge.copyWith(
                    color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
                  ),
                ),
                if ((portfolio['category'] ?? '').isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      portfolio['category'],
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                if ((portfolio['description'] ?? '').isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    portfolio['description'],
                    style: AppTheme.bodySmall.copyWith(
                      color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if ((portfolio['ownerName'] ?? '').isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.person_outline,
                        size: 14,
                        color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'by ${portfolio['ownerName']}',
                        style: AppTheme.bodySmall.copyWith(
                          color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          // View Button
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
              'View',
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