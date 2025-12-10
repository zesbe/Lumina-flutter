import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/foundation.dart';

// Simple player that ALWAYS works
class SimpleAudioPlayer {
  final AudioPlayer player = AudioPlayer();
  
  Future<void> playUrl(String url) async {
    await player.setUrl(url);
    await player.play();
  }
  
  Future<void> play() => player.play();
  Future<void> pause() => player.pause();
  Future<void> stop() => player.stop();
  Future<void> seek(Duration pos) => player.seek(pos);
}

// Audio Service handler for notifications
class AudioPlayerHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer player = AudioPlayer();

  AudioPlayerHandler() {
    player.playbackEventStream.listen(_broadcastState);
    player.playerStateStream.listen((_) => _broadcastState(PlaybackEvent()));
  }

  void _broadcastState(PlaybackEvent event) {
    playbackState.add(PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        player.playing ? MediaControl.pause : MediaControl.play,
        MediaControl.stop,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.play, MediaAction.pause, MediaAction.stop,
        MediaAction.seek, MediaAction.skipToNext, MediaAction.skipToPrevious,
      },
      androidCompactActionIndices: const [0, 1, 3],
      processingState: {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[player.processingState] ?? AudioProcessingState.idle,
      playing: player.playing,
      updatePosition: player.position,
      bufferedPosition: player.bufferedPosition,
      speed: player.speed,
    ));
  }

  Future<void> playUrl(String url, String title, String artist, String? artUrl) async {
    mediaItem.add(MediaItem(
      id: url,
      title: title,
      artist: artist,
      artUri: artUrl != null ? Uri.tryParse(artUrl) : null,
    ));
    await player.setUrl(url);
    await player.play();
  }

  @override Future<void> play() => player.play();
  @override Future<void> pause() => player.pause();
  @override Future<void> stop() async { await player.stop(); await super.stop(); }
  @override Future<void> seek(Duration position) => player.seek(position);
  @override Future<void> skipToNext() async {}
  @override Future<void> skipToPrevious() async {}
}

// Global instances
AudioPlayerHandler? audioHandler;
SimpleAudioPlayer? fallbackPlayer;
bool useAudioService = false;

// Get the active player
AudioPlayer get activePlayer {
  if (useAudioService && audioHandler != null) {
    return audioHandler!.player;
  }
  fallbackPlayer ??= SimpleAudioPlayer();
  return fallbackPlayer!.player;
}

Future<void> initAudioService() async {
  debugPrint('[Audio] Initializing...');
  
  try {
    audioHandler = await AudioService.init(
      builder: () => AudioPlayerHandler(),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'id.my.zesbe.lumina.audio',
        androidNotificationChannelName: 'Lumina AI',
        androidStopForegroundOnPause: true,
      ),
    );
    useAudioService = true;
    debugPrint('[Audio] AudioService OK - notifications enabled');
  } catch (e) {
    debugPrint('[Audio] AudioService failed: $e');
    debugPrint('[Audio] Using fallback player - no notifications');
    fallbackPlayer = SimpleAudioPlayer();
    useAudioService = false;
  }
}

Future<void> playMusic(String url, String title, String artist, String? artUrl) async {
  debugPrint('[Audio] Playing: $title');
  
  if (useAudioService && audioHandler != null) {
    await audioHandler!.playUrl(url, title, artist, artUrl);
  } else {
    fallbackPlayer ??= SimpleAudioPlayer();
    await fallbackPlayer!.playUrl(url);
  }
}

Future<void> pauseMusic() async {
  if (useAudioService && audioHandler != null) {
    await audioHandler!.pause();
  } else {
    await fallbackPlayer?.pause();
  }
}

Future<void> resumeMusic() async {
  if (useAudioService && audioHandler != null) {
    await audioHandler!.play();
  } else {
    await fallbackPlayer?.play();
  }
}

Future<void> stopMusic() async {
  if (useAudioService && audioHandler != null) {
    await audioHandler!.stop();
  } else {
    await fallbackPlayer?.stop();
  }
}
