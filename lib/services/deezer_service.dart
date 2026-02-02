import 'package:dio/dio.dart';
import '../models/models.dart';
import 'music_service.dart';

/// Deezer Service Implementation
/// Uses deezer-api-orpin.vercel.app for metadata and streaming
class DeezerServiceImpl implements MusicService {
  static const _baseUrl = 'https://deezer-api-orpin.vercel.app';
  
  final Dio _dio;

  DeezerServiceImpl() : _dio = Dio() {
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 15);
  }

  @override
  MusicSource get source => MusicSource.deezer;

  // ============== SEARCH ==============

  @override
  Future<SearchResult> search(String query, {int limit = 30}) async {
    print('🔍 Deezer search: $query');
    
    try {
      final response = await _dio.get(
        '$_baseUrl/search',
        queryParameters: {'q': query},
      );
      
      if (response.statusCode == 200) {
        return _parseSearchResult(response.data);
      }
    } catch (e) {
      print('❌ Deezer search failed: $e');
    }

    return const SearchResult(source: MusicSource.deezer);
  }

  @override
  Future<List<Track>> searchTracks(String query, {int limit = 20}) async {
    final result = await search(query);
    return result.tracks.take(limit).toList();
  }

  @override
  Future<List<Album>> searchAlbums(String query, {int limit = 20}) async {
    final result = await search(query);
    return result.albums.take(limit).toList();
  }

  @override
  Future<List<Artist>> searchArtists(String query, {int limit = 20}) async {
    final result = await search(query);
    return result.artists.take(limit).toList();
  }

  @override
  Future<List<Playlist>> searchPlaylists(String query, {int limit = 20}) async {
    // Deezer search doesn't return playlists in our API
    return [];
  }

  // ============== DETAILS ==============

  @override
  Future<AlbumDetail?> getAlbum(String id) async {
    try {
      final albumId = id.replaceFirst('deezer:', '');
      print('💿 Fetching Deezer album: $albumId');
      
      final response = await _dio.get('$_baseUrl/album/$albumId');
      
      if (response.statusCode == 200) {
        return _albumDetailFromDeezer(response.data);
      }
    } catch (e) {
      print('❌ Deezer getAlbum failed: $e');
    }
    return null;
  }

  @override
  Future<ArtistDetail?> getArtist(String id) async {
    try {
      final artistId = id.replaceFirst('deezer:', '');
      print('🎤 Fetching Deezer artist: $artistId');
      
      final response = await _dio.get('$_baseUrl/artist/$artistId');
      
      if (response.statusCode == 200) {
        return _artistDetailFromDeezer(response.data);
      }
    } catch (e) {
      print('❌ Deezer getArtist failed: $e');
    }
    return null;
  }

  @override
  Future<PlaylistDetail?> getPlaylist(String id) async {
    try {
      final playlistId = id.replaceFirst('deezer:', '');
      print('📋 Fetching Deezer playlist: $playlistId');
      
      final response = await _dio.get('$_baseUrl/playlist/$playlistId');
      
      if (response.statusCode == 200) {
        return _playlistDetailFromDeezer(response.data);
      }
    } catch (e) {
      print('❌ Deezer getPlaylist failed: $e');
    }
    return null;
  }

  // ============== STREAMING ==============

  @override
  Future<String?> getStreamUrl(String trackId) async {
    try {
      final cleanId = trackId.replaceFirst('deezer:', '');
      print('🎵 Getting Deezer stream for: $cleanId');
      
      final response = await _dio.get('$_baseUrl/track/$cleanId');
      
      if (response.statusCode == 200) {
        final data = response.data;
        
        // Check for MEDIA array with stream URLs
        final media = data['MEDIA'] as List?;
        if (media != null && media.isNotEmpty) {
          for (final m in media) {
            final href = m['HREF'] as String?;
            if (href != null && href.isNotEmpty) {
              if (m['TYPE'] != 'preview') {
                print('✅ Got Deezer full stream');
                return href;
              }
            }
          }
          // Fallback to preview
          final preview = media.firstWhere(
            (m) => m['TYPE'] == 'preview' && m['HREF'] != null,
            orElse: () => null,
          );
          if (preview != null) {
            print('⚠️ Using Deezer preview (30s)');
            return preview['HREF'];
          }
        }
      }
    } catch (e) {
      print('❌ Deezer getStreamUrl failed: $e');
    }
    
    return null;
  }

  @override
  String getCoverArt(String? id, {int size = 300}) {
    if (id == null || id.isEmpty) return '';
    if (id.startsWith('http')) return id;
    return 'https://e-cdns-images.dzcdn.net/images/cover/$id/${size}x$size.jpg';
  }

  // ============== DISCOVERY (uses curated search) ==============

  @override
  Future<List<Album>> getNewAlbums({int limit = 20}) async {
    return searchAlbums('new releases 2026', limit: limit);
  }

  @override
  Future<List<Playlist>> getPopularPlaylists({int limit = 20}) async {
    // Deezer API doesn't return playlists in search
    return [];
  }

  @override
  Future<List<Track>> getRandomTracks({int limit = 20}) async {
    return searchTracks('top hits', limit: limit);
  }

  // ============== PARSING ==============

  SearchResult _parseSearchResult(dynamic json) {
    final tracks = <Track>[];
    final albums = <Album>[];
    final artists = <Artist>[];

    // Parse TRACK results
    final trackData = json['TRACK']?['data'] as List? ?? [];
    for (final t in trackData) {
      tracks.add(_trackFromDeezer(t));
    }

    // Parse ALBUM results
    final albumData = json['ALBUM']?['data'] as List? ?? [];
    for (final a in albumData) {
      albums.add(_albumFromDeezer(a));
    }

    // Parse ARTIST results
    final artistData = json['ARTIST']?['data'] as List? ?? [];
    for (final a in artistData) {
      artists.add(_artistFromDeezer(a));
    }

    print('✅ Deezer parsed: ${tracks.length} tracks, ${albums.length} albums, ${artists.length} artists');

    return SearchResult(
      tracks: tracks,
      albums: albums,
      artists: artists,
      playlists: const [],
      source: MusicSource.deezer,
    );
  }

  Track _trackFromDeezer(Map<String, dynamic> json) {
    final sngId = json['SNG_ID']?.toString() ?? '';
    final artId = json['ART_ID']?.toString() ?? '';
    final albId = json['ALB_ID']?.toString() ?? '';
    
    // Get artist name
    final artists = json['ARTISTS'] as List?;
    final artistName = artists?.isNotEmpty == true 
        ? artists!.first['ART_NAME']?.toString() ?? json['ART_NAME']?.toString() ?? 'Unknown'
        : json['ART_NAME']?.toString() ?? 'Unknown';
    
    // Get cover art
    final albPicture = json['ALB_PICTURE']?.toString() ?? '';
    final coverUrl = albPicture.isNotEmpty 
        ? 'https://e-cdns-images.dzcdn.net/images/cover/$albPicture/500x500.jpg'
        : null;
    
    // Parse duration
    final durationSecs = int.tryParse(json['DURATION']?.toString() ?? '0') ?? 0;
    
    return Track(
      id: 'deezer:$sngId',
      title: json['SNG_TITLE']?.toString() ?? 'Unknown',
      artist: artistName,
      artistId: 'deezer:$artId',
      album: json['ALB_TITLE']?.toString() ?? 'Unknown',
      albumId: 'deezer:$albId',
      duration: Duration(seconds: durationSecs),
      trackNumber: int.tryParse(json['TRACK_NUMBER']?.toString() ?? '1') ?? 1,
      coverArtUrl: coverUrl,
      source: MusicSource.deezer,
    );
  }

  Album _albumFromDeezer(Map<String, dynamic> json) {
    final albId = json['ALB_ID']?.toString() ?? '';
    final artId = json['ART_ID']?.toString() ?? '';
    
    final albPicture = json['ALB_PICTURE']?.toString() ?? '';
    final coverUrl = albPicture.isNotEmpty 
        ? 'https://e-cdns-images.dzcdn.net/images/cover/$albPicture/500x500.jpg'
        : null;
    
    // Parse year from release date
    final releaseDate = json['DIGITAL_RELEASE_DATE']?.toString() ?? 
                        json['PHYSICAL_RELEASE_DATE']?.toString();
    int? year;
    if (releaseDate != null && releaseDate.length >= 4) {
      year = int.tryParse(releaseDate.substring(0, 4));
    }
    
    return Album(
      id: 'deezer:$albId',
      title: json['ALB_TITLE']?.toString() ?? 'Unknown',
      artist: json['ART_NAME']?.toString() ?? 'Unknown',
      artistId: 'deezer:$artId',
      coverArtUrl: coverUrl,
      year: year,
      trackCount: int.tryParse(json['NUMBER_TRACK']?.toString() ?? '0') ?? 0,
      source: MusicSource.deezer,
    );
  }

  Artist _artistFromDeezer(Map<String, dynamic> json) {
    final artId = json['ART_ID']?.toString() ?? '';
    
    final artPicture = json['ART_PICTURE']?.toString() ?? '';
    final imageUrl = artPicture.isNotEmpty 
        ? 'https://e-cdns-images.dzcdn.net/images/artist/$artPicture/500x500.jpg'
        : null;
    
    return Artist(
      id: 'deezer:$artId',
      name: json['ART_NAME']?.toString() ?? 'Unknown',
      imageUrl: imageUrl,
      source: MusicSource.deezer,
    );
  }

  AlbumDetail _albumDetailFromDeezer(Map<String, dynamic> json) {
    final data = json['DATA'] ?? json;
    final songsData = json['SONGS']?['data'] as List? ?? [];
    
    final albId = data['ALB_ID']?.toString() ?? '';
    final artId = data['ART_ID']?.toString() ?? '';
    
    final albPicture = data['ALB_PICTURE']?.toString() ?? '';
    final coverUrl = albPicture.isNotEmpty 
        ? 'https://e-cdns-images.dzcdn.net/images/cover/$albPicture/500x500.jpg'
        : null;
    
    final tracks = songsData.map((t) => _trackFromDeezer(t as Map<String, dynamic>)).toList();
    
    // Parse year
    final releaseDate = data['DIGITAL_RELEASE_DATE']?.toString() ?? 
                        data['PHYSICAL_RELEASE_DATE']?.toString();
    int? year;
    if (releaseDate != null && releaseDate.length >= 4) {
      year = int.tryParse(releaseDate.substring(0, 4));
    }
    
    // Parse duration
    final durationSecs = int.tryParse(data['DURATION']?.toString() ?? '0') ?? 0;
    
    return AlbumDetail(
      id: 'deezer:$albId',
      title: data['ALB_TITLE']?.toString() ?? 'Unknown',
      artist: data['ART_NAME']?.toString() ?? 'Unknown',
      artistId: 'deezer:$artId',
      coverArtUrl: coverUrl,
      year: year,
      trackCount: tracks.length,
      tracks: tracks,
      duration: Duration(seconds: durationSecs),
      copyright: data['COPYRIGHT']?.toString(),
      source: MusicSource.deezer,
    );
  }

  ArtistDetail _artistDetailFromDeezer(Map<String, dynamic> json) {
    final data = json['DATA'] ?? json;
    final topData = json['TOP']?['data'] as List? ?? [];
    
    final artId = data['ART_ID']?.toString() ?? '';
    
    final artPicture = data['ART_PICTURE']?.toString() ?? '';
    final imageUrl = artPicture.isNotEmpty 
        ? 'https://e-cdns-images.dzcdn.net/images/artist/$artPicture/500x500.jpg'
        : null;
    
    final topTracks = topData.map((t) => _trackFromDeezer(t as Map<String, dynamic>)).toList();
    
    return ArtistDetail(
      id: 'deezer:$artId',
      name: data['ART_NAME']?.toString() ?? 'Unknown',
      imageUrl: imageUrl,
      albums: const [],
      topTracks: topTracks,
      source: MusicSource.deezer,
    );
  }

  PlaylistDetail _playlistDetailFromDeezer(Map<String, dynamic> json) {
    final data = json['DATA'] ?? json;
    final songsData = json['SONGS']?['data'] as List? ?? [];
    
    final playlistId = data['PLAYLIST_ID']?.toString() ?? '';
    
    final picture = data['PLAYLIST_PICTURE']?.toString() ?? '';
    final coverUrl = picture.isNotEmpty 
        ? 'https://e-cdns-images.dzcdn.net/images/playlist/$picture/500x500.jpg'
        : null;
    
    final tracks = songsData.map((t) => _trackFromDeezer(t as Map<String, dynamic>)).toList();
    
    // Parse duration
    final durationSecs = int.tryParse(data['DURATION']?.toString() ?? '0') ?? 0;
    
    return PlaylistDetail(
      id: 'deezer:$playlistId',
      title: data['TITLE']?.toString() ?? 'Unknown',
      description: data['DESCRIPTION']?.toString(),
      coverArtUrl: coverUrl,
      trackCount: tracks.length,
      tracks: tracks,
      duration: Duration(seconds: durationSecs),
      source: MusicSource.deezer,
    );
  }
}
