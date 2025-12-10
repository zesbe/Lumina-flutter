import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import '../models/generation.dart';
import '../services/audio_handler.dart';

enum RepeatMode { off, one, all }

class PlayerProvider with ChangeNotifier {
  AudioPlayerHandler? _audioHandler;
  Generation? _currentSong;
  List<Generation> _playlist = [];
  List<Generation> _originalPlaylist = []; // For shuffle
  int _currentIndex = 0;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isInitialized = false;
  
  // Repeat & Shuffle
  RepeatMode _repeatMode = RepeatMode.off;
  bool _shuffleEnabled = false;
  
  // Sleep Timer
  Timer? _sleepTimer;
  Duration? _sleepTimerRemaining;
  DateTime? _sleepTimerEnd;

  // Getters
  Generation? get currentSong => _currentSong;
  List<Generation> get playlist => _playlist;
  bool get isPlaying => _isPlaying;
  Duration get position => _position;
  Duration get duration => _duration;
  double get progress => _duration.inMilliseconds > 0 
      ? _position.inMilliseconds / _duration.inMilliseconds 
      : 0;
  bool get isInitialized => _isInitialized;
  RepeatMode get repeatMode => _repeatMode;
  bool get shuffleEnabled => _shuffleEnabled;
  Duration? get sleepTimerRemaining => _sleepTimerRemaining;
  bool get hasSleepTimer => _sleepTimerEnd != null;

  Future<void> init() async {
    if (_isInitialized) return;
    
    try {
      debugPrint('[Player] Initializing AudioService...');
      _audioHandler = await initAudioService();
      _setupListeners();
      _isInitialized = true;
      debugPrint('[Player] AudioService initialized');
    } catch (e) {
      debugPrint('[Player] AudioService init failed: $e');
      _audioHandler = AudioPlayerHandler();
      _setupListeners();
      _isInitialized = true;
    }
  }

  void _setupListeners() {
    if (_audioHandler == null) return;
    
    _audioHandler!.player.positionStream.listen((pos) {
      _position = pos;
      _updateSleepTimer();
      notifyListeners();
    });
    
    _audioHandler!.player.durationStream.listen((dur) {
      _duration = dur ?? Duration.zero;
      notifyListeners();
    });
    
    _audioHandler!.player.playerStateStream.listen((state) {
      final wasPlaying = _isPlaying;
      _isPlaying = state.playing;
      
      if (state.processingState == ProcessingState.completed) {
        _handleSongComplete();
      }
      
      if (wasPlaying != _isPlaying) {
        notifyListeners();
      }
    });
  }

  void _handleSongComplete() {
    switch (_repeatMode) {
      case RepeatMode.one:
        // Replay same song
        _audioHandler?.seek(Duration.zero);
        _audioHandler?.play();
        break;
      case RepeatMode.all:
        // Play next, loop to start
        _playNextInternal(loop: true);
        break;
      case RepeatMode.off:
        // Play next, stop at end
        if (_currentIndex < _playlist.length - 1) {
          _playNextInternal(loop: false);
        } else {
          // End of playlist
          _isPlaying = false;
          notifyListeners();
        }
        break;
    }
  }

  void _updateSleepTimer() {
    if (_sleepTimerEnd == null) return;
    
    final remaining = _sleepTimerEnd!.difference(DateTime.now());
    if (remaining.isNegative) {
      // Timer expired, stop playback
      stop();
      cancelSleepTimer();
    } else {
      _sleepTimerRemaining = remaining;
    }
  }

  // Repeat Mode
  void toggleRepeatMode() {
    switch (_repeatMode) {
      case RepeatMode.off:
        _repeatMode = RepeatMode.all;
        break;
      case RepeatMode.all:
        _repeatMode = RepeatMode.one;
        break;
      case RepeatMode.one:
        _repeatMode = RepeatMode.off;
        break;
    }
    debugPrint('[Player] Repeat mode: $_repeatMode');
    notifyListeners();
  }

  // Shuffle
  void toggleShuffle() {
    _shuffleEnabled = !_shuffleEnabled;
    
    if (_shuffleEnabled) {
      // Save original order and shuffle
      _originalPlaylist = List.from(_playlist);
      _playlist.shuffle();
      // Keep current song at position 0
      if (_currentSong != null) {
        _playlist.remove(_currentSong);
        _playlist.insert(0, _currentSong!);
        _currentIndex = 0;
      }
    } else {
      // Restore original order
      if (_originalPlaylist.isNotEmpty) {
        _playlist = List.from(_originalPlaylist);
        if (_currentSong != null) {
          _currentIndex = _playlist.indexWhere((s) => s.id == _currentSong!.id);
          if (_currentIndex < 0) _currentIndex = 0;
        }
      }
    }
    
    debugPrint('[Player] Shuffle: $_shuffleEnabled');
    notifyListeners();
  }

  // Sleep Timer
  void setSleepTimer(Duration duration) {
    cancelSleepTimer();
    _sleepTimerEnd = DateTime.now().add(duration);
    _sleepTimerRemaining = duration;
    
    _sleepTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateSleepTimer();
      notifyListeners();
    });
    
    debugPrint('[Player] Sleep timer set: $duration');
    notifyListeners();
  }

  void cancelSleepTimer() {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    _sleepTimerEnd = null;
    _sleepTimerRemaining = null;
    debugPrint('[Player] Sleep timer cancelled');
    notifyListeners();
  }

  void setPlaylist(List<Generation> songs) {
    _playlist = songs.where((s) => s.status == 'completed').toList();
    _originalPlaylist = List.from(_playlist);
    
    if (_shuffleEnabled) {
      _playlist.shuffle();
    }
    
    debugPrint('[Player] Playlist set: ${_playlist.length} songs');
  }

  Future<void> play(Generation song) async {
    if (song.fullOutputUrl.isEmpty) return;
    if (!_isInitialized) await init();
    
    _currentSong = song;
    _currentIndex = _playlist.indexWhere((s) => s.id == song.id);
    if (_currentIndex < 0) _currentIndex = 0;
    
    debugPrint('[Player] Playing: ${song.title}');
    
    try {
      await _audioHandler?.playFromUrl(
        url: song.fullOutputUrl,
        title: song.title,
        artist: song.displayArtist,
        album: 'Lumina AI',
        artUrl: song.fullThumbnailUrl,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('[Player] Error: $e');
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
    await _playNextInternal(loop: _repeatMode == RepeatMode.all);
  }

  Future<void> _playNextInternal({bool loop = false}) async {
    if (_playlist.isEmpty) return;
    
    if (_currentIndex < _playlist.length - 1) {
      _currentIndex++;
    } else if (loop) {
      _currentIndex = 0;
    } else {
      return;
    }
    
    await play(_playlist[_currentIndex]);
  }

  Future<void> playPrevious() async {
    if (_playlist.isEmpty) return;
    
    if (_position.inSeconds > 3) {
      await seek(0);
      return;
    }
    
    if (_currentIndex > 0) {
      _currentIndex--;
    } else if (_repeatMode == RepeatMode.all) {
      _currentIndex = _playlist.length - 1;
    } else {
      return;
    }
    
    await play(_playlist[_currentIndex]);
  }

  Future<void> seek(double percent) async {
    if (!_isInitialized || _audioHandler == null) return;
    final newPosition = Duration(milliseconds: (percent * _duration.inMilliseconds).toInt());
    await _audioHandler!.seek(newPosition);
  }

  Future<void> stop() async {
    await _audioHandler?.stop();
    _currentSong = null;
    _isPlaying = false;
    _position = Duration.zero;
    cancelSleepTimer();
    notifyListeners();
  }

  @override
  void dispose() {
    _sleepTimer?.cancel();
    _audioHandler?.dispose();
    super.dispose();
  }
}
