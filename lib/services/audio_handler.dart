import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/foundation.dart';

class AudioPlayerHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer _player = AudioPlayer();
  
  AudioPlayer get player => _player;

  AudioPlayerHandler() {
    // Broadcast initial state
    _broadcastState(PlaybackEvent());
    
    // Listen to player events
    _player.playbackEventStream.listen(_broadcastState);
    
    _player.playerStateStream.listen((state) {
      _broadcastState(PlaybackEvent());
    });
    
    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        playbackState.add(playbackState.value.copyWith(
          processingState: AudioProcessingState.completed,
        ));
      }
    });
  }

  void _broadcastState(PlaybackEvent event) {
    final playing = _player.playing;
    
    playbackState.add(PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        playing ? MediaControl.pause : MediaControl.play,
        MediaControl.stop,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
        MediaAction.skipToNext,
        MediaAction.skipToPrevious,
        MediaAction.play,
        MediaAction.pause,
        MediaAction.stop,
      },
      androidCompactActionIndices: const [0, 1, 3],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState] ?? AudioProcessingState.idle,
      playing: playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: 0,
    ));
  }

  Future<void> playUrl(String url, String title, String artist, String? artUrl) async {
    debugPrint('[AudioHandler] Playing: $title from $url');
    
    // Set media item first (for notification)
    final item = MediaItem(
      id: url,
      title: title,
      artist: artist,
      artUri: artUrl != null && artUrl.isNotEmpty ? Uri.tryParse(artUrl) : null,
    );
    mediaItem.add(item);
    
    try {
      // Load and play
      await _player.setUrl(url);
      await _player.play();
      debugPrint('[AudioHandler] Playback started');
    } catch (e) {
      debugPrint('[AudioHandler] Error: $e');
      rethrow;
    }
  }

  @override
  Future<void> play() async {
    debugPrint('[AudioHandler] play()');
    await _player.play();
  }

  @override
  Future<void> pause() async {
    debugPrint('[AudioHandler] pause()');
    await _player.pause();
  }

  @override
  Future<void> stop() async {
    debugPrint('[AudioHandler] stop()');
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) async {
    debugPrint('[AudioHandler] seek($position)');
    await _player.seek(position);
  }

  @override
  Future<void> skipToNext() async {
    debugPrint('[AudioHandler] skipToNext()');
    // Handled by PlayerProvider
  }

  @override
  Future<void> skipToPrevious() async {
    debugPrint('[AudioHandler] skipToPrevious()');
    // Handled by PlayerProvider
  }
  
  @override
  Future<void> click([MediaButton button = MediaButton.media]) async {
    debugPrint('[AudioHandler] click($button)');
    switch (button) {
      case MediaButton.media:
        if (_player.playing) {
          await pause();
        } else {
          await play();
        }
        break;
      case MediaButton.next:
        await skipToNext();
        break;
      case MediaButton.previous:
        await skipToPrevious();
        break;
    }
  }
}

AudioPlayerHandler? audioHandler;
bool audioServiceInitialized = false;

Future<void> initAudioService() async {
  debugPrint('[AudioService] Initializing...');
  try {
    audioHandler = await AudioService.init(
      builder: () => AudioPlayerHandler(),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'id.my.zesbe.lumina.channel',
        androidNotificationChannelName: 'Lumina AI Music',
        androidNotificationChannelDescription: 'Music playback controls',
        androidNotificationIcon: 'mipmap/ic_launcher',
        androidShowNotificationBadge: true,
        androidStopForegroundOnPause: true,
        artDownscaleWidth: 300,
        artDownscaleHeight: 300,
        fastForwardInterval: Duration(seconds: 10),
        rewindInterval: Duration(seconds: 10),
      ),
    );
    audioServiceInitialized = true;
    debugPrint('[AudioService] Initialized successfully!');
  } catch (e) {
    debugPrint('[AudioService] Init failed: $e');
    audioServiceInitialized = false;
  }
}
