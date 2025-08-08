import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ConnectionUserCard extends StatefulWidget {
  final Map<String, dynamic> user;
  final Future<void> Function() onFollowToggle;
  final VoidCallback onMessage;
  final VoidCallback onProfileTap;

  const ConnectionUserCard({
    Key? key,
    required this.user,
    required this.onFollowToggle,
    required this.onMessage,
    required this.onProfileTap,
  }) : super(key: key);

  @override
  State<ConnectionUserCard> createState() => _ConnectionUserCardState();
}

class _ConnectionUserCardState extends State<ConnectionUserCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final bool isFollowing = user['isFollowingBack'] ?? false;
    final bool isCurrentUser = user['isCurrentUser'] ?? false;
    final int mutualConnections = user['mutualConnections'] ?? 0;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            margin: EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Color(0xFF2A2A2A), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(51),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: widget.onProfileTap,
                onTapDown: (_) => _animationController.forward(),
                onTapUp: (_) => _animationController.reverse(),
                onTapCancel: () => _animationController.reverse(),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Avatar with status indicator
                      Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: isCurrentUser
                                    ? [Colors.amber, Colors.orange]
                                    : isFollowing
                                        ? [Color(0xFF6C63FF), Color(0xFFFF6B9D)]
                                        : [Colors.blue, Colors.lightBlue],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: (isCurrentUser ? Colors.amber : isFollowing ? Color(0xFF6C63FF) : Colors.blue).withAlpha(76),
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            padding: EdgeInsets.all(2),
                            child: CircleAvatar(
                              radius: 28,
                              backgroundColor: Color(0xFF1A1A1A),
                              backgroundImage: user['profileImageUrl'] != null && user['profileImageUrl'].isNotEmpty
                                  ? NetworkImage(user['profileImageUrl'])
                                  : null,
                              child: user['profileImageUrl'] == null || user['profileImageUrl'].isEmpty
                                  ? Text(
                                      (user['name'] ?? 'U')[0].toUpperCase(),
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                          
                          // Status indicators
                          if (isCurrentUser)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.amber,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Color(0xFF1A1A1A), width: 2),
                                ),
                                child: Icon(Icons.star, size: 12, color: Colors.white),
                              ),
                            ),
                        ],
                      ),
                      
                      SizedBox(width: 16),
                      
                      // User info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    user['name'] ?? 'Unknown User',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isCurrentUser)
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.withAlpha(51),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'YOU',
                                      style: GoogleFonts.poppins(
                                        color: Colors.amber,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            
                            Text(
                              '@${user['username'] ?? 'unknown'}',
                              style: GoogleFonts.poppins(
                                color: Colors.grey[400],
                                fontSize: 14,
                              ),
                            ),
                            
                            SizedBox(height: 4),
                            
                            Row(
                              children: [
                                Text(
                                  '${user['followersCount'] ?? 0} followers',
                                  style: GoogleFonts.poppins(
                                    color: Colors.grey[500],
                                    fontSize: 12,
                                  ),
                                ),
                                if (mutualConnections > 0) ...[
                                  Text(' • ', style: TextStyle(color: Colors.grey[500])),
                                  Text(
                                    '$mutualConnections mutual',
                                    style: GoogleFonts.poppins(
                                      color: Colors.blue,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            
                            if (user['bio'] != null && user['bio'].isNotEmpty)
                              Padding(
                                padding: EdgeInsets.only(top: 6),
                                child: Text(
                                  user['bio'],
                                  style: GoogleFonts.poppins(
                                    color: Colors.grey[300],
                                    fontSize: 13,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                        ),
                      ),
                      
                      SizedBox(width: 12),
                      
                      // Action buttons
                      if (!isCurrentUser)
                        Column(
                          children: [
                            // Follow/Following button
                            AnimatedContainer(
                              duration: Duration(milliseconds: 200),
                              child: ElevatedButton(
                                onPressed: isLoading ? null : () async {
                                  setState(() => isLoading = true);
                                  await widget.onFollowToggle();
                                  setState(() => isLoading = false);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isFollowing ? Color(0xFF2A2A2A) : Colors.blue,
                                  foregroundColor: isFollowing ? Colors.grey[300] : Colors.white,
                                  minimumSize: Size(85, 36),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                    side: isFollowing ? BorderSide(color: Color(0xFF3A3A3A)) : BorderSide.none,
                                  ),
                                  elevation: isFollowing ? 0 : 2,
                                ),
                                child: isLoading
                                    ? SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        isFollowing ? 'Following' : 'Follow',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),
                            
                            SizedBox(height: 8),
                            
                            // Message button
                            OutlinedButton(
                              onPressed: widget.onMessage,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.grey[300],
                                side: BorderSide(color: Color(0xFF3A3A3A)),
                                minimumSize: Size(85, 32),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.message_outlined, size: 14),
                                  SizedBox(width: 4),
                                  Text(
                                    'Message',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
