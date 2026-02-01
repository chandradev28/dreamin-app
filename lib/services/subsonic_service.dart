import 'package:dio/dio.dart';
import '../core/constants/api_constants.dart';
import '../models/models.dart';
import 'music_service.dart';

/// Subsonic/OpenSubsonic Service - Full Implementation
/// Works with Navidrome, Gonic, Airsonic, and custom hifi servers
class SubsonicServiceImpl implements MusicService {
  final Dio _dio;
  final SubsonicConfig config;

  SubsonicServiceImpl(this.config) : _dio = Dio() {
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
  }

  @override
  MusicSource get source => MusicSource.subsonic;

  /// Build query params with Subsonic auth
  Map<String, String> _authParams() {
    return {
      'u': config.username,
      'p': config.password,
      'v': config.apiVersion,
      'c': 'DreaminApp',
      'f': 'json',
    };
  }

  /// Build full URL with auth params
  String _buildUrl(String endpoint, [Map<String, String>? extra]) {
    final params = {..._authParams(), ...?extra};
    final query = params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');
    return '${config.serverUrl}/rest/$endpoint?$query';
  }

  /// Ping server to verify connection
  Future<bool> ping() async {
    try {
      final response = await _dio.get(_buildUrl('ping'));
      if (response.data is Map) {
        final status = response.data['subsonic-response']?['status'];
        return status == 'ok';
      }
      return false;
    } catch (e) {
      print('❌ Subsonic ping failed: $e');
      return false;
    }
  }

  /// Search across library (songs, albums, artists)
  @override
  Future<SearchResult> search(String query, {int limit = 30}) async {
    try {
      final url = _buildUrl('search3', {
        'query': query,
        'songCount': limit.toString(),
        'albumCount': '20',
        'artistCount': '20',
      });

      final response = await _dio.get(url);
      final data = response.data['subsonic-response']['searchResult3'] ?? {};

      // Parse songs
      final songs = <Track>[];
      if (data['song'] is List) {
        for (final s in data['song']) {
          songs.add(_trackFromSubsonic(s));
        }
      }

      // Parse albums
      final albums = <Album>[];
      if (data['album'] is List) {
        for (final a in data['album']) {
          albums.add(_albumFromSubsonic(a));
        }
      }

      // Parse artists
      final artists = <Artist>[];
      if (data['artist'] is List) {
        for (final a in data['artist']) {
          artists.add(_artistFromSubsonic(a));
        }
      }

      return SearchResult(
        tracks: songs,
        albums: albums,
        artists: artists,
        playlists: const [],
        source: MusicSource.subsonic,
      );
    } catch (e) {
      print('❌ Subsonic search failed: $e');
      return const SearchResult(
        tracks: [],
        albums: [],
        artists: [],
        playlists: [],
        source: MusicSource.subsonic,
      );
    }
  }

  /// Search tracks only
  @override
  Future<List<Track>> searchTracks(String query, {int limit = 30}) async {
    final result = await search(query, limit: limit);
    return result.tracks;
  }

  /// Search albums only
  @override
  Future<List<Album>> searchAlbums(String query, {int limit = 20}) async {
    final result = await search(query, limit: limit);
    return result.albums;
  }

  /// Search artists only
  @override
  Future<List<Artist>> searchArtists(String query, {int limit = 20}) async {
    final result = await search(query, limit: limit);
    return result.artists;
  }

  /// Search playlists (not supported on Subsonic/HiFi)
  @override
  Future<List<Playlist>> searchPlaylists(String query, {int limit = 20}) async {
    return []; // Subsonic doesn't support playlist search
  }

  /// Get album details with all tracks
  @override
  Future<AlbumDetail?> getAlbum(String albumId) async {
    try {
      final url = _buildUrl('getAlbum', {'id': albumId});
      final response = await _dio.get(url);
      final data = response.data['subsonic-response']['album'];

      if (data == null) return null;

      final tracks = <Track>[];
      if (data['song'] is List) {
        for (final s in data['song']) {
          tracks.add(_trackFromSubsonic(s));
        }
      }

      return AlbumDetail(
        id: data['id']?.toString() ?? albumId,
        title: data['name'] ?? data['title'] ?? 'Unknown Album',
        artist: data['artist'] ?? 'Unknown Artist',
        artistId: data['artistId']?.toString() ?? '',
        coverArtUrl: getCoverArtUrl(data['coverArt']),
        year: data['year'] as int?,
        trackCount: tracks.length,
        duration: Duration(seconds: data['duration'] ?? 0),
        tracks: tracks,
        source: MusicSource.subsonic,
      );
    } catch (e) {
      print('❌ Subsonic getAlbum failed: $e');
      return null;
    }
  }

  /// Get artist details
  @override
  Future<ArtistDetail?> getArtist(String artistId) async {
    try {
      final url = _buildUrl('getArtist', {'id': artistId});
      final response = await _dio.get(url);
      final data = response.data['subsonic-response']['artist'];

      if (data == null) return null;

      final albums = <Album>[];
      if (data['album'] is List) {
        for (final a in data['album']) {
          albums.add(_albumFromSubsonic(a));
        }
      }

      return ArtistDetail(
        id: data['id']?.toString() ?? artistId,
        name: data['name'] ?? 'Unknown Artist',
        imageUrl: getCoverArtUrl(data['coverArt']),
        albums: albums,
        topTracks: const [],
        source: MusicSource.subsonic,
      );
    } catch (e) {
      print('❌ Subsonic getArtist failed: $e');
      return null;
    }
  }

  /// Get stream URL (async version for MusicService interface)
  @override
  Future<String?> getStreamUrl(String trackId) async {
    return getStreamUrlSync(trackId);
  }

  /// Cover art for MusicService interface
  @override
  String getCoverArt(String? id, {int size = 300}) {
    return getCoverArtUrl(id, size: size);
  }

  /// Get playlist details (not fully supported on Subsonic/HiFi)
  @override
  Future<PlaylistDetail?> getPlaylist(String id) async {
    // Subsonic/HiFi doesn't expose TIDAL playlists
    return null;
  }

  /// Sync version of stream URL for internal use
  String getStreamUrlSync(String trackId, {int? maxBitRate}) {
    final params = <String, String>{'id': trackId};
    if (maxBitRate != null) {
      params['maxBitRate'] = maxBitRate.toString();
    }
    return _buildUrl('stream', params);
  }

  /// Get cover art URL
  String getCoverArtUrl(String? coverArtId, {int size = 300}) {
    if (coverArtId == null || coverArtId.isEmpty) return '';
    return _buildUrl('getCoverArt', {'id': coverArtId, 'size': size.toString()});
  }

  /// Get random songs
  Future<List<Track>> getRandomSongs({int count = 20, String? genre}) async {
    try {
      final params = <String, String>{'size': count.toString()};
      if (genre != null) params['genre'] = genre;

      final url = _buildUrl('getRandomSongs', params);
      final response = await _dio.get(url);
      final data = response.data['subsonic-response']['randomSongs'];

      final songs = <Track>[];
      if (data?['song'] is List) {
        for (final s in data['song']) {
          songs.add(_trackFromSubsonic(s));
        }
      }
      return songs;
    } catch (e) {
      print('❌ Subsonic getRandomSongs failed: $e');
      return [];
    }
  }

  // ============== DISCOVERY (MusicService interface) ==============

  @override
  Future<List<Album>> getNewAlbums({int limit = 20}) async {
    try {
      final url = _buildUrl('getAlbumList2', {
        'type': 'newest',
        'size': limit.toString(),
      });
      final response = await _dio.get(url);
      final data = response.data['subsonic-response']['albumList2'];

      final albums = <Album>[];
      if (data?['album'] is List) {
        for (final a in data['album']) {
          albums.add(_albumFromSubsonic(a));
        }
      }
      return albums;
    } catch (e) {
      print('❌ Subsonic getNewAlbums failed: $e');
      return [];
    }
  }

  @override
  Future<List<Playlist>> getPopularPlaylists({int limit = 20}) async {
    // Subsonic doesn't have playlists
    return [];
  }

  @override
  Future<List<Track>> getRandomTracks({int limit = 20}) async {
    return getRandomSongs(count: limit);
  }

  /// Get starred/favorite items
  Future<List<Track>> getStarred() async {
    try {
      final url = _buildUrl('getStarred2');
      final response = await _dio.get(url);
      final data = response.data['subsonic-response']['starred2'];

      final songs = <Track>[];
      if (data?['song'] is List) {
        for (final s in data['song']) {
          songs.add(_trackFromSubsonic(s));
        }
      }
      return songs;
    } catch (e) {
      print('❌ Subsonic getStarred failed: $e');
      return [];
    }
  }

  /// Star a track
  Future<void> star(String trackId) async {
    try {
      await _dio.get(_buildUrl('star', {'id': trackId}));
    } catch (e) {
      print('❌ Subsonic star failed: $e');
    }
  }

  /// Unstar a track
  Future<void> unstar(String trackId) async {
    try {
      await _dio.get(_buildUrl('unstar', {'id': trackId}));
    } catch (e) {
      print('❌ Subsonic unstar failed: $e');
    }
  }

  /// Scrobble a play
  Future<void> scrobble(String trackId, {bool submission = true}) async {
    try {
      await _dio.get(_buildUrl('scrobble', {
        'id': trackId,
        'submission': submission.toString(),
      }));
    } catch (e) {
      print('❌ Subsonic scrobble failed: $e');
    }
  }

  /// Get playlists
  Future<List<Playlist>> getPlaylists() async {
    try {
      final url = _buildUrl('getPlaylists');
      final response = await _dio.get(url);
      final data = response.data['subsonic-response']['playlists'];

      final playlists = <Playlist>[];
      if (data?['playlist'] is List) {
        for (final p in data['playlist']) {
          playlists.add(Playlist(
            id: p['id']?.toString() ?? '',
            title: p['name'] ?? 'Unknown Playlist',
            trackCount: p['songCount'] ?? 0,
            coverArtUrl: getCoverArtUrl(p['coverArt']),
            creatorName: p['owner'] ?? 'You',
            source: MusicSource.subsonic,
          ));
        }
      }
      return playlists;
    } catch (e) {
      print('❌ Subsonic getPlaylists failed: $e');
      return [];
    }
  }

  // ============ CONVERSION HELPERS ============

  Track _trackFromSubsonic(Map<String, dynamic> s) {
    return Track(
      id: 'subsonic:${s['id']}',
      title: s['title'] ?? 'Unknown',
      artist: s['artist'] ?? 'Unknown Artist',
      artistId: s['artistId']?.toString() ?? '',
      album: s['album'] ?? 'Unknown Album',
      albumId: s['albumId']?.toString() ?? '',
      duration: Duration(seconds: s['duration'] ?? 0),
      trackNumber: s['track'] as int? ?? 1,
      coverArtUrl: getCoverArtUrl(s['coverArt']),
      isExplicit: false,
      source: MusicSource.subsonic,
    );
  }

  Album _albumFromSubsonic(Map<String, dynamic> a) {
    return Album(
      id: 'subsonic:${a['id']}',
      title: a['name'] ?? a['title'] ?? 'Unknown Album',
      artist: a['artist'] ?? 'Unknown Artist',
      artistId: a['artistId']?.toString() ?? '',
      coverArtUrl: getCoverArtUrl(a['coverArt']),
      year: a['year'] as int?,
      trackCount: a['songCount'] ?? 0,
      source: MusicSource.subsonic,
    );
  }

  Artist _artistFromSubsonic(Map<String, dynamic> a) {
    return Artist(
      id: 'subsonic:${a['id']}',
      name: a['name'] ?? 'Unknown Artist',
      imageUrl: getCoverArtUrl(a['coverArt']),
      source: MusicSource.subsonic,
    );
  }
}
