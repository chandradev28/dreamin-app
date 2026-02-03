import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../data/database.dart';
import '../services/tidal_service.dart';
import '../services/music_service.dart';
import '../services/lastfm_service.dart';
import '../services/recommendation_service.dart';
import '../models/models.dart';
import 'source_provider.dart';

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

/// Search Notifier - Uses the active music source
class SearchNotifier extends StateNotifier<SearchState> {
  final MusicService _musicService;

  SearchNotifier(this._musicService) : super(const SearchState());

  Future<void> search(String query) async {
    if (query.isEmpty) {
      state = const SearchState();
      return;
    }

    state = state.copyWith(isLoading: true, query: query, error: null);

    try {
      final result = await _musicService.search(query);
      state = state.copyWith(isLoading: false, result: result);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void clear() {
    state = const SearchState();
  }
}

/// Search Provider - Uses the active music source
final searchProvider = StateNotifierProvider<SearchNotifier, SearchState>((ref) {
  final musicService = ref.watch(musicServiceProvider);
  return SearchNotifier(musicService);
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
  // Qobuz genre sections (filled only for Qobuz source)
  final List<Album> jazzAlbums;               // Jazz collection
  final List<Album> classicalAlbums;          // Classical collection
  final List<Album> rockAlbums;               // Rock collection
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
    this.jazzAlbums = const [],
    this.classicalAlbums = const [],
    this.rockAlbums = const [],
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
    List<Album>? jazzAlbums,
    List<Album>? classicalAlbums,
    List<Album>? rockAlbums,
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
      jazzAlbums: jazzAlbums ?? this.jazzAlbums,
      classicalAlbums: classicalAlbums ?? this.classicalAlbums,
      rockAlbums: rockAlbums ?? this.rockAlbums,
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
/// Falls back to active music source for new users
class HomeDataNotifier extends StateNotifier<HomeDataState> {
  final MusicService _musicService;
  final LastFmService _lastFmService;
  final AppDatabase _database;
  final RecommendationService _recommendationService;

  HomeDataNotifier(
    this._musicService, 
    this._lastFmService,
    this._database,
    this._recommendationService,
  ) : super(const HomeDataState()) {
    loadData();
  }

  Future<void> loadData() async {
    state = state.copyWith(isLoading: true, error: null);

    // DIAGNOSTIC: Log which service is being used
    print('🏠 HOME: loadData() called');
    print('🏠 HOME: _musicService.runtimeType = ${_musicService.runtimeType}');
    print('🏠 HOME: _musicService.source = ${_musicService.source}');
    print('🏠 HOME: MusicSource.qobuz = ${MusicSource.qobuz}');
    print('🏠 HOME: Check result = ${_musicService.source == MusicSource.qobuz}');

    try {
      // Check if using Qobuz - it needs different curated content loading
      if (_musicService.source == MusicSource.qobuz) {
        print('🎵 Home: Using Qobuz curated content');
        await _loadQobuzDiscovery();
        return;
      }
      

      // Check if using Subsonic/HiFi Server
      if (_musicService.source == MusicSource.subsonic) {
        print('🎵 Home: Using HiFi Server content');
        await _loadSubsonicDiscovery();
        return;
      }
      
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
      _musicService.searchAlbums(name, limit: 3)
        .catchError((_) => <Album>[])
    ).toList();

    final albumByGenreFutures = topGenres.take(3).map((genre) =>
      _musicService.searchAlbums('$genre new 2024', limit: 4)
        .catchError((_) => <Album>[])
    ).toList();

    final playlistByGenreFutures = topGenres.take(2).map((genre) =>
      _musicService.searchPlaylists('$genre playlist', limit: 5)
        .catchError((_) => <Playlist>[])
    ).toList();

    // Execute all in parallel
    final results = await Future.wait([
      Future.wait(albumByArtistFutures),
      Future.wait(albumByGenreFutures),
      Future.wait(playlistByGenreFutures),
      _musicService.searchPlaylists('songs of the year', limit: 10)
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
  /// SIMPLIFIED: Direct TIDAL searches only - fast and reliable
  Future<void> _loadDiscoveryData() async {
    try {
      print('🏠 Loading discovery data (new user mode)...');
      
      // ALL searches run in parallel - single phase, fast loading
      final results = await Future.wait([
        // 1. Songs of the Year playlists
        _musicService.searchPlaylists('songs of the year', limit: 10)
            .catchError((_) => <Playlist>[]),
        // 2. Popular playlists 
        _musicService.searchPlaylists('top hits 2024', limit: 10)
            .catchError((_) => <Playlist>[]),
        // 3. Trending tracks
        _musicService.searchTracks('trending 2024', limit: 12)
            .catchError((_) => <Track>[]),
        // 4. New albums
        _musicService.searchAlbums('new releases 2024', limit: 10)
            .catchError((_) => <Album>[]),
        // 5. Popular albums
        _musicService.searchAlbums('best albums', limit: 10)
            .catchError((_) => <Album>[]),
        // 6. Top artists for genre display
        _musicService.searchArtists('popular', limit: 6)
            .catchError((_) => <Artist>[]),
      ]);

      final songsOfYear = results[0] as List<Playlist>;
      final popular = results[1] as List<Playlist>;
      final trendingTracks = results[2] as List<Track>;
      final newAlbums = results[3] as List<Album>;
      final albumsYouLlEnjoy = results[4] as List<Album>;
      final artists = results[5] as List<Artist>;

      print('✅ Discovery loaded: ${songsOfYear.length} year playlists, ${popular.length} popular, ${trendingTracks.length} tracks, ${newAlbums.length} new albums');

      state = state.copyWith(
        isLoading: false,
        songsOfTheYear: songsOfYear,
        trendingTracks: trendingTracks.take(10).toList(),
        popularPlaylists: popular,
        newAlbums: newAlbums.take(10).toList(),
        albumsYouLlEnjoy: albumsYouLlEnjoy.take(10).toList(),
        recommendations: trendingTracks.take(10).toList(),
        playlistsForYou: songsOfYear,
        topGenres: const ['Pop', 'Rock', 'Hip Hop', 'R&B', 'Electronic', 'Jazz'],
        recentlyPlayedArtists: artists,
      );
    } catch (e) {
      print('❌ Discovery load error: $e');
      // Fallback to pure TIDAL if anything fails
      await _loadTidalOnly();
    }
  }

  /// Load curated content for Qobuz (no discovery API, so use search queries)
  /// Creates a Spotify-like experience with genre sections + Hi-Res focus
  Future<void> _loadQobuzDiscovery() async {
    String? firstError;
    
    // Helper to wrap API calls with proper error logging
    Future<List<T>> safeSearch<T>(Future<List<T>> Function() apiCall, String label) async {
      try {
        final result = await apiCall();
        print('✅ Qobuz $label: ${result.length} items');
        return result;
      } catch (e) {
        print('❌ Qobuz $label FAILED: $e');
        firstError ??= 'Qobuz $label: $e';
        return <T>[];
      }
    }

    try {
      print('🎧 Loading Qobuz curated content (Hi-Res focus)...');
      
      // All curated searches run in parallel with proper error logging
      final results = await Future.wait([
        // 1. Featured Albums
        safeSearch<Album>(() => _musicService.searchAlbums('pop', limit: 12), 'Featured Albums'),
        // 2. New Releases
        safeSearch<Album>(() => _musicService.searchAlbums('new', limit: 10), 'New Releases'),
        // 3. Trending Pop Tracks
        safeSearch<Track>(() => _musicService.searchTracks('hits', limit: 12), 'Trending Tracks'),
        // 4. Jazz Collection
        safeSearch<Album>(() => _musicService.searchAlbums('jazz', limit: 10), 'Jazz'),
        // 5. Classical Collection
        safeSearch<Album>(() => _musicService.searchAlbums('classical', limit: 10), 'Classical'),
        // 6. Rock Collection
        safeSearch<Album>(() => _musicService.searchAlbums('rock', limit: 10), 'Rock'),
        // 7. Electronic/Dance
        safeSearch<Album>(() => _musicService.searchAlbums('electronic', limit: 10), 'Electronic'),
        // 8. Featured Artists
        safeSearch<Artist>(() => _musicService.searchArtists('popular', limit: 8), 'Artists'),
      ]);

      final popAlbums = results[0] as List<Album>;
      final newReleases = results[1] as List<Album>;
      final trendingTracks = results[2] as List<Track>;
      final jazzAlbums = results[3] as List<Album>;
      final classicalAlbums = results[4] as List<Album>;
      final rockAlbums = results[5] as List<Album>;
      final electronicAlbums = results[6] as List<Album>;
      final artists = results[7] as List<Artist>;

      print('✅ Qobuz home loaded: ${popAlbums.length} pop, ${newReleases.length} new, ${trendingTracks.length} tracks, ${jazzAlbums.length} jazz');

      // If ALL results are empty and we had an error, surface it
      final totalItems = popAlbums.length + newReleases.length + trendingTracks.length + jazzAlbums.length;
      if (totalItems == 0 && firstError != null) {
        state = state.copyWith(isLoading: false, error: firstError);
        return;
      }

      // Map Qobuz content to home state
      state = state.copyWith(
        isLoading: false,
        error: null,
        newAlbums: popAlbums.take(10).toList(),
        albumsYouLlEnjoy: newReleases.take(10).toList(),
        trendingTracks: trendingTracks.take(10).toList(),
        recommendations: trendingTracks.take(10).toList(),
        jazzAlbums: jazzAlbums.take(10).toList(),
        classicalAlbums: classicalAlbums.take(10).toList(),
        rockAlbums: rockAlbums.take(10).toList(),
        songsOfTheYear: const [],
        popularPlaylists: const [],
        playlistsForYou: const [],
        topGenres: const ['Pop', 'Jazz', 'Classical', 'Rock', 'Electronic', 'New'],
        recentlyPlayedArtists: artists,
      );
    } catch (e) {
      print('❌ Qobuz home load error: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }


  /// Load content for Subsonic/HiFi Server
  /// Shows library content from the personal server
  Future<void> _loadSubsonicDiscovery() async {
    try {
      print('🎵 Loading HiFi Server content...');
      
      // For Subsonic, we search the user's own library
      final results = await Future.wait([
        // Random albums from library
        _musicService.searchAlbums('', limit: 15)
            .catchError((_) => <Album>[]),
        // Random tracks
        _musicService.searchTracks('', limit: 12)
            .catchError((_) => <Track>[]),
        // Artists in library
        _musicService.searchArtists('', limit: 10)
            .catchError((_) => <Artist>[]),
      ]);

      final albums = results[0] as List<Album>;
      final tracks = results[1] as List<Track>;
      final artists = results[2] as List<Artist>;

      print('✅ HiFi Server loaded: ${albums.length} albums, ${tracks.length} tracks');

      state = state.copyWith(
        isLoading: false,
        newAlbums: albums.take(10).toList(),
        albumsYouLlEnjoy: albums.skip(5).take(10).toList(),
        trendingTracks: tracks.take(10).toList(),
        recommendations: tracks.take(10).toList(),
        songsOfTheYear: const [],
        popularPlaylists: const [],
        playlistsForYou: const [],
        topGenres: const ['Your Library', 'Albums', 'Artists', 'Tracks'],
        recentlyPlayedArtists: artists,
      );
    } catch (e) {
      print('❌ HiFi Server load error: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
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
        _musicService.searchPlaylists('songs of the year', limit: 10)
            .catchError((_) => <Playlist>[]),
        _musicService.searchTracks('trending', limit: 8)
            .catchError((_) => <Track>[]),
        _musicService.searchPlaylists('hip hop', limit: 10)
            .catchError((_) => <Playlist>[]),
        _musicService.searchAlbums('new albums 2024', limit: 10)
            .catchError((_) => <Album>[]),
        _musicService.searchAlbums('pop hits', limit: 10)
            .catchError((_) => <Album>[]),
        _musicService.searchArtists('pop', limit: 6)
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

/// Home Data Provider (with personalization + active source)
final homeDataProvider = StateNotifierProvider<HomeDataNotifier, HomeDataState>((ref) {
  final musicService = ref.watch(musicServiceProvider);
  final lastFmService = ref.watch(lastFmServiceProvider);
  final database = ref.watch(databaseProvider);
  final recommendationService = ref.watch(recommendationServiceProvider);
  return HomeDataNotifier(musicService, lastFmService, database, recommendationService);
});

// ============================================================================
// ALBUM, ARTIST, PLAYLIST DETAIL PROVIDERS
// ============================================================================

/// Album Detail Provider - Uses active music source
final albumDetailProvider = FutureProvider.family<AlbumDetail?, String>((ref, albumId) async {
  final musicService = ref.watch(musicServiceProvider);
  try {
    return await musicService.getAlbum(albumId);
  } catch (e) {
    return null;
  }
});

/// Artist Detail Provider - Uses active music source
final artistDetailProvider = FutureProvider.family<ArtistDetail?, String>((ref, artistId) async {
  final musicService = ref.watch(musicServiceProvider);
  try {
    return await musicService.getArtist(artistId);
  } catch (e) {
    return null;
  }
});

/// Playlist Detail Provider - Uses active music source
final playlistDetailProvider = FutureProvider.family<PlaylistDetail?, String>((ref, playlistId) async {
  final musicService = ref.watch(musicServiceProvider);
  try {
    return await musicService.getPlaylist(playlistId);
  } catch (e) {
    return null;
  }
});
