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

/// Home Data State
class HomeDataState {
  final bool isLoading;
  final List<Album> newAlbums;
  final List<Playlist> popularPlaylists;
  final List<Playlist> featuredPlaylists;
  final List<Track> recommendations;
  final String? error;

  const HomeDataState({
    this.isLoading = false,
    this.newAlbums = const [],
    this.popularPlaylists = const [],
    this.featuredPlaylists = const [],
    this.recommendations = const [],
    this.error,
  });

  HomeDataState copyWith({
    bool? isLoading,
    List<Album>? newAlbums,
    List<Playlist>? popularPlaylists,
    List<Playlist>? featuredPlaylists,
    List<Track>? recommendations,
    String? error,
  }) {
    return HomeDataState(
      isLoading: isLoading ?? this.isLoading,
      newAlbums: newAlbums ?? this.newAlbums,
      popularPlaylists: popularPlaylists ?? this.popularPlaylists,
      featuredPlaylists: featuredPlaylists ?? this.featuredPlaylists,
      recommendations: recommendations ?? this.recommendations,
      error: error,
    );
  }
}

/// Home Data Notifier
class HomeDataNotifier extends StateNotifier<HomeDataState> {
  final TidalService _tidalService;
  final RecommendationService _recommendationService;

  HomeDataNotifier(this._tidalService, this._recommendationService) 
      : super(const HomeDataState()) {
    loadData();
  }

  Future<void> loadData() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Load data in parallel
      final results = await Future.wait([
        _tidalService.getNewAlbums(limit: 10).catchError((_) => <Album>[]),
        _tidalService.getPopularPlaylists(limit: 10).catchError((_) => <Playlist>[]),
        _tidalService.getFeaturedPlaylists(limit: 10).catchError((_) => <Playlist>[]),
        _recommendationService.getRecommendations(limit: 20).catchError((_) => <Track>[]),
      ]);

      state = state.copyWith(
        isLoading: false,
        newAlbums: results[0] as List<Album>,
        popularPlaylists: results[1] as List<Playlist>,
        featuredPlaylists: results[2] as List<Playlist>,
        recommendations: results[3] as List<Track>,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() async {
    _recommendationService.invalidateCache();
    await loadData();
  }
}

/// Home Data Provider
final homeDataProvider = StateNotifierProvider<HomeDataNotifier, HomeDataState>((ref) {
  final tidalService = ref.watch(tidalServiceProvider);
  final recommendationService = ref.watch(recommendationServiceProvider);
  return HomeDataNotifier(tidalService, recommendationService);
});

/// Album Detail Provider
final albumDetailProvider = FutureProvider.family<AlbumDetail, String>((ref, albumId) async {
  final tidalService = ref.watch(tidalServiceProvider);
  return tidalService.getAlbum(albumId);
});

/// Artist Detail Provider
final artistDetailProvider = FutureProvider.family<ArtistDetail, String>((ref, artistId) async {
  final tidalService = ref.watch(tidalServiceProvider);
  return tidalService.getArtist(artistId);
});

/// Playlist Detail Provider
final playlistDetailProvider = FutureProvider.family<PlaylistDetail, String>((ref, playlistId) async {
  final tidalService = ref.watch(tidalServiceProvider);
  return tidalService.getPlaylist(playlistId);
});

/// Favorites State
class FavoritesState {
  final bool isLoading;
  final List<Track> favorites;
  final Set<String> favoriteIds;

  const FavoritesState({
    this.isLoading = false,
    this.favorites = const [],
    this.favoriteIds = const {},
  });

  FavoritesState copyWith({
    bool? isLoading,
    List<Track>? favorites,
    Set<String>? favoriteIds,
  }) {
    return FavoritesState(
      isLoading: isLoading ?? this.isLoading,
      favorites: favorites ?? this.favorites,
      favoriteIds: favoriteIds ?? this.favoriteIds,
    );
  }
}

/// Favorites Notifier
class FavoritesNotifier extends StateNotifier<FavoritesState> {
  final AppDatabase _database;

  FavoritesNotifier(this._database) : super(const FavoritesState()) {
    loadFavorites();
  }

  Future<void> loadFavorites() async {
    state = state.copyWith(isLoading: true);
    
    try {
      final favs = await _database.getAllFavorites();
      final tracks = favs.map((f) {
        final json = jsonDecode(f.trackJson) as Map<String, dynamic>;
        return Track.fromTidalJson(json);
      }).toList();
      
      final ids = tracks.map((t) => '${t.id}_${t.source.name}').toSet();
      
      state = state.copyWith(
        isLoading: false,
        favorites: tracks,
        favoriteIds: ids,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> toggleFavorite(Track track) async {
    final key = '${track.id}_${track.source.name}';
    
    if (state.favoriteIds.contains(key)) {
      await _database.removeFavorite(track.id, track.source.index);
      state = state.copyWith(
        favorites: state.favorites.where((t) => t.id != track.id).toList(),
        favoriteIds: Set.from(state.favoriteIds)..remove(key),
      );
    } else {
      await _database.addFavorite(
        trackId: track.id,
        source: track.source.index,
        trackJson: jsonEncode(track.toJson()),
      );
      state = state.copyWith(
        favorites: [track, ...state.favorites],
        favoriteIds: Set.from(state.favoriteIds)..add(key),
      );
    }
  }

  bool isFavorite(Track track) {
    return state.favoriteIds.contains('${track.id}_${track.source.name}');
  }
}

/// Favorites Provider
final favoritesProvider = StateNotifierProvider<FavoritesNotifier, FavoritesState>((ref) {
  final database = ref.watch(databaseProvider);
  return FavoritesNotifier(database);
});

/// History State
class HistoryState {
  final bool isLoading;
  final List<Track> recentlyPlayed;
  final List<Track> mostPlayed;

  const HistoryState({
    this.isLoading = false,
    this.recentlyPlayed = const [],
    this.mostPlayed = const [],
  });

  HistoryState copyWith({
    bool? isLoading,
    List<Track>? recentlyPlayed,
    List<Track>? mostPlayed,
  }) {
    return HistoryState(
      isLoading: isLoading ?? this.isLoading,
      recentlyPlayed: recentlyPlayed ?? this.recentlyPlayed,
      mostPlayed: mostPlayed ?? this.mostPlayed,
    );
  }
}

/// History Notifier
class HistoryNotifier extends StateNotifier<HistoryState> {
  final AppDatabase _database;
  final RecommendationService _recommendationService;

  HistoryNotifier(this._database, this._recommendationService) 
      : super(const HistoryState()) {
    loadHistory();
  }

  Future<void> loadHistory() async {
    state = state.copyWith(isLoading: true);
    
    try {
      final recent = await _database.getRecentlyPlayed(limit: 50);
      final recentTracks = recent.map((h) {
        final json = jsonDecode(h.trackJson) as Map<String, dynamic>;
        return Track.fromTidalJson(json);
      }).toList();

      // Remove duplicates, keep most recent
      final seenIds = <String>{};
      final uniqueRecent = <Track>[];
      for (final track in recentTracks) {
        if (!seenIds.contains(track.id)) {
          seenIds.add(track.id);
          uniqueRecent.add(track);
        }
      }

      state = state.copyWith(
        isLoading: false,
        recentlyPlayed: uniqueRecent,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> recordPlay(Track track, Duration playedDuration) async {
    await _database.recordPlay(
      trackId: track.id,
      source: track.source.index,
      trackJson: jsonEncode(track.toJson()),
      playedDurationMs: playedDuration.inMilliseconds,
      genre: track.genre,
      artistId: track.artistId,
    );
    
    // Refresh recommendations after enough plays
    final totalPlays = await _database.getTotalPlayCount();
    if (totalPlays % 5 == 0) {
      _recommendationService.invalidateCache();
    }
    
    await loadHistory();
  }

  Future<void> recordSkip(Track track) async {
    await _database.recordSkip(track.id, track.source.index);
  }

  Future<void> clearHistory() async {
    await _database.clearHistory();
    state = state.copyWith(recentlyPlayed: [], mostPlayed: []);
  }
}

/// History Provider
final historyProvider = StateNotifierProvider<HistoryNotifier, HistoryState>((ref) {
  final database = ref.watch(databaseProvider);
  final recommendationService = ref.watch(recommendationServiceProvider);
  return HistoryNotifier(database, recommendationService);
});
