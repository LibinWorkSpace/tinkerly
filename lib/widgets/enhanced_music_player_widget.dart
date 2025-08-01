import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/audio_player_service.dart';

class EnhancedMusicPlayerWidget extends StatefulWidget {
  final dynamic track;
  final VoidCallback onClose;

  const EnhancedMusicPlayerWidget({
    Key? key,
    required this.track,
    required this.onClose,
  }) : super(key: key);

  @override
  State<EnhancedMusicPlayerWidget> createState() => _EnhancedMusicPlayerWidgetState();
}

class _EnhancedMusicPlayerWidgetState extends State<EnhancedMusicPlayerWidget>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late AnimationController _waveController;

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
    _waveController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseController.repeat(reverse: true);
    
    // Start playing the track
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final audioService = Provider.of<AudioPlayerService>(context, listen: false);
      audioService.playTrack(
        widget.track['url'],
        title: widget.track['description'] ?? widget.track['title'] ?? 'Audio Track',
      );
    });
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  Widget _buildWaveAnimation() {
    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(7, (index) {
            final delay = index * 0.15;
            final animationValue = Curves.easeInOut.transform(
              (((_waveController.value + delay) % 1.0).clamp(0.0, 1.0)),
            );
            return Container(
              margin: EdgeInsets.symmetric(horizontal: 2),
              width: 4,
              height: 30 + (animationValue * 40),
              decoration: BoxDecoration(
                color: Color(0xFF1DB954),
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioPlayerService>(
      builder: (context, audioService, child) {
        // Update animations based on playback state
        if (audioService.isPlaying) {
          _rotationController.repeat();
          _waveController.repeat();
        } else {
          _rotationController.stop();
          _waveController.stop();
        }

        return Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF1a1a2e),
                Color(0xFF16213e),
                Color(0xFF0f3460),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header with close button
              Padding(
                padding: EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Now Playing',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    GestureDetector(
                      onTap: widget.onClose,
                      child: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          Icons.keyboard_arrow_down,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Album art with rotation animation
                    AnimatedBuilder(
                      animation: _rotationController,
                      builder: (context, child) {
                        return Transform.rotate(
                          angle: _rotationController.value * 2 * 3.14159,
                          child: Container(
                            width: 280,
                            height: 280,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  Color(0xFF1DB954),
                                  Color(0xFF191414),
                                ],
                                stops: [0.3, 1.0],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0xFF1DB954).withValues(alpha: 0.3),
                                  blurRadius: 30,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Container(
                                width: 200,
                                height: 200,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFF191414),
                                  border: Border.all(
                                    color: Color(0xFF1DB954),
                                    width: 2,
                                  ),
                                ),
                                child: Icon(
                                  Icons.music_note,
                                  color: Color(0xFF1DB954),
                                  size: 80,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    
                    // Wave animation when playing
                    if (audioService.isPlaying) ...[
                      SizedBox(height: 20),
                      _buildWaveAnimation(),
                    ],
                    
                    // Track info
                    Column(
                      children: [
                        Text(
                          audioService.currentTitle ?? 'Unknown Track',
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
                          'Audio Track',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                    
                    // Progress slider
                    Column(
                      children: [
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: Color(0xFF1DB954),
                            inactiveTrackColor: Colors.white.withValues(alpha: 0.3),
                            thumbColor: Color(0xFF1DB954),
                            overlayColor: Color(0xFF1DB954).withValues(alpha: 0.2),
                            thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
                            trackHeight: 4,
                          ),
                          child: Slider(
                            value: audioService.progress,
                            onChanged: (value) {
                              final position = Duration(
                                milliseconds: (value * audioService.duration.inMilliseconds).round(),
                              );
                              audioService.seekTo(position);
                            },
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                audioService.formatDuration(audioService.position),
                                style: GoogleFonts.poppins(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                audioService.formatDuration(audioService.duration),
                                style: GoogleFonts.poppins(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    // Control buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          onPressed: () => audioService.toggleShuffle(),
                          icon: Icon(
                            Icons.shuffle, 
                            color: audioService.isShuffle 
                                ? Color(0xFF1DB954) 
                                : Colors.white.withValues(alpha: 0.7),
                          ),
                          iconSize: 28,
                        ),
                        IconButton(
                          onPressed: () {},
                          icon: Icon(Icons.skip_previous, color: Colors.white),
                          iconSize: 36,
                        ),
                        
                        // Main play/pause button
                        GestureDetector(
                          onTap: () => audioService.togglePlayPause(),
                          child: AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              return Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFF1DB954),
                                  boxShadow: audioService.isPlaying ? [
                                    BoxShadow(
                                      color: Color(0xFF1DB954).withValues(alpha: 0.4 * _pulseController.value),
                                      blurRadius: 20,
                                      spreadRadius: 10 * _pulseController.value,
                                    ),
                                  ] : null,
                                ),
                                child: audioService.isLoading
                                    ? CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 3,
                                      )
                                    : Icon(
                                        audioService.isPlaying ? Icons.pause : Icons.play_arrow,
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
                          onPressed: () => audioService.toggleRepeat(),
                          icon: Icon(
                            Icons.repeat, 
                            color: audioService.isRepeat 
                                ? Color(0xFF1DB954) 
                                : Colors.white.withValues(alpha: 0.7),
                          ),
                          iconSize: 28,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
