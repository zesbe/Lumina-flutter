import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

class MyAudioHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer player = AudioPlayer();
  
  // Callbacks for skip actions
  Function()? onSkipToNext;
  Function()? onSkipToPrevious;

  MyAudioHandler() {
    player.playbackEventStream.listen(_broadcastState);
    player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        playbackState.add(playbackState.value.copyWith(
          processingState: AudioProcessingState.completed,
        ));
      }
    });
  }

  void _broadcastState(PlaybackEvent event) {
    final playing = player.playing;
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
    final item = MediaItem(
      id: url,
      title: title,
      artist: artist,
      artUri: (artUrl != null && artUrl.isNotEmpty) ? Uri.tryParse(artUrl) : null,
    );
    mediaItem.add(item);
    await player.setUrl(url);
    await player.play();
  }

  @override Future<void> play() => player.play();
  @override Future<void> pause() => player.pause();
  @override Future<void> seek(Duration position) => player.seek(position);
  
  @override 
  Future<void> skipToNext() async {
    onSkipToNext?.call();
  }
  
  @override 
  Future<void> skipToPrevious() async {
    onSkipToPrevious?.call();
  }
  
  @override
  Future<void> stop() async {
    await player.stop();
    await super.stop();
  }
}

late MyAudioHandler audioHandler;

Future<void> initAudioService() async {
  audioHandler = await AudioService.init(
    builder: () => MyAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'id.my.zesbe.lumina.audio',
      androidNotificationChannelName: 'Lumina AI',
      androidStopForegroundOnPause: true,
    ),
  );
}
