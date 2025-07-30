import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class UnifiedProfileHeader extends StatelessWidget {
  final Map<String, dynamic> userProfile;
  final int postCount;
  final bool isOwnProfile;
  final VoidCallback? onEditProfile;

  const UnifiedProfileHeader({
    Key? key,
    required this.userProfile,
    required this.postCount,
    this.isOwnProfile = false,
    this.onEditProfile,
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
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
                color: Colors.white.withOpacity(0.3),
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 0,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 50,
              backgroundColor: Colors.white.withOpacity(0.2),
              backgroundImage: userProfile['profileImageUrl'] != null
                  ? NetworkImage(userProfile['profileImageUrl'])
                  : null,
              child: userProfile['profileImageUrl'] == null
                  ? Text(
                      userProfile['name']?.isNotEmpty == true
                          ? userProfile['name'][0].toUpperCase()
                          : 'N',
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
          // Name and Username
          Text(
            userProfile['name'] ?? '',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 24,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "@${userProfile['username'] ?? 'username'}",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w500,
              fontSize: 16,
              color: Colors.black.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 20),
          // Stats Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatColumn("Posts", postCount.toString()),
              if (isOwnProfile) ...[
                _buildStatColumn(
                    "Followers", (userProfile['followerCount'] ?? 0).toString()),
                _buildStatColumn(
                    "Following", (userProfile['followingCount'] ?? 0).toString()),
              ],
            ],
          ),
          // Bio
          if (userProfile['bio'] != null && userProfile['bio'].isNotEmpty) ...[
            const SizedBox(height: 20),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Text(
                userProfile['bio'],
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.black.withOpacity(0.9),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
          if (isOwnProfile) ...[
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
                    color: primaryColor.withOpacity(0.4),
                    blurRadius: 15,
                    spreadRadius: 0,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: onEditProfile,
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
                    Text('Edit Profile'),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w500,
            fontSize: 14,
            color: Colors.black.withOpacity(0.6),
          ),
        ),
      ],
    );
  }
}