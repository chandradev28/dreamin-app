import '../models/models.dart';

/// Qobuz Service - SCAFFOLDED FOR FUTURE
/// This service will handle 24-bit hi-res streaming from Qobuz
abstract class QobuzService {
  /// Search for music
  Future<SearchResult> search(String query);

  /// Get album details
  Future<AlbumDetail> getAlbum(String id);

  /// Get playlist tracks
  Future<List<Track>> getPlaylistTracks(String id);

  /// Get stream URL for track (24-bit FLAC)
  Future<String> getStreamUrl(String trackId);

  /// Check endpoint health
  Future<bool> checkHealth(String endpoint);

  /// Get current active endpoint
  String get activeEndpoint;
}

/// Qobuz Service Implementation - TO BE IMPLEMENTED
class QobuzServiceImpl implements QobuzService {
  // TODO: Implement when activating Qobuz support
  
  @override
  Future<SearchResult> search(String query) async {
    throw UnimplementedError('Qobuz service not yet implemented');
  }

  @override
  Future<AlbumDetail> getAlbum(String id) async {
    throw UnimplementedError('Qobuz service not yet implemented');
  }

  @override
  Future<List<Track>> getPlaylistTracks(String id) async {
    throw UnimplementedError('Qobuz service not yet implemented');
  }

  @override
  Future<String> getStreamUrl(String trackId) async {
    throw UnimplementedError('Qobuz service not yet implemented');
  }

  @override
  Future<bool> checkHealth(String endpoint) async {
    throw UnimplementedError('Qobuz service not yet implemented');
  }

  @override
  String get activeEndpoint => throw UnimplementedError('Qobuz service not yet implemented');
}
