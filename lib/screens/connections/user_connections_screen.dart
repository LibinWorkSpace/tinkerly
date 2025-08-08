import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../constants/api_constants.dart';
import '../../services/user_service.dart';
import '../user/profile_screen.dart';
import '../../widgets/connection_user_card.dart';

class UserConnectionsScreen extends StatefulWidget {
  final String userId;
  final String userName;
  final int initialTab; // 0 = followers, 1 = following

  const UserConnectionsScreen({
    Key? key,
    required this.userId,
    required this.userName,
    this.initialTab = 0,
  }) : super(key: key);

  @override
  State<UserConnectionsScreen> createState() => _UserConnectionsScreenState();
}

class _UserConnectionsScreenState extends State<UserConnectionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> followers = [];
  List<dynamic> following = [];
  bool isLoadingFollowers = true;
  bool isLoadingFollowing = true;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      initialIndex: widget.initialTab,
      vsync: this,
    );
    _loadConnections();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadConnections() async {
    await Future.wait([
      _loadFollowers(),
      _loadFollowing(),
    ]);
  }

  Future<void> _loadFollowers() async {
    try {
      final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/user/${widget.userId}/followers'),
        headers: {'Authorization': 'Bearer $idToken'},
      );

      if (response.statusCode == 200) {
        setState(() {
          followers = jsonDecode(response.body);
          isLoadingFollowers = false;
        });
      }
    } catch (e) {
      print('Error loading followers: $e');
      setState(() => isLoadingFollowers = false);
    }
  }

  Future<void> _loadFollowing() async {
    try {
      final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/user/${widget.userId}/following'),
        headers: {'Authorization': 'Bearer $idToken'},
      );

      if (response.statusCode == 200) {
        setState(() {
          following = jsonDecode(response.body);
          isLoadingFollowing = false;
        });
      }
    } catch (e) {
      print('Error loading following: $e');
      setState(() => isLoadingFollowing = false);
    }
  }

  List<dynamic> _filterConnections(List<dynamic> connections) {
    if (searchQuery.isEmpty) return connections;
    return connections.where((user) {
      final name = (user['name'] ?? '').toLowerCase();
      final username = (user['username'] ?? '').toLowerCase();
      final query = searchQuery.toLowerCase();
      return name.contains(query) || username.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final bool isCurrentUser = widget.userId == FirebaseAuth.instance.currentUser?.uid;
    
    return Scaffold(
      backgroundColor: Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Color(0xFF0A0A0A),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isCurrentUser ? 'Your Connections' : '${widget.userName}\'s Connections',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${followers.length} followers • ${following.length} following',
              style: GoogleFonts.poppins(
                color: Colors.grey[400],
                fontSize: 12,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(100),
          child: Column(
            children: [
              // Search bar
              Container(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Color(0xFF2A2A2A)),
                ),
                child: TextField(
                  style: GoogleFonts.poppins(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search connections...',
                    hintStyle: GoogleFonts.poppins(color: Colors.grey[500]),
                    prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: (value) {
                    setState(() => searchQuery = value);
                  },
                ),
              ),
              
              // Tabs
              Container(
                margin: EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.grey[400],
                  labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  unselectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w400),
                  tabs: [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline, size: 16),
                          SizedBox(width: 6),
                          Text('Followers'),
                          SizedBox(width: 4),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.withAlpha(51),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${followers.length}',
                              style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_add_outlined, size: 16),
                          SizedBox(width: 6),
                          Text('Following'),
                          SizedBox(width: 4),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.withAlpha(51),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${following.length}',
                              style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFollowersTab(),
          _buildFollowingTab(),
        ],
      ),
    );
  }

  Widget _buildFollowersTab() {
    if (isLoadingFollowers) {
      return Center(
        child: CircularProgressIndicator(color: Colors.blue),
      );
    }

    final filteredFollowers = _filterConnections(followers);

    if (filteredFollowers.isEmpty) {
      return _buildEmptyState(
        icon: Icons.people_outline,
        title: searchQuery.isEmpty ? 'No followers yet' : 'No followers found',
        subtitle: searchQuery.isEmpty 
          ? 'When people follow ${widget.userName}, they\'ll appear here'
          : 'Try a different search term',
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: filteredFollowers.length,
      itemBuilder: (context, index) {
        return ConnectionUserCard(
          user: filteredFollowers[index],
          onFollowToggle: () async => await _toggleFollow(filteredFollowers[index]),
          onMessage: () => _openMessage(filteredFollowers[index]),
          onProfileTap: () => _openProfile(filteredFollowers[index]),
        );
      },
    );
  }

  Widget _buildFollowingTab() {
    if (isLoadingFollowing) {
      return Center(
        child: CircularProgressIndicator(color: Colors.blue),
      );
    }

    final filteredFollowing = _filterConnections(following);

    if (filteredFollowing.isEmpty) {
      return _buildEmptyState(
        icon: Icons.person_add_outlined,
        title: searchQuery.isEmpty ? 'Not following anyone' : 'No users found',
        subtitle: searchQuery.isEmpty 
          ? '${widget.userName} hasn\'t followed anyone yet'
          : 'Try a different search term',
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: filteredFollowing.length,
      itemBuilder: (context, index) {
        return ConnectionUserCard(
          user: filteredFollowing[index],
          onFollowToggle: () async => await _toggleFollow(filteredFollowing[index]),
          onMessage: () => _openMessage(filteredFollowing[index]),
          onProfileTap: () => _openProfile(filteredFollowing[index]),
        );
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Color(0xFF1A1A1A),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 48, color: Colors.grey[600]),
          ),
          SizedBox(height: 24),
          Text(
            title,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              color: Colors.grey[400],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _toggleFollow(dynamic user) async {
    try {
      final bool isFollowing = user['isFollowingBack'] ?? false;
      bool success;
      
      if (isFollowing) {
        success = await UserService.unfollowUser(user['uid']);
      } else {
        success = await UserService.followUser(user['uid']);
      }

      if (success) {
        // Refresh the connections
        await _loadConnections();
      }
    } catch (e) {
      print('Error toggling follow: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update follow status')),
      );
    }
  }

  void _openMessage(dynamic user) {
    // TODO: Implement messaging
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Messaging feature coming soon!')),
    );
  }

  void _openProfile(dynamic user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PublicProfileScreen(uid: user['uid']),
      ),
    );
  }
}
