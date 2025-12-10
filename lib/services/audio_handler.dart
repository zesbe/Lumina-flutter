import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/foundation.dart';

class AudioPlayerHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final AudioPlayer _player = AudioPlayer();
  
  AudioPlayer get player => _player;

  AudioPlayerHandler() {
    _init();
  }

  Future<void> _init() async {
    // Broadcast playback state changes
    _player.playbackEventStream.listen(_broadcastState);
    
    // Handle completion
    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        skipToNext();
      }
    });

    // Broadcast current position periodically
    _player.positionStream.listen((position) {
      playbackState.add(playbackState.value.copyWith(
        updatePosition: position,
      ));
    });
  }

  void _broadcastState(PlaybackEvent event) {
    final playing = _player.playing;
    
    playbackState.add(PlaybackState(
      // Controls shown in notification
      controls: [
        MediaControl.skipToPrevious,
        if (playing) MediaControl.pause else MediaControl.play,
        MediaControl.stop,
        MediaControl.skipToNext,
      ],
      // Actions enabled in compact notification
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
        MediaAction.skipToNext,
        MediaAction.skipToPrevious,
      },
      // Compact notification buttons
      androidCompactActionIndices: const [0, 1, 3],
      // Current state
      processingState: {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: 0,
    ));
  }

  /// Play a URL with media info for notification
  Future<void> playFromUrl({
    required String url,
    required String title,
    String? artist,
    String? album,
    String? artUrl,
    Duration? duration,
  }) async {
    // Set media item first (this shows in notification)
    final item = MediaItem(
      id: url,
      title: title,
      artist: artist ?? 'Lumina AI',
      album: album ?? 'AI Generated',
      duration: duration,
      artUri: artUrl != null && artUrl.isNotEmpty ? Uri.tryParse(artUrl) : null,
      artHeaders: const {}, // Required for some image loading
    );
    
    mediaItem.add(item);
    debugPrint('[AudioHandler] MediaItem set: $title');
    
    // Load and play
    try {
      final audioDuration = await _player.setUrl(url);
      
      // Update media item with actual duration
      if (audioDuration != null) {
        mediaItem.add(item.copyWith(duration: audioDuration));
      }
      
      await _player.play();
      debugPrint('[AudioHandler] Playing: $url');
    } catch (e) {
      debugPrint('[AudioHandler] Error playing: $e');
    }
  }

  @override
  Future<void> play() async {
    await _player.play();
  }

  @override
  Future<void> pause() async {
    await _player.pause();
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  @override
  Future<void> skipToNext() async {
    // Handled by PlayerProvider
    debugPrint('[AudioHandler] skipToNext called');
  }

  @override
  Future<void> skipToPrevious() async {
    // Handled by PlayerProvider
    debugPrint('[AudioHandler] skipToPrevious called');
  }

  @override
  Future<void> setSpeed(double speed) async {
    await _player.setSpeed(speed);
  }

  Future<void> dispose() async {
    await _player.dispose();
  }
}

/// Initialize AudioService with proper notification config
Future<AudioPlayerHandler> initAudioService() async {
  return await AudioService.init(
    builder: () => AudioPlayerHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'id.my.zesbe.luminaai.audio',
      androidNotificationChannelName: 'Lumina AI Music',
      androidNotificationChannelDescription: 'Music playback controls',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: false, // Keep notification when paused
      androidShowNotificationBadge: true,
      androidNotificationIcon: 'drawable/ic_notification',
      notificationColor: Color(0xFF84CC16),
      // Show in lock screen
      androidResumeOnClick: true,
      preloadArtwork: true,
      artDownscaleWidth: 300,
      artDownscaleHeight: 300,
    ),
  );
}

// Helper color class since we can't import material here
class Color {
  final int value;
  const Color(this.value);
}
