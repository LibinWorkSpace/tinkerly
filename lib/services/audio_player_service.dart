import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';

class AudioPlayerService extends ChangeNotifier {
  static final AudioPlayerService _instance = AudioPlayerService._internal();
  factory AudioPlayerService() => _instance;
  AudioPlayerService._internal();

  AudioPlayer? _audioPlayer;
  String? _currentUrl;
  String? _currentTitle;
  bool _isPlaying = false;
  bool _isLoading = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  double _volume = 1.0;
  bool _isRepeat = false;
  bool _isShuffle = false;

  // Getters
  bool get isPlaying => _isPlaying;
  bool get isLoading => _isLoading;
  Duration get duration => _duration;
  Duration get position => _position;
  String? get currentUrl => _currentUrl;
  String? get currentTitle => _currentTitle;
  double get volume => _volume;
  bool get isRepeat => _isRepeat;
  bool get isShuffle => _isShuffle;
  bool get hasCurrentTrack => _currentUrl != null;

  // Initialize the audio player
  Future<void> _initializePlayer() async {
    if (_audioPlayer != null) return;

    _audioPlayer = AudioPlayer();

    // Listen to player state changes
    _audioPlayer!.onPlayerStateChanged.listen((PlayerState state) {
      _isPlaying = state == PlayerState.playing;
      _isLoading = state == PlayerState.playing ? false : _isLoading;
      notifyListeners();
    });

    // Listen to duration changes
    _audioPlayer!.onDurationChanged.listen((Duration d) {
      _duration = d;
      notifyListeners();
    });

    // Listen to position changes
    _audioPlayer!.onPositionChanged.listen((Duration p) {
      _position = p;
      notifyListeners();
    });

    // Handle player completion
    _audioPlayer!.onPlayerComplete.listen((event) {
      if (_isRepeat) {
        // Repeat the current track
        _audioPlayer!.seek(Duration.zero);
        _audioPlayer!.resume();
      } else {
        _isPlaying = false;
        _position = Duration.zero;
        notifyListeners();
      }
    });
  }

  // Play a new track
  Future<void> playTrack(String url, {String? title}) async {
    try {
      await _initializePlayer();
      
      _isLoading = true;
      notifyListeners();

      // If it's the same track, just toggle play/pause
      if (_currentUrl == url) {
        await togglePlayPause();
        return;
      }

      // Stop current track if playing
      if (_audioPlayer != null) {
        await _audioPlayer!.stop();
      }

      // Set new track
      _currentUrl = url;
      _currentTitle = title;
      await _audioPlayer!.setSourceUrl(url);
      await _audioPlayer!.resume();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error playing track: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  // Toggle play/pause
  Future<void> togglePlayPause() async {
    if (_audioPlayer == null || _currentUrl == null) return;

    try {
      if (_isPlaying) {
        await _audioPlayer!.pause();
      } else {
        await _audioPlayer!.resume();
      }
    } catch (e) {
      print('Error toggling play/pause: $e');
    }
  }

  // Stop playback
  Future<void> stop() async {
    if (_audioPlayer == null) return;

    try {
      await _audioPlayer!.stop();
      _currentUrl = null;
      _currentTitle = null;
      _isPlaying = false;
      _position = Duration.zero;
      notifyListeners();
    } catch (e) {
      print('Error stopping playback: $e');
    }
  }

  // Seek to position
  Future<void> seekTo(Duration position) async {
    if (_audioPlayer == null) return;

    try {
      await _audioPlayer!.seek(position);
    } catch (e) {
      print('Error seeking: $e');
    }
  }

  // Set volume
  Future<void> setVolume(double volume) async {
    if (_audioPlayer == null) return;

    try {
      _volume = volume.clamp(0.0, 1.0);
      await _audioPlayer!.setVolume(_volume);
      notifyListeners();
    } catch (e) {
      print('Error setting volume: $e');
    }
  }

  // Toggle repeat
  void toggleRepeat() {
    _isRepeat = !_isRepeat;
    notifyListeners();
  }

  // Toggle shuffle
  void toggleShuffle() {
    _isShuffle = !_isShuffle;
    notifyListeners();
  }

  // Check if a specific track is currently playing
  bool isTrackPlaying(String url) {
    return _currentUrl == url && _isPlaying;
  }

  // Check if a specific track is the current track
  bool isCurrentTrack(String url) {
    return _currentUrl == url;
  }

  // Get progress as percentage
  double get progress {
    if (_duration.inMilliseconds == 0) return 0.0;
    return _position.inMilliseconds / _duration.inMilliseconds;
  }

  // Format duration for display
  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  // Dispose resources
  @override
  void dispose() {
    _audioPlayer?.dispose();
    super.dispose();
  }
}
