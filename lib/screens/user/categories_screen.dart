import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'music_category_screen.dart';
import 'category_feed_screen.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0A0A0A), // Dark background like Spotify
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(20),
              child: Row(
                children: [
                  Text(
                    'Categories',
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Spacer(),
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.search,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
            
            // Categories Grid
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.5,
                  children: [
                    _buildCategoryCard(
                      context,
                      'Music',
                      Icons.music_note,
                      [Color(0xFF1DB954), Color(0xFF1ED760)], // Spotify green
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => MusicCategoryScreen()),
                      ),
                    ),
                    _buildCategoryCard(
                      context,
                      'Art & Design',
                      Icons.palette,
                      [Color(0xFFFF6B9D), Color(0xFFC44569)],
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CategoryFeedScreen(
                            category: 'Digital Art',
                            primaryColor: Color(0xFFFF6B9D),
                            secondaryColor: Color(0xFFC44569),
                            icon: Icons.palette,
                          ),
                        ),
                      ),
                    ),
                    _buildCategoryCard(
                      context,
                      'Photography',
                      Icons.camera_alt,
                      [Color(0xFF6C63FF), Color(0xFF5A52FF)],
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CategoryFeedScreen(
                            category: 'Photography',
                            primaryColor: Color(0xFF6C63FF),
                            secondaryColor: Color(0xFF5A52FF),
                            icon: Icons.camera_alt,
                          ),
                        ),
                      ),
                    ),
                    _buildCategoryCard(
                      context,
                      'Videos',
                      Icons.videocam,
                      [Color(0xFFFF9500), Color(0xFFFF6B35)],
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CategoryFeedScreen(
                            category: 'Videos',
                            primaryColor: Color(0xFFFF9500),
                            secondaryColor: Color(0xFFFF6B35),
                            icon: Icons.videocam,
                          ),
                        ),
                      ),
                    ),
                    _buildCategoryCard(
                      context,
                      'Fashion',
                      Icons.checkroom,
                      [Color(0xFFE056FD), Color(0xFFB721FF)],
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CategoryFeedScreen(
                            category: 'Fashion',
                            primaryColor: Color(0xFFE056FD),
                            secondaryColor: Color(0xFFB721FF),
                            icon: Icons.checkroom,
                          ),
                        ),
                      ),
                    ),
                    _buildCategoryCard(
                      context,
                      'Technology',
                      Icons.computer,
                      [Color(0xFF00D4AA), Color(0xFF00A693)],
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CategoryFeedScreen(
                            category: 'Programming',
                            primaryColor: Color(0xFF00D4AA),
                            secondaryColor: Color(0xFF00A693),
                            icon: Icons.computer,
                          ),
                        ),
                      ),
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

  Widget _buildCategoryCard(
    BuildContext context,
    String title,
    IconData icon,
    List<Color> gradientColors,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: gradientColors[0].withOpacity(0.3),
              blurRadius: 12,
              spreadRadius: 0,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background pattern
            Positioned(
              right: -20,
              bottom: -20,
              child: Icon(
                icon,
                size: 80,
                color: Colors.white.withOpacity(0.2),
              ),
            ),
            // Content
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    icon,
                    color: Colors.white,
                    size: 32,
                  ),
                  Spacer(),
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
