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

  Future<void> init() async {
    if (_isInitialized) return;
    
    try {
      _audioHandler = await AudioService.init(
        builder: () => AudioPlayerHandler(),
        config: const AudioServiceConfig(
          androidNotificationChannelId: 'id.my.zesbe.luminaai.audio',
          androidNotificationChannelName: 'Lumina AI Music',
          androidNotificationOngoing: true,
          androidStopForegroundOnPause: true,
          androidNotificationIcon: 'drawable/ic_notification',
        ),
      );
      
      _setupListeners();
      _isInitialized = true;
      debugPrint('[Player] AudioService initialized');
    } catch (e) {
      debugPrint('[Player] AudioService init failed: $e');
      // Fallback to simple player without notification
      _setupSimplePlayer();
    }
  }

  void _setupSimplePlayer() {
    // Fallback without audio_service
    _audioHandler = AudioPlayerHandler();
    _setupListeners();
    _isInitialized = true;
  }

  void _setupListeners() {
    if (_audioHandler == null) return;
    
    _audioHandler!.player.positionStream.listen((pos) {
      _position = pos;
      notifyListeners();
    });
    
    _audioHandler!.player.durationStream.listen((dur) {
      _duration = dur ?? Duration.zero;
      notifyListeners();
    });
    
    _audioHandler!.player.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      if (state.processingState == ProcessingState.completed) {
        playNext();
      }
      notifyListeners();
    });
  }

  void setPlaylist(List<Generation> songs) {
    _playlist = songs.where((s) => s.status == 'completed').toList();
  }

  Future<void> play(Generation song) async {
    if (song.fullOutputUrl.isEmpty) return;
    if (!_isInitialized) await init();
    
    _currentSong = song;
    _currentIndex = _playlist.indexWhere((s) => s.id == song.id);
    if (_currentIndex < 0) _currentIndex = 0;
    
    try {
      await _audioHandler?.playUrl(
        song.fullOutputUrl,
        title: song.title,
        artist: song.style ?? 'AI Generated',
        artUrl: song.fullThumbnailUrl.isNotEmpty ? song.fullThumbnailUrl : null,
      );
    } catch (e) {
      debugPrint('[Player] Error playing: $e');
    }
    notifyListeners();
  }

  Future<void> togglePlay() async {
    if (!_isInitialized) return;
    
    if (_isPlaying) {
      await _audioHandler?.pause();
    } else {
      await _audioHandler?.play();
    }
  }

  Future<void> playNext() async {
    if (_playlist.isEmpty) return;
    _currentIndex = (_currentIndex + 1) % _playlist.length;
    await play(_playlist[_currentIndex]);
  }

  Future<void> playPrevious() async {
    if (_playlist.isEmpty) return;
    _currentIndex = (_currentIndex - 1 + _playlist.length) % _playlist.length;
    await play(_playlist[_currentIndex]);
  }

  Future<void> seek(double percent) async {
    final newPosition = Duration(milliseconds: (percent * _duration.inMilliseconds).toInt());
    await _audioHandler?.seek(newPosition);
  }

  Future<void> stop() async {
    await _audioHandler?.stop();
    _currentSong = null;
    _isPlaying = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _audioHandler?.dispose();
    super.dispose();
  }
}
