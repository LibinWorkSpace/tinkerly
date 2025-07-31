import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MusicPlayerWidget extends StatefulWidget {
  final dynamic track;
  final VoidCallback onClose;

  const MusicPlayerWidget({
    Key? key,
    required this.track,
    required this.onClose,
  }) : super(key: key);

  @override
  State<MusicPlayerWidget> createState() => _MusicPlayerWidgetState();
}

class _MusicPlayerWidgetState extends State<MusicPlayerWidget>
    with TickerProviderStateMixin {
  bool isPlaying = false;
  bool isLoading = false;
  Duration duration = Duration(minutes: 3, seconds: 45); // Mock duration
  Duration position = Duration.zero;
  late AnimationController _rotationController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: Duration(seconds: 10),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      isPlaying = !isPlaying;
    });
    
    if (isPlaying) {
      _rotationController.repeat();
    } else {
      _rotationController.stop();
    }
    
    // TODO: Implement actual audio playback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Audio player will be available after installing audioplayers package'),
        backgroundColor: Color(0xFF1DB954),
        duration: Duration(seconds: 2),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF0A0A0A),
            Color(0xFF1A1A1A),
            Color(0xFF2A2A2A),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              children: [
                GestureDetector(
                  onTap: widget.onClose,
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                Spacer(),
                Text(
                  'Now Playing',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Spacer(),
                Icon(
                  Icons.more_vert,
                  color: Colors.white,
                  size: 24,
                ),
              ],
            ),
          ),
          
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: Column(
                children: [
                  // Album art / Visualizer
                  Expanded(
                    flex: 3,
                    child: Center(
                      child: AnimatedBuilder(
                        animation: _rotationController,
                        builder: (context, child) {
                          return Transform.rotate(
                            angle: _rotationController.value * 2 * 3.14159,
                            child: Container(
                              width: 280,
                              height: 280,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFF1DB954),
                                    Color(0xFF1ED760),
                                    Color(0xFF1DB954),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0xFF1DB954).withOpacity(0.3),
                                    blurRadius: 30,
                                    spreadRadius: 0,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Container(
                                  width: 200,
                                  height: 200,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xFF0A0A0A),
                                  ),
                                  child: Icon(
                                    Icons.music_note,
                                    color: Colors.white,
                                    size: 80,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 40),
                  
                  // Track info
                  Expanded(
                    flex: 1,
                    child: Column(
                      children: [
                        Text(
                          widget.track['description'] ?? 'Untitled Track',
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 8),
                        Text(
                          widget.track['username'] ?? 'Unknown Artist',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Progress bar
                  Column(
                    children: [
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: Color(0xFF1DB954),
                          inactiveTrackColor: Colors.white.withOpacity(0.3),
                          thumbColor: Color(0xFF1DB954),
                          overlayColor: Color(0xFF1DB954).withOpacity(0.2),
                          thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
                          trackHeight: 4,
                        ),
                        child: Slider(
                          value: duration.inMilliseconds > 0 
                              ? position.inMilliseconds / duration.inMilliseconds 
                              : 0.0,
                          onChanged: (value) {
                            setState(() {
                              position = Duration(
                                milliseconds: (value * duration.inMilliseconds).round(),
                              );
                            });
                          },
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDuration(position),
                              style: GoogleFonts.poppins(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              _formatDuration(duration),
                              style: GoogleFonts.poppins(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 30),
                  
                  // Controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        onPressed: () {},
                        icon: Icon(Icons.shuffle, color: Colors.white.withOpacity(0.7)),
                        iconSize: 28,
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: Icon(Icons.skip_previous, color: Colors.white),
                        iconSize: 36,
                      ),
                      GestureDetector(
                        onTap: _togglePlayPause,
                        child: AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            return Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF1DB954),
                                boxShadow: isPlaying ? [
                                  BoxShadow(
                                    color: Color(0xFF1DB954).withOpacity(0.4 * _pulseController.value),
                                    blurRadius: 20,
                                    spreadRadius: 10 * _pulseController.value,
                                  ),
                                ] : null,
                              ),
                              child: Icon(
                                isPlaying ? Icons.pause : Icons.play_arrow,
                                color: Colors.white,
                                size: 36,
                              ),
                            );
                          },
                        ),
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: Icon(Icons.skip_next, color: Colors.white),
                        iconSize: 36,
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: Icon(Icons.repeat, color: Colors.white.withOpacity(0.7)),
                        iconSize: 28,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
