import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import '../models/models.dart';
import 'music_service.dart';

/// Subsonic/OpenSubsonic Service - Full Implementation
/// Works with Navidrome, Gonic, Airsonic, and custom hifi servers
/// Rewritten to use http package for reliability
class SubsonicServiceImpl implements MusicService {
  final http.Client _client;
  final SubsonicConfig config;

  SubsonicServiceImpl(this.config) : _client = http.Client();

  @override
  MusicSource get source => MusicSource.subsonic;

  /// Build authentication parameters for Subsonic API
  Map<String, String> _authParams() {
    return {
      'u': config.username,
      'p': config.password,
      'v': config.apiVersion,
      'c': 'DreaminApp',
      'f': 'json',
    };
  }

  /// Build full URI with auth params using proper encoding
  Uri _buildUri(String endpoint, [Map<String, String>? extraParams]) {
    final params = _authParams();
    if (extraParams != null) {
      params.addAll(extraParams);
    }
    return Uri.parse('${config.serverUrl}/rest/$endpoint')
        .replace(queryParameters: params);
  }

  /// Get cover art URL from cover art ID (returns FULL authenticated URL)
  String getCoverArtUrl(String? coverArtId, {int size = 300}) {
    if (coverArtId == null || coverArtId.isEmpty) return '';
    
    // If already a full URL, return as-is
    if (coverArtId.startsWith('http')) return coverArtId;
    
    // Strip subsonic: prefix if present
    String cleanId = coverArtId;
    if (coverArtId.startsWith('subsonic:')) {
      cleanId = coverArtId.substring(9);
    }
    
    final params = _authParams();
    params['id'] = cleanId;
    params['size'] = size.toString();
    
    return Uri.parse('${config.serverUrl}/rest/getCoverArt')
        .replace(queryParameters: params)
        .toString();
  }

  /// Strip 'subsonic:' prefix from ID if present
  String _stripPrefix(String id) {
    if (id.startsWith('subsonic:')) {
      return id.substring(9); // 'subsonic:'.length == 9
    }
    return id;
  }

  @override
  String getCoverArt(String? id, {int size = 300}) {
    return getCoverArtUrl(id, size: size);
  }

  /// Get stream URL for a track
  String getStreamUrlSync(String trackId, {int? maxBitRate}) {
    final cleanId = _stripPrefix(trackId);
    final params = _authParams();
    params['id'] = cleanId;
    if (maxBitRate != null) {
      params['maxBitRate'] = maxBitRate.toString();
    }
    
    final url = Uri.parse('${config.serverUrl}/rest/stream')
        .replace(queryParameters: params)
        .toString();
    print('[HiFi] Stream URL: $url');
    return url;
  }

  @override
  Future<String?> getStreamUrl(String trackId) async {
    return getStreamUrlSync(trackId);
  }

  /// Ping server to verify connection
  Future<bool> ping() async {
    try {
      final uri = _buildUri('ping');
      print('[HiFi] Ping: $uri');
      final response = await _client.get(uri).timeout(const Duration(seconds: 5));
      
      if (response.statusCode != 200) {
        print('[HiFi] Ping failed: ${response.statusCode}');
        return false;
      }
      
      final data = json.decode(response.body);
      final status = data['subsonic-response']?['status'];
      print('[HiFi] Ping status: $status');
      return status == 'ok';
    } catch (e) {
      print('[HiFi] Ping error: $e');
      return false;
    }
  }

  /// Search across library (songs, albums, artists)
  @override
  Future<SearchResult> search(String query, {int limit = 30}) async {
    if (query.trim().isEmpty) {
      return const SearchResult(
        tracks: [],
        albums: [],
        artists: [],
        playlists: [],
        source: MusicSource.subsonic,
      );
    }
    
    print('[HiFi] Searching for: "$query"');
    
    try {
      final uri = _buildUri('search3', {
        'query': query,
        'songCount': limit.toString(),
        'albumCount': '20',
        'artistCount': '20',
      });
      
      print('[HiFi] Search URL: $uri');
      
      final response = await _client.get(uri).timeout(const Duration(seconds: 15));
      
      if (response.statusCode != 200) {
        print('[HiFi] Search failed: ${response.statusCode}');
        throw Exception('Search failed: ${response.statusCode}');
      }
      
      final data = json.decode(response.body);
      final result = data['subsonic-response'];
      
      if (result?['status'] == 'failed') {
        final error = result['error']?['message'] ?? 'Unknown error';
        print('[HiFi] Search error: $error');
        throw Exception('Search error: $error');
      }
      
      final searchResult = result?['searchResult3'] ?? {};
      
      // Parse songs
      final songs = <Track>[];
      if (searchResult['song'] is List) {
        for (final s in searchResult['song']) {
          songs.add(_trackFromSubsonic(s as Map<String, dynamic>));
        }
      }

      // Parse albums
      final albums = <Album>[];
      if (searchResult['album'] is List) {
        for (final a in searchResult['album']) {
          albums.add(_albumFromSubsonic(a as Map<String, dynamic>));
        }
      }

      // Parse artists
      final artists = <Artist>[];
      if (searchResult['artist'] is List) {
        for (final a in searchResult['artist']) {
          artists.add(_artistFromSubsonic(a as Map<String, dynamic>));
        }
      }

      print('[HiFi] Found ${songs.length} tracks, ${albums.length} albums, ${artists.length} artists');

      return SearchResult(
        tracks: songs,
        albums: albums,
        artists: artists,
        playlists: const [],
        source: MusicSource.subsonic,
      );
    } catch (e) {
      print('[HiFi] Search error: $e');
      throw Exception('HiFi search failed: $e');
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
    print('[HiFi] Getting album: $albumId');
    
    try {
      final uri = _buildUri('getAlbum', {'id': albumId});
      final response = await _client.get(uri).timeout(const Duration(seconds: 10));
      
      if (response.statusCode != 200) return null;
      
      final data = json.decode(response.body);
      final result = data['subsonic-response'];
      
      if (result?['status'] == 'failed') return null;
      
      final albumData = result?['album'];
      if (albumData == null) return null;

      final tracks = <Track>[];
      if (albumData['song'] is List) {
        for (final s in albumData['song']) {
          tracks.add(_trackFromSubsonic(s as Map<String, dynamic>));
        }
      }

      print('[HiFi] Found ${tracks.length} tracks in album');

      return AlbumDetail(
        id: albumData['id']?.toString() ?? albumId,
        title: albumData['name'] ?? albumData['title'] ?? 'Unknown Album',
        artist: albumData['artist'] ?? 'Unknown Artist',
        artistId: albumData['artistId']?.toString() ?? '',
        coverArtUrl: getCoverArtUrl(albumData['coverArt']?.toString()),
        year: albumData['year'] as int?,
        trackCount: tracks.length,
        duration: Duration(seconds: albumData['duration'] ?? 0),
        tracks: tracks,
        source: MusicSource.subsonic,
      );
    } catch (e) {
      print('[HiFi] getAlbum error: $e');
      return null;
    }
  }

  /// Get artist details
  @override
  Future<ArtistDetail?> getArtist(String artistId) async {
    print('[HiFi] Getting artist: $artistId');
    
    try {
      final uri = _buildUri('getArtist', {'id': artistId});
      final response = await _client.get(uri).timeout(const Duration(seconds: 10));
      
      if (response.statusCode != 200) return null;
      
      final data = json.decode(response.body);
      final result = data['subsonic-response'];
      
      if (result?['status'] == 'failed') return null;
      
      final artistData = result?['artist'];
      if (artistData == null) return null;

      final albums = <Album>[];
      if (artistData['album'] is List) {
        for (final a in artistData['album']) {
          albums.add(_albumFromSubsonic(a as Map<String, dynamic>));
        }
      }

      print('[HiFi] Found ${albums.length} albums for artist');

      return ArtistDetail(
        id: artistData['id']?.toString() ?? artistId,
        name: artistData['name'] ?? 'Unknown Artist',
        imageUrl: getCoverArtUrl(artistData['coverArt']?.toString()),
        albums: albums,
        topTracks: const [],
        source: MusicSource.subsonic,
      );
    } catch (e) {
      print('[HiFi] getArtist error: $e');
      return null;
    }
  }

  /// Get playlist details (not fully supported on Subsonic/HiFi)
  @override
  Future<PlaylistDetail?> getPlaylist(String id) async {
    // Subsonic/HiFi doesn't expose TIDAL playlists
    return null;
  }

  /// Get random songs
  Future<List<Track>> getRandomSongs({int count = 20, String? genre}) async {
    print('[HiFi] Getting $count random songs');
    
    try {
      final params = <String, String>{'size': count.toString()};
      if (genre != null) params['genre'] = genre;

      final uri = _buildUri('getRandomSongs', params);
      final response = await _client.get(uri).timeout(const Duration(seconds: 10));
      
      if (response.statusCode != 200) {
        print('[HiFi] getRandomSongs failed: ${response.statusCode}');
        return [];
      }
      
      final data = json.decode(response.body);
      final result = data['subsonic-response'];
      
      if (result?['status'] == 'failed') {
        print('[HiFi] getRandomSongs error: ${result['error']?['message']}');
        return [];
      }
      
      final songs = result?['randomSongs']?['song'] as List? ?? [];
      
      final tracks = songs
          .map((s) => _trackFromSubsonic(s as Map<String, dynamic>))
          .toList();
      
      print('[HiFi] Got ${tracks.length} random tracks');
      return tracks;
    } catch (e) {
      print('[HiFi] getRandomSongs error: $e');
      return [];
    }
  }

  // ============== DISCOVERY (MusicService interface) ==============

  @override
  Future<List<Album>> getNewAlbums({int limit = 20}) async {
    return _getAlbumList('newest', limit: limit);
  }

  /// Get frequently played albums
  Future<List<Album>> getFrequentAlbums({int limit = 20}) async {
    return _getAlbumList('frequent', limit: limit);
  }

  /// Get recently played albums
  Future<List<Album>> getRecentAlbums({int limit = 20}) async {
    return _getAlbumList('recent', limit: limit);
  }

  /// Get random albums
  Future<List<Album>> getRandomAlbums({int limit = 20}) async {
    return _getAlbumList('random', limit: limit);
  }

  /// Internal helper to fetch album lists by type
  Future<List<Album>> _getAlbumList(String type, {int limit = 20}) async {
    print('[HiFi] Getting album list: $type');
    
    try {
      final uri = _buildUri('getAlbumList2', {
        'type': type,
        'size': limit.toString(),
      });
      
      final response = await _client.get(uri).timeout(const Duration(seconds: 10));
      
      if (response.statusCode != 200) {
        print('[HiFi] getAlbumList2 failed: ${response.statusCode}');
        return [];
      }
      
      final data = json.decode(response.body);
      final result = data['subsonic-response'];
      
      if (result?['status'] == 'failed') {
        print('[HiFi] getAlbumList2 error: ${result['error']?['message']}');
        return [];
      }
      
      final albumList = result?['albumList2']?['album'] as List? ?? [];
      
      final albums = albumList
          .map((a) => _albumFromSubsonic(a as Map<String, dynamic>))
          .toList();
      
      print('[HiFi] Got ${albums.length} $type albums');
      return albums;
    } catch (e) {
      print('[HiFi] getAlbumList2 error: $e');
      return [];
    }
  }

  /// Get all artists (indexed alphabetically)
  Future<List<Artist>> getArtists() async {
    print('[HiFi] Getting all artists');
    
    try {
      final uri = _buildUri('getArtists');
      final response = await _client.get(uri).timeout(const Duration(seconds: 10));
      
      if (response.statusCode != 200) {
        print('[HiFi] getArtists failed: ${response.statusCode}');
        return [];
      }
      
      final data = json.decode(response.body);
      final result = data['subsonic-response'];
      
      if (result?['status'] == 'failed') {
        print('[HiFi] getArtists error: ${result['error']?['message']}');
        return [];
      }
      
      final artistsData = result?['artists'];
      final artists = <Artist>[];
      
      // Artists are grouped by index (A, B, C, etc.)
      if (artistsData?['index'] is List) {
        for (final index in artistsData['index']) {
          if (index['artist'] is List) {
            for (final a in index['artist']) {
              artists.add(_artistFromSubsonic(a as Map<String, dynamic>));
            }
          }
        }
      }
      
      print('[HiFi] Found ${artists.length} artists');
      return artists;
    } catch (e) {
      print('[HiFi] getArtists error: $e');
      return [];
    }
  }

  @override
  Future<List<Playlist>> getPopularPlaylists({int limit = 20}) async {
    // Return user's own playlists from the server
    return getPlaylists();
  }

  @override
  Future<List<Track>> getRandomTracks({int limit = 20}) async {
    return getRandomSongs(count: limit);
  }

  /// Get starred/favorite items
  Future<List<Track>> getStarred() async {
    print('[HiFi] Getting starred items');
    
    try {
      final uri = _buildUri('getStarred2');
      final response = await _client.get(uri).timeout(const Duration(seconds: 10));
      
      if (response.statusCode != 200) return [];
      
      final data = json.decode(response.body);
      final result = data['subsonic-response'];
      
      if (result?['status'] == 'failed') return [];
      
      final starred = result?['starred2'] ?? {};
      
      final songs = <Track>[];
      if (starred['song'] is List) {
        for (final s in starred['song']) {
          songs.add(_trackFromSubsonic(s as Map<String, dynamic>));
        }
      }

      print('[HiFi] Found ${songs.length} starred tracks');
      return songs;
    } catch (e) {
      print('[HiFi] getStarred error: $e');
      return [];
    }
  }

  /// Star a track
  Future<void> star(String trackId) async {
    try {
      final uri = _buildUri('star', {'id': trackId});
      await _client.get(uri).timeout(const Duration(seconds: 5));
    } catch (e) {
      print('[HiFi] star error: $e');
    }
  }

  /// Unstar a track
  Future<void> unstar(String trackId) async {
    try {
      final uri = _buildUri('unstar', {'id': trackId});
      await _client.get(uri).timeout(const Duration(seconds: 5));
    } catch (e) {
      print('[HiFi] unstar error: $e');
    }
  }

  /// Scrobble a play
  Future<void> scrobble(String trackId, {bool submission = true}) async {
    try {
      final uri = _buildUri('scrobble', {
        'id': trackId,
        'submission': submission.toString(),
      });
      await _client.get(uri).timeout(const Duration(seconds: 5));
    } catch (e) {
      print('[HiFi] scrobble error: $e');
    }
  }

  /// Get playlists
  Future<List<Playlist>> getPlaylists() async {
    print('[HiFi] Getting playlists');
    
    try {
      final uri = _buildUri('getPlaylists');
      final response = await _client.get(uri).timeout(const Duration(seconds: 10));
      
      if (response.statusCode != 200) return [];
      
      final data = json.decode(response.body);
      final result = data['subsonic-response'];
      
      if (result?['status'] == 'failed') return [];
      
      final playlistsData = result?['playlists']?['playlist'] as List? ?? [];

      final playlists = <Playlist>[];
      for (final p in playlistsData) {
        playlists.add(Playlist(
          id: p['id']?.toString() ?? '',
          title: p['name'] ?? 'Unknown Playlist',
          trackCount: p['songCount'] ?? 0,
          coverArtUrl: getCoverArtUrl(p['coverArt']?.toString()),
          creatorName: p['owner'] ?? 'You',
          source: MusicSource.subsonic,
        ));
      }
      
      print('[HiFi] Found ${playlists.length} playlists');
      return playlists;
    } catch (e) {
      print('[HiFi] getPlaylists error: $e');
      return [];
    }
  }

  // ============ CONVERSION HELPERS ============

  /// Safely parse int from dynamic value (handles String or int)
  int _parseInt(dynamic value, [int defaultValue = 0]) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  Track _trackFromSubsonic(Map<String, dynamic> s) {
    // Build FULL cover art URL immediately
    final coverArtUrl = getCoverArtUrl(s['coverArt']?.toString());
    
    return Track(
      id: 'subsonic:${s['id']}',
      title: s['title']?.toString() ?? 'Unknown',
      artist: s['artist']?.toString() ?? 'Unknown Artist',
      artistId: s['artistId']?.toString() ?? '',
      album: s['album']?.toString() ?? 'Unknown Album',
      albumId: 'subsonic:${s['albumId'] ?? ''}',
      duration: Duration(seconds: _parseInt(s['duration'])),
      coverArtUrl: coverArtUrl,
      trackNumber: _parseInt(s['track'], 1),
      isExplicit: false,
      source: MusicSource.subsonic,
    );
  }

  Album _albumFromSubsonic(Map<String, dynamic> a) {
    // Build FULL cover art URL immediately
    final coverArtUrl = getCoverArtUrl(a['coverArt']?.toString());
    
    // Safely parse year
    int? year;
    final yearVal = a['year'];
    if (yearVal != null) {
      year = _parseInt(yearVal);
      if (year == 0) year = null;
    }
    
    return Album(
      id: 'subsonic:${a['id']}',
      title: a['name']?.toString() ?? a['title']?.toString() ?? 'Unknown Album',
      artist: a['artist']?.toString() ?? 'Unknown Artist',
      artistId: a['artistId']?.toString() ?? '',
      coverArtUrl: coverArtUrl,
      year: year,
      trackCount: _parseInt(a['songCount']),
      source: MusicSource.subsonic,
    );
  }

  Artist _artistFromSubsonic(Map<String, dynamic> a) {
    // Build FULL cover art URL immediately
    final coverArtUrl = getCoverArtUrl(a['coverArt']?.toString());
    
    return Artist(
      id: 'subsonic:${a['id']}',
      name: a['name']?.toString() ?? 'Unknown Artist',
      imageUrl: coverArtUrl,
      source: MusicSource.subsonic,
    );
  }
}
