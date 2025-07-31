import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants/api_constants.dart';
import '../widgets/music_player_widget.dart';

class MusicPortfolioWidget extends StatefulWidget {
  final String userId;
  final bool isOwnProfile;

  const MusicPortfolioWidget({
    Key? key,
    required this.userId,
    required this.isOwnProfile,
  }) : super(key: key);

  @override
  State<MusicPortfolioWidget> createState() => _MusicPortfolioWidgetState();
}

class _MusicPortfolioWidgetState extends State<MusicPortfolioWidget> {
  List<dynamic> _musicTracks = [];
  bool _isLoading = true;
  String? _currentPlayingId;

  @override
  void initState() {
    super.initState();
    print('🎵 MusicPortfolioWidget initialized for user: ${widget.userId}');
    _fetchUserMusicTracks();
  }

  Future<void> _fetchUserMusicTracks() async {
    try {
      print('🎵 Fetching music tracks for user: ${widget.userId}');
      final user = FirebaseAuth.instance.currentUser;
      final idToken = await user?.getIdToken();

      final url = '${ApiConstants.baseUrl}/posts/user/${widget.userId}/audio';
      print('🎵 API URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $idToken'},
      );

      print('🎵 Response status: ${response.statusCode}');
      print('🎵 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> tracks = jsonDecode(response.body);
        print('🎵 Found ${tracks.length} music tracks');
        setState(() {
          _musicTracks = tracks;
          _isLoading = false;
        });
      } else {
        print('🎵 Failed to fetch music tracks: ${response.statusCode}');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('🎵 Error fetching user music tracks: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: 200,
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1DB954)),
          ),
        ),
      );
    }

    if (_musicTracks.isEmpty) {
      return Container(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.music_note,
              size: 48,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              widget.isOwnProfile ? 'No music tracks yet' : 'No music shared',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              widget.isOwnProfile 
                  ? 'Share your first music track!' 
                  : 'This user hasn\'t shared any music yet',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF0A0A0A),
            Color(0xFF1A1A1A),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF1DB954), Color(0xFF1ED760)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.music_note,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Music Collection',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${_musicTracks.length} track${_musicTracks.length != 1 ? 's' : ''}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
                Spacer(),
                if (_musicTracks.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      // Play all tracks
                      _showMusicPlayer(_musicTracks[0]);
                    },
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Color(0xFF1DB954),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Music tracks list
          Container(
            height: _musicTracks.length > 3 ? 240 : _musicTracks.length * 80.0,
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 20),
              itemCount: _musicTracks.length > 3 ? 3 : _musicTracks.length,
              itemBuilder: (context, index) {
                final track = _musicTracks[index];
                final isPlaying = _currentPlayingId == track['_id'];
                
                return _buildCompactTrackItem(track, index, isPlaying);
              },
            ),
          ),
          
          // View all button if more than 3 tracks
          if (_musicTracks.length > 3)
            Container(
              padding: EdgeInsets.all(20),
              child: GestureDetector(
                onTap: () {
                  // Navigate to full music list
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => UserMusicListScreen(
                        userId: widget.userId,
                        tracks: _musicTracks,
                        isOwnProfile: widget.isOwnProfile,
                      ),
                    ),
                  );
                },
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                  decoration: BoxDecoration(
                    border: Border.all(color: Color(0xFF1DB954), width: 1),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View All ${_musicTracks.length} Tracks',
                        style: GoogleFonts.poppins(
                          color: Color(0xFF1DB954),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward,
                        color: Color(0xFF1DB954),
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCompactTrackItem(dynamic track, int index, bool isPlaying) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isPlaying ? Color(0xFF1DB954).withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isPlaying 
            ? Border.all(color: Color(0xFF1DB954), width: 1)
            : null,
      ),
      child: Row(
        children: [
          // Track number
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: isPlaying ? Color(0xFF1DB954) : Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: isPlaying
                  ? Icon(Icons.pause, color: Colors.white, size: 12)
                  : Text(
                      '${index + 1}',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
          SizedBox(width: 12),
          
          // Track info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  track['description'] ?? 'Untitled Track',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isPlaying ? Color(0xFF1DB954) : Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Audio Track',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          
          // Play button
          GestureDetector(
            onTap: () {
              setState(() {
                _currentPlayingId = isPlaying ? null : track['_id'];
              });
              
              if (!isPlaying) {
                _showMusicPlayer(track);
              }
            },
            child: Container(
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Color(0xFF1DB954),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
                size: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMusicPlayer(dynamic track) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => MusicPlayerWidget(
        track: track,
        onClose: () {
          setState(() {
            _currentPlayingId = null;
          });
          Navigator.pop(context);
        },
      ),
    );
  }
}

// Placeholder for full music list screen
class UserMusicListScreen extends StatelessWidget {
  final String userId;
  final List<dynamic> tracks;
  final bool isOwnProfile;

  const UserMusicListScreen({
    Key? key,
    required this.userId,
    required this.tracks,
    required this.isOwnProfile,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Color(0xFF0A0A0A),
        title: Text(
          isOwnProfile ? 'My Music' : 'Music Collection',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Text(
          'Full music list coming soon!',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
      ),
    );
  }
}
