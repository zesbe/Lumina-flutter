import 'package:just_audio/just_audio.dart';
import 'package:flutter/foundation.dart';

class AudioPlayerHandler {
  final AudioPlayer _player = AudioPlayer();
  
  AudioPlayer get player => _player;

  Future<void> playFromUrl({
    required String url,
    required String title,
    String? artist,
    String? album,
    String? artUrl,
    Duration? duration,
  }) async {
    try {
      await _player.setUrl(url);
      await _player.play();
      debugPrint('[Audio] Playing: $title');
    } catch (e) {
      debugPrint('[Audio] Error: $e');
      rethrow;
    }
  }

  Future<void> play() => _player.play();
  Future<void> pause() => _player.pause();
  Future<void> stop() => _player.stop();
  Future<void> seek(Duration position) => _player.seek(position);
  Future<void> dispose() => _player.dispose();
}
