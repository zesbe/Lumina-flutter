import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color;

class AudioPlayerHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final AudioPlayer _player = AudioPlayer();
  
  AudioPlayer get player => _player;

  AudioPlayerHandler() {
    _init();
  }

  Future<void> _init() async {
    _player.playbackEventStream.listen(_broadcastState);
    
    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        playbackState.add(playbackState.value.copyWith(
          processingState: AudioProcessingState.completed,
        ));
      }
    });

    _player.positionStream.listen((position) {
      playbackState.add(playbackState.value.copyWith(
        updatePosition: position,
      ));
    });

    debugPrint('[AudioHandler] Initialized');
  }

  void _broadcastState(PlaybackEvent event) {
    final playing = _player.playing;
    
    playbackState.add(PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        if (playing) MediaControl.pause else MediaControl.play,
        MediaControl.stop,
        MediaControl.skipToNext,
      ],
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
      androidCompactActionIndices: const [0, 1, 3],
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

  Future<void> playFromUrl({
    required String url,
    required String title,
    String? artist,
    String? album,
    String? artUrl,
    Duration? duration,
  }) async {
    final item = MediaItem(
      id: url,
      title: title,
      artist: artist ?? 'Lumina AI',
      album: album ?? 'AI Generated',
      duration: duration,
      artUri: artUrl != null && artUrl.isNotEmpty ? Uri.tryParse(artUrl) : null,
    );
    
    mediaItem.add(item);
    
    try {
      final audioDuration = await _player.setUrl(url);
      if (audioDuration != null) {
        mediaItem.add(item.copyWith(duration: audioDuration));
      }
      await _player.play();
    } catch (e) {
      debugPrint('[AudioHandler] Error: $e');
      rethrow;
    }
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() async {}

  @override
  Future<void> skipToPrevious() async {}

  @override
  Future<void> onTaskRemoved() async {
    // Keep playing when app closed
  }

  Future<void> dispose() => _player.dispose();
}

Future<AudioPlayerHandler> initAudioService() async {
  return await AudioService.init(
    builder: () => AudioPlayerHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'id.my.zesbe.luminaai.audio',
      androidNotificationChannelName: 'Lumina AI Music',
      androidNotificationChannelDescription: 'Musik sedang diputar',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: false,
      androidShowNotificationBadge: true,
      androidNotificationIcon: 'drawable/ic_notification',
      notificationColor: Color(0xFF84CC16),
      androidResumeOnClick: true,
      preloadArtwork: true,
      artDownscaleWidth: 300,
      artDownscaleHeight: 300,
      fastForwardInterval: Duration(seconds: 10),
      rewindInterval: Duration(seconds: 10),
    ),
  );
}
