import '../models/models.dart';

/// Unified Music Service Interface
/// All sources (TIDAL, Subsonic, Qobuz) implement this interface
abstract class MusicService {
  /// Get the source type for this service
  MusicSource get source;

  // ============== SEARCH ==============

  /// Search all content types
  Future<SearchResult> search(String query, {int limit = 30});

  /// Search tracks only
  Future<List<Track>> searchTracks(String query, {int limit = 30});

  /// Search albums only
  Future<List<Album>> searchAlbums(String query, {int limit = 20});

  /// Search artists only
  Future<List<Artist>> searchArtists(String query, {int limit = 20});

  /// Search playlists only
  Future<List<Playlist>> searchPlaylists(String query, {int limit = 20});

  // ============== DETAILS ==============

  /// Get album details with tracks
  Future<AlbumDetail?> getAlbum(String id);

  /// Get artist details with albums
  Future<ArtistDetail?> getArtist(String id);

  /// Get playlist details with tracks
  Future<PlaylistDetail?> getPlaylist(String id);

  // ============== STREAMING ==============

  /// Get stream URL for a track
  Future<String?> getStreamUrl(String trackId);

  /// Get cover art URL
  String getCoverArt(String? id, {int size = 300});

  // ============== DISCOVERY (optional) ==============

  /// Get new/popular albums (for home screen)
  Future<List<Album>> getNewAlbums({int limit = 20}) async => [];

  /// Get popular playlists (for home screen)
  Future<List<Playlist>> getPopularPlaylists({int limit = 20}) async => [];

  /// Get random tracks (for discovery)
  Future<List<Track>> getRandomTracks({int limit = 20}) async => [];
}

/// Extension to check source capabilities
extension MusicServiceCapabilities on MusicService {
  bool get supportsPlaylists => source != MusicSource.subsonic;
  bool get supportsArtistDetails => source != MusicSource.subsonic;
  bool get supportsDiscovery =>
      source == MusicSource.tidal || source == MusicSource.qobuz;
}
