import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../models/generation.dart';
import '../services/audio_handler.dart';

enum RepeatMode { off, one, all }

class PlayerProvider with ChangeNotifier {
  Generation? _currentSong;
  List<Generation> _playlist = [];
  List<Generation> _originalPlaylist = [];
  int _currentIndex = 0;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isInitialized = false;
  
  RepeatMode _repeatMode = RepeatMode.off;
  bool _shuffleEnabled = false;
  
  Timer? _sleepTimer;
  Duration? _sleepTimerRemaining;
  DateTime? _sleepTimerEnd;

  Generation? get currentSong => _currentSong;
  List<Generation> get playlist => _playlist;
  bool get isPlaying => _isPlaying;
  Duration get position => _position;
  Duration get duration => _duration;
  double get progress => _duration.inMilliseconds > 0 
      ? _position.inMilliseconds / _duration.inMilliseconds : 0;
  bool get isInitialized => _isInitialized;
  RepeatMode get repeatMode => _repeatMode;
  bool get shuffleEnabled => _shuffleEnabled;
  Duration? get sleepTimerRemaining => _sleepTimerRemaining;
  bool get hasSleepTimer => _sleepTimerEnd != null;

  Future<void> init() async {
    if (_isInitialized) return;
    _setupListeners();
    _isInitialized = true;
    debugPrint('[Player] Initialized');
  }

  void _setupListeners() {
    // Use activePlayer from audio_handler
    activePlayer.positionStream.listen((pos) {
      _position = pos;
      _updateSleepTimer();
      notifyListeners();
    });
    
    activePlayer.durationStream.listen((dur) {
      _duration = dur ?? Duration.zero;
      notifyListeners();
    });
    
    activePlayer.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      if (state.processingState == ProcessingState.completed) {
        _handleSongComplete();
      }
      notifyListeners();
    });
  }

  void _handleSongComplete() {
    debugPrint('[Player] Song completed, repeatMode: $_repeatMode');
    switch (_repeatMode) {
      case RepeatMode.one:
        activePlayer.seek(Duration.zero);
        activePlayer.play();
        break;
      case RepeatMode.all:
        _playNextInternal(loop: true);
        break;
      case RepeatMode.off:
        if (_currentIndex < _playlist.length - 1) {
          _playNextInternal(loop: false);
        } else {
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
      stop();
      cancelSleepTimer();
    } else {
      _sleepTimerRemaining = remaining;
    }
  }

  void toggleRepeatMode() {
    _repeatMode = RepeatMode.values[(_repeatMode.index + 1) % 3];
    debugPrint('[Player] Repeat mode: $_repeatMode');
    notifyListeners();
  }

  void toggleShuffle() {
    _shuffleEnabled = !_shuffleEnabled;
    if (_shuffleEnabled) {
      _originalPlaylist = List.from(_playlist);
      _playlist.shuffle();
      if (_currentSong != null) {
        _playlist.remove(_currentSong);
        _playlist.insert(0, _currentSong!);
        _currentIndex = 0;
      }
    } else if (_originalPlaylist.isNotEmpty) {
      _playlist = List.from(_originalPlaylist);
      _currentIndex = _playlist.indexWhere((s) => s.id == _currentSong?.id);
      if (_currentIndex < 0) _currentIndex = 0;
    }
    debugPrint('[Player] Shuffle: $_shuffleEnabled');
    notifyListeners();
  }

  void setSleepTimer(Duration duration) {
    cancelSleepTimer();
    _sleepTimerEnd = DateTime.now().add(duration);
    _sleepTimerRemaining = duration;
    _sleepTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateSleepTimer();
      notifyListeners();
    });
    notifyListeners();
  }

  void cancelSleepTimer() {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    _sleepTimerEnd = null;
    _sleepTimerRemaining = null;
    notifyListeners();
  }

  void setPlaylist(List<Generation> songs) {
    _playlist = songs.where((s) => s.status == 'completed').toList();
    _originalPlaylist = List.from(_playlist);
    if (_shuffleEnabled) _playlist.shuffle();
    debugPrint('[Player] Playlist set: ${_playlist.length} songs');
  }

  Future<void> play(Generation song) async {
    if (song.fullOutputUrl.isEmpty) {
      debugPrint('[Player] No URL for song');
      return;
    }
    
    if (!_isInitialized) await init();
    
    _currentSong = song;
    _currentIndex = _playlist.indexWhere((s) => s.id == song.id);
    if (_currentIndex < 0) _currentIndex = 0;
    
    debugPrint('[Player] Playing: ${song.title}');
    debugPrint('[Player] URL: ${song.fullOutputUrl}');
    
    try {
      await playMusic(
        song.fullOutputUrl,
        song.title,
        song.displayArtist,
        song.fullThumbnailUrl.isNotEmpty ? song.fullThumbnailUrl : null,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('[Player] Error playing: $e');
    }
  }

  Future<void> togglePlay() async {
    debugPrint('[Player] Toggle play, isPlaying: $_isPlaying');
    if (_isPlaying) {
      await pauseMusic();
    } else {
      await resumeMusic();
    }
  }

  Future<void> playNext() => _playNextInternal(loop: _repeatMode == RepeatMode.all);

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
    final pos = Duration(milliseconds: (percent * _duration.inMilliseconds).toInt());
    await activePlayer.seek(pos);
  }

  Future<void> stop() async {
    await stopMusic();
    _currentSong = null;
    _isPlaying = false;
    _position = Duration.zero;
    cancelSleepTimer();
    notifyListeners();
  }

  @override
  void dispose() {
    _sleepTimer?.cancel();
    super.dispose();
  }
}
