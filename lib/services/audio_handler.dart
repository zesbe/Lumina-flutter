import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/foundation.dart';

/// Audio handler that supports background playback
class AudioPlayerHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final AudioPlayer _player = AudioPlayer();
  
  AudioPlayer get player => _player;

  AudioPlayerHandler() {
    _init();
  }

  Future<void> _init() async {
    // Set audio session for background playback
    _player.playbackEventStream.listen(_broadcastState);
    
    // Handle song completion
    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        // Will trigger skipToNext in PlayerProvider
        playbackState.add(playbackState.value.copyWith(
          processingState: AudioProcessingState.completed,
        ));
      }
    });

    // Keep updating position
    _player.positionStream.listen((position) {
      playbackState.add(playbackState.value.copyWith(
        updatePosition: position,
      ));
    });

    debugPrint('[AudioHandler] Initialized for background playback');
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
      // System actions
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
        MediaAction.skipToNext,
        MediaAction.skipToPrevious,
        MediaAction.stop,
        MediaAction.play,
        MediaAction.pause,
      },
      // Compact notification shows these buttons
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
    // Create media item for notification display
    final item = MediaItem(
      id: url,
      title: title,
      artist: artist ?? 'Lumina AI',
      album: album ?? 'AI Generated',
      duration: duration,
      artUri: artUrl != null && artUrl.isNotEmpty ? Uri.tryParse(artUrl) : null,
    );
    
    // Update notification with song info
    mediaItem.add(item);
    debugPrint('[AudioHandler] MediaItem: $title by $artist');
    
    try {
      // Load and play
      final audioDuration = await _player.setUrl(url);
      
      // Update with actual duration
      if (audioDuration != null) {
        mediaItem.add(item.copyWith(duration: audioDuration));
      }
      
      await _player.play();
      debugPrint('[AudioHandler] Playing in background: $url');
    } catch (e) {
      debugPrint('[AudioHandler] Error: $e');
      rethrow;
    }
  }

  @override
  Future<void> play() async {
    debugPrint('[AudioHandler] Play from notification');
    await _player.play();
  }

  @override
  Future<void> pause() async {
    debugPrint('[AudioHandler] Pause from notification');
    await _player.pause();
  }

  @override
  Future<void> stop() async {
    debugPrint('[AudioHandler] Stop from notification');
    await _player.stop();
    // This will remove the notification
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  @override
  Future<void> skipToNext() async {
    debugPrint('[AudioHandler] Skip to next from notification');
    // Handled by PlayerProvider listener
  }

  @override
  Future<void> skipToPrevious() async {
    debugPrint('[AudioHandler] Skip to previous from notification');
    // Handled by PlayerProvider listener
  }

  @override
  Future<void> onTaskRemoved() async {
    // Keep playing when app is swiped away from recents
    // Only stop if user explicitly stops
    debugPrint('[AudioHandler] Task removed, continuing playback...');
  }

  Future<void> dispose() async {
    await _player.dispose();
  }
}

/// Initialize AudioService with background playback config
Future<AudioPlayerHandler> initAudioService() async {
  return await AudioService.init(
    builder: () => AudioPlayerHandler(),
    config: const AudioServiceConfig(
      // Notification channel
      androidNotificationChannelId: 'id.my.zesbe.luminaai.audio',
      androidNotificationChannelName: 'Lumina AI Music',
      androidNotificationChannelDescription: 'Musik sedang diputar',
      
      // Keep notification visible
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: false, // Keep notification when paused
      
      // Notification appearance
      androidShowNotificationBadge: true,
      androidNotificationIcon: 'drawable/ic_notification',
      notificationColor: Color(0xFF84CC16),
      
      // Background playback settings
      androidResumeOnClick: true,
      preloadArtwork: true,
      artDownscaleWidth: 300,
      artDownscaleHeight: 300,
      
      // Keep service alive
      fastForwardInterval: Duration(seconds: 10),
      rewindInterval: Duration(seconds: 10),
    ),
  );
}

class Color {
  final int value;
  const Color(this.value);
}
