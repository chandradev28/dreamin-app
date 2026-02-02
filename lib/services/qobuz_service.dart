import 'dart:convert';
import 'package:dio/dio.dart';
import '../models/models.dart';
import 'music_service.dart';

/// Qobuz Service Implementation
/// Uses qobuz.squid.wtf as primary with dab.yeet.su and dabmusic.xyz as fallbacks
/// Provides 24-bit Hi-Res FLAC streaming
class QobuzServiceImpl implements MusicService {
  static const _searchUrl = 'https://qobuz.squid.wtf/api/get-music';
  static const _albumUrl = 'https://qobuz.squid.wtf/api/get-album';
  static const _artistUrl = 'https://qobuz.squid.wtf/api/get-artist';
  static const _playlistUrl = 'https://qobuz.squid.wtf/api/get-playlist';
  
  // Fallback search endpoints
  static const _searchFallbacks = [
    'https://dab.yeet.su/api/search',
    'https://dabmusic.xyz/api/search',
  ];
  
  // Stream endpoints with fallback - quality 27 = 24-bit/192kHz (MAX)
  static const _streamEndpoints = [
    {'url': 'https://qobuz.squid.wtf/api/download-music', 'param': 'track_id'},
    {'url': 'https://dab.yeet.su/api/stream', 'param': 'trackId', 'quality': '27'},
    {'url': 'https://dabmusic.xyz/api/stream', 'param': 'trackId', 'quality': '27'},
  ];

  final Dio _dio;

  QobuzServiceImpl() : _dio = Dio() {
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 15);
  }

  @override
  MusicSource get source => MusicSource.qobuz;

  // ============== SEARCH ==============

  @override
  Future<SearchResult> search(String query, {int limit = 30}) async {
    print('🔍 Qobuz search: $query');
    
    try {
      // Try primary squid.wtf endpoint
      final response = await _dio.get(
        _searchUrl,
        queryParameters: {'q': query, 'offset': 0},
      );
      
      print('📡 Qobuz response status: ${response.statusCode}');
      print('📡 Qobuz response type: ${response.data.runtimeType}');
      
      if (response.statusCode == 200) {
        final result = _parseSquidSearchResult(response.data);
        print('✅ Qobuz parsed: ${result.tracks.length} tracks, ${result.albums.length} albums, ${result.artists.length} artists');
        return result;
      }
    } catch (e) {
      print('⚠️ Qobuz primary search failed: $e');
    }

    // Try fallback endpoints
    for (final fallback in _searchFallbacks) {
      try {
        print('🔄 Trying fallback: $fallback');
        final response = await _dio.get(
          fallback,
          queryParameters: {'q': query},
        ).timeout(const Duration(seconds: 8));
        
        if (response.statusCode == 200) {
          final result = _parseDabSearchResult(response.data);
          print('✅ Fallback parsed: ${result.tracks.length} tracks');
          return result;
        }
      } catch (e) {
        print('⚠️ Qobuz fallback $fallback failed: $e');
      }
    }

    print('❌ All Qobuz endpoints failed');
    return const SearchResult(
      tracks: [],
      albums: [],
      artists: [],
      playlists: [],
      source: MusicSource.qobuz,
    );
  }

  /// Parse squid.wtf response format
  SearchResult _parseSquidSearchResult(dynamic json) {
    final data = json is Map ? (json['data'] ?? json) : {};
    
    final tracks = <Track>[];
    final albums = <Album>[];
    final artists = <Artist>[];
    final playlists = <Playlist>[];

    // Parse tracks
    final trackItems = data['tracks']?['items'] as List? ?? [];
    for (final t in trackItems) {
      tracks.add(_trackFromSquid(t));
    }

    // Parse albums
    final albumItems = data['albums']?['items'] as List? ?? [];
    for (final a in albumItems) {
      albums.add(_albumFromSquid(a));
    }

    // Parse artists
    final artistItems = data['artists']?['items'] as List? ?? [];
    for (final a in artistItems) {
      artists.add(_artistFromSquid(a));
    }

    // Parse playlists
    final playlistItems = data['playlists']?['items'] as List? ?? [];
    for (final p in playlistItems) {
      playlists.add(_playlistFromSquid(p));
    }

    return SearchResult(
      tracks: tracks,
      albums: albums,
      artists: artists,
      playlists: playlists,
      source: MusicSource.qobuz,
    );
  }

  /// Parse dab/dabmusic response format
  SearchResult _parseDabSearchResult(dynamic json) {
    final tracks = <Track>[];
    final albums = <Album>[];

    if (json is! Map) {
      return const SearchResult(tracks: [], albums: [], artists: [], playlists: [], source: MusicSource.qobuz);
    }

    // Parse tracks (flat array in dab format)
    final trackList = json['tracks'] as List? ?? [];
    for (final t in trackList) {
      tracks.add(_trackFromDab(t));
    }

    // Parse albums if present
    final albumList = json['albums'] as List? ?? [];
    for (final a in albumList) {
      albums.add(_albumFromDab(a));
    }

    return SearchResult(
      tracks: tracks,
      albums: albums,
      artists: const [],
      playlists: const [],
      source: MusicSource.qobuz,
    );
  }

  @override
  Future<List<Track>> searchTracks(String query, {int limit = 30}) async {
    final result = await search(query, limit: limit);
    return result.tracks;
  }

  @override
  Future<List<Album>> searchAlbums(String query, {int limit = 20}) async {
    final result = await search(query, limit: limit);
    return result.albums;
  }

  @override
  Future<List<Artist>> searchArtists(String query, {int limit = 20}) async {
    final result = await search(query, limit: limit);
    return result.artists;
  }

  @override
  Future<List<Playlist>> searchPlaylists(String query, {int limit = 20}) async {
    final result = await search(query, limit: limit);
    return result.playlists;
  }

  // ============== DETAILS ==============

  @override
  Future<AlbumDetail?> getAlbum(String id) async {
    try {
      // Remove 'qobuz:' prefix if present
      final albumId = id.replaceFirst('qobuz:', '');
      final response = await _dio.get(
        _albumUrl,
        queryParameters: {'album_id': albumId},
      );
      
      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        return _albumDetailFromSquid(data);
      }
    } catch (e) {
      print('❌ Qobuz getAlbum failed: $e');
    }
    return null;
  }

  @override
  Future<ArtistDetail?> getArtist(String id) async {
    try {
      final artistId = id.replaceFirst('qobuz:', '');
      print('🎤 Fetching Qobuz artist: $artistId');
      
      final response = await _dio.get(
        _artistUrl,
        queryParameters: {'artist_id': artistId},
      );
      
      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        final artistData = data['artist'] ?? data;
        
        // Get artist biography
        final bio = artistData['biography'];
        final bioContent = bio is Map ? (bio['content'] ?? '') : '';
        
        // Get artist name
        final name = artistData['name'];
        final displayName = name is Map ? (name['display'] ?? 'Unknown') : (name ?? 'Unknown');
        
        // Get image
        final picture = artistData['picture'] ??
            artistData['image']?['large'] ??
            artistData['image']?['small'] ?? '';
        
        print('✅ Qobuz artist loaded: $displayName');
        
        // Search for artist albums
        final albumsResult = await searchAlbums(displayName.toString(), limit: 20);
        
        return ArtistDetail(
          id: 'qobuz:$artistId',
          name: displayName.toString(),
          imageUrl: picture.toString(),
          bio: bioContent.toString(),
          albums: albumsResult,
          topTracks: const [],
          source: MusicSource.qobuz,
        );
      }
    } catch (e) {
      print('❌ Qobuz getArtist failed: $e');
    }
    return null;
  }

  @override
  Future<PlaylistDetail?> getPlaylist(String id) async {
    try {
      final playlistId = id.replaceFirst('qobuz:', '');
      final response = await _dio.get(
        _playlistUrl,
        queryParameters: {'id': playlistId, 'offset': 0, 'limit': 100},
      );
      
      if (response.statusCode == 200) {
        return _playlistDetailFromSquid(response.data, playlistId);
      }
    } catch (e) {
      print('❌ Qobuz getPlaylist failed: $e');
    }
    return null;
  }

  // ============== STREAMING ==============

  @override
  Future<String?> getStreamUrl(String trackId) async {
    final cleanId = trackId.replaceFirst('qobuz:', '');
    
    for (final endpoint in _streamEndpoints) {
      try {
        final params = <String, dynamic>{
          endpoint['param']!: cleanId,
        };
        if (endpoint['quality'] != null) {
          params['quality'] = endpoint['quality'];
        }
        
        final response = await _dio.get(
          endpoint['url']!,
          queryParameters: params,
        ).timeout(const Duration(seconds: 8));
        
        if (response.statusCode == 200) {
          final data = response.data;
          final streamUrl = data['url'] ?? data['data']?['url'];
          if (streamUrl != null && streamUrl.toString().isNotEmpty) {
            print('✅ Got Qobuz stream from ${endpoint['url']}');
            return streamUrl;
          }
        }
      } catch (e) {
        print('⚠️ Stream endpoint ${endpoint['url']} failed: $e');
      }
    }
    
    print('❌ All Qobuz stream endpoints failed for track $cleanId');
    return null;
  }

  @override
  String getCoverArt(String? id, {int size = 300}) {
    // Qobuz cover URLs are returned directly in the API response
    // This method is for when we only have an ID
    if (id == null || id.isEmpty) {
      return '';
    }
    // If it's already a full URL, return it
    if (id.startsWith('http')) {
      return id;
    }
    return '';
  }

  // ============== DISCOVERY (optional) ==============

  @override
  Future<List<Album>> getNewAlbums({int limit = 20}) async {
    // Qobuz doesn't have a dedicated new albums endpoint
    // Search for popular/new content as fallback
    final result = await search('new releases 2024', limit: limit);
    return result.albums;
  }

  @override
  Future<List<Playlist>> getPopularPlaylists({int limit = 20}) async {
    // Search for playlists as fallback
    final result = await search('best hits', limit: limit);
    return result.playlists;
  }

  @override
  Future<List<Track>> getRandomTracks({int limit = 20}) async {
    // Get trending/popular tracks as fallback
    final result = await search('popular 2024', limit: limit);
    return result.tracks;
  }

  // ============== MODEL CONVERSIONS (squid.wtf format) ==============

  Track _trackFromSquid(Map<String, dynamic> t) {
    final performer = t['performer'] as Map<String, dynamic>? ?? {};
    final album = t['album'] as Map<String, dynamic>? ?? {};
    final image = album['image'] as Map<String, dynamic>? ?? {};

    return Track(
      id: 'qobuz:${t['id']}',
      title: t['title'] ?? 'Unknown',
      artist: performer['name'] ?? 'Unknown Artist',
      artistId: performer['id']?.toString() ?? '',
      album: album['title'] ?? 'Unknown Album',
      albumId: album['id']?.toString() ?? '',
      duration: Duration(seconds: t['duration'] ?? 0),
      trackNumber: t['track_number'] ?? 1,
      coverArtUrl: image['large'] ?? image['small'] ?? '',
      isExplicit: false,
      source: MusicSource.qobuz,
    );
  }

  Album _albumFromSquid(Map<String, dynamic> a) {
    final artist = a['artist'] as Map<String, dynamic>? ?? {};
    final image = a['image'] as Map<String, dynamic>? ?? {};

    return Album(
      id: 'qobuz:${a['id']}',
      title: a['title'] ?? a['name'] ?? 'Unknown Album',
      artist: artist['name'] ?? 'Unknown Artist',
      artistId: artist['id']?.toString() ?? '',
      coverArtUrl: image['large'] ?? image['small'] ?? '',
      year: _parseYear(a['release_date_original']),
      trackCount: a['tracks_count'] ?? 0,
      source: MusicSource.qobuz,
    );
  }

  Artist _artistFromSquid(Map<String, dynamic> a) {
    final image = a['image'] as Map<String, dynamic>? ?? {};

    return Artist(
      id: 'qobuz:${a['id']}',
      name: a['name'] ?? 'Unknown Artist',
      imageUrl: image['large'] ?? image['small'] ?? '',
      source: MusicSource.qobuz,
    );
  }

  Playlist _playlistFromSquid(Map<String, dynamic> p) {
    final images = p['images'] as Map<String, dynamic>? ?? {};

    return Playlist(
      id: 'qobuz:${p['id']}',
      title: p['name'] ?? 'Unknown Playlist',
      description: p['description'] ?? '',
      coverArtUrl: images['large'] ?? images['small'] ?? '',
      trackCount: p['tracks_count'] ?? 0,
      source: MusicSource.qobuz,
    );
  }

  AlbumDetail _albumDetailFromSquid(Map<String, dynamic> data) {
    final artist = data['artist'] as Map<String, dynamic>? ?? {};
    final image = data['image'] as Map<String, dynamic>? ?? {};
    final tracksData = data['tracks'] as Map<String, dynamic>? ?? {};
    final trackItems = tracksData['items'] as List? ?? [];

    final tracks = trackItems.map((t) => _trackFromSquid(t)).toList();

    return AlbumDetail(
      id: 'qobuz:${data['id']}',
      title: data['title'] ?? data['name'] ?? 'Unknown Album',
      artist: artist['name'] ?? 'Unknown Artist',
      artistId: artist['id']?.toString() ?? '',
      coverArtUrl: image['large'] ?? image['small'] ?? '',
      year: _parseYear(data['release_date_original']),
      trackCount: tracks.length,
      tracks: tracks,
      source: MusicSource.qobuz,
    );
  }

  PlaylistDetail _playlistDetailFromSquid(Map<String, dynamic> json, String playlistId) {
    final tracksData = json['tracks'] as Map<String, dynamic>? ?? {};
    final trackItems = tracksData['items'] as List? ?? [];

    final tracks = trackItems.map((t) => _trackFromSquid(t)).toList();

    return PlaylistDetail(
      id: 'qobuz:$playlistId',
      title: json['name'] ?? 'Playlist',
      description: json['description'] ?? '',
      coverArtUrl: tracks.isNotEmpty ? tracks.first.coverArtUrl : '',
      trackCount: tracks.length,
      tracks: tracks,
      source: MusicSource.qobuz,
    );
  }

  // ============== MODEL CONVERSIONS (dab/dabmusic format) ==============

  Track _trackFromDab(Map<String, dynamic> t) {
    return Track(
      id: 'qobuz:${t['id']}',
      title: t['title'] ?? 'Unknown',
      artist: t['artist'] ?? 'Unknown Artist',
      artistId: t['artistId']?.toString() ?? '',
      album: t['albumTitle'] ?? 'Unknown Album',
      albumId: t['albumId']?.toString() ?? '',
      duration: Duration(seconds: t['duration'] ?? 0),
      trackNumber: 1,
      coverArtUrl: t['albumCover'] ?? '',
      isExplicit: t['parental_warning'] ?? false,
      source: MusicSource.qobuz,
    );
  }

  Album _albumFromDab(Map<String, dynamic> a) {
    return Album(
      id: 'qobuz:${a['id']}',
      title: a['title'] ?? 'Unknown Album',
      artist: a['artist'] ?? 'Unknown Artist',
      artistId: a['artistId']?.toString() ?? '',
      coverArtUrl: a['cover'] ?? a['albumCover'] ?? '',
      year: _parseYear(a['releaseDate']),
      trackCount: a['tracksCount'] ?? 0,
      source: MusicSource.qobuz,
    );
  }

  int? _parseYear(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    try {
      return int.parse(dateStr.split('-').first);
    } catch (_) {
      return null;
    }
  }
}
