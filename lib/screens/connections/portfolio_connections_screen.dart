import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../constants/api_constants.dart';
import '../../services/user_service.dart';
import '../../widgets/connection_user_card.dart';
import '../user/profile_screen.dart';
import '../user/portfolio_profile_screen.dart';

class PortfolioConnectionsScreen extends StatefulWidget {
  final String? portfolioId;
  final String? portfolioName;
  final String? userId; // For showing user's followed portfolios

  const PortfolioConnectionsScreen({
    Key? key,
    this.portfolioId,
    this.portfolioName,
    this.userId,
  }) : super(key: key);

  @override
  State<PortfolioConnectionsScreen> createState() => _PortfolioConnectionsScreenState();
}

class _PortfolioConnectionsScreenState extends State<PortfolioConnectionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> portfolioFollowers = [];
  List<dynamic> followedPortfolios = [];
  Map<String, dynamic>? portfolioInfo;
  bool isLoadingFollowers = true;
  bool isLoadingPortfolios = true;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.wait([
      if (widget.portfolioId != null) _loadPortfolioFollowers(),
      _loadFollowedPortfolios(),
    ]);
  }

  Future<void> _loadPortfolioFollowers() async {
    try {
      final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/portfolios/${widget.portfolioId}/followers'),
        headers: {'Authorization': 'Bearer $idToken'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          portfolioInfo = data['portfolio'];
          portfolioFollowers = data['followers'];
          isLoadingFollowers = false;
        });
      }
    } catch (e) {
      print('Error loading portfolio followers: $e');
      setState(() => isLoadingFollowers = false);
    }
  }

  Future<void> _loadFollowedPortfolios() async {
    try {
      final currentUserId = widget.userId ?? FirebaseAuth.instance.currentUser?.uid;
      final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/portfolios/user/$currentUserId/followed'),
        headers: {'Authorization': 'Bearer $idToken'},
      );

      if (response.statusCode == 200) {
        setState(() {
          followedPortfolios = jsonDecode(response.body);
          isLoadingPortfolios = false;
        });
      }
    } catch (e) {
      print('Error loading followed portfolios: $e');
      setState(() => isLoadingPortfolios = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool showPortfolioFollowers = widget.portfolioId != null;
    
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
              showPortfolioFollowers 
                ? '${widget.portfolioName ?? 'Portfolio'} Connections'
                : 'Portfolio Connections',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (showPortfolioFollowers && portfolioInfo != null)
              Text(
                '${portfolioFollowers.length} followers',
                style: GoogleFonts.poppins(
                  color: Colors.grey[400],
                  fontSize: 12,
                ),
              ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(showPortfolioFollowers ? 100 : 60),
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
                    hintText: 'Search...',
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
              
              // Tabs (only if showing portfolio followers)
              if (showPortfolioFollowers)
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
                                '${portfolioFollowers.length}',
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
                            Icon(Icons.folder_special_outlined, size: 16),
                            SizedBox(width: 6),
                            Text('My Portfolios'),
                            SizedBox(width: 4),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.purple.withAlpha(51),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${followedPortfolios.length}',
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
      body: showPortfolioFollowers
          ? TabBarView(
              controller: _tabController,
              children: [
                _buildPortfolioFollowersTab(),
                _buildFollowedPortfoliosTab(),
              ],
            )
          : _buildFollowedPortfoliosTab(),
    );
  }

  Widget _buildPortfolioFollowersTab() {
    if (isLoadingFollowers) {
      return Center(child: CircularProgressIndicator(color: Colors.blue));
    }

    final filteredFollowers = _filterUsers(portfolioFollowers);

    if (filteredFollowers.isEmpty) {
      return _buildEmptyState(
        icon: Icons.people_outline,
        title: 'No followers yet',
        subtitle: 'When people follow this portfolio, they\'ll appear here',
        color: Colors.blue,
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: filteredFollowers.length,
      itemBuilder: (context, index) {
        return ConnectionUserCard(
          user: filteredFollowers[index],
          onFollowToggle: () async => await _toggleUserFollow(filteredFollowers[index]),
          onMessage: () => _openMessage(filteredFollowers[index]),
          onProfileTap: () => _openProfile(filteredFollowers[index]),
        );
      },
    );
  }

  Widget _buildFollowedPortfoliosTab() {
    if (isLoadingPortfolios) {
      return Center(child: CircularProgressIndicator(color: Colors.purple));
    }

    final filteredPortfolios = _filterPortfolios(followedPortfolios);

    if (filteredPortfolios.isEmpty) {
      return _buildEmptyState(
        icon: Icons.folder_special_outlined,
        title: 'No followed portfolios',
        subtitle: 'Portfolios you follow will appear here',
        color: Colors.purple,
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: filteredPortfolios.length,
      itemBuilder: (context, index) {
        return _buildPortfolioCard(filteredPortfolios[index]);
      },
    );
  }



  Widget _buildPortfolioCard(dynamic portfolio) {
    return Container(
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
          onTap: () => _openPortfolio(portfolio),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                // Portfolio avatar
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Colors.purple, Colors.deepPurple],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple.withAlpha(76),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.all(2),
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor: Color(0xFF1A1A1A),
                    backgroundImage: portfolio['profileImageUrl'] != null && portfolio['profileImageUrl'].isNotEmpty
                        ? NetworkImage(portfolio['profileImageUrl'])
                        : null,
                    child: portfolio['profileImageUrl'] == null || portfolio['profileImageUrl'].isEmpty
                        ? Icon(Icons.folder_special, color: Colors.white, size: 24)
                        : null,
                  ),
                ),
                
                SizedBox(width: 16),
                
                // Portfolio info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        portfolio['profilename'] ?? 'Portfolio',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      
                      Text(
                        'by @${portfolio['owner']['username']}',
                        style: GoogleFonts.poppins(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                      ),
                      
                      SizedBox(height: 4),
                      
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.purple.withAlpha(51),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              portfolio['category'] ?? 'General',
                              style: GoogleFonts.poppins(
                                color: Colors.purple,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            '${portfolio['followersCount'] ?? 0} followers',
                            style: GoogleFonts.poppins(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Action buttons
                Column(
                  children: [
                    // View button
                    ElevatedButton(
                      onPressed: () => _openPortfolio(portfolio),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        minimumSize: Size(70, 32),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'View',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    
                    SizedBox(height: 6),
                    
                    // Unfollow button
                    OutlinedButton(
                      onPressed: () => _unfollowPortfolio(portfolio),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red[300],
                        side: BorderSide(color: Colors.red.withAlpha(102)),
                        minimumSize: Size(70, 28),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'Unfollow',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              shape: BoxShape.circle,
              border: Border.all(color: color.withAlpha(76), width: 2),
            ),
            child: Icon(icon, size: 64, color: color),
          ),
          SizedBox(height: 32),
          Text(
            title,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 12),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              subtitle,
              style: GoogleFonts.poppins(
                color: Colors.grey[400],
                fontSize: 14,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  List<dynamic> _filterUsers(List<dynamic> users) {
    if (searchQuery.isEmpty) return users;
    return users.where((user) {
      final name = (user['name'] ?? '').toLowerCase();
      final username = (user['username'] ?? '').toLowerCase();
      final query = searchQuery.toLowerCase();
      return name.contains(query) || username.contains(query);
    }).toList();
  }

  List<dynamic> _filterPortfolios(List<dynamic> portfolios) {
    if (searchQuery.isEmpty) return portfolios;
    return portfolios.where((portfolio) {
      final name = (portfolio['profilename'] ?? '').toLowerCase();
      final category = (portfolio['category'] ?? '').toLowerCase();
      final ownerName = (portfolio['owner']['name'] ?? '').toLowerCase();
      final query = searchQuery.toLowerCase();
      return name.contains(query) || category.contains(query) || ownerName.contains(query);
    }).toList();
  }

  Future<void> _toggleUserFollow(dynamic user) async {
    try {
      final bool isFollowing = user['isFollowingBack'] ?? false;
      bool success;

      if (isFollowing) {
        success = await UserService.unfollowUser(user['uid']);
      } else {
        success = await UserService.followUser(user['uid']);
      }

      if (success) {
        // Refresh the portfolio followers list
        if (widget.portfolioId != null) {
          await _loadPortfolioFollowers();
        }
      }
    } catch (e) {
      print('Error toggling user follow: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update follow status')),
        );
      }
    }
  }

  Future<void> _unfollowPortfolio(dynamic portfolio) async {
    try {
      final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
      final response = await http.delete(
        Uri.parse('${ApiConstants.baseUrl}/portfolios/${portfolio['_id']}/unfollow'),
        headers: {'Authorization': 'Bearer $idToken'},
      );

      if (response.statusCode == 200) {
        // Refresh the list
        await _loadFollowedPortfolios();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unfollowed ${portfolio['profilename']}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error unfollowing portfolio: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to unfollow portfolio')),
      );
    }
  }

  void _openMessage(dynamic user) {
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

  void _openPortfolio(dynamic portfolio) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PortfolioProfileScreen(portfolioId: portfolio['_id']),
      ),
    );
  }
}
