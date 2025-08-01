import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';

class AudioPlayerWidget extends StatefulWidget {
  final String audioUrl;
  final String? title;
  final double height;
  final Color? primaryColor;
  final bool showTitle;
  final bool autoPlay;

  const AudioPlayerWidget({
    Key? key,
    required this.audioUrl,
    this.title,
    this.height = 120,
    this.primaryColor,
    this.showTitle = true,
    this.autoPlay = false,
  }) : super(key: key);

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget>
    with TickerProviderStateMixin {
  late AudioPlayer _audioPlayer;
  bool isPlaying = false;
  bool isLoading = false;
  bool hasError = false;
  Duration duration = Duration.zero;
  Duration position = Duration.zero;
  late AnimationController _waveController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _waveController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );
    _initializePlayer();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _waveController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _initializePlayer() async {
    try {
      setState(() {
        isLoading = true;
        hasError = false;
      });

      // Listen to player state changes
      _audioPlayer.onPlayerStateChanged.listen((PlayerState state) {
        if (mounted) {
          setState(() {
            isPlaying = state == PlayerState.playing;
            isLoading = state == PlayerState.playing ? false : isLoading;
          });

          if (isPlaying) {
            _waveController.repeat();
            _pulseController.repeat(reverse: true);
          } else {
            _waveController.stop();
            _pulseController.stop();
          }
        }
      });

      // Listen to duration changes
      _audioPlayer.onDurationChanged.listen((Duration d) {
        if (mounted) {
          setState(() {
            duration = d;
          });
        }
      });

      // Listen to position changes
      _audioPlayer.onPositionChanged.listen((Duration p) {
        if (mounted) {
          setState(() {
            position = p;
          });
        }
      });

      // Handle player completion
      _audioPlayer.onPlayerComplete.listen((event) {
        if (mounted) {
          setState(() {
            isPlaying = false;
            position = Duration.zero;
          });
          _waveController.stop();
          _pulseController.stop();
        }
      });

      // Set the audio source
      await _audioPlayer.setSourceUrl(widget.audioUrl);

      setState(() {
        isLoading = false;
      });

      // Auto play if requested
      if (widget.autoPlay) {
        await _togglePlayPause();
      }
    } catch (e) {
      print('Error initializing audio player: $e');
      setState(() {
        isLoading = false;
        hasError = true;
      });
    }
  }

  Future<void> _togglePlayPause() async {
    try {
      if (isPlaying) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.resume();
      }
    } catch (e) {
      print('Error toggling play/pause: $e');
      setState(() {
        hasError = true;
      });
    }
  }

  Future<void> _seekTo(double value) async {
    final position = Duration(milliseconds: (duration.inMilliseconds * value).round());
    await _audioPlayer.seek(position);
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  Widget _buildWaveAnimation() {
    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            final delay = index * 0.2;
            final animationValue = Curves.easeInOut.transform(
              (((_waveController.value + delay) % 1.0).clamp(0.0, 1.0)),
            );
            return Container(
              margin: EdgeInsets.symmetric(horizontal: 1),
              width: 3,
              height: 20 + (animationValue * 15),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8),
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
    final primaryColor = widget.primaryColor ?? Color(0xFF6C63FF);

    if (hasError) {
      return Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 32),
              SizedBox(height: 8),
              Text(
                'Failed to load audio',
                style: GoogleFonts.poppins(
                  color: Colors.red,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8),
              ElevatedButton(
                onPressed: _initializePlayer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryColor.withValues(alpha: 0.8),
            primaryColor.withValues(alpha: 0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title and wave animation
            if (widget.showTitle && widget.title != null)
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title!,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isPlaying) _buildWaveAnimation(),
                ],
              ),

            Spacer(),

            // Main play button and progress
            Row(
              children: [
                GestureDetector(
                  onTap: isLoading ? null : _togglePlayPause,
                  child: AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                          boxShadow: isPlaying ? [
                            BoxShadow(
                              color: Colors.white.withValues(alpha: 0.3 * _pulseController.value),
                              blurRadius: 10,
                              spreadRadius: 5 * _pulseController.value,
                            ),
                          ] : null,
                        ),
                        child: isLoading
                            ? SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(
                                isPlaying ? Icons.pause : Icons.play_arrow,
                                color: Colors.white,
                                size: 24,
                              ),
                      );
                    },
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Progress bar
                      GestureDetector(
                        onTapDown: (details) {
                          final RenderBox box = context.findRenderObject() as RenderBox;
                          final localPosition = box.globalToLocal(details.globalPosition);
                          final progress = (localPosition.dx - 60) / (box.size.width - 76);
                          _seekTo(progress.clamp(0.0, 1.0));
                        },
                        child: Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: LinearProgressIndicator(
                            value: duration.inMilliseconds > 0
                                ? position.inMilliseconds / duration.inMilliseconds
                                : 0.0,
                            backgroundColor: Colors.transparent,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                      SizedBox(height: 8),
                      // Time display
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(position),
                            style: GoogleFonts.poppins(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            _formatDuration(duration),
                            style: GoogleFonts.poppins(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
