import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/foundation.dart';

class MyAudioHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer player = AudioPlayer();

  MyAudioHandler() {
    debugPrint('[AudioHandler] Initializing...');
    
    // Listen to player state and broadcast
    player.playbackEventStream.listen(_broadcastState);
    
    player.processingStateStream.listen((state) {
      debugPrint('[AudioHandler] ProcessingState: $state');
      if (state == ProcessingState.completed) {
        playbackState.add(playbackState.value.copyWith(
          processingState: AudioProcessingState.completed,
        ));
      }
    });
  }

  void _broadcastState(PlaybackEvent event) {
    final playing = player.playing;
    debugPrint('[AudioHandler] Broadcasting state: playing=$playing');
    
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
      },
      androidCompactActionIndices: const [0, 1, 3],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[player.processingState] ?? AudioProcessingState.idle,
      playing: playing,
      updatePosition: player.position,
      bufferedPosition: player.bufferedPosition,
      speed: player.speed,
      queueIndex: 0,
    ));
  }

  Future<void> playUrl(String url, String title, String artist, String? artUrl) async {
    debugPrint('[AudioHandler] playUrl: $title');
    debugPrint('[AudioHandler] URL: $url');
    debugPrint('[AudioHandler] Art: $artUrl');
    
    // Set media item FIRST - this shows in notification
    final item = MediaItem(
      id: url,
      title: title,
      artist: artist,
      artUri: (artUrl != null && artUrl.isNotEmpty) ? Uri.tryParse(artUrl) : null,
    );
    mediaItem.add(item);
    debugPrint('[AudioHandler] MediaItem set');
    
    // Load and play
    await player.setUrl(url);
    await player.play();
    debugPrint('[AudioHandler] Playing!');
  }

  @override
  Future<void> play() async {
    debugPrint('[AudioHandler] play()');
    await player.play();
  }

  @override
  Future<void> pause() async {
    debugPrint('[AudioHandler] pause()');
    await player.pause();
  }

  @override
  Future<void> stop() async {
    debugPrint('[AudioHandler] stop()');
    await player.stop();
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) async {
    debugPrint('[AudioHandler] seek($position)');
    await player.seek(position);
  }

  @override
  Future<void> skipToNext() async {
    debugPrint('[AudioHandler] skipToNext');
  }

  @override
  Future<void> skipToPrevious() async {
    debugPrint('[AudioHandler] skipToPrevious');
  }
}

// Global handler
late MyAudioHandler audioHandler;

Future<void> initAudioService() async {
  debugPrint('[AudioService] Initializing...');
  
  audioHandler = await AudioService.init(
    builder: () => MyAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'id.my.zesbe.lumina.audio',
      androidNotificationChannelName: 'Lumina AI',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: false,
    ),
  );
  
  debugPrint('[AudioService] Initialized successfully!');
}
