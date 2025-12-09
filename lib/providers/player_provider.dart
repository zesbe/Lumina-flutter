import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../models/generation.dart';

class PlayerProvider with ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  Generation? _currentSong;
  List<Generation> _playlist = [];
  int _currentIndex = 0;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  Generation? get currentSong => _currentSong;
  List<Generation> get playlist => _playlist;
  bool get isPlaying => _isPlaying;
  Duration get position => _position;
  Duration get duration => _duration;
  double get progress => _duration.inMilliseconds > 0 
      ? _position.inMilliseconds / _duration.inMilliseconds 
      : 0;

  PlayerProvider() {
    _setupListeners();
  }

  void _setupListeners() {
    _player.positionStream.listen((pos) {
      _position = pos;
      notifyListeners();
    });
    
    _player.durationStream.listen((dur) {
      _duration = dur ?? Duration.zero;
      notifyListeners();
    });
    
    _player.playerStateStream.listen((state) {
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
    
    _currentSong = song;
    _currentIndex = _playlist.indexWhere((s) => s.id == song.id);
    if (_currentIndex < 0) _currentIndex = 0;
    
    try {
      await _player.setUrl(song.fullOutputUrl);
      await _player.play();
    } catch (e) {
      debugPrint('Error playing: $e');
    }
    notifyListeners();
  }

  Future<void> togglePlay() async {
    if (_isPlaying) {
      await _player.pause();
    } else {
      await _player.play();
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
    await _player.seek(newPosition);
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
