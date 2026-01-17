import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../data/database.dart';
import '../services/tidal_service.dart';
import '../services/lastfm_service.dart';
import '../services/deezer_service.dart';
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

/// Deezer Service Provider (for ISRC fallback)
final deezerServiceProvider = Provider<DeezerService>((ref) {
  return DeezerService();
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

/// Home Data Notifier - Hybrid TIDAL + Last.fm content loading
/// With Deezer ISRC fallback for better matching
class HomeDataNotifier extends StateNotifier<HomeDataState> {
  final TidalService _tidalService;
  final LastFmService _lastFmService;
  final DeezerService _deezerService;

  HomeDataNotifier(this._tidalService, this._lastFmService, this._deezerService) : super(const HomeDataState()) {
    loadData();
  }

  Future<void> loadData() async {
    state = state.copyWith(isLoading: true, error: null);

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

      // PHASE 2: Use Last.fm data to find actual playable content on TIDAL
      final List<Track> trendingTracks = [];
      final List<Album> newAlbums = [];
      final List<Album> albumsYouLlEnjoy = [];
      final List<Artist> recentArtists = [];

      // Randomize which tracks we search for (don't always take first 8)
      final shuffledTracks = List<LastFmTrack>.from(lastFmTracks)..shuffle();
      for (final lfmTrack in shuffledTracks.take(8)) {
        try {
          final query = '${lfmTrack.artist} ${lfmTrack.name}';
          var results = await _tidalService.searchTracks(query, limit: 1);
          
          // FALLBACK: If Tidal search returns empty, try Deezer ISRC matching
          if (results.isEmpty) {
            final deezerTrack = await _deezerService.searchTrackForIsrc(query);
            if (deezerTrack?.isrc != null) {
              final isrcMatch = await _tidalService.searchTrackByIsrc(deezerTrack!.isrc!);
              if (isrcMatch != null) {
                results = [isrcMatch];
              }
            }
          }
          
          if (results.isNotEmpty) {
            trendingTracks.add(results.first);
          }
        } catch (_) {}
      }

      // Randomize artists for "Suggested new albums" (shuffle before taking)
      final shuffledArtists = List<LastFmArtist>.from(lastFmArtists)..shuffle();
      for (final lfmArtist in shuffledArtists.take(5)) {
        try {
          final results = await _tidalService.searchAlbums(lfmArtist.name, limit: 2);
          newAlbums.addAll(results);
        } catch (_) {}
      }

      // Use multiple random tags for "Albums you'll enjoy" (more variety)
      if (topTags.length >= 3) {
        final shuffledTags = List<String>.from(topTags)..shuffle();
        for (final tag in shuffledTags.take(3)) {
          final tagAlbums = await _lastFmService.getTopAlbumsByTag(tag, limit: 5);
          for (final lfmAlbum in tagAlbums.take(2)) {
            try {
              final results = await _tidalService.searchAlbums(
                '${lfmAlbum.artist} ${lfmAlbum.name}', 
                limit: 1
              );
              if (results.isNotEmpty) {
                albumsYouLlEnjoy.add(results.first);
              }
            } catch (_) {}
          }
        }
      }

      // Convert Last.fm artists to TIDAL artists
      for (final lfmArtist in lastFmArtists.take(6)) {
        try {
          final results = await _tidalService.searchArtists(lfmArtist.name, limit: 1);
          if (results.isNotEmpty) {
            recentArtists.add(results.first);
          }
        } catch (_) {}
      }

      // Fallback: if Last.fm didn't give us enough, use varied search terms
      if (trendingTracks.length < 5) {
        // Use current month for freshness
        final months = ['january', 'february', 'march', 'april', 'may', 'june', 
                        'july', 'august', 'september', 'october', 'november', 'december'];
        final currentMonth = months[DateTime.now().month - 1];
        final moreTracks = await _tidalService.searchTracks('trending $currentMonth 2024', limit: 8)
            .catchError((_) => <Track>[]);
        trendingTracks.addAll(moreTracks);
      }

      if (newAlbums.length < 5) {
        // Search for recent releases with variety
        final searchTerms = ['new release 2025', 'album 2024', 'latest music'];
        final searchTerm = searchTerms[DateTime.now().second % searchTerms.length];
        final moreAlbums = await _tidalService.searchAlbums(searchTerm, limit: 10)
            .catchError((_) => <Album>[]);
        newAlbums.addAll(moreAlbums);
      }

      if (albumsYouLlEnjoy.length < 5) {
        final genres = ['pop', 'rock', 'hip hop', 'r&b', 'indie', 'electronic'];
        final genre = genres[DateTime.now().minute % genres.length];
        final moreAlbums = await _tidalService.searchAlbums('best $genre albums', limit: 10)
            .catchError((_) => <Album>[]);
        albumsYouLlEnjoy.addAll(moreAlbums);
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

/// Home Data Provider (with Last.fm integration + Deezer fallback)
final homeDataProvider = StateNotifierProvider<HomeDataNotifier, HomeDataState>((ref) {
  final tidalService = ref.watch(tidalServiceProvider);
  final lastFmService = ref.watch(lastFmServiceProvider);
  final deezerService = ref.watch(deezerServiceProvider);
  return HomeDataNotifier(tidalService, lastFmService, deezerService);
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
