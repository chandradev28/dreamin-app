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

/// Home Data State with Echo-style sections
class HomeDataState {
  final bool isLoading;
  final List<Track> recommendations;           // For You section
  final List<Album> newAlbums;                 // New releases for you
  final List<Artist> recentlyPlayedArtists;    // Continue streaming (circular avatars)
  final List<Track> mixesTracks;               // Mixes inspired by...
  final List<Artist> similarArtists;           // Since you like [Artist]
  final String? similarToArtistName;           // The artist to compare
  final List<Track> lovedTracks;               // Recently you've been loving
  final List<Playlist> playlistsForYou;        // Playlists you'll love
  final List<String> topGenres;                // Your top genres
  final List<Playlist> popularPlaylists;
  final List<Playlist> featuredPlaylists;
  final String? error;

  const HomeDataState({
    this.isLoading = false,
    this.recommendations = const [],
    this.newAlbums = const [],
    this.recentlyPlayedArtists = const [],
    this.mixesTracks = const [],
    this.similarArtists = const [],
    this.similarToArtistName,
    this.lovedTracks = const [],
    this.playlistsForYou = const [],
    this.topGenres = const [],
    this.popularPlaylists = const [],
    this.featuredPlaylists = const [],
    this.error,
  });

  HomeDataState copyWith({
    bool? isLoading,
    List<Track>? recommendations,
    List<Album>? newAlbums,
    List<Artist>? recentlyPlayedArtists,
    List<Track>? mixesTracks,
    List<Artist>? similarArtists,
    String? similarToArtistName,
    List<Track>? lovedTracks,
    List<Playlist>? playlistsForYou,
    List<String>? topGenres,
    List<Playlist>? popularPlaylists,
    List<Playlist>? featuredPlaylists,
    String? error,
  }) {
    return HomeDataState(
      isLoading: isLoading ?? this.isLoading,
      recommendations: recommendations ?? this.recommendations,
      newAlbums: newAlbums ?? this.newAlbums,
      recentlyPlayedArtists: recentlyPlayedArtists ?? this.recentlyPlayedArtists,
      mixesTracks: mixesTracks ?? this.mixesTracks,
      similarArtists: similarArtists ?? this.similarArtists,
      similarToArtistName: similarToArtistName ?? this.similarToArtistName,
      lovedTracks: lovedTracks ?? this.lovedTracks,
      playlistsForYou: playlistsForYou ?? this.playlistsForYou,
      topGenres: topGenres ?? this.topGenres,
      popularPlaylists: popularPlaylists ?? this.popularPlaylists,
      featuredPlaylists: featuredPlaylists ?? this.featuredPlaylists,
      error: error,
    );
  }
}

/// Home Data Notifier with Echo-style content loading
class HomeDataNotifier extends StateNotifier<HomeDataState> {
  final TidalService _tidalService;
  final RecommendationService _recommendationService;
  final AppDatabase _database;

  HomeDataNotifier(this._tidalService, this._recommendationService, this._database) 
      : super(const HomeDataState()) {
    loadData();
  }

  Future<void> loadData() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Load ALL data in parallel - no dependency on history
      final baseFutures = await Future.wait([
        _tidalService.getTrendingTracks(limit: 20).catchError((_) => <Track>[]),
        _recommendationService.getRecommendations(limit: 15).catchError((_) => <Track>[]),
        _tidalService.getNewAlbums(limit: 10).catchError((_) => <Album>[]),
        _tidalService.getPopularPlaylists(limit: 10).catchError((_) => <Playlist>[]),
        // Search for popular artists for "Continue streaming" section
        _tidalService.searchArtists('pop', limit: 8).catchError((_) => <Artist>[]),
        // Search for tracks for "Mixes inspired by" section
        _tidalService.searchTracks('electronic chill', limit: 10).catchError((_) => <Track>[]),
        // Search for artists for "Since you like" section
        _tidalService.searchArtists('rock', limit: 6).catchError((_) => <Artist>[]),
      ]);

      final trendingTracks = baseFutures[0] as List<Track>;
      final recommendations = baseFutures[1] as List<Track>;
      final newAlbums = baseFutures[2] as List<Album>;
      final playlists = baseFutures[3] as List<Playlist>;
      final popArtists = baseFutures[4] as List<Artist>;
      final mixesTracks = baseFutures[5] as List<Track>;
      final rockArtists = baseFutures[6] as List<Artist>;

      // Try to get user history - if available, use it; otherwise use API defaults
      List<Artist> recentArtists = [];
      List<String> topGenres = [];
      List<Track> lovedTracks = [];
      String? similarArtistName;
      List<Artist> similarArtists = [];

      try {
        // Get recently played artists from history
        final recentHistory = await _database.getRecentlyPlayed(limit: 20);
        final artistsMap = <String, Artist>{};
        for (final history in recentHistory) {
          try {
            final json = jsonDecode(history.trackJson) as Map<String, dynamic>;
            final track = Track.fromTidalJson(json);
            if (track.artistId.isNotEmpty && !artistsMap.containsKey(track.artistId)) {
              artistsMap[track.artistId] = Artist(
                id: track.artistId,
                name: track.artist,
                imageUrl: track.coverArtUrl,
                source: track.source,
              );
            }
          } catch (_) {}
        }
        recentArtists = artistsMap.values.take(6).toList();

        // Get top genres from history
        topGenres = await _database.getTopGenres(limit: 6);

        // Get loved tracks (favorites)
        final favorites = await _database.getAllFavorites();
        lovedTracks = favorites.take(10).map((f) {
          final json = jsonDecode(f.trackJson) as Map<String, dynamic>;
          return Track.fromTidalJson(json);
        }).toList();

        // Get similar artists if we have history
        if (recentArtists.isNotEmpty) {
          similarArtistName = recentArtists.first.name;
          final artistSearchResults = await _tidalService
              .searchArtists(recentArtists.first.name, limit: 5)
              .catchError((_) => <Artist>[]);
          similarArtists = artistSearchResults
              .where((a) => a.id != recentArtists.first.id)
              .take(4)
              .toList();
        }
      } catch (_) {
        // Database error - continue with API defaults
      }

      // FALLBACKS - Use API data if user history is empty
      if (recentArtists.isEmpty) {
        recentArtists = popArtists.take(6).toList();
      }

      if (topGenres.isEmpty) {
        topGenres = ['Pop', 'Rock', 'Electronic', 'Hip Hop', 'R&B', 'Jazz'];
      }

      if (lovedTracks.isEmpty) {
        lovedTracks = trendingTracks.take(8).toList();
      }

      if (similarArtists.isEmpty) {
        similarArtistName = rockArtists.isNotEmpty ? rockArtists.first.name : 'Popular Artists';
        similarArtists = rockArtists.skip(1).take(5).toList();
      }

      state = state.copyWith(
        isLoading: false,
        recommendations: [...trendingTracks, ...recommendations].take(20).toList(),
        newAlbums: newAlbums,
        recentlyPlayedArtists: recentArtists,
        mixesTracks: mixesTracks.isNotEmpty ? mixesTracks : trendingTracks.take(10).toList(),
        similarArtists: similarArtists,
        similarToArtistName: similarArtistName,
        lovedTracks: lovedTracks,
        playlistsForYou: playlists,
        topGenres: topGenres,
        popularPlaylists: playlists,
        featuredPlaylists: <Playlist>[],
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
  final database = ref.watch(databaseProvider);
  return HomeDataNotifier(tidalService, recommendationService, database);
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
