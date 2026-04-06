import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/database.dart';
import '../services/tidal_service.dart';
import '../services/music_service.dart';
import '../services/lastfm_service.dart';
import '../services/recommendation_service.dart';
import '../services/subsonic_service.dart';
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

class SearchHistoryNotifier extends StateNotifier<List<String>> {
  static const String _prefsKey = 'search_history_queries';
  static const int _maxEntries = 10;

  SearchHistoryNotifier() : super(const []) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getStringList(_prefsKey) ?? const [];
  }

  Future<void> add(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty || trimmed.length < 2) return;

    final normalized = trimmed.toLowerCase();
    final next = [
      trimmed,
      ...state.where((entry) => entry.toLowerCase() != normalized),
    ];
    final limited = next.take(_maxEntries).toList(growable: false);

    state = limited;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, limited);
  }

  Future<void> remove(String query) async {
    final normalized = query.trim().toLowerCase();
    final next = state
        .where((entry) => entry.toLowerCase() != normalized)
        .toList(growable: false);
    state = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, next);
  }

  Future<void> clear() async {
    state = const [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }
}

final searchHistoryProvider =
    StateNotifierProvider<SearchHistoryNotifier, List<String>>((ref) {
  return SearchHistoryNotifier();
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
final searchProvider =
    StateNotifierProvider<SearchNotifier, SearchState>((ref) {
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
  final List<Playlist> essentialsPlaylists; // Essentials to explore
  final List<Playlist> customMixes; // Custom mixes
  final List<Track> recentlyPlayedTracks; // Local history-backed recent tracks
  final List<Playlist> songsOfTheYear; // Songs of the Year playlists
  final List<Track> trendingTracks; // Recommended new tracks (bento box)
  final List<Playlist> moodPlaylists; // Set the Tone
  final List<Playlist> personalRadioPlaylists; // Personal radio stations
  final List<Playlist> madeForYouPlaylists; // Made for you
  final List<Playlist> popularPlaylists; // Popular playlists on TIDAL
  final List<Album> newAlbums; // Suggested new albums for you
  final List<Album> albumsYouLlEnjoy; // Albums you'll enjoy
  final List<Album> listeningHistoryAlbums; // Derived from recent history
  // Qobuz genre sections (filled only for Qobuz source)
  final List<Album> jazzAlbums; // Jazz collection
  final List<Album> classicalAlbums; // Classical collection
  final List<Album> rockAlbums; // Rock collection
  // Legacy fields for backward compatibility with other screens
  final List<Track> recommendations; // Alias for trendingTracks
  final List<Playlist> playlistsForYou; // Alias for songsOfTheYear
  final List<String> topGenres; // Default genres
  final List<Artist> recentlyPlayedArtists; // Empty for now
  final String? error;

  const HomeDataState({
    this.isLoading = false,
    this.essentialsPlaylists = const [],
    this.customMixes = const [],
    this.recentlyPlayedTracks = const [],
    this.songsOfTheYear = const [],
    this.trendingTracks = const [],
    this.moodPlaylists = const [],
    this.personalRadioPlaylists = const [],
    this.madeForYouPlaylists = const [],
    this.popularPlaylists = const [],
    this.newAlbums = const [],
    this.albumsYouLlEnjoy = const [],
    this.listeningHistoryAlbums = const [],
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
    List<Playlist>? essentialsPlaylists,
    List<Playlist>? customMixes,
    List<Track>? recentlyPlayedTracks,
    List<Playlist>? songsOfTheYear,
    List<Track>? trendingTracks,
    List<Playlist>? moodPlaylists,
    List<Playlist>? personalRadioPlaylists,
    List<Playlist>? madeForYouPlaylists,
    List<Playlist>? popularPlaylists,
    List<Album>? newAlbums,
    List<Album>? albumsYouLlEnjoy,
    List<Album>? listeningHistoryAlbums,
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
      essentialsPlaylists: essentialsPlaylists ?? this.essentialsPlaylists,
      customMixes: customMixes ?? this.customMixes,
      recentlyPlayedTracks: recentlyPlayedTracks ?? this.recentlyPlayedTracks,
      songsOfTheYear: songsOfTheYear ?? this.songsOfTheYear,
      trendingTracks: trendingTracks ?? this.trendingTracks,
      moodPlaylists: moodPlaylists ?? this.moodPlaylists,
      personalRadioPlaylists:
          personalRadioPlaylists ?? this.personalRadioPlaylists,
      madeForYouPlaylists: madeForYouPlaylists ?? this.madeForYouPlaylists,
      popularPlaylists: popularPlaylists ?? this.popularPlaylists,
      newAlbums: newAlbums ?? this.newAlbums,
      albumsYouLlEnjoy: albumsYouLlEnjoy ?? this.albumsYouLlEnjoy,
      listeningHistoryAlbums:
          listeningHistoryAlbums ?? this.listeningHistoryAlbums,
      jazzAlbums: jazzAlbums ?? this.jazzAlbums,
      classicalAlbums: classicalAlbums ?? this.classicalAlbums,
      rockAlbums: rockAlbums ?? this.rockAlbums,
      recommendations: recommendations ?? this.recommendations,
      playlistsForYou: playlistsForYou ?? this.playlistsForYou,
      topGenres: topGenres ?? this.topGenres,
      recentlyPlayedArtists:
          recentlyPlayedArtists ?? this.recentlyPlayedArtists,
      error: error,
    );
  }
}

/// Home Data Notifier - Personalized content loading
/// Uses LOCAL DATABASE for personalization when user has history
/// Falls back to active music source for new users
class HomeDataNotifier extends StateNotifier<HomeDataState> {
  static const int _homeSeeAllLimit = 50;

  final MusicService _musicService;
  final AppDatabase _database;
  final RecommendationService _recommendationService;

  HomeDataNotifier(
    this._musicService,
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
    print(
        '🏠 HOME: Check result = ${_musicService.source == MusicSource.qobuz}');

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
      final totalPlays =
          await _database.getTotalPlayCount(source: _musicService.source.index);
      final hasPersonalization = totalPlays >= 10;

      print(
          '🎵 Home: User has $totalPlays plays. Personalization: $hasPersonalization');

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

  Future<List<Playlist>> _loadCuratedPlaylists(
    List<String> queries, {
    int limitPerQuery = 4,
    int maxItems = 12,
  }) async {
    final queryResults = await Future.wait(
      queries.where((query) => query.trim().isNotEmpty).map(
            (query) => _musicService
                .searchPlaylists(query, limit: limitPerQuery)
                .catchError((_) => <Playlist>[]),
          ),
    );

    final curated = <Playlist>[];
    final seenIds = <String>{};

    for (final playlist in queryResults.expand((items) => items)) {
      final key = '${playlist.source.name}:${playlist.id}';
      if (playlist.id.isEmpty || seenIds.contains(key)) continue;
      seenIds.add(key);
      curated.add(playlist);
      if (curated.length >= maxItems) break;
    }

    return curated;
  }

  Future<List<Track>> _loadRecentlyPlayedTracks({int limit = 12}) async {
    final history = await _database.getRecentlyPlayed(
      limit: limit * 4,
      source: _musicService.source.index,
    );
    final tracks = <Track>[];
    final seenIds = <String>{};

    for (final entry in history) {
      try {
        final track = Track.fromJson(
          jsonDecode(entry.trackJson) as Map<String, dynamic>,
        );
        final key = '${track.source.name}:${track.id}';
        if (track.id.isEmpty || seenIds.contains(key)) continue;
        seenIds.add(key);
        tracks.add(track);
        if (tracks.length >= limit) break;
      } catch (_) {}
    }

    return tracks;
  }

  List<Album> _buildAlbumsFromTracks(List<Track> tracks, {int limit = 10}) {
    final albums = <Album>[];
    final seenIds = <String>{};

    for (final track in tracks) {
      if (track.albumId.isEmpty || track.album.isEmpty) continue;

      final key = '${track.source.name}:${track.albumId}';
      if (seenIds.contains(key)) continue;
      seenIds.add(key);

      albums.add(
        Album(
          id: track.albumId,
          title: track.album,
          artist: track.artist,
          artistId: track.artistId,
          coverArtUrl: track.coverArtUrl,
          year: track.year,
          trackCount: 0,
          source: track.source,
          isExplicit: track.isExplicit,
        ),
      );

      if (albums.length >= limit) break;
    }

    return albums;
  }

  List<String> _extractArtistNamesFromTracks(
    List<Track> tracks, {
    int limit = 6,
  }) {
    final counts = <String, int>{};

    for (final track in tracks) {
      final artist = track.artist.trim();
      if (artist.isEmpty) continue;
      counts.update(artist, (count) => count + 1, ifAbsent: () => 1);
    }

    final ranked = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return ranked.take(limit).map((entry) => entry.key).toList();
  }

  List<String> _mergeSeedValues(
    List<String> primary,
    List<String> secondary, {
    int limit = 6,
  }) {
    final merged = <String>[];
    final seen = <String>{};

    for (final value in [...primary, ...secondary]) {
      final normalized = value.trim();
      final key = normalized.toLowerCase();
      if (normalized.isEmpty || seen.contains(key)) continue;
      seen.add(key);
      merged.add(normalized);
      if (merged.length >= limit) break;
    }

    return merged;
  }

  /// Load personalized content based on user's listening history
  /// OPTIMIZED: Uses parallel API calls
  Future<void> _loadPersonalizedData() async {
    final currentYear = DateTime.now().year;

    // Get user preferences from local database (fast, local)
    final dbResults = await Future.wait([
      _database.getTopArtistNames(
        limit: 10,
        source: _musicService.source.index,
      ),
      _database.getTopGenres(
        limit: 5,
        source: _musicService.source.index,
      ),
      _recommendationService.getRecommendations(
        limit: _homeSeeAllLimit,
        source: _musicService.source.index,
      ),
      _loadRecentlyPlayedTracks(limit: 12),
    ]);

    final topArtistNames = dbResults[0] as List<String>;
    final topGenres = dbResults[1] as List<String>;
    final personalizedTracks = dbResults[2] as List<Track>;
    final recentlyPlayedTracks = dbResults[3] as List<Track>;
    final artistSeeds = _mergeSeedValues(
      _extractArtistNamesFromTracks(recentlyPlayedTracks),
      topArtistNames,
    );
    final genreSeeds =
        _mergeSeedValues(topGenres, const ['Pop', 'Rock'], limit: 4);

    print(
        '📊 User prefs - Artists: ${artistSeeds.take(3)}, Genres: ${genreSeeds.take(3)}');

    // PARALLEL: All API searches run concurrently
    final albumByArtistFutures = artistSeeds
        .take(5)
        .map((name) => _musicService
            .searchAlbums(name, limit: 3)
            .catchError((_) => <Album>[]))
        .toList();

    final albumByGenreFutures = genreSeeds
        .take(3)
        .map((genre) => _musicService
            .searchAlbums('$genre new $currentYear', limit: 4)
            .catchError((_) => <Album>[]))
        .toList();

    final playlistByGenreFutures = genreSeeds
        .take(2)
        .map((genre) => _musicService
            .searchPlaylists('$genre playlist', limit: 25)
            .catchError((_) => <Playlist>[]))
        .toList();

    // Execute all in parallel
    final results = await Future.wait([
      Future.wait(albumByArtistFutures),
      Future.wait(albumByGenreFutures),
      Future.wait(playlistByGenreFutures),
      _musicService
          .searchPlaylists(
            'songs of the year',
            limit: _homeSeeAllLimit,
          )
          .catchError((_) => <Playlist>[]),
      _loadCuratedPlaylists([
        ...artistSeeds.take(6).map((artist) => '$artist essentials'),
        ...genreSeeds.take(2).map((genre) => '$genre essentials'),
        'essentials',
      ]),
      _loadCuratedPlaylists([
        ...artistSeeds.take(4).map((artist) => '$artist mix'),
        ...genreSeeds.take(2).map((genre) => '$genre mix'),
        'daily mix',
      ]),
      _loadCuratedPlaylists([
        ...artistSeeds.take(2).map((artist) => '$artist mood'),
        ...genreSeeds.take(2).map((genre) => '$genre mood'),
        'set the tone',
        'mood',
      ]),
      _loadCuratedPlaylists([
        ...artistSeeds.take(4).map((artist) => '$artist radio'),
        'artist radio',
      ]),
      _loadCuratedPlaylists([
        ...artistSeeds.take(3).map((artist) => '$artist mix'),
        ...genreSeeds.take(2).map((genre) => '$genre playlist'),
        'for you',
      ]),
    ]);

    final albumsForYou = (results[0] as List<List<Album>>)
        .expand((x) => x.take(2))
        .take(10)
        .toList();
    final newAlbumsByFavorites =
        (results[1] as List<List<Album>>).expand((x) => x).take(10).toList();
    final playlistsForUser = (results[2] as List<List<Playlist>>)
        .expand((x) => x)
        .take(_homeSeeAllLimit)
        .toList();
    final songsOfYear = results[3] as List<Playlist>;
    final essentialsPlaylists = results[4] as List<Playlist>;
    final customMixes = results[5] as List<Playlist>;
    final moodPlaylists = results[6] as List<Playlist>;
    final personalRadioPlaylists = results[7] as List<Playlist>;
    final madeForYouPlaylists = results[8] as List<Playlist>;
    final listeningHistoryAlbums = _buildAlbumsFromTracks(recentlyPlayedTracks);

    // Display user's top genres nicely
    final displayGenres = genreSeeds.isNotEmpty
        ? genreSeeds.map((g) => _capitalizeTag(g)).toList()
        : const ['Pop', 'Rock', 'Hip Hop', 'R&B', 'Electronic', 'Jazz'];

    state = state.copyWith(
      isLoading: false,
      essentialsPlaylists: essentialsPlaylists,
      customMixes: customMixes,
      recentlyPlayedTracks: recentlyPlayedTracks,
      songsOfTheYear: songsOfYear,
      trendingTracks: personalizedTracks.take(_homeSeeAllLimit).toList(),
      moodPlaylists: moodPlaylists,
      personalRadioPlaylists: personalRadioPlaylists,
      madeForYouPlaylists: madeForYouPlaylists,
      popularPlaylists: playlistsForUser.take(_homeSeeAllLimit).toList(),
      newAlbums: albumsForYou.take(10).toList(),
      albumsYouLlEnjoy: newAlbumsByFavorites.take(10).toList(),
      listeningHistoryAlbums: listeningHistoryAlbums,
      recommendations: personalizedTracks.take(_homeSeeAllLimit).toList(),
      playlistsForYou: songsOfYear,
      topGenres: displayGenres,
      recentlyPlayedArtists: const [],
    );
  }

  /// Load discovery content for new users (no history)
  /// SIMPLIFIED: Direct TIDAL searches only - fast and reliable
  Future<void> _loadDiscoveryData() async {
    try {
      final currentYear = DateTime.now().year;
      print('🏠 Loading discovery data (new user mode)...');

      // ALL searches run in parallel - single phase, fast loading
      final results = await Future.wait([
        // 1. Songs of the Year playlists
        _musicService
            .searchPlaylists('songs of the year', limit: _homeSeeAllLimit)
            .catchError((_) => <Playlist>[]),
        // 2. Popular playlists
        _musicService
            .searchPlaylists('top hits', limit: _homeSeeAllLimit)
            .catchError((_) => <Playlist>[]),
        // 3. Trending tracks
        _musicService
            .searchTracks('trending $currentYear', limit: _homeSeeAllLimit)
            .catchError((_) => <Track>[]),
        // 4. New albums
        _musicService
            .searchAlbums('new releases $currentYear', limit: 10)
            .catchError((_) => <Album>[]),
        // 5. Popular albums
        _musicService
            .searchAlbums('best albums', limit: 10)
            .catchError((_) => <Album>[]),
        // 6. Top artists for genre display
        _musicService
            .searchArtists('popular', limit: 6)
            .catchError((_) => <Artist>[]),
        // 7. Essentials to explore
        _loadCuratedPlaylists(
            ['essentials', 'genre essentials', 'tidal essentials']),
        // 8. Custom mixes
        _loadCuratedPlaylists(['daily mix', 'custom mix', 'mix']),
        // 9. Recently played from local history
        _loadRecentlyPlayedTracks(limit: 12),
        // 10. Mood playlists
        _loadCuratedPlaylists(['set the tone', 'mood', 'chill']),
        // 11. Personal radio stations
        _loadCuratedPlaylists(['artist radio', 'radio', 'station']),
        // 12. Made for you
        _loadCuratedPlaylists(['made for you', 'for you', 'daily discovery']),
      ]);

      final songsOfYear = results[0] as List<Playlist>;
      final popular = results[1] as List<Playlist>;
      final trendingTracks = results[2] as List<Track>;
      final newAlbums = results[3] as List<Album>;
      final albumsYouLlEnjoy = results[4] as List<Album>;
      final artists = results[5] as List<Artist>;
      final essentialsPlaylists = results[6] as List<Playlist>;
      final customMixes = results[7] as List<Playlist>;
      final recentlyPlayedTracks = results[8] as List<Track>;
      final moodPlaylists = results[9] as List<Playlist>;
      final personalRadioPlaylists = results[10] as List<Playlist>;
      final madeForYouPlaylists = results[11] as List<Playlist>;
      final listeningHistoryAlbums =
          _buildAlbumsFromTracks(recentlyPlayedTracks);

      print(
          '✅ Discovery loaded: ${songsOfYear.length} year playlists, ${popular.length} popular, ${trendingTracks.length} tracks, ${newAlbums.length} new albums');

      state = state.copyWith(
        isLoading: false,
        essentialsPlaylists: essentialsPlaylists,
        customMixes: customMixes,
        recentlyPlayedTracks: recentlyPlayedTracks,
        songsOfTheYear: songsOfYear,
        trendingTracks: trendingTracks.take(_homeSeeAllLimit).toList(),
        moodPlaylists: moodPlaylists,
        personalRadioPlaylists: personalRadioPlaylists,
        madeForYouPlaylists: madeForYouPlaylists,
        popularPlaylists: popular,
        newAlbums: newAlbums.take(10).toList(),
        albumsYouLlEnjoy: albumsYouLlEnjoy.take(10).toList(),
        listeningHistoryAlbums: listeningHistoryAlbums,
        recommendations: trendingTracks.take(_homeSeeAllLimit).toList(),
        playlistsForYou: songsOfYear,
        topGenres: const [
          'Pop',
          'Rock',
          'Hip Hop',
          'R&B',
          'Electronic',
          'Jazz'
        ],
        recentlyPlayedArtists: artists,
      );
    } catch (e) {
      print('❌ Discovery load error: $e');
      // Fallback to pure TIDAL if anything fails
      await _loadTidalOnly();
    }
  }

  /// Load curated content for Qobuz (search-based discovery)
  /// Creates a Spotify-like experience with genre sections + Hi-Res focus
  Future<void> _loadQobuzDiscovery() async {
    String? firstError;

    // Helper to wrap API calls with proper error logging
    Future<List<T>> safeSearch<T>(
        Future<List<T>> Function() apiCall, String label) async {
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
      print('🎧 Loading Qobuz curated content...');

      // All curated searches run in parallel with proper error logging
      final results = await Future.wait([
        // 1. Featured Albums (pop search returns rich results)
        safeSearch<Album>(
            () => _musicService.searchAlbums('pop', limit: 15), 'Featured'),
        // 2. New Releases
        safeSearch<Album>(
            () => _musicService.searchAlbums('new releases', limit: 12), 'New'),
        // 3. Trending Tracks
        safeSearch<Track>(
            () => _musicService.searchTracks('hits', limit: 15), 'Tracks'),
        // 4. Jazz Collection
        safeSearch<Album>(
            () => _musicService.searchAlbums('jazz', limit: 12), 'Jazz'),
        // 5. Classical Collection
        safeSearch<Album>(
            () => _musicService.searchAlbums('classical', limit: 12),
            'Classical'),
        // 6. Rock Collection
        safeSearch<Album>(
            () => _musicService.searchAlbums('rock', limit: 12), 'Rock'),
        // 7. Featured Artists
        safeSearch<Artist>(
            () => _musicService.searchArtists('artist', limit: 10), 'Artists'),
      ]);

      final popAlbums = results[0] as List<Album>;
      final newReleases = results[1] as List<Album>;
      final trendingTracks = results[2] as List<Track>;
      final jazzAlbums = results[3] as List<Album>;
      final classicalAlbums = results[4] as List<Album>;
      final rockAlbums = results[5] as List<Album>;
      final artists = results[6] as List<Artist>;

      final totalItems =
          popAlbums.length + newReleases.length + trendingTracks.length;
      print('✅ Qobuz home: $totalItems total items loaded');

      // If ALL results are empty and we had an error, surface it
      if (totalItems == 0 && firstError != null) {
        state = state.copyWith(isLoading: false, error: firstError);
        return;
      }

      // Map Qobuz content to home state
      state = state.copyWith(
        isLoading: false,
        error: null,
        essentialsPlaylists: const [],
        customMixes: const [],
        recentlyPlayedTracks: const [],
        newAlbums: popAlbums.take(12).toList(),
        albumsYouLlEnjoy: newReleases.take(12).toList(),
        trendingTracks: trendingTracks.take(12).toList(),
        recommendations: trendingTracks.take(12).toList(),
        moodPlaylists: const [],
        personalRadioPlaylists: const [],
        madeForYouPlaylists: const [],
        jazzAlbums: jazzAlbums.take(10).toList(),
        classicalAlbums: classicalAlbums.take(10).toList(),
        rockAlbums: rockAlbums.take(10).toList(),
        songsOfTheYear: const [],
        popularPlaylists: const [],
        listeningHistoryAlbums: const [],
        playlistsForYou: const [],
        topGenres: const [
          'Pop',
          'Jazz',
          'Classical',
          'Rock',
          'Electronic',
          'New'
        ],
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
    String? firstError;

    // Helper to wrap API calls with proper error logging
    Future<List<T>> safeCall<T>(
        Future<List<T>> Function() apiCall, String label) async {
      try {
        final result = await apiCall();
        print('✅ HiFi $label: ${result.length} items');
        return result;
      } catch (e) {
        print('❌ HiFi $label FAILED: $e');
        firstError ??= 'HiFi $label: $e';
        return <T>[];
      }
    }

    try {
      print('🎵 Loading HiFi Server content...');

      // Cast to SubsonicServiceImpl to access specific methods
      final subsonicService = _musicService as SubsonicServiceImpl;

      // Use proper Subsonic discovery endpoints
      final results = await Future.wait([
        // New albums (getAlbumList2 type=newest)
        safeCall<Album>(
            () => subsonicService.getNewAlbums(limit: 20), 'New Albums'),
        // Random albums (getAlbumList2 type=random)
        safeCall<Album>(
            () => subsonicService.getRandomAlbums(limit: 20), 'Random Albums'),
        // Random tracks (getRandomSongs)
        safeCall<Track>(
            () => subsonicService.getRandomSongs(count: 20), 'Random Songs'),
        // All artists (getArtists)
        safeCall<Artist>(() => subsonicService.getArtists(), 'Artists'),
        // User playlists
        safeCall<Playlist>(() => subsonicService.getPlaylists(), 'Playlists'),
      ]);

      final newAlbums = results[0] as List<Album>;
      final randomAlbums = results[1] as List<Album>;
      final randomTracks = results[2] as List<Track>;
      final artists = results[3] as List<Artist>;
      final playlists = results[4] as List<Playlist>;

      final totalItems =
          newAlbums.length + randomTracks.length + randomAlbums.length;
      print('✅ HiFi Server: $totalItems total items loaded');

      // If ALL results are empty and we had an error, surface it
      if (totalItems == 0 && firstError != null) {
        state = state.copyWith(isLoading: false, error: firstError);
        return;
      }

      state = state.copyWith(
        isLoading: false,
        error: null,
        essentialsPlaylists: const [],
        customMixes: const [],
        recentlyPlayedTracks: const [],
        newAlbums: newAlbums.take(12).toList(),
        albumsYouLlEnjoy: randomAlbums.take(12).toList(),
        trendingTracks: randomTracks.take(12).toList(),
        recommendations: randomTracks.take(12).toList(),
        moodPlaylists: const [],
        personalRadioPlaylists: const [],
        madeForYouPlaylists: const [],
        songsOfTheYear: const [],
        popularPlaylists: playlists.take(10).toList(),
        listeningHistoryAlbums: const [],
        playlistsForYou: const [],
        topGenres: const ['Your Library', 'Albums', 'Artists', 'Tracks'],
        recentlyPlayedArtists: artists.take(12).toList(),
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
      final currentYear = DateTime.now().year;

      final results = await Future.wait([
        _musicService
            .searchPlaylists('songs of the year', limit: _homeSeeAllLimit)
            .catchError((_) => <Playlist>[]),
        _musicService
            .searchTracks('trending $currentYear', limit: _homeSeeAllLimit)
            .catchError((_) => <Track>[]),
        _musicService
            .searchPlaylists('top hits', limit: _homeSeeAllLimit)
            .catchError((_) => <Playlist>[]),
        _musicService
            .searchAlbums('new albums $currentYear', limit: 10)
            .catchError((_) => <Album>[]),
        _musicService
            .searchAlbums('pop hits', limit: 10)
            .catchError((_) => <Album>[]),
        _musicService
            .searchArtists('pop', limit: 6)
            .catchError((_) => <Artist>[]),
        _loadCuratedPlaylists(
            ['essentials', 'genre essentials', 'tidal essentials']),
        _loadCuratedPlaylists(['daily mix', 'custom mix', 'mix']),
        _loadRecentlyPlayedTracks(limit: 12),
        _loadCuratedPlaylists(['set the tone', 'mood', 'chill']),
        _loadCuratedPlaylists(['artist radio', 'radio', 'station']),
        _loadCuratedPlaylists(['made for you', 'for you', 'daily discovery']),
      ]);

      final recentlyPlayedTracks = results[8] as List<Track>;

      state = state.copyWith(
        isLoading: false,
        essentialsPlaylists: results[6] as List<Playlist>,
        customMixes: results[7] as List<Playlist>,
        recentlyPlayedTracks: recentlyPlayedTracks,
        songsOfTheYear: results[0] as List<Playlist>,
        trendingTracks: results[1] as List<Track>,
        moodPlaylists: results[9] as List<Playlist>,
        personalRadioPlaylists: results[10] as List<Playlist>,
        madeForYouPlaylists: results[11] as List<Playlist>,
        popularPlaylists: results[2] as List<Playlist>,
        newAlbums: results[3] as List<Album>,
        albumsYouLlEnjoy: results[4] as List<Album>,
        listeningHistoryAlbums: _buildAlbumsFromTracks(recentlyPlayedTracks),
        recommendations: results[1] as List<Track>,
        playlistsForYou: results[0] as List<Playlist>,
        topGenres: const [
          'Pop',
          'Rock',
          'Hip Hop',
          'R&B',
          'Electronic',
          'Jazz'
        ],
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
final homeDataProvider =
    StateNotifierProvider<HomeDataNotifier, HomeDataState>((ref) {
  final musicService = ref.watch(musicServiceProvider);
  final database = ref.watch(databaseProvider);
  final recommendationService = ref.watch(recommendationServiceProvider);
  return HomeDataNotifier(musicService, database, recommendationService);
});

// ============================================================================
// ALBUM, ARTIST, PLAYLIST DETAIL PROVIDERS
// ============================================================================

/// Album Detail Provider - Uses active music source
final albumDetailProvider =
    FutureProvider.family<AlbumDetail?, String>((ref, albumId) async {
  final musicService = ref.watch(musicServiceProvider);
  try {
    return await musicService.getAlbum(albumId);
  } catch (e) {
    return null;
  }
});

/// Artist Detail Provider - Uses active music source
final artistDetailProvider =
    FutureProvider.family<ArtistDetail?, String>((ref, artistId) async {
  final musicService = ref.watch(musicServiceProvider);
  try {
    return await musicService.getArtist(artistId);
  } catch (e) {
    return null;
  }
});

/// Playlist Detail Provider - Uses active music source
final playlistDetailProvider =
    FutureProvider.family<PlaylistDetail?, String>((ref, playlistId) async {
  final musicService = ref.watch(musicServiceProvider);
  try {
    return await musicService.getPlaylist(playlistId);
  } catch (e) {
    return null;
  }
});
