import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../data/database.dart';
import '../services/tidal_service.dart';
import '../services/lastfm_service.dart';
import '../services/recommendation_service.dart';
import '../models/models.dart';

/// Database Provider
final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

/// Dio Provider (shared HTTP client)
final dioProvider = Provider<Dio>((ref) {
  return Dio();
});

/// TIDAL Service Provider
final tidalServiceProvider = Provider<TidalService>((ref) {
  return TidalService();
});

/// Last.fm Service Provider (for recommendations)
final lastFmServiceProvider = Provider<LastFmService>((ref) {
  final dio = ref.watch(dioProvider);
  return LastFmService(dio);
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

/// Home Data State - TIDAL sections with backward compatibility
class HomeDataState {
  final bool isLoading;
  // New TIDAL sections
  final List<Playlist> songsOfTheYear;       // Songs of the Year playlists
  final List<Track> trendingTracks;           // Recommended new tracks (bento box)
  final List<Playlist> popularPlaylists;      // Popular playlists on TIDAL
  final List<Album> newAlbums;                // Suggested new albums for you
  final List<Album> albumsYouLlEnjoy;         // Albums you'll enjoy
  // Legacy fields for backward compatibility with other screens
  final List<Track> recommendations;          // Alias for trendingTracks
  final List<Playlist> playlistsForYou;       // Alias for songsOfTheYear
  final List<String> topGenres;               // Default genres
  final List<Artist> recentlyPlayedArtists;   // Empty for now
  final String? error;

  const HomeDataState({
    this.isLoading = false,
    this.songsOfTheYear = const [],
    this.trendingTracks = const [],
    this.popularPlaylists = const [],
    this.newAlbums = const [],
    this.albumsYouLlEnjoy = const [],
    this.recommendations = const [],
    this.playlistsForYou = const [],
    this.topGenres = const [],
    this.recentlyPlayedArtists = const [],
    this.error,
  });

  HomeDataState copyWith({
    bool? isLoading,
    List<Playlist>? songsOfTheYear,
    List<Track>? trendingTracks,
    List<Playlist>? popularPlaylists,
    List<Album>? newAlbums,
    List<Album>? albumsYouLlEnjoy,
    List<Track>? recommendations,
    List<Playlist>? playlistsForYou,
    List<String>? topGenres,
    List<Artist>? recentlyPlayedArtists,
    String? error,
  }) {
    return HomeDataState(
      isLoading: isLoading ?? this.isLoading,
      songsOfTheYear: songsOfTheYear ?? this.songsOfTheYear,
      trendingTracks: trendingTracks ?? this.trendingTracks,
      popularPlaylists: popularPlaylists ?? this.popularPlaylists,
      newAlbums: newAlbums ?? this.newAlbums,
      albumsYouLlEnjoy: albumsYouLlEnjoy ?? this.albumsYouLlEnjoy,
      recommendations: recommendations ?? this.recommendations,
      playlistsForYou: playlistsForYou ?? this.playlistsForYou,
      topGenres: topGenres ?? this.topGenres,
      recentlyPlayedArtists: recentlyPlayedArtists ?? this.recentlyPlayedArtists,
      error: error,
    );
  }
}

/// Home Data Notifier - Personalized content loading
/// Uses LOCAL DATABASE for personalization when user has history
/// Falls back to Last.fm/Tidal for new users
class HomeDataNotifier extends StateNotifier<HomeDataState> {
  final TidalService _tidalService;
  final LastFmService _lastFmService;
  final AppDatabase _database;
  final RecommendationService _recommendationService;

  HomeDataNotifier(
    this._tidalService, 
    this._lastFmService,
    this._database,
    this._recommendationService,
  ) : super(const HomeDataState()) {
    loadData();
  }

  Future<void> loadData() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Check if user has enough listening history for personalization
      final totalPlays = await _database.getTotalPlayCount();
      final hasPersonalization = totalPlays >= 10;
      
      print('🎵 Home: User has $totalPlays plays. Personalization: $hasPersonalization');

      if (hasPersonalization) {
        await _loadPersonalizedData();
      } else {
        await _loadDiscoveryData();
      }
    } catch (e) {
      print('❌ Home load error: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Load personalized content based on user's listening history
  /// OPTIMIZED: Uses parallel API calls
  Future<void> _loadPersonalizedData() async {
    // Get user preferences from local database (fast, local)
    final dbResults = await Future.wait([
      _database.getTopArtistNames(limit: 10),
      _database.getTopGenres(limit: 5),
      _recommendationService.getRecommendations(limit: 15),
    ]);

    final topArtistNames = dbResults[0] as List<String>;
    final topGenres = dbResults[1] as List<String>;
    final personalizedTracks = dbResults[2] as List<Track>;
    
    print('📊 User prefs - Artists: ${topArtistNames.take(3)}, Genres: ${topGenres.take(3)}');

    // PARALLEL: All API searches run concurrently
    final albumByArtistFutures = topArtistNames.take(5).map((name) =>
      _tidalService.searchAlbums(name, limit: 3)
        .catchError((_) => <Album>[])
    ).toList();

    final albumByGenreFutures = topGenres.take(3).map((genre) =>
      _tidalService.searchAlbums('$genre new 2024', limit: 4)
        .catchError((_) => <Album>[])
    ).toList();

    final playlistByGenreFutures = topGenres.take(2).map((genre) =>
      _tidalService.searchPlaylists('$genre playlist', limit: 5)
        .catchError((_) => <Playlist>[])
    ).toList();

    // Execute all in parallel
    final results = await Future.wait([
      Future.wait(albumByArtistFutures),
      Future.wait(albumByGenreFutures),
      Future.wait(playlistByGenreFutures),
      _tidalService.searchPlaylists('songs of the year', limit: 10)
        .catchError((_) => <Playlist>[]),
    ]);

    final albumsForYou = (results[0] as List<List<Album>>)
        .expand((x) => x.take(2)).take(10).toList();
    final newAlbumsByFavorites = (results[1] as List<List<Album>>)
        .expand((x) => x).take(10).toList();
    final playlistsForUser = (results[2] as List<List<Playlist>>)
        .expand((x) => x).take(10).toList();
    final songsOfYear = results[3] as List<Playlist>;

    // Display user's top genres nicely
    final displayGenres = topGenres.isNotEmpty 
        ? topGenres.map((g) => _capitalizeTag(g)).toList()
        : const ['Pop', 'Rock', 'Hip Hop', 'R&B', 'Electronic', 'Jazz'];

    state = state.copyWith(
      isLoading: false,
      songsOfTheYear: songsOfYear,
      trendingTracks: personalizedTracks.take(10).toList(),
      popularPlaylists: playlistsForUser.take(10).toList(),
      newAlbums: albumsForYou.take(10).toList(),
      albumsYouLlEnjoy: newAlbumsByFavorites.take(10).toList(),
      recommendations: personalizedTracks.take(10).toList(),
      playlistsForYou: songsOfYear,
      topGenres: displayGenres,
      recentlyPlayedArtists: const [],
    );
  }

  /// Load discovery content for new users (no history)
  /// OPTIMIZED: Uses parallel API calls instead of sequential loops
  Future<void> _loadDiscoveryData() async {
    try {
      // PHASE 1: Load TIDAL content + Last.fm chart data in parallel
      final phase1Results = await Future.wait([
        // 1. Songs of the Year playlists (TIDAL)
        _tidalService.searchPlaylists('songs of the year', limit: 10)
            .catchError((_) => <Playlist>[]),
        // 2. Popular playlists (TIDAL)
        _tidalService.searchPlaylists('top hits', limit: 10)
            .catchError((_) => <Playlist>[]),
        // 3. Get chart top tracks from Last.fm (for discovery)
        _lastFmService.getChartTopTracks(limit: 20)
            .catchError((_) => <LastFmTrack>[]),
        // 4. Get chart top artists from Last.fm
        _lastFmService.getChartTopArtists(limit: 10)
            .catchError((_) => <LastFmArtist>[]),
        // 5. Get top tags/genres from Last.fm
        _lastFmService.getTopTags(limit: 20)
            .catchError((_) => <String>[]),
      ]);

      final songsOfYear = phase1Results[0] as List<Playlist>;
      final popular = phase1Results[1] as List<Playlist>;
      final lastFmTracks = phase1Results[2] as List<LastFmTrack>;
      final lastFmArtists = phase1Results[3] as List<LastFmArtist>;
      final topTags = phase1Results[4] as List<String>;

      // PHASE 2: PARALLEL lookups - all executed concurrently
      final shuffledTracks = List<LastFmTrack>.from(lastFmTracks)..shuffle();
      final shuffledArtists = List<LastFmArtist>.from(lastFmArtists)..shuffle();
      final shuffledTags = List<String>.from(topTags)..shuffle();

      // Create all futures FIRST (don't await yet)
      final trackFutures = shuffledTracks.take(8).map((lfm) =>
        _tidalService.searchTracks('${lfm.artist} ${lfm.name}', limit: 1)
          .catchError((_) => <Track>[])
      ).toList();

      final albumFutures = shuffledArtists.take(5).map((lfm) =>
        _tidalService.searchAlbums(lfm.name, limit: 2)
          .catchError((_) => <Album>[])
      ).toList();

      final artistFutures = lastFmArtists.take(6).map((lfm) =>
        _tidalService.searchArtists(lfm.name, limit: 1)
          .catchError((_) => <Artist>[])
      ).toList();

      // Get albums by tags in parallel
      final tagAlbumFutures = <Future<List<Album>>>[];
      for (final tag in shuffledTags.take(3)) {
        tagAlbumFutures.add(
          _lastFmService.getTopAlbumsByTag(tag, limit: 3).then((lfmAlbums) async {
            final results = <Album>[];
            // Sub-searches in parallel too
            final subFutures = lfmAlbums.take(2).map((lfm) =>
              _tidalService.searchAlbums('${lfm.artist} ${lfm.name}', limit: 1)
                .catchError((_) => <Album>[])
            );
            final subResults = await Future.wait(subFutures);
            for (final r in subResults) {
              if (r.isNotEmpty) results.add(r.first);
            }
            return results;
          }).catchError((_) => <Album>[])
        );
      }

      // EXECUTE ALL PHASE 2 IN PARALLEL
      final phase2Results = await Future.wait([
        Future.wait(trackFutures),
        Future.wait(albumFutures),
        Future.wait(artistFutures),
        Future.wait(tagAlbumFutures),
      ]);

      // Flatten results
      final trendingTracks = (phase2Results[0] as List<List<Track>>)
          .expand((x) => x).take(10).toList();
      final newAlbums = (phase2Results[1] as List<List<Album>>)
          .expand((x) => x).take(10).toList();
      final recentArtists = (phase2Results[2] as List<List<Artist>>)
          .expand((x) => x).take(6).toList();
      final albumsYouLlEnjoy = (phase2Results[3] as List<List<Album>>)
          .expand((x) => x).take(10).toList();

      // PHASE 3: Quick fallbacks if needed (parallel)
      final List<Future<void>> fallbackFutures = [];
      
      List<Track> extraTracks = [];
      List<Album> extraAlbums = [];
      List<Album> extraEnjoyAlbums = [];

      if (trendingTracks.length < 5) {
        fallbackFutures.add(
          _tidalService.searchTracks('trending 2024', limit: 8)
            .then((r) => extraTracks = r)
            .catchError((_) {})
        );
      }
      if (newAlbums.length < 5) {
        fallbackFutures.add(
          _tidalService.searchAlbums('new release 2024', limit: 10)
            .then((r) => extraAlbums = r)
            .catchError((_) {})
        );
      }
      if (albumsYouLlEnjoy.length < 5) {
        fallbackFutures.add(
          _tidalService.searchAlbums('best albums', limit: 10)
            .then((r) => extraEnjoyAlbums = r)
            .catchError((_) {})
        );
      }

      if (fallbackFutures.isNotEmpty) {
        await Future.wait(fallbackFutures);
        trendingTracks.addAll(extraTracks);
        newAlbums.addAll(extraAlbums);
        albumsYouLlEnjoy.addAll(extraEnjoyAlbums);
      }

      // Filter genres to show nice display names
      final displayGenres = topTags.isNotEmpty 
          ? topTags.take(10).map((t) => _capitalizeTag(t)).toList()
          : const ['Pop', 'Rock', 'Hip Hop', 'R&B', 'Electronic', 'Jazz'];

      state = state.copyWith(
        isLoading: false,
        songsOfTheYear: songsOfYear,
        trendingTracks: trendingTracks.take(10).toList(),
        popularPlaylists: popular,
        newAlbums: newAlbums.take(10).toList(),
        albumsYouLlEnjoy: albumsYouLlEnjoy.take(10).toList(),
        recommendations: trendingTracks.take(10).toList(),
        playlistsForYou: songsOfYear,
        topGenres: displayGenres,
        recentlyPlayedArtists: recentArtists,
      );
    } catch (e) {
      // Fallback to pure TIDAL if Last.fm fails
      await _loadTidalOnly();
    }
  }

  String _capitalizeTag(String tag) {
    return tag.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  /// Fallback: Load only from TIDAL if Last.fm is unavailable
  Future<void> _loadTidalOnly() async {
    try {
      final results = await Future.wait([
        _tidalService.searchPlaylists('songs of the year', limit: 10)
            .catchError((_) => <Playlist>[]),
        _tidalService.searchTracks('trending', limit: 8)
            .catchError((_) => <Track>[]),
        _tidalService.searchPlaylists('hip hop', limit: 10)
            .catchError((_) => <Playlist>[]),
        _tidalService.searchAlbums('new albums 2024', limit: 10)
            .catchError((_) => <Album>[]),
        _tidalService.searchAlbums('pop hits', limit: 10)
            .catchError((_) => <Album>[]),
        _tidalService.searchArtists('pop', limit: 6)
            .catchError((_) => <Artist>[]),
      ]);

      state = state.copyWith(
        isLoading: false,
        songsOfTheYear: results[0] as List<Playlist>,
        trendingTracks: results[1] as List<Track>,
        popularPlaylists: results[2] as List<Playlist>,
        newAlbums: results[3] as List<Album>,
        albumsYouLlEnjoy: results[4] as List<Album>,
        recommendations: results[1] as List<Track>,
        playlistsForYou: results[0] as List<Playlist>,
        topGenres: const ['Pop', 'Rock', 'Hip Hop', 'R&B', 'Electronic', 'Jazz'],
        recentlyPlayedArtists: results[5] as List<Artist>,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() async {
    await loadData();
  }
}

/// Home Data Provider (with personalization + Last.fm fallback)
final homeDataProvider = StateNotifierProvider<HomeDataNotifier, HomeDataState>((ref) {
  final tidalService = ref.watch(tidalServiceProvider);
  final lastFmService = ref.watch(lastFmServiceProvider);
  final database = ref.watch(databaseProvider);
  final recommendationService = ref.watch(recommendationServiceProvider);
  return HomeDataNotifier(tidalService, lastFmService, database, recommendationService);
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
