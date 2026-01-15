import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import '../data/database.dart';
import '../services/tidal_service.dart';
import '../services/recommendation_service.dart';
import '../models/models.dart';

/// Database Provider
final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

/// TIDAL Service Provider
final tidalServiceProvider = Provider<TidalService>((ref) {
  return TidalService();
});

/// Recommendation Service Provider
final recommendationServiceProvider = Provider<RecommendationService>((ref) {
  final database = ref.watch(databaseProvider);
  final tidalService = ref.watch(tidalServiceProvider);
  return RecommendationService(database, tidalService);
});

/// Search State
class SearchState {
  final bool isLoading;
  final SearchResult? result;
  final String? error;
  final String query;

  const SearchState({
    this.isLoading = false,
    this.result,
    this.error,
    this.query = '',
  });

  SearchState copyWith({
    bool? isLoading,
    SearchResult? result,
    String? error,
    String? query,
  }) {
    return SearchState(
      isLoading: isLoading ?? this.isLoading,
      result: result ?? this.result,
      error: error,
      query: query ?? this.query,
    );
  }
}

/// Search Notifier
class SearchNotifier extends StateNotifier<SearchState> {
  final TidalService _tidalService;

  SearchNotifier(this._tidalService) : super(const SearchState());

  Future<void> search(String query) async {
    if (query.isEmpty) {
      state = const SearchState();
      return;
    }

    state = state.copyWith(isLoading: true, query: query, error: null);

    try {
      final result = await _tidalService.search(query);
      state = state.copyWith(isLoading: false, result: result);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void clear() {
    state = const SearchState();
  }
}

/// Search Provider
final searchProvider = StateNotifierProvider<SearchNotifier, SearchState>((ref) {
  final tidalService = ref.watch(tidalServiceProvider);
  return SearchNotifier(tidalService);
});

// ============================================================================
// TIDAL HOMEPAGE STATE - Simple API-based sections
// ============================================================================

/// Home Data State - Simple TIDAL sections
class HomeDataState {
  final bool isLoading;
  final List<Playlist> songsOfTheYear;      // Songs of the Year playlists
  final List<Track> trendingTracks;          // Recommended new tracks (bento box)
  final List<Playlist> popularPlaylists;     // Popular playlists on TIDAL
  final List<Album> newAlbums;               // Suggested new albums for you
  final List<Album> albumsYouLlEnjoy;        // Albums you'll enjoy
  final String? error;

  const HomeDataState({
    this.isLoading = false,
    this.songsOfTheYear = const [],
    this.trendingTracks = const [],
    this.popularPlaylists = const [],
    this.newAlbums = const [],
    this.albumsYouLlEnjoy = const [],
    this.error,
  });

  HomeDataState copyWith({
    bool? isLoading,
    List<Playlist>? songsOfTheYear,
    List<Track>? trendingTracks,
    List<Playlist>? popularPlaylists,
    List<Album>? newAlbums,
    List<Album>? albumsYouLlEnjoy,
    String? error,
  }) {
    return HomeDataState(
      isLoading: isLoading ?? this.isLoading,
      songsOfTheYear: songsOfTheYear ?? this.songsOfTheYear,
      trendingTracks: trendingTracks ?? this.trendingTracks,
      popularPlaylists: popularPlaylists ?? this.popularPlaylists,
      newAlbums: newAlbums ?? this.newAlbums,
      albumsYouLlEnjoy: albumsYouLlEnjoy ?? this.albumsYouLlEnjoy,
      error: error,
    );
  }
}

/// Home Data Notifier - Simple TIDAL content loading
class HomeDataNotifier extends StateNotifier<HomeDataState> {
  final TidalService _tidalService;

  HomeDataNotifier(this._tidalService) : super(const HomeDataState()) {
    loadData();
  }

  Future<void> loadData() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Load ALL sections in parallel - simple API searches
      final results = await Future.wait([
        // 1. Songs of the Year playlists
        _tidalService.searchPlaylists('songs of the year', limit: 10)
            .catchError((_) => <Playlist>[]),
        // 2. Trending tracks for bento box
        _tidalService.searchTracks('trending', limit: 8)
            .catchError((_) => <Track>[]),
        // 3. Popular playlists (hip-hop, pop, etc.)
        _tidalService.searchPlaylists('hip hop', limit: 10)
            .catchError((_) => <Playlist>[]),
        // 4. New albums
        _tidalService.searchAlbums('new albums 2024', limit: 10)
            .catchError((_) => <Album>[]),
        // 5. Albums you'll enjoy (pop hits)
        _tidalService.searchAlbums('pop hits', limit: 10)
            .catchError((_) => <Album>[]),
      ]);

      state = state.copyWith(
        isLoading: false,
        songsOfTheYear: results[0] as List<Playlist>,
        trendingTracks: results[1] as List<Track>,
        popularPlaylists: results[2] as List<Playlist>,
        newAlbums: results[3] as List<Album>,
        albumsYouLlEnjoy: results[4] as List<Album>,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() async {
    await loadData();
  }
}

/// Home Data Provider
final homeDataProvider = StateNotifierProvider<HomeDataNotifier, HomeDataState>((ref) {
  final tidalService = ref.watch(tidalServiceProvider);
  return HomeDataNotifier(tidalService);
});

// ============================================================================
// ALBUM, ARTIST, PLAYLIST DETAIL PROVIDERS
// ============================================================================

/// Album Detail Provider
final albumDetailProvider = FutureProvider.family<AlbumDetail?, String>((ref, albumId) async {
  final tidalService = ref.watch(tidalServiceProvider);
  try {
    return await tidalService.getAlbum(albumId);
  } catch (e) {
    return null;
  }
});

/// Artist Detail Provider  
final artistDetailProvider = FutureProvider.family<ArtistDetail?, String>((ref, artistId) async {
  final tidalService = ref.watch(tidalServiceProvider);
  try {
    return await tidalService.getArtist(artistId);
  } catch (e) {
    return null;
  }
});

/// Playlist Detail Provider
final playlistDetailProvider = FutureProvider.family<PlaylistDetail?, String>((ref, playlistId) async {
  final tidalService = ref.watch(tidalServiceProvider);
  try {
    return await tidalService.getPlaylist(playlistId);
  } catch (e) {
    return null;
  }
});

// ============================================================================
// PLAYER PROVIDERS
// ============================================================================

class PlayerState {
  final Track? currentTrack;
  final List<Track> queue;
  final int currentIndex;
  final bool isPlaying;
  final bool isLoading;
  final Duration position;
  final Duration duration;
  final bool shuffle;
  final RepeatMode repeatMode;

  const PlayerState({
    this.currentTrack,
    this.queue = const [],
    this.currentIndex = 0,
    this.isPlaying = false,
    this.isLoading = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.shuffle = false,
    this.repeatMode = RepeatMode.off,
  });

  PlayerState copyWith({
    Track? currentTrack,
    List<Track>? queue,
    int? currentIndex,
    bool? isPlaying,
    bool? isLoading,
    Duration? position,
    Duration? duration,
    bool? shuffle,
    RepeatMode? repeatMode,
  }) {
    return PlayerState(
      currentTrack: currentTrack ?? this.currentTrack,
      queue: queue ?? this.queue,
      currentIndex: currentIndex ?? this.currentIndex,
      isPlaying: isPlaying ?? this.isPlaying,
      isLoading: isLoading ?? this.isLoading,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      shuffle: shuffle ?? this.shuffle,
      repeatMode: repeatMode ?? this.repeatMode,
    );
  }
}

enum RepeatMode { off, one, all }

class PlayerNotifier extends StateNotifier<PlayerState> {
  final TidalService _tidalService;
  final AppDatabase _database;

  PlayerNotifier(this._tidalService, this._database) : super(const PlayerState());

  Future<void> playTrack(Track track) async {
    state = state.copyWith(
      currentTrack: track,
      queue: [track],
      currentIndex: 0,
      isLoading: true,
    );

    try {
      // Get stream URL
      final streamUrl = await _tidalService.getStreamUrl(track.id);
      if (streamUrl != null) {
        // Save to history
        await _database.recordPlay(
          trackId: track.id,
          source: track.source == MusicSource.tidal ? 0 : 1,
          trackJson: jsonEncode(track.toJson()),
          playedDurationMs: 0,
          genre: track.genre,
          artistId: track.artistId,
        );
      }
      state = state.copyWith(isLoading: false, isPlaying: true);
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> playQueue(List<Track> tracks, {int startIndex = 0}) async {
    if (tracks.isEmpty) return;

    state = state.copyWith(
      queue: tracks,
      currentIndex: startIndex,
      currentTrack: tracks[startIndex],
      isLoading: true,
    );

    try {
      final track = tracks[startIndex];
      final streamUrl = await _tidalService.getStreamUrl(track.id);
      if (streamUrl != null) {
        await _database.recordPlay(
          trackId: track.id,
          source: track.source == MusicSource.tidal ? 0 : 1,
          trackJson: jsonEncode(track.toJson()),
          playedDurationMs: 0,
          genre: track.genre,
          artistId: track.artistId,
        );
      }
      state = state.copyWith(isLoading: false, isPlaying: true);
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  void pause() {
    state = state.copyWith(isPlaying: false);
  }

  void resume() {
    state = state.copyWith(isPlaying: true);
  }

  void togglePlayPause() {
    state = state.copyWith(isPlaying: !state.isPlaying);
  }

  Future<void> next() async {
    if (state.queue.isEmpty) return;
    
    int nextIndex = state.currentIndex + 1;
    if (nextIndex >= state.queue.length) {
      if (state.repeatMode == RepeatMode.all) {
        nextIndex = 0;
      } else {
        return;
      }
    }

    await playQueue(state.queue, startIndex: nextIndex);
  }

  Future<void> previous() async {
    if (state.queue.isEmpty) return;
    
    int prevIndex = state.currentIndex - 1;
    if (prevIndex < 0) {
      if (state.repeatMode == RepeatMode.all) {
        prevIndex = state.queue.length - 1;
      } else {
        prevIndex = 0;
      }
    }

    await playQueue(state.queue, startIndex: prevIndex);
  }

  void seek(Duration position) {
    state = state.copyWith(position: position);
  }

  void toggleShuffle() {
    state = state.copyWith(shuffle: !state.shuffle);
  }

  void toggleRepeat() {
    final modes = RepeatMode.values;
    final nextIndex = (modes.indexOf(state.repeatMode) + 1) % modes.length;
    state = state.copyWith(repeatMode: modes[nextIndex]);
  }

  void updatePosition(Duration position) {
    state = state.copyWith(position: position);
  }

  void updateDuration(Duration duration) {
    state = state.copyWith(duration: duration);
  }

  void stop() {
    state = const PlayerState();
  }
}

/// Player Provider
final playerProvider = StateNotifierProvider<PlayerNotifier, PlayerState>((ref) {
  final tidalService = ref.watch(tidalServiceProvider);
  final database = ref.watch(databaseProvider);
  return PlayerNotifier(tidalService, database);
});

/// Current Track Provider (convenience)
final currentTrackProvider = Provider<Track?>((ref) {
  return ref.watch(playerProvider).currentTrack;
});

/// Is Playing Provider (convenience)
final isPlayingProvider = Provider<bool>((ref) {
  return ref.watch(playerProvider).isPlaying;
});
