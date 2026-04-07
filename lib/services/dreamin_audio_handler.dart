import 'package:audio_service/audio_service.dart';
import '../models/models.dart';

typedef PlaybackVoidCallback = Future<void> Function();
typedef PlaybackSeekCallback = Future<void> Function(Duration position);

class DreaminAudioHandler extends BaseAudioHandler with SeekHandler {
  PlaybackVoidCallback? _onPlay;
  PlaybackVoidCallback? _onPause;
  PlaybackVoidCallback? _onStop;
  PlaybackVoidCallback? _onSkipNext;
  PlaybackVoidCallback? _onSkipPrevious;
  PlaybackSeekCallback? _onSeek;

  void attachCallbacks({
    PlaybackVoidCallback? onPlay,
    PlaybackVoidCallback? onPause,
    PlaybackVoidCallback? onStop,
    PlaybackVoidCallback? onSkipNext,
    PlaybackVoidCallback? onSkipPrevious,
    PlaybackSeekCallback? onSeek,
  }) {
    _onPlay = onPlay;
    _onPause = onPause;
    _onStop = onStop;
    _onSkipNext = onSkipNext;
    _onSkipPrevious = onSkipPrevious;
    _onSeek = onSeek;
  }

  MediaItem mediaItemFromTrack(Track track) {
    final extras = <String, dynamic>{
      'source': track.source.name,
      'albumId': track.albumId,
      'artistId': track.artistId,
      'trackNumber': track.trackNumber,
      'isExplicit': track.isExplicit,
      if (track.year != null) 'year': track.year,
      if (track.genre != null) 'genre': track.genre,
    };

    return MediaItem(
      id: '${track.source.name}:${track.id}',
      album: track.album,
      title: track.title,
      artist: track.artist,
      duration: track.duration,
      artUri: track.coverArtUrl == null || track.coverArtUrl!.isEmpty
          ? null
          : Uri.tryParse(track.coverArtUrl!),
      extras: extras,
    );
  }

  void updateQueueFromTracks(List<Track> tracks) {
    queue.add(tracks.map(mediaItemFromTrack).toList(growable: false));
  }

  void updateCurrentTrack(Track? track) {
    mediaItem.add(track == null ? null : mediaItemFromTrack(track));
  }

  void updatePlayback({
    required bool playing,
    required AudioProcessingState processingState,
    required Duration updatePosition,
    required Duration bufferedPosition,
    required double speed,
    required int queueIndex,
    required bool canSkipNext,
    required bool canSkipPrevious,
  }) {
    final controls = <MediaControl>[
      if (canSkipPrevious) MediaControl.skipToPrevious,
      if (playing) MediaControl.pause else MediaControl.play,
      if (canSkipNext) MediaControl.skipToNext,
      MediaControl.stop,
    ];

    final compact = <int>[
      if (canSkipPrevious) controls.indexOf(MediaControl.skipToPrevious),
      controls.indexOf(playing ? MediaControl.pause : MediaControl.play),
      if (canSkipNext) controls.indexOf(MediaControl.skipToNext),
    ].where((index) => index >= 0).toSet().take(3).toList(growable: false);

    playbackState.add(
      PlaybackState(
        controls: controls,
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
          MediaAction.playPause,
        },
        androidCompactActionIndices: compact,
        processingState: processingState,
        playing: playing,
        updatePosition: updatePosition,
        bufferedPosition: bufferedPosition,
        speed: speed,
        queueIndex: queueIndex,
      ),
    );
  }

  @override
  Future<void> play() async => _onPlay?.call();

  @override
  Future<void> pause() async => _onPause?.call();

  @override
  Future<void> stop() async => _onStop?.call();

  @override
  Future<void> skipToNext() async => _onSkipNext?.call();

  @override
  Future<void> skipToPrevious() async => _onSkipPrevious?.call();

  @override
  Future<void> seek(Duration position) async => _onSeek?.call(position);
}

late final DreaminAudioHandler dreaminAudioHandler;

Future<void> initDreaminAudioHandler() async {
  final handler = await AudioService.init(
    builder: DreaminAudioHandler.new,
    config: AudioServiceConfig(
      androidNotificationChannelId: 'com.dreamin.dreamin_app.channel.audio',
      androidNotificationChannelName: 'Dreamin playback',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: false,
      preloadArtwork: true,
    ),
  );

  dreaminAudioHandler = handler;
}
