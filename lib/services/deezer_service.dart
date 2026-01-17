import 'package:dio/dio.dart';
import '../core/constants/api_constants.dart';

/// Deezer Service - Used for ISRC fallback matching
/// When Tidal search fails, we search Deezer to get ISRC, then search Tidal by ISRC
class DeezerService {
  final Dio _dio;

  DeezerService() : _dio = Dio(BaseOptions(
    baseUrl: DeezerEndpoints.baseUrl,
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 8),
  ));

  /// Search Deezer and get track with ISRC
  /// Returns a map with track info including ISRC for Tidal matching
  Future<DeezerTrackInfo?> searchTrackForIsrc(String query) async {
    try {
      final response = await _dio.get(
        DeezerEndpoints.searchPath,
        queryParameters: {'q': query},
      );

      if (response.statusCode != 200) return null;

      final data = response.data;
      if (data == null) return null;

      // Parse TRACK results from Deezer response
      final trackData = data['TRACK']?['data'];
      if (trackData == null || trackData is! List || trackData.isEmpty) {
        return null;
      }

      final track = trackData[0];
      return DeezerTrackInfo(
        id: track['SNG_ID']?.toString() ?? '',
        title: track['SNG_TITLE'] ?? '',
        artist: track['ART_NAME'] ?? '',
        artistId: track['ART_ID']?.toString() ?? '',
        albumId: track['ALB_ID']?.toString() ?? '',
        albumTitle: track['ALB_TITLE'] ?? '',
        isrc: track['ISRC'],
        duration: int.tryParse(track['DURATION']?.toString() ?? '0') ?? 0,
        coverArtId: track['ALB_PICTURE'],
      );
    } catch (e) {
      return null;
    }
  }

  /// Get track details by ID (includes ISRC)
  Future<DeezerTrackInfo?> getTrackById(String trackId) async {
    try {
      final response = await _dio.get('${DeezerEndpoints.trackPath}/$trackId');

      if (response.statusCode != 200) return null;

      final track = response.data;
      if (track == null) return null;

      return DeezerTrackInfo(
        id: track['SNG_ID']?.toString() ?? trackId,
        title: track['SNG_TITLE'] ?? '',
        artist: track['ART_NAME'] ?? '',
        artistId: track['ART_ID']?.toString() ?? '',
        albumId: track['ALB_ID']?.toString() ?? '',
        albumTitle: track['ALB_TITLE'] ?? '',
        isrc: track['ISRC'],
        duration: int.tryParse(track['DURATION']?.toString() ?? '0') ?? 0,
        coverArtId: track['ALB_PICTURE'],
      );
    } catch (e) {
      return null;
    }
  }

  /// Get Deezer cover art URL
  static String? getCoverArtUrl(String? pictureId, {int size = 500}) {
    if (pictureId == null || pictureId.isEmpty) return null;
    return 'https://e-cdns-images.dzcdn.net/images/cover/$pictureId/${size}x$size-000000-80-0-0.jpg';
  }

  /// Search for an artist by name
  Future<DeezerArtistInfo?> searchArtist(String artistName) async {
    try {
      final response = await _dio.get(
        DeezerEndpoints.searchPath,
        queryParameters: {'q': artistName},
      );

      if (response.statusCode != 200) return null;

      final data = response.data;
      if (data == null) return null;

      // Parse ARTIST results from Deezer response
      final artistData = data['ARTIST']?['data'];
      if (artistData == null || artistData is! List || artistData.isEmpty) {
        return null;
      }

      final artist = artistData[0];
      return DeezerArtistInfo(
        id: artist['ART_ID']?.toString() ?? '',
        name: artist['ART_NAME'] ?? '',
        pictureId: artist['ART_PICTURE'],
      );
    } catch (e) {
      return null;
    }
  }

  /// Get albums by artist ID
  Future<List<DeezerAlbumInfo>> getArtistAlbums(String artistId, {int limit = 10}) async {
    try {
      final response = await _dio.get('${DeezerEndpoints.artistPath}/$artistId/albums');

      if (response.statusCode != 200) return [];

      final data = response.data;
      if (data == null) return [];

      final albumsData = data['data'] as List<dynamic>?;
      if (albumsData == null) return [];

      return albumsData.take(limit).map((album) => DeezerAlbumInfo(
        id: album['ALB_ID']?.toString() ?? '',
        title: album['ALB_TITLE'] ?? '',
        artistName: album['ART_NAME'] ?? '',
        artistId: album['ART_ID']?.toString() ?? '',
        coverId: album['ALB_PICTURE'],
        year: album['DIGITAL_RELEASE_DATE']?.split('-').first,
      )).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get related artists for an artist ID
  Future<List<DeezerArtistInfo>> getRelatedArtists(String artistId, {int limit = 10}) async {
    try {
      final response = await _dio.get('${DeezerEndpoints.artistPath}/$artistId/related');

      if (response.statusCode != 200) return [];

      final data = response.data;
      if (data == null) return [];

      final artistsData = data['data'] as List<dynamic>?;
      if (artistsData == null) return [];

      return artistsData.take(limit).map((artist) => DeezerArtistInfo(
        id: artist['ART_ID']?.toString() ?? '',
        name: artist['ART_NAME'] ?? '',
        pictureId: artist['ART_PICTURE'],
      )).toList();
    } catch (e) {
      return [];
    }
  }
}

/// Deezer track info for ISRC matching
class DeezerTrackInfo {
  final String id;
  final String title;
  final String artist;
  final String artistId;
  final String albumId;
  final String albumTitle;
  final String? isrc;
  final int duration;
  final String? coverArtId;

  const DeezerTrackInfo({
    required this.id,
    required this.title,
    required this.artist,
    required this.artistId,
    required this.albumId,
    required this.albumTitle,
    this.isrc,
    required this.duration,
    this.coverArtId,
  });

  String? get coverArtUrl => DeezerService.getCoverArtUrl(coverArtId);
}

/// Deezer artist info for related artists
class DeezerArtistInfo {
  final String id;
  final String name;
  final String? pictureId;

  const DeezerArtistInfo({
    required this.id,
    required this.name,
    this.pictureId,
  });

  String? get pictureUrl {
    if (pictureId == null || pictureId!.isEmpty) return null;
    return 'https://e-cdns-images.dzcdn.net/images/artist/$pictureId/500x500-000000-80-0-0.jpg';
  }
}

/// Deezer album info for artist albums
class DeezerAlbumInfo {
  final String id;
  final String title;
  final String artistName;
  final String artistId;
  final String? coverId;
  final String? year;

  const DeezerAlbumInfo({
    required this.id,
    required this.title,
    required this.artistName,
    required this.artistId,
    this.coverId,
    this.year,
  });

  String? get coverUrl => DeezerService.getCoverArtUrl(coverId);
}
