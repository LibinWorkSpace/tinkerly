import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/audio_player_service.dart';

class MiniAudioPlayer extends StatelessWidget {
  final Color? primaryColor;
  final VoidCallback? onTap;

  const MiniAudioPlayer({
    Key? key,
    this.primaryColor,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioPlayerService>(
      builder: (context, audioService, child) {
        if (!audioService.hasCurrentTrack) {
          return SizedBox.shrink();
        }

        final color = primaryColor ?? Color(0xFF6C63FF);

        return GestureDetector(
          onTap: onTap,
          child: Container(
            height: 70,
            margin: EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.9),
                  color.withValues(alpha: 0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  // Album art placeholder
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.music_note,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 12),
                  
                  // Track info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          audioService.currentTitle ?? 'Unknown Track',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 2),
                        // Progress bar
                        LinearProgressIndicator(
                          value: audioService.progress,
                          backgroundColor: Colors.white.withValues(alpha: 0.3),
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 12),
                  
                  // Play/pause button
                  GestureDetector(
                    onTap: () => audioService.togglePlayPause(),
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: audioService.isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Icon(
                              audioService.isPlaying ? Icons.pause : Icons.play_arrow,
                              color: Colors.white,
                              size: 20,
                            ),
                    ),
                  ),
                  SizedBox(width: 8),
                  
                  // Close button
                  GestureDetector(
                    onTap: () => audioService.stop(),
                    child: Container(
                      padding: EdgeInsets.all(4),
                      child: Icon(
                        Icons.close,
                        color: Colors.white.withValues(alpha: 0.8),
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class ExpandedAudioPlayer extends StatelessWidget {
  final Color? primaryColor;

  const ExpandedAudioPlayer({
    Key? key,
    this.primaryColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioPlayerService>(
      builder: (context, audioService, child) {
        if (!audioService.hasCurrentTrack) {
          return SizedBox.shrink();
        }

        final color = primaryColor ?? Color(0xFF6C63FF);

        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: 0.9),
                color.withValues(alpha: 0.7),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(height: 32),
                
                // Album art
                Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.music_note,
                    color: Colors.white,
                    size: 80,
                  ),
                ),
                SizedBox(height: 32),
                
                // Track title
                Text(
                  audioService.currentTitle ?? 'Unknown Track',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 8),
                
                Text(
                  'Audio Track',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 32),
                
                // Progress slider
                Column(
                  children: [
                    Slider(
                      value: audioService.progress,
                      onChanged: (value) {
                        final position = Duration(
                          milliseconds: (audioService.duration.inMilliseconds * value).round(),
                        );
                        audioService.seekTo(position);
                      },
                      activeColor: Colors.white,
                      inactiveColor: Colors.white.withValues(alpha: 0.3),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            audioService.formatDuration(audioService.position),
                            style: GoogleFonts.poppins(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            audioService.formatDuration(audioService.duration),
                            style: GoogleFonts.poppins(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 32),
                
                // Control buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      onPressed: () => audioService.toggleShuffle(),
                      icon: Icon(
                        Icons.shuffle,
                        color: audioService.isShuffle 
                            ? Colors.white 
                            : Colors.white.withValues(alpha: 0.5),
                        size: 28,
                      ),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: Icon(Icons.skip_previous, color: Colors.white, size: 36),
                    ),
                    GestureDetector(
                      onTap: () => audioService.togglePlayPause(),
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: audioService.isLoading
                            ? Center(
                                child: CircularProgressIndicator(
                                  color: color,
                                  strokeWidth: 3,
                                ),
                              )
                            : Icon(
                                audioService.isPlaying ? Icons.pause : Icons.play_arrow,
                                color: color,
                                size: 36,
                              ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: Icon(Icons.skip_next, color: Colors.white, size: 36),
                    ),
                    IconButton(
                      onPressed: () => audioService.toggleRepeat(),
                      icon: Icon(
                        Icons.repeat,
                        color: audioService.isRepeat 
                            ? Colors.white 
                            : Colors.white.withValues(alpha: 0.5),
                        size: 28,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
