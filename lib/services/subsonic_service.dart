import '../core/constants/api_constants.dart';
import '../models/models.dart';

/// Subsonic Service - SCAFFOLDED FOR FUTURE
/// This service will handle communication with personal Subsonic/Navidrome server
abstract class SubsonicService {
  /// Ping server to verify connection
  Future<bool> ping();

  /// Get all artists from library
  Future<List<Artist>> getArtists();

  /// Get artist details with albums
  Future<ArtistDetail> getArtist(String id);

  /// Get all albums
  Future<List<Album>> getAlbums({int offset = 0, int limit = 50});

  /// Get album details with tracks
  Future<AlbumDetail> getAlbum(String id);

  /// Search across library
  Future<SearchResult> search(String query);

  /// Get stream URL for track
  Future<String> getStreamUrl(String trackId, {int? maxBitRate});

  /// Get cover art URL
  String getCoverArtUrl(String id, {int? size});

  /// Star/unstar a track
  Future<void> star(String id);
  Future<void> unstar(String id);

  /// Get starred items
  Future<List<Track>> getStarred();

  /// Get playlists
  Future<List<Playlist>> getPlaylists();

  /// Scrobble a play
  Future<void> scrobble(String trackId);
}

/// Subsonic Service Implementation - TO BE IMPLEMENTED
class SubsonicServiceImpl implements SubsonicService {
  final SubsonicConfig config;

  SubsonicServiceImpl(this.config);

  // TODO: Implement all methods when activating Subsonic support
  
  @override
  Future<bool> ping() async {
    throw UnimplementedError('Subsonic service not yet implemented');
  }

  @override
  Future<List<Artist>> getArtists() async {
    throw UnimplementedError('Subsonic service not yet implemented');
  }

  @override
  Future<ArtistDetail> getArtist(String id) async {
    throw UnimplementedError('Subsonic service not yet implemented');
  }

  @override
  Future<List<Album>> getAlbums({int offset = 0, int limit = 50}) async {
    throw UnimplementedError('Subsonic service not yet implemented');
  }

  @override
  Future<AlbumDetail> getAlbum(String id) async {
    throw UnimplementedError('Subsonic service not yet implemented');
  }

  @override
  Future<SearchResult> search(String query) async {
    throw UnimplementedError('Subsonic service not yet implemented');
  }

  @override
  Future<String> getStreamUrl(String trackId, {int? maxBitRate}) async {
    throw UnimplementedError('Subsonic service not yet implemented');
  }

  @override
  String getCoverArtUrl(String id, {int? size}) {
    throw UnimplementedError('Subsonic service not yet implemented');
  }

  @override
  Future<void> star(String id) async {
    throw UnimplementedError('Subsonic service not yet implemented');
  }

  @override
  Future<void> unstar(String id) async {
    throw UnimplementedError('Subsonic service not yet implemented');
  }

  @override
  Future<List<Track>> getStarred() async {
    throw UnimplementedError('Subsonic service not yet implemented');
  }

  @override
  Future<List<Playlist>> getPlaylists() async {
    throw UnimplementedError('Subsonic service not yet implemented');
  }

  @override
  Future<void> scrobble(String trackId) async {
    throw UnimplementedError('Subsonic service not yet implemented');
  }
}
