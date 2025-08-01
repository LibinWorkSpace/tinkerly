import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../constants/api_constants.dart';
import '../../widgets/enhanced_music_player_widget.dart';

class MusicCategoryScreen extends StatefulWidget {
  const MusicCategoryScreen({Key? key}) : super(key: key);

  @override
  State<MusicCategoryScreen> createState() => _MusicCategoryScreenState();
}

class _MusicCategoryScreenState extends State<MusicCategoryScreen> {
  List<dynamic> _audioTracks = [];
  bool _isLoading = true;
  String? _currentPlayingId;

  @override
  void initState() {
    super.initState();
    _fetchAudioTracks();
  }

  Future<void> _fetchAudioTracks() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final idToken = await user?.getIdToken();
      
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/posts/audio'),
        headers: {'Authorization': 'Bearer $idToken'},
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> allPosts = jsonDecode(response.body);
        setState(() {
          _audioTracks = allPosts.where((post) => post['mediaType'] == 'audio').toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching audio tracks: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0A0A0A),
      body: SafeArea(
        child: Column(
          children: [
            // Header with back button
            Container(
              padding: EdgeInsets.all(20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Music',
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '${_audioTracks.length} tracks',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                  Spacer(),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF1DB954), Color(0xFF1ED760)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Icon(
                      Icons.shuffle,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
            
            // Music List
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1DB954)),
                      ),
                    )
                  : _audioTracks.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.music_off,
                                size: 64,
                                color: Colors.white.withOpacity(0.5),
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No music tracks found',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  color: Colors.white.withOpacity(0.7),
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Be the first to share some music!',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.5),
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _fetchAudioTracks,
                          color: Color(0xFF1DB954),
                          backgroundColor: Color(0xFF1A1A1A),
                          child: ListView.builder(
                            padding: EdgeInsets.symmetric(horizontal: 20),
                            itemCount: _audioTracks.length,
                            itemBuilder: (context, index) {
                              final track = _audioTracks[index];
                              final isPlaying = _currentPlayingId == track['_id'];
                              
                              return _buildTrackItem(track, index, isPlaying);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackItem(dynamic track, int index, bool isPlaying) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isPlaying ? Color(0xFF1DB954).withOpacity(0.1) : Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: isPlaying 
            ? Border.all(color: Color(0xFF1DB954), width: 1)
            : null,
      ),
      child: Row(
        children: [
          // Track number or play indicator
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isPlaying ? Color(0xFF1DB954) : Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: isPlaying
                  ? Icon(Icons.pause, color: Colors.white, size: 20)
                  : Text(
                      '${index + 1}',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
          SizedBox(width: 16),
          
          // Track info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  track['description'] ?? 'Untitled Track',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isPlaying ? Color(0xFF1DB954) : Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4),
                Text(
                  track['username'] ?? 'Unknown Artist',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
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
              
              // Show music player widget
              if (!isPlaying) {
                _showMusicPlayer(track);
              }
            },
            child: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Color(0xFF1DB954),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
                size: 20,
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
      builder: (context) => EnhancedMusicPlayerWidget(
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
