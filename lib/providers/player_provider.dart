import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:convert';
import '../models/models.dart';
import '../services/tidal_service.dart';
import '../data/database.dart';
import 'music_provider.dart';

/// Playback State
enum PlaybackStatus { idle, loading, playing, paused, error }

/// Repeat Mode
enum RepeatMode { off, all, one }

/// Player State
class PlayerState {
  final Track? currentTrack;
  final PlaybackStatus status;
  final Duration position;
  final Duration duration;
  final double volume;
  final bool isMuted;
  final bool isShuffleOn;
  final RepeatMode repeatMode;
  final List<Track> queue;
  final int queueIndex;
  final String? queueSource; // Playlist/album name for 'Playing From'
  final String? error;

  const PlayerState({
    this.currentTrack,
    this.status = PlaybackStatus.idle,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.volume = 1.0,
    this.isMuted = false,
    this.isShuffleOn = false,
    this.repeatMode = RepeatMode.off,
    this.queue = const [],
    this.queueIndex = 0,
    this.queueSource,
    this.error,
  });

  bool get isPlaying => status == PlaybackStatus.playing;
  bool get isPaused => status == PlaybackStatus.paused;
  bool get isLoading => status == PlaybackStatus.loading;
  bool get hasError => status == PlaybackStatus.error;
  bool get hasTrack => currentTrack != null;
  bool get hasQueue => queue.isNotEmpty;
  bool get shuffleEnabled => isShuffleOn;

  double get progress {
    if (duration.inMilliseconds == 0) return 0;
    return position.inMilliseconds / duration.inMilliseconds;
  }

  PlayerState copyWith({
    Track? currentTrack,
    PlaybackStatus? status,
    Duration? position,
    Duration? duration,
    double? volume,
    bool? isMuted,
    bool? isShuffleOn,
    RepeatMode? repeatMode,
    List<Track>? queue,
    int? queueIndex,
    String? queueSource,
    String? error,
  }) {
    return PlayerState(
      currentTrack: currentTrack ?? this.currentTrack,
      status: status ?? this.status,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      volume: volume ?? this.volume,
      isMuted: isMuted ?? this.isMuted,
      isShuffleOn: isShuffleOn ?? this.isShuffleOn,
      repeatMode: repeatMode ?? this.repeatMode,
      queue: queue ?? this.queue,
      queueIndex: queueIndex ?? this.queueIndex,
      queueSource: queueSource ?? this.queueSource,
      error: error,
    );
  }
}

/// Player Notifier with History Recording
class PlayerNotifier extends StateNotifier<PlayerState> {
  final AudioPlayer _audioPlayer;
  final TidalService _tidalService;
  final AppDatabase _database;
  final Ref _ref;
  List<Track> _originalQueue = [];
  DateTime? _playStartTime;
  static const _minimumPlayDuration = Duration(seconds: 30);

  PlayerNotifier(this._tidalService, this._database, this._ref)
      : _audioPlayer = AudioPlayer(),
        super(const PlayerState()) {
    _initListeners();
  }

  void _initListeners() {
    _audioPlayer.playerStateStream.listen((playerState) {
      final status = switch (playerState.processingState) {
        ProcessingState.idle => PlaybackStatus.idle,
        ProcessingState.loading => PlaybackStatus.loading,
        ProcessingState.buffering => PlaybackStatus.loading,
        ProcessingState.ready => playerState.playing 
            ? PlaybackStatus.playing 
            : PlaybackStatus.paused,
        ProcessingState.completed => _handleCompletion(),
      };
      
      // Track play start time
      if (status == PlaybackStatus.playing && _playStartTime == null) {
        _playStartTime = DateTime.now();
      }
      
      state = state.copyWith(status: status);
    });

    _audioPlayer.positionStream.listen((position) {
      state = state.copyWith(position: position);
    });

    _audioPlayer.durationStream.listen((duration) {
      if (duration != null) {
        state = state.copyWith(duration: duration);
      }
    });
  }

  PlaybackStatus _handleCompletion() {
    // Record play to history
    _recordPlayToHistory();
    
    // Handle track completion based on repeat mode
    if (state.repeatMode == RepeatMode.one) {
      _audioPlayer.seek(Duration.zero);
      _audioPlayer.play();
      _playStartTime = DateTime.now();
      return PlaybackStatus.playing;
    } else if (state.queueIndex < state.queue.length - 1) {
      skipNext();
      return PlaybackStatus.loading;
    } else if (state.repeatMode == RepeatMode.all && state.queue.isNotEmpty) {
      playAtIndex(0);
      return PlaybackStatus.loading;
    }
    return PlaybackStatus.paused;
  }

  Future<void> _recordPlayToHistory() async {
    if (state.currentTrack == null || _playStartTime == null) return;
    
    final playedDuration = DateTime.now().difference(_playStartTime!);
    
    // Only record if played for at least 30 seconds
    if (playedDuration >= _minimumPlayDuration) {
      try {
        await _database.recordPlay(
          trackId: state.currentTrack!.id,
          source: state.currentTrack!.source.index,
          trackJson: jsonEncode(state.currentTrack!.toJson()),
          playedDurationMs: playedDuration.inMilliseconds,
          genre: state.currentTrack!.genre,
          artistId: state.currentTrack!.artistId,
        );
        
        // Refresh history in the provider
        _ref.read(historyProvider.notifier).loadHistory();
      } catch (e) {
        // Silent fail for history recording
      }
    }
    
    _playStartTime = null;
  }

  /// Play a track
  Future<void> play(Track track) async {
    // Record previous track if any
    if (state.currentTrack != null) {
      await _recordPlayToHistory();
    }
    
    state = state.copyWith(
      currentTrack: track,
      status: PlaybackStatus.loading,
      position: Duration.zero,
    );

    try {
      final streamUrl = await _tidalService.getStreamUrl(track.id);
      await _audioPlayer.setUrl(streamUrl);
      await _audioPlayer.play();
      _playStartTime = DateTime.now();
    } catch (e) {
      state = state.copyWith(
        status: PlaybackStatus.error,
        error: e.toString(),
      );
    }
  }

  /// Play a list of tracks (album/playlist)
  Future<void> playQueue(List<Track> tracks, {int startIndex = 0, String? source}) async {
    if (tracks.isEmpty) return;

    _originalQueue = List.from(tracks);
    state = state.copyWith(
      queue: tracks,
      queueIndex: startIndex,
      queueSource: source,
    );

    await play(tracks[startIndex]);
  }

  /// Play track at specific index in queue
  Future<void> playAtIndex(int index) async {
    if (index < 0 || index >= state.queue.length) return;

    state = state.copyWith(queueIndex: index);
    await play(state.queue[index]);
  }

  /// Pause playback
  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  /// Resume playback
  Future<void> resume() async {
    await _audioPlayer.play();
    if (_playStartTime == null) {
      _playStartTime = DateTime.now();
    }
  }

  /// Toggle play/pause
  Future<void> togglePlayPause() async {
    if (state.isPlaying) {
      await pause();
    } else {
      await resume();
    }
  }

  /// Seek to position
  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  /// Skip to next track
  Future<void> skipNext() async {
    if (state.queue.isEmpty) return;

    // Check if this was a skip (played less than 30 seconds)
    if (state.currentTrack != null && 
        _playStartTime != null &&
        DateTime.now().difference(_playStartTime!) < _minimumPlayDuration) {
      // Record as skip
      await _database.recordSkip(state.currentTrack!.id, state.currentTrack!.source.index);
    } else {
      await _recordPlayToHistory();
    }

    int nextIndex = state.queueIndex + 1;
    if (nextIndex >= state.queue.length) {
      if (state.repeatMode == RepeatMode.all) {
        nextIndex = 0;
      } else {
        return;
      }
    }

    await playAtIndex(nextIndex);
  }

  /// Skip to previous track
  Future<void> skipPrevious() async {
    if (state.queue.isEmpty) return;

    // If more than 3 seconds into the track, restart it
    if (state.position.inSeconds > 3) {
      await seek(Duration.zero);
      return;
    }

    int prevIndex = state.queueIndex - 1;
    if (prevIndex < 0) {
      if (state.repeatMode == RepeatMode.all) {
        prevIndex = state.queue.length - 1;
      } else {
        await seek(Duration.zero);
        return;
      }
    }

    await playAtIndex(prevIndex);
  }

  /// Toggle shuffle mode
  void toggleShuffle() {
    if (state.isShuffleOn) {
      // Restore original order
      final currentTrack = state.currentTrack;
      state = state.copyWith(
        isShuffleOn: false,
        queue: _originalQueue,
        queueIndex: currentTrack != null 
            ? _originalQueue.indexWhere((t) => t.id == currentTrack.id)
            : 0,
      );
    } else {
      // Shuffle queue
      final shuffled = List<Track>.from(state.queue)..shuffle();
      final currentTrack = state.currentTrack;
      
      // Move current track to front
      if (currentTrack != null) {
        shuffled.removeWhere((t) => t.id == currentTrack.id);
        shuffled.insert(0, currentTrack);
      }

      state = state.copyWith(
        isShuffleOn: true,
        queue: shuffled,
        queueIndex: 0,
      );
    }
  }

  /// Cycle repeat mode
  void toggleRepeat() {
    final nextMode = switch (state.repeatMode) {
      RepeatMode.off => RepeatMode.all,
      RepeatMode.all => RepeatMode.one,
      RepeatMode.one => RepeatMode.off,
    };
    state = state.copyWith(repeatMode: nextMode);
  }

  // Aliases for now_playing_screen
  Future<void> next() => skipNext();
  Future<void> previous() => skipPrevious();
  void cycleRepeatMode() => toggleRepeat();

  /// Set volume
  Future<void> setVolume(double volume) async {
    await _audioPlayer.setVolume(volume);
    state = state.copyWith(volume: volume, isMuted: volume == 0);
  }

  /// Toggle mute
  Future<void> toggleMute() async {
    if (state.isMuted) {
      await setVolume(1.0);
    } else {
      await setVolume(0);
    }
  }

  /// Add track to queue
  void addToQueue(Track track) {
    state = state.copyWith(
      queue: [...state.queue, track],
    );
    _originalQueue.add(track);
  }

  /// Play track next
  void playNext(Track track) {
    final queue = List<Track>.from(state.queue);
    queue.insert(state.queueIndex + 1, track);
    state = state.copyWith(queue: queue);
    _originalQueue.insert(state.queueIndex + 1, track);
  }

  /// Remove track from queue
  void removeFromQueue(int index) {
    if (index < 0 || index >= state.queue.length) return;

    final queue = List<Track>.from(state.queue);
    queue.removeAt(index);

    int newIndex = state.queueIndex;
    if (index < state.queueIndex) {
      newIndex--;
    } else if (index == state.queueIndex && queue.isNotEmpty) {
      if (newIndex >= queue.length) {
        newIndex = queue.length - 1;
      }
    }

    state = state.copyWith(
      queue: queue,
      queueIndex: newIndex,
    );
  }

  /// Stop playback
  Future<void> stop() async {
    await _recordPlayToHistory();
    await _audioPlayer.stop();
    state = const PlayerState();
  }

  @override
  void dispose() {
    _recordPlayToHistory();
    _audioPlayer.dispose();
    super.dispose();
  }
}

/// Player Provider
final playerProvider = StateNotifierProvider<PlayerNotifier, PlayerState>((ref) {
  final tidalService = ref.watch(tidalServiceProvider);
  final database = ref.watch(databaseProvider);
  return PlayerNotifier(tidalService, database, ref);
});

// ============================================================================
// FAVORITES PROVIDER
// ============================================================================

class FavoritesState {
  final List<Track> favorites;
  final bool isLoading;
  final String? error;

  const FavoritesState({
    this.favorites = const [],
    this.isLoading = false,
    this.error,
  });

  FavoritesState copyWith({
    List<Track>? favorites,
    bool? isLoading,
    String? error,
  }) {
    return FavoritesState(
      favorites: favorites ?? this.favorites,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  bool isFavorite(Track track) {
    return favorites.any((f) => f.id == track.id && f.source == track.source);
  }
}

class FavoritesNotifier extends StateNotifier<FavoritesState> {
  final AppDatabase _database;

  FavoritesNotifier(this._database) : super(const FavoritesState()) {
    loadFavorites();
  }

  Future<void> loadFavorites() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final favorites = await _database.getAllFavorites();
      final tracks = favorites.map((f) {
        try {
          final json = jsonDecode(f.trackJson) as Map<String, dynamic>;
          return Track.fromTidalJson(json);
        } catch (_) {
          return null;
        }
      }).whereType<Track>().toList();
      
      state = state.copyWith(favorites: tracks, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> toggleFavorite(Track track) async {
    try {
      final isFav = state.isFavorite(track);
      if (isFav) {
        await _database.removeFavorite(track.id, track.source.index);
        state = state.copyWith(
          favorites: state.favorites.where((f) => 
            !(f.id == track.id && f.source == track.source)
          ).toList(),
        );
      } else {
        await _database.addFavorite(
          trackId: track.id,
          source: track.source.index,
          trackJson: jsonEncode(track.toJson()),
        );
        state = state.copyWith(
          favorites: [...state.favorites, track],
        );
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

final favoritesProvider = StateNotifierProvider<FavoritesNotifier, FavoritesState>((ref) {
  final database = ref.watch(databaseProvider);
  return FavoritesNotifier(database);
});

// ============================================================================
// HISTORY PROVIDER
// ============================================================================

class HistoryState {
  final List<Track> history;
  final bool isLoading;
  final String? error;

  const HistoryState({
    this.history = const [],
    this.isLoading = false,
    this.error,
  });

  HistoryState copyWith({
    List<Track>? history,
    bool? isLoading,
    String? error,
  }) {
    return HistoryState(
      history: history ?? this.history,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class HistoryNotifier extends StateNotifier<HistoryState> {
  final AppDatabase _database;

  HistoryNotifier(this._database) : super(const HistoryState()) {
    loadHistory();
  }

  Future<void> loadHistory() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final history = await _database.getRecentlyPlayed(limit: 50);
      final tracks = history.map((h) {
        try {
          final json = jsonDecode(h.trackJson) as Map<String, dynamic>;
          return Track.fromTidalJson(json);
        } catch (_) {
          return null;
        }
      }).whereType<Track>().toList();
      
      state = state.copyWith(history: tracks, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> clearHistory() async {
    try {
      await _database.clearHistory();
      state = state.copyWith(history: []);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

final historyProvider = StateNotifierProvider<HistoryNotifier, HistoryState>((ref) {
  final database = ref.watch(databaseProvider);
  return HistoryNotifier(database);
});
