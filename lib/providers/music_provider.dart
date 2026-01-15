import 'package:flutter_riverpod/flutter_riverpod.dart';
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
        // 6. Get some artists for legacy support
        _tidalService.searchArtists('pop', limit: 6)
            .catchError((_) => <Artist>[]),
      ]);

      final songsOfYear = results[0] as List<Playlist>;
      final trending = results[1] as List<Track>;
      final popular = results[2] as List<Playlist>;
      final albums = results[3] as List<Album>;
      final albumsEnjoy = results[4] as List<Album>;
      final artists = results[5] as List<Artist>;

      state = state.copyWith(
        isLoading: false,
        songsOfTheYear: songsOfYear,
        trendingTracks: trending,
        popularPlaylists: popular,
        newAlbums: albums,
        albumsYouLlEnjoy: albumsEnjoy,
        // Legacy field mappings for backward compatibility
        recommendations: trending,
        playlistsForYou: songsOfYear,
        topGenres: const ['Pop', 'Rock', 'Hip Hop', 'R&B', 'Electronic', 'Jazz'],
        recentlyPlayedArtists: artists,
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
