import 'dart:math';
import '../data/database.dart';
import '../models/models.dart';
import '../services/tidal_service.dart';

/// On-Device Recommendation Engine
/// Analyzes listening history to provide personalized recommendations
class RecommendationService {
  final AppDatabase _database;
  final TidalService _tidalService;
  
  // Cache recommendations to avoid recalculating too often
  List<Track>? _cachedRecommendations;
  DateTime? _lastRecommendationTime;
  static const _cacheValidDuration = Duration(minutes: 30);

  RecommendationService(this._database, this._tidalService);

  /// Get personalized recommendations based on listening history
  Future<List<Track>> getRecommendations({int limit = 20}) async {
    // Return cached if still valid
    if (_cachedRecommendations != null && 
        _lastRecommendationTime != null &&
        DateTime.now().difference(_lastRecommendationTime!) < _cacheValidDuration) {
      return _cachedRecommendations!;
    }

    final totalPlays = await _database.getTotalPlayCount();
    
    // If insufficient history, return popular/random tracks
    if (totalPlays < 10) {
      return _getDefaultRecommendations(limit);
    }

    final recommendations = <Track>[];
    
    // Get user preferences
    final topGenres = await _database.getTopGenres(limit: 5);
    final topArtistIds = await _database.getTopArtistIds(limit: 10);
    
    // 1. Get tracks from top genres (40% of recommendations)
    final genreCount = (limit * 0.4).round();
    if (topGenres.isNotEmpty) {
      final genreTracks = await _getTracksByGenres(topGenres, genreCount);
      recommendations.addAll(genreTracks);
    }

    // 2. Get tracks from similar artists (40% of recommendations)
    final artistCount = (limit * 0.4).round();
    if (topArtistIds.isNotEmpty) {
      final artistTracks = await _getTracksByArtists(topArtistIds, artistCount);
      recommendations.addAll(artistTracks);
    }

    // 3. Add some discovery/random tracks (20% of recommendations)
    final discoveryCount = limit - recommendations.length;
    if (discoveryCount > 0) {
      final discoveryTracks = await _getDiscoveryTracks(discoveryCount);
      recommendations.addAll(discoveryTracks);
    }

    // Shuffle to mix recommendations
    recommendations.shuffle(Random());

    // Remove duplicates and limit
    final uniqueTracks = <String, Track>{};
    for (final track in recommendations) {
      uniqueTracks['${track.id}_${track.source.name}'] = track;
    }

    _cachedRecommendations = uniqueTracks.values.take(limit).toList();
    _lastRecommendationTime = DateTime.now();

    return _cachedRecommendations!;
  }

  /// Get genre-based recommendations
  Future<List<Track>> getGenreRecommendations(String genre, {int limit = 10}) async {
    try {
      // Search for tracks in this genre
      final result = await _tidalService.search(genre, limit: limit * 2);
      return result.tracks.take(limit).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get tracks from user's top genres
  Future<List<Track>> _getTracksByGenres(List<String> genres, int limit) async {
    final tracks = <Track>[];
    final perGenre = (limit / genres.length).ceil();
    
    for (final genre in genres) {
      try {
        final result = await _tidalService.search(genre, limit: perGenre);
        tracks.addAll(result.tracks);
      } catch (e) {
        // Skip failed searches
      }
    }
    
    return tracks.take(limit).toList();
  }

  /// Get tracks from user's top artists
  Future<List<Track>> _getTracksByArtists(List<String> artistIds, int limit) async {
    final tracks = <Track>[];
    final perArtist = (limit / artistIds.length).ceil();
    
    for (final artistId in artistIds.take(5)) {
      try {
        final artist = await _tidalService.getArtist(artistId);
        if (artist.albums.isNotEmpty) {
          // Get tracks from artist's albums
          for (final album in artist.albums.take(2)) {
            try {
              final albumDetail = await _tidalService.getAlbum(album.id);
              tracks.addAll(albumDetail.tracks.take(perArtist));
            } catch (e) {
              // Skip failed fetches
            }
          }
        }
      } catch (e) {
        // Skip failed fetches
      }
    }
    
    return tracks.take(limit).toList();
  }

  /// Get discovery tracks (new releases, trending, etc.)
  Future<List<Track>> _getDiscoveryTracks(int limit) async {
    try {
      final newAlbums = await _tidalService.getNewAlbums(limit: 5);
      final tracks = <Track>[];
      
      for (final album in newAlbums.take(3)) {
        try {
          final albumDetail = await _tidalService.getAlbum(album.id);
          tracks.addAll(albumDetail.tracks.take(3));
        } catch (e) {
          // Skip failed fetches
        }
      }
      
      return tracks.take(limit).toList();
    } catch (e) {
      return [];
    }
  }

  /// Default recommendations when insufficient history
  Future<List<Track>> _getDefaultRecommendations(int limit) async {
    try {
      // Get popular playlists and extract tracks
      final playlists = await _tidalService.getPopularPlaylists(limit: 3);
      final tracks = <Track>[];
      
      for (final playlist in playlists) {
        try {
          final detail = await _tidalService.getPlaylist(playlist.id);
          tracks.addAll(detail.tracks.take(limit ~/ 3));
        } catch (e) {
          // Skip failed fetches
        }
      }
      
      if (tracks.isEmpty) {
        // Fallback to search for popular genres
        final popularGenres = ['pop', 'hip hop', 'rock', 'electronic'];
        for (final genre in popularGenres) {
          try {
            final result = await _tidalService.search(genre, limit: 5);
            tracks.addAll(result.tracks);
          } catch (e) {
            // Skip failed searches
          }
        }
      }
      
      return tracks.take(limit).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get listening patterns (time-of-day analysis)
  Future<ListeningPatterns> getListeningPatterns() async {
    final hourCounts = await _database.getListeningPatterns();
    final topGenres = await _database.getTopGenres(limit: 5);
    final topArtists = await _database.getTopArtistIds(limit: 5);
    
    return ListeningPatterns(
      hourlyDistribution: hourCounts,
      topGenres: topGenres,
      topArtistIds: topArtists,
    );
  }

  /// Refresh recommendations (call after significant listening activity)
  void invalidateCache() {
    _cachedRecommendations = null;
    _lastRecommendationTime = null;
  }

  /// Check if recommendations should be refreshed
  bool shouldRefresh() {
    if (_lastRecommendationTime == null) return true;
    return DateTime.now().difference(_lastRecommendationTime!) > _cacheValidDuration;
  }
}

/// Listening patterns data
class ListeningPatterns {
  final Map<String, int> hourlyDistribution;
  final List<String> topGenres;
  final List<String> topArtistIds;

  ListeningPatterns({
    required this.hourlyDistribution,
    required this.topGenres,
    required this.topArtistIds,
  });

  String get peakListeningHour {
    if (hourlyDistribution.isEmpty) return 'N/A';
    return hourlyDistribution.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  bool get hasEnoughData => hourlyDistribution.isNotEmpty;
}
