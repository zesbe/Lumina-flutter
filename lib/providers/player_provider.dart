import 'package:flutter/foundation.dart';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import '../models/generation.dart';
import '../services/audio_handler.dart';

class PlayerProvider with ChangeNotifier {
  AudioPlayerHandler? _audioHandler;
  Generation? _currentSong;
  List<Generation> _playlist = [];
  int _currentIndex = 0;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isInitialized = false;

  Generation? get currentSong => _currentSong;
  List<Generation> get playlist => _playlist;
  bool get isPlaying => _isPlaying;
  Duration get position => _position;
  Duration get duration => _duration;
  double get progress => _duration.inMilliseconds > 0 
      ? _position.inMilliseconds / _duration.inMilliseconds 
      : 0;
  bool get isInitialized => _isInitialized;

  Future<void> init() async {
    if (_isInitialized) return;
    
    try {
      debugPrint('[Player] Initializing AudioService...');
      _audioHandler = await initAudioService();
      _setupListeners();
      _isInitialized = true;
      debugPrint('[Player] AudioService initialized successfully');
    } catch (e) {
      debugPrint('[Player] AudioService init failed: $e');
      // Fallback without notification
      _audioHandler = AudioPlayerHandler();
      _setupListeners();
      _isInitialized = true;
    }
  }

  void _setupListeners() {
    if (_audioHandler == null) return;
    
    // Listen to player position
    _audioHandler!.player.positionStream.listen((pos) {
      _position = pos;
      notifyListeners();
    });
    
    // Listen to duration
    _audioHandler!.player.durationStream.listen((dur) {
      _duration = dur ?? Duration.zero;
      notifyListeners();
    });
    
    // Listen to player state
    _audioHandler!.player.playerStateStream.listen((state) {
      final wasPlaying = _isPlaying;
      _isPlaying = state.playing;
      
      if (state.processingState == ProcessingState.completed) {
        _playNextInternal();
      }
      
      if (wasPlaying != _isPlaying) {
        notifyListeners();
      }
    });

    // Listen to custom events from notification buttons
    AudioService.notificationClicked.listen((clicked) {
      if (clicked) {
        debugPrint('[Player] Notification clicked');
        // App should be brought to foreground automatically
      }
    });
  }

  void setPlaylist(List<Generation> songs) {
    _playlist = songs.where((s) => s.status == 'completed').toList();
    debugPrint('[Player] Playlist set: ${_playlist.length} songs');
  }

  Future<void> play(Generation song) async {
    if (song.fullOutputUrl.isEmpty) {
      debugPrint('[Player] No output URL for song');
      return;
    }
    
    if (!_isInitialized) {
      debugPrint('[Player] Not initialized, initializing...');
      await init();
    }
    
    _currentSong = song;
    _currentIndex = _playlist.indexWhere((s) => s.id == song.id);
    if (_currentIndex < 0) _currentIndex = 0;
    
    debugPrint('[Player] Playing: ${song.title}');
    
    try {
      await _audioHandler?.playFromUrl(
        url: song.fullOutputUrl,
        title: song.title,
        artist: song.style ?? 'AI Generated',
        album: 'Lumina AI',
        artUrl: song.fullThumbnailUrl,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('[Player] Error playing: $e');
    }
  }

  Future<void> togglePlay() async {
    if (!_isInitialized || _audioHandler == null) return;
    
    if (_isPlaying) {
      await _audioHandler!.pause();
    } else {
      await _audioHandler!.play();
    }
  }

  Future<void> playNext() async {
    await _playNextInternal();
  }

  Future<void> _playNextInternal() async {
    if (_playlist.isEmpty) return;
    _currentIndex = (_currentIndex + 1) % _playlist.length;
    await play(_playlist[_currentIndex]);
  }

  Future<void> playPrevious() async {
    if (_playlist.isEmpty) return;
    
    // If more than 3 seconds into song, restart it
    if (_position.inSeconds > 3) {
      await seek(0);
      return;
    }
    
    _currentIndex = (_currentIndex - 1 + _playlist.length) % _playlist.length;
    await play(_playlist[_currentIndex]);
  }

  Future<void> seek(double percent) async {
    if (!_isInitialized || _audioHandler == null) return;
    
    final newPosition = Duration(
      milliseconds: (percent * _duration.inMilliseconds).toInt()
    );
    await _audioHandler!.seek(newPosition);
  }

  Future<void> seekTo(Duration position) async {
    if (!_isInitialized || _audioHandler == null) return;
    await _audioHandler!.seek(position);
  }

  Future<void> stop() async {
    await _audioHandler?.stop();
    _currentSong = null;
    _isPlaying = false;
    _position = Duration.zero;
    notifyListeners();
  }

  @override
  void dispose() {
    _audioHandler?.dispose();
    super.dispose();
  }
}
