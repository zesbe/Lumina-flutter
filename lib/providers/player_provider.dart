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
    
    // Set callbacks for notification controls
    audioHandler.onSkipToNext = () => playNext();
    audioHandler.onSkipToPrevious = () => playPrevious();
    
    _setupListeners();
    _isInitialized = true;
    debugPrint('[Player] Initialized with notification callbacks');
  }

  void _setupListeners() {
    audioHandler.player.positionStream.listen((pos) {
      _position = pos;
      _updateSleepTimer();
      notifyListeners();
    });
    
    audioHandler.player.durationStream.listen((dur) {
      _duration = dur ?? Duration.zero;
      notifyListeners();
    });
    
    audioHandler.player.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      if (state.processingState == ProcessingState.completed) {
        _handleSongComplete();
      }
      notifyListeners();
    });
  }

  void _handleSongComplete() {
    debugPrint('[Player] Song completed');
    switch (_repeatMode) {
      case RepeatMode.one:
        audioHandler.player.seek(Duration.zero);
        audioHandler.play();
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
    if (song.fullOutputUrl.isEmpty) return;
    if (!_isInitialized) await init();
    
    _currentSong = song;
    _currentIndex = _playlist.indexWhere((s) => s.id == song.id);
    if (_currentIndex < 0) _currentIndex = 0;
    
    debugPrint('[Player] Playing: ${song.title} (index $_currentIndex/${_playlist.length})');
    
    await audioHandler.playUrl(
      song.fullOutputUrl,
      song.title,
      song.displayArtist,
      song.fullThumbnailUrl.isNotEmpty ? song.fullThumbnailUrl : null,
    );
    notifyListeners();
  }

  Future<void> togglePlay() async {
    if (_isPlaying) {
      await audioHandler.pause();
    } else {
      await audioHandler.play();
    }
  }

  Future<void> playNext() => _playNextInternal(loop: _repeatMode == RepeatMode.all);

  Future<void> _playNextInternal({bool loop = false}) async {
    if (_playlist.isEmpty) {
      debugPrint('[Player] No playlist');
      return;
    }
    
    debugPrint('[Player] Next: current=$_currentIndex, total=${_playlist.length}');
    
    if (_currentIndex < _playlist.length - 1) {
      _currentIndex++;
    } else if (loop) {
      _currentIndex = 0;
    } else {
      debugPrint('[Player] End of playlist');
      return;
    }
    await play(_playlist[_currentIndex]);
  }

  Future<void> playPrevious() async {
    if (_playlist.isEmpty) {
      debugPrint('[Player] No playlist');
      return;
    }
    
    debugPrint('[Player] Previous: current=$_currentIndex, position=${_position.inSeconds}s');
    
    // If more than 3 seconds in, restart current song
    if (_position.inSeconds > 3) {
      await seek(0);
      return;
    }
    
    if (_currentIndex > 0) {
      _currentIndex--;
    } else if (_repeatMode == RepeatMode.all) {
      _currentIndex = _playlist.length - 1;
    } else {
      debugPrint('[Player] Start of playlist');
      return;
    }
    await play(_playlist[_currentIndex]);
  }

  Future<void> seek(double percent) async {
    final pos = Duration(milliseconds: (percent * _duration.inMilliseconds).toInt());
    await audioHandler.seek(pos);
  }

  Future<void> stop() async {
    await audioHandler.stop();
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
