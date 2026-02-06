import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import '../models/models.dart';
import '../services/tidal_service.dart';
import '../services/music_service.dart';
import '../services/subsonic_service.dart';
import '../services/qobuz_service.dart';
import '../services/recommendation_service.dart';
import '../data/database.dart';
import 'music_provider.dart';
import 'source_provider.dart';
import 'subsonic_provider.dart';

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
  final String? currentQuality; // 'HI_RES_LOSSLESS', 'LOSSLESS', 'HIGH', etc.

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
    this.currentQuality,
  });

  bool get isPlaying => status == PlaybackStatus.playing;
  bool get isPaused => status == PlaybackStatus.paused;
  bool get isLoading => status == PlaybackStatus.loading;
  bool get hasError => status == PlaybackStatus.error;
  bool get hasTrack => currentTrack != null;
  bool get hasQueue => queue.isNotEmpty;
  bool get shuffleEnabled => isShuffleOn;

  /// Get quality label for display: MAX (24-bit), HIGH (16-bit FLAC)
  String? get qualityLabel {
    if (currentQuality == null)
      return null; // Don't show badge until quality is known
    switch (currentQuality) {
      case 'HI_RES_LOSSLESS':
        return 'MAX'; // 24-bit Hi-Res
      case 'MAX':
        return 'MAX'; // Alias
      case 'LOSSLESS':
        return 'HIGH'; // 16-bit FLAC
      case 'HIGH':
        return 'HIGH'; // Alias for FLAC quality
      case 'OFFLINE':
        return 'OFFLINE'; // Cached files
      default:
        return 'HIGH'; // Default to HIGH for any FLAC
    }
  }

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
    String? currentQuality,
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
      currentQuality: currentQuality ?? this.currentQuality,
    );
  }
}

/// Player Notifier with History Recording
class PlayerNotifier extends StateNotifier<PlayerState> {
  final AudioPlayer _audioPlayer;
  final MusicService _musicService;
  final TidalService? _tidalService; // For TIDAL-specific quality info
  final AppDatabase _database;
  final Ref _ref;
  List<Track> _originalQueue = [];
  DateTime? _playStartTime;
  int _consecutiveFailures = 0; // Track consecutive play failures
  static const _minimumPlayDuration = Duration(seconds: 30);
  static const _maxConsecutiveFailures = 3; // Stop skipping after 3 failures

  // Volume normalization (Android loudness enhancer)
  AndroidLoudnessEnhancer? _loudnessEnhancer;
  static const _normalizationGainDb = 6.0; // Target gain in decibels

  PlayerNotifier(
      this._musicService, this._tidalService, this._database, this._ref)
      : _audioPlayer = AudioPlayer(),
        super(const PlayerState()) {
    _initListeners();
    _initLoudnessEnhancer();
  }

  /// Initialize loudness enhancer for volume normalization (Android only)
  Future<void> _initLoudnessEnhancer() async {
    try {
      _loudnessEnhancer = AndroidLoudnessEnhancer();
      await _loudnessEnhancer!.setTargetGain(_normalizationGainDb);
      await _loudnessEnhancer!
          .setEnabled(false); // Start disabled, enable per setting
      await _audioPlayer
          .setAudioSource(
            AudioSource.uri(Uri.parse('asset:///assets/audio/silence.mp3')),
            preload: false,
          )
          .catchError((_) => null); // Ignore if no silence file
      print('🔊 Volume normalization: Loudness enhancer initialized');
    } catch (e) {
      print('🔊 Volume normalization: Not available on this platform - $e');
      _loudnessEnhancer = null;
    }
  }

  /// Check if volume normalization is enabled in settings
  Future<bool> _isNormalizeVolumeEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('normalizeVolume') ?? false; // Default to false
  }

  /// Apply volume normalization based on settings
  Future<void> _applyVolumeNormalization() async {
    if (_loudnessEnhancer == null) return;

    try {
      final enabled = await _isNormalizeVolumeEnabled();
      await _loudnessEnhancer!.setEnabled(enabled);
      print('🔊 Volume normalization: ${enabled ? "ENABLED" : "DISABLED"}');
    } catch (e) {
      print('🔊 Volume normalization: Error applying setting - $e');
    }
  }

  void _initListeners() {
    _audioPlayer.playerStateStream.listen((playerState) {
      final status = switch (playerState.processingState) {
        ProcessingState.idle => PlaybackStatus.idle,
        ProcessingState.loading => PlaybackStatus.loading,
        ProcessingState.buffering => PlaybackStatus.loading,
        ProcessingState.ready =>
          playerState.playing ? PlaybackStatus.playing : PlaybackStatus.paused,
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

    // Handle playback errors
    _audioPlayer.playbackEventStream.listen(
      (event) {},
      onError: (Object e, StackTrace stackTrace) {
        print('Audio Player Error: $e');
        // Auto-skip to next on error
        if (state.queue.isNotEmpty &&
            state.queueIndex < state.queue.length - 1) {
          skipNext();
        } else {
          state = state.copyWith(
            status: PlaybackStatus.error,
            error: 'Playback failed. Please try again.',
          );
        }
      },
    );
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

    // Queue ended - trigger autoplay if enabled
    _triggerAutoplay();

    return PlaybackStatus.paused;
  }

  /// Check if autoplay is enabled in settings
  Future<bool> _isAutoplayEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('autoplay') ?? true; // Default to true
  }

  /// Trigger autoplay - fetch recommendations and add to queue
  Future<void> _triggerAutoplay() async {
    try {
      // Check if autoplay is enabled
      final autoplayEnabled = await _isAutoplayEnabled();
      if (!autoplayEnabled) {
        print('🎵 Autoplay: Disabled in settings');
        return;
      }

      // Don't trigger if queue is empty (nothing was playing)
      if (state.queue.isEmpty) {
        print('🎵 Autoplay: Queue is empty, skipping');
        return;
      }

      print('🎵 Autoplay: Queue ended, fetching recommendations...');

      // Get recommendation service via ref
      final recommendationService = _ref.read(recommendationServiceProvider);

      // Fetch personalized recommendations
      final recommendations =
          await recommendationService.getRecommendations(limit: 10);

      if (recommendations.isEmpty) {
        print('🎵 Autoplay: No recommendations available');
        return;
      }

      // Filter out tracks already in queue to avoid duplicates
      final existingIds =
          state.queue.map((t) => '${t.id}_${t.source.name}').toSet();
      final newTracks = recommendations
          .where((t) => !existingIds.contains('${t.id}_${t.source.name}'))
          .toList();

      if (newTracks.isEmpty) {
        print('🎵 Autoplay: All recommendations already in queue');
        return;
      }

      print(
          '🎵 Autoplay: Adding ${newTracks.length} recommended tracks to queue');

      // Add recommended tracks to queue
      final newQueue = [...state.queue, ...newTracks];
      _originalQueue = [..._originalQueue, ...newTracks];

      state = state.copyWith(
        queue: newQueue,
        queueSource: 'Autoplay Recommendations',
      );

      // Start playing the first recommended track
      playAtIndex(state.queueIndex + 1);
    } catch (e) {
      print('🎵 Autoplay: Error fetching recommendations - $e');
    }
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
      error: null,
      currentQuality: '',
    );

    try {
      print(
          '🎵 Playing: ${track.title} (ID: ${track.id}, Source: ${track.source.name})');

      String? streamUrl;
      String?
          quality; // Don't set default - will be determined from stream info
      int bitDepth = 0;
      int sampleRate = 0;
      bool isOffline = false;

      // Check for cached local file first (offline playback)
      final database = _ref.read(databaseProvider);
      final cachedPath =
          await database.getCachedPath(track.id, track.source.index);
      if (cachedPath != null) {
        final file = File(cachedPath);
        if (await file.exists()) {
          streamUrl = cachedPath; // just_audio supports file paths directly
          isOffline = true;
          quality = 'OFFLINE';
          print('📱 Playing from local cache: $cachedPath');
        }
      }

      // Get stream URL based on track source if not cached
      if (!isOffline) {
        switch (track.source) {
          case MusicSource.tidal:
            final tidalService = _tidalService;
            if (tidalService != null) {
              final streamInfo = await tidalService.getStreamInfo(track.id);
              streamUrl = streamInfo.url;
              quality = streamInfo.quality;
              bitDepth = streamInfo.bitDepth;
              sampleRate = streamInfo.sampleRate;
              print(
                  '📊 TIDAL Quality: $quality, BitDepth: $bitDepth, SampleRate: $sampleRate');
            }
            break;

          case MusicSource.subsonic:
            // CRITICAL: Use SubsonicServiceImpl directly via provider
            // This ensures correct service is used regardless of which musicService
            // the player was initialized with
            final subsonicService = _ref.read(subsonicServiceProvider);
            if (subsonicService != null) {
              streamUrl = subsonicService.getStreamUrlSync(track.id);
              print('[HiFi] Using SubsonicService directly for stream URL');
            } else {
              // Fallback to generic service
              streamUrl = await _musicService.getStreamUrl(track.id);
            }
            quality = 'LOSSLESS';
            bitDepth = 16;
            sampleRate = 44100;
            print('📊 HiFi Server Quality: $quality (FLAC)');
            break;

          case MusicSource.qobuz:
            final fallbackBitDepth = track.quality?.bitDepth ?? 16;
            final fallbackSampleRate = track.quality?.sampleRate ?? 44100;

            if (_musicService is QobuzServiceImpl) {
              final qobuzInfo = await _musicService.getStreamInfo(
                track.id,
                fallbackQuality: track.quality,
              );
              if (qobuzInfo != null) {
                streamUrl = qobuzInfo.url;
                quality = qobuzInfo.qualityCode;
                bitDepth = qobuzInfo.bitDepth;
                sampleRate = qobuzInfo.sampleRate;
              }
            }

            streamUrl ??= await _musicService.getStreamUrl(track.id);
            quality ??= fallbackBitDepth >= 24 ? 'HI_RES_LOSSLESS' : 'LOSSLESS';
            if (bitDepth < 1) {
              bitDepth = fallbackBitDepth;
            }
            if (sampleRate < 1) {
              sampleRate = fallbackSampleRate;
            }
            print(
                '📊 Qobuz Quality: $quality, BitDepth: $bitDepth, SampleRate: $sampleRate');
            break;

          default:
            streamUrl = await _musicService.getStreamUrl(track.id);
            print('📊 ${track.source.name} Quality: $quality');
        }
      }

      if (streamUrl == null || streamUrl.isEmpty) {
        throw Exception('Failed to get stream URL');
      }

      print(
          '🔗 Stream URL: ${streamUrl.substring(0, 50.clamp(0, streamUrl.length))}...');

      await _audioPlayer.setUrl(streamUrl);
      print('✅ URL set successfully');

      // Apply volume normalization setting before playing
      await _applyVolumeNormalization();

      await _audioPlayer.play();
      print('▶️ Play started');
      _playStartTime = DateTime.now();

      // Reset consecutive failures on successful play
      _consecutiveFailures = 0;

      // Update state with current quality
      state = state.copyWith(currentQuality: quality);
    } catch (e) {
      print('❌ Play error for "${track.title}": $e');
      _consecutiveFailures++;

      // Store the actual error so UI can show it
      final errorMsg = e.toString().replaceAll('TidalApiException: ', '');

      // Check if we should try next track or stop
      final hasMoreTracks =
          state.queue.isNotEmpty && state.queueIndex < state.queue.length - 1;
      final shouldSkip =
          hasMoreTracks && _consecutiveFailures < _maxConsecutiveFailures;

      if (shouldSkip) {
        print(
            '⏭️ Skipping "${track.title}" - trying next (failure $_consecutiveFailures/$_maxConsecutiveFailures)');
        // Update state to show which track failed (briefly)
        state = state.copyWith(
          error: 'Skipping "${track.title}" - not available',
        );
        await Future.delayed(const Duration(milliseconds: 500));
        skipNext();
        return;
      }

      // Too many failures or no more tracks - show error and stop
      print(
          '🛑 Stopping playback after $_consecutiveFailures consecutive failures');
      _consecutiveFailures = 0; // Reset for next attempt
      state = state.copyWith(
        status: PlaybackStatus.error,
        error: 'Track unavailable: "$errorMsg"',
      );
    }
  }

  /// Play a list of tracks (album/playlist)
  Future<void> playQueue(List<Track> tracks,
      {int startIndex = 0, String? source}) async {
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
      await _database.recordSkip(
          state.currentTrack!.id, state.currentTrack!.source.index);
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

  /// Add track to end of queue
  void addToQueue(Track track) {
    if (state.queue.isEmpty) {
      // No queue, just play the track
      play(track);
      return;
    }

    final newQueue = List<Track>.from(state.queue)..add(track);
    state = state.copyWith(queue: newQueue);
  }

  /// Add track to play next (after current track)
  void addToQueueNext(Track track) {
    if (state.queue.isEmpty) {
      // No queue, just play the track
      play(track);
      return;
    }

    final newQueue = List<Track>.from(state.queue);
    final insertIndex = state.queueIndex + 1;
    newQueue.insert(insertIndex.clamp(0, newQueue.length), track);
    state = state.copyWith(queue: newQueue);
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

/// Player Provider - Uses active music source with TIDAL fallback for quality info
final playerProvider =
    StateNotifierProvider<PlayerNotifier, PlayerState>((ref) {
  final musicService = ref.watch(musicServiceProvider);
  final tidalService = ref.watch(tidalServiceProvider);
  final database = ref.watch(databaseProvider);
  return PlayerNotifier(musicService, tidalService, database, ref);
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
      final tracks = favorites
          .map((f) {
            try {
              final json = jsonDecode(f.trackJson) as Map<String, dynamic>;
              // Use fromJson since we save with toJson (not TIDAL API format)
              return Track.fromJson(json);
            } catch (_) {
              return null;
            }
          })
          .whereType<Track>()
          .toList();

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
          favorites: state.favorites
              .where((f) => !(f.id == track.id && f.source == track.source))
              .toList(),
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

final favoritesProvider =
    StateNotifierProvider<FavoritesNotifier, FavoritesState>((ref) {
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
      final tracks = history
          .map((h) {
            try {
              final json = jsonDecode(h.trackJson) as Map<String, dynamic>;
              return Track.fromTidalJson(json);
            } catch (_) {
              return null;
            }
          })
          .whereType<Track>()
          .toList();

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

final historyProvider =
    StateNotifierProvider<HistoryNotifier, HistoryState>((ref) {
  final database = ref.watch(databaseProvider);
  return HistoryNotifier(database);
});
