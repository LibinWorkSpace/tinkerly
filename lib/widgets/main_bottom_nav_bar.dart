import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MainBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const MainBottomNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 60,
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                context,
                index: 0,
                icon: Icons.home_rounded,
                label: 'Home',
                gradient: [Color(0xFF6C63FF), Color(0xFFFF6B9D)],
              ),
              _buildNavItem(
                context,
                index: 1,
                icon: Icons.search_rounded,
                label: 'Search',
                gradient: [Color(0xFF6C63FF), Color(0xFFFF6B9D)],
              ),
              _buildNavItem(
                context,
                index: 2,
                icon: Icons.add_circle_rounded,
                label: 'Add',
                gradient: [Color(0xFF6C63FF), Color(0xFFFF6B9D)],
                isSpecial: true,
              ),
              _buildNavItem(
                context,
                index: 3,
                icon: Icons.category_rounded,
                label: 'Categories',
                gradient: [Color(0xFF6C63FF), Color(0xFFFF6B9D)],
              ),
              _buildNavItem(
                context,
                index: 4,
                icon: Icons.person_rounded,
                label: 'Profile',
                gradient: [Color(0xFF6C63FF), Color(0xFFFF6B9D)],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required int index,
    required IconData icon,
    required String label,
    required List<Color> gradient,
    bool isSpecial = false,
  }) {
    final isSelected = currentIndex == index;
    final size = isSpecial ? 40.0 : 32.0;
    
    return GestureDetector(
      onTap: () => onTap(index),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                gradient: isSelected 
                  ? LinearGradient(
                      colors: gradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
                color: isSelected ? null : Color(0xFFF7FAFC),
                borderRadius: BorderRadius.circular(isSpecial ? 20 : 16),
                boxShadow: isSelected ? [
                  BoxShadow(
                    color: gradient[0].withOpacity(0.6),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ] : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 3,
                    offset: Offset(0, 1),
                  ),
                ],
                border: isSelected ? Border.all(
                  color: Colors.white,
                  width: 2,
                ) : Border.all(
                  color: Color(0xFFE2E8F0),
                  width: 1,
                ),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : Color(0xFF718096),
                size: isSpecial ? 18 : 14,
              ),
            ),
            SizedBox(height: 0),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 9,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? Color(0xFF6C63FF) : Color(0xFF718096),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 