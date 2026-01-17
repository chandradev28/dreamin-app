import 'dart:convert';
import 'dart:math';
import 'package:dio/dio.dart';
import '../core/constants/api_constants.dart';
import '../models/models.dart';

/// Audio Quality Levels for TIDAL
enum TidalQuality {
  /// Standard quality (320kbps AAC)
  standard('LOW'),
  /// High quality (16-bit/44.1kHz FLAC)
  high('HIGH'),
  /// HiFi quality (16-bit/44.1kHz FLAC lossless)
  hifi('LOSSLESS'),
  /// Master quality (24-bit/up to 192kHz MQA)
  master('HI_RES_LOSSLESS');

  final String apiValue;
  const TidalQuality(this.apiValue);
}

/// TIDAL API Service - ACTIVE
/// Uses hifi-api format with working endpoints
/// Load balanced with random starting endpoint
class TidalService {
  final Dio _dio;
  int _currentEndpointIndex;
  final Map<int, int> _endpointFailureCount = {};
  static final Random _random = Random();
  
  /// Default to Master quality, falls back to HiFi
  TidalQuality preferredQuality = TidalQuality.master;

  TidalService() : 
    _dio = Dio(),
    // Random starting endpoint for load balancing
    _currentEndpointIndex = _random.nextInt(TidalEndpoints.endpoints.length) {
    _dio.options.connectTimeout = const Duration(seconds: 15);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    _dio.options.headers = {
      'Accept': 'application/json',
      'User-Agent': 'DreaminApp/1.0',
    };
  }

  String get _currentEndpoint => TidalEndpoints.endpoints[_currentEndpointIndex];

  /// Try next endpoint in the fallback list
  void _switchToNextEndpoint() {
    _endpointFailureCount[_currentEndpointIndex] = 
        (_endpointFailureCount[_currentEndpointIndex] ?? 0) + 1;
    
    _currentEndpointIndex = 
        (_currentEndpointIndex + 1) % TidalEndpoints.endpoints.length;
  }

  /// Execute request with automatic fallback
  Future<Response<T>> _executeWithFallback<T>(
    Future<Response<T>> Function(String baseUrl) request,
  ) async {
    int attempts = 0;
    final maxAttempts = TidalEndpoints.endpoints.length;
    Exception? lastError;

    while (attempts < maxAttempts) {
      try {
        final response = await request(_currentEndpoint);
        return response;
      } catch (e) {
        lastError = e as Exception;
        attempts++;
        if (attempts < maxAttempts) {
          _switchToNextEndpoint();
        }
      }
    }

    throw TidalApiException('All endpoints failed: $lastError');
  }

  // ==================== SEARCH ====================

  /// Search for tracks
  Future<List<Track>> searchTracks(String query, {int limit = 25}) async {
    try {
      final response = await _executeWithFallback((baseUrl) {
        return _dio.get(
          '$baseUrl${TidalEndpoints.searchPath}',
          queryParameters: {'s': query},  // hifi-api uses 's' for track search
        );
      });

      final data = response.data;
      List<dynamic> items = [];
      
      if (data is Map<String, dynamic>) {
        if (data['data'] is Map && data['data']['items'] is List) {
          items = data['data']['items'] as List;
        } else if (data['data'] is Map && data['data']['tracks'] is List) {
          items = data['data']['tracks'] as List;
        } else if (data['tracks'] is Map && data['tracks']['items'] is List) {
          items = data['tracks']['items'] as List;
        } else if (data['tracks'] is List) {
          items = data['tracks'] as List;
        } else if (data['items'] is List) {
          items = data['items'] as List;
        }
      } else if (data is List) {
        items = data;
      }
      
      final result = <Track>[];
      for (final t in items.take(limit)) {
        if (t is Map<String, dynamic>) {
          try {
            result.add(Track.fromTidalJson(t));
          } catch (_) {}
        }
      }
      return result;
    } catch (e) {
      throw TidalApiException('Track search failed: $e');
    }
  }

  /// Search for tracks by ISRC (more precise matching)
  /// Used as fallback when regular search doesn't find exact match
  Future<Track?> searchTrackByIsrc(String isrc) async {
    try {
      // Search using ISRC as query - Tidal will return exact match if found
      final response = await _executeWithFallback((baseUrl) {
        return _dio.get(
          '$baseUrl${TidalEndpoints.searchPath}',
          queryParameters: {'s': isrc},
        );
      });

      final data = response.data;
      List<dynamic> items = [];
      
      if (data is Map<String, dynamic>) {
        if (data['data'] is Map && data['data']['items'] is List) {
          items = data['data']['items'] as List;
        } else if (data['items'] is List) {
          items = data['items'] as List;
        }
      }

      // Look for track with matching ISRC
      for (final item in items) {
        if (item is Map<String, dynamic>) {
          final trackIsrc = item['isrc'] as String?;
          if (trackIsrc != null && trackIsrc.toUpperCase() == isrc.toUpperCase()) {
            return Track.fromTidalJson(item);
          }
        }
      }

      // If no exact ISRC match, return first result (still a good match)
      if (items.isNotEmpty && items.first is Map<String, dynamic>) {
        return Track.fromTidalJson(items.first as Map<String, dynamic>);
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Search for albums
  Future<List<Album>> searchAlbums(String query, {int limit = 20}) async {
    try {
      final response = await _executeWithFallback((baseUrl) {
        return _dio.get(
          '$baseUrl${TidalEndpoints.searchPath}',
          queryParameters: {'al': query},  // hifi-api uses 'al' for album search
        );
      });

      final data = response.data;
      List<dynamic> items = [];
      
      if (data is Map<String, dynamic>) {
        // Try various response structures
        if (data['data'] is Map && data['data']['albums'] is List) {
          items = data['data']['albums'] as List;
        } else if (data['data'] is Map && data['data']['albums'] is Map && data['data']['albums']['items'] is List) {
          items = data['data']['albums']['items'] as List;
        } else if (data['albums'] is Map && data['albums']['items'] is List) {
          items = data['albums']['items'] as List;
        } else if (data['albums'] is List) {
          items = data['albums'] as List;
        } else if (data['items'] is List) {
          items = data['items'] as List;
        }
      } else if (data is List) {
        items = data;
      }
      
      final result = <Album>[];
      for (final a in items.take(limit)) {
        if (a is Map<String, dynamic>) {
          try {
            result.add(Album.fromTidalJson(a));
          } catch (_) {}
        }
      }
      return result;
    } catch (e) {
      throw TidalApiException('Album search failed: $e');
    }
  }

  /// Search for artists
  Future<List<Artist>> searchArtists(String query, {int limit = 20}) async {
    try {
      final response = await _executeWithFallback((baseUrl) {
        return _dio.get(
          '$baseUrl${TidalEndpoints.searchPath}',
          queryParameters: {'a': query},  // hifi-api uses 'a' for artist search
        );
      });

      final data = response.data;
      List<dynamic> items = [];
      
      // Handle various response formats
      if (data is Map<String, dynamic>) {
        // Try different paths where artists might be
        if (data['data'] is Map && data['data']['artists'] is List) {
          items = data['data']['artists'] as List;
        } else if (data['artists'] is Map && data['artists']['items'] is List) {
          items = data['artists']['items'] as List;
        } else if (data['artists'] is List) {
          items = data['artists'] as List;
        } else if (data['items'] is List) {
          items = data['items'] as List;
        }
      } else if (data is List) {
        items = data;
      }
      
      final result = <Artist>[];
      for (final a in items.take(limit)) {
        if (a is Map<String, dynamic>) {
          try {
            result.add(Artist.fromTidalJson(a));
          } catch (_) {}
        }
      }
      return result;
    } catch (e) {
      throw TidalApiException('Artist search failed: $e');
    }
  }

  /// Search for playlists (TIDAL curated playlists like "Songs of the Year")
  Future<List<Playlist>> searchPlaylists(String query, {int limit = 25}) async {
    try {
      final response = await _executeWithFallback((baseUrl) {
        return _dio.get(
          '$baseUrl${TidalEndpoints.searchPath}',
          queryParameters: {'p': query},  // 'p' for playlist search
        );
      });

      final data = response.data;
      List<dynamic> items = [];
      
      if (data is Map<String, dynamic>) {
        if (data['data'] is Map && data['data']['playlists'] is Map && data['data']['playlists']['items'] is List) {
          items = data['data']['playlists']['items'] as List;
        } else if (data['data'] is Map && data['data']['playlists'] is List) {
          items = data['data']['playlists'] as List;
        } else if (data['playlists'] is Map && data['playlists']['items'] is List) {
          items = data['playlists']['items'] as List;
        } else if (data['playlists'] is List) {
          items = data['playlists'] as List;
        } else if (data['items'] is List) {
          items = data['items'] as List;
        }
      } else if (data is List) {
        items = data;
      }
      
      final result = <Playlist>[];
      for (final p in items.take(limit)) {
        if (p is Map<String, dynamic>) {
          try {
            result.add(Playlist.fromTidalJson(p));
          } catch (_) {}
        }
      }
      return result;
    } catch (e) {
      throw TidalApiException('Playlist search failed: $e');
    }
  }

  /// Get "Songs of the Year" playlists
  Future<List<Playlist>> getSongsOfTheYearPlaylists({int limit = 10}) async {
    return searchPlaylists('songs of the year', limit: limit);
  }

  /// Combined search (returns all types)
  Future<SearchResult> search(String query, {int limit = 20}) async {
    try {
      // Search all types in parallel
      final results = await Future.wait([
        searchTracks(query, limit: limit),
        searchAlbums(query, limit: limit),
        searchArtists(query, limit: limit),
        searchPlaylists(query, limit: limit),
      ]);
      
      return SearchResult(
        tracks: results[0] as List<Track>,
        albums: results[1] as List<Album>,
        artists: results[2] as List<Artist>,
        playlists: results[3] as List<Playlist>,
        source: MusicSource.tidal,
      );
    } catch (e) {
      throw TidalApiException('Search failed: $e');
    }
  }

  // ==================== ALBUM ====================

  /// Get album details with all tracks
  Future<AlbumDetail> getAlbum(String albumId) async {
    try {
      final response = await _executeWithFallback((baseUrl) {
        return _dio.get(
          '$baseUrl${TidalEndpoints.albumPath}',
          queryParameters: {'id': int.parse(albumId)},
        );
      });

      final data = response.data as Map<String, dynamic>;
      
      // Try multiple paths where album data might be
      Map<String, dynamic> albumData = {};
      if (data['data'] is Map) {
        albumData = data['data'] as Map<String, dynamic>;
      } else if (data['album'] is Map) {
        albumData = data['album'] as Map<String, dynamic>;
      } else if (data['title'] != null) {
        // Album data is directly in response
        albumData = data;
      } else {
        albumData = data;
      }
      
      // Try multiple paths where tracks might be
      List<dynamic> rawTracks = [];
      if (data['items'] is List) {
        rawTracks = data['items'] as List;
      } else if (data['tracks'] is List) {
        rawTracks = data['tracks'] as List;
      } else if (data['tracks'] is Map && data['tracks']['items'] is List) {
        rawTracks = data['tracks']['items'] as List;
      } else if (albumData['items'] is List) {
        rawTracks = albumData['items'] as List;
      } else if (albumData['tracks'] is List) {
        rawTracks = albumData['tracks'] as List;
      }
      
      // Process tracks - handle both direct track objects and wrapped items
      final List<Map<String, dynamic>> tracksData = [];
      for (final item in rawTracks) {
        if (item is Map<String, dynamic>) {
          // Check if track data is nested inside 'item' wrapper
          if (item['item'] is Map) {
            tracksData.add(item['item'] as Map<String, dynamic>);
          } else if (item['track'] is Map) {
            tracksData.add(item['track'] as Map<String, dynamic>);
          } else if (item['title'] != null) {
            // Direct track object
            tracksData.add(item);
          } else if (item['id'] != null && item['title'] == null) {
            // Might be partial track data - try to use it
            tracksData.add(item);
          }
        }
      }
      
      // If album data doesn't have id, try to extract from response
      if (albumData['id'] == null) {
        albumData['id'] = int.tryParse(albumId);
      }

      return AlbumDetail.fromTidalJson(albumData, tracksData);
    } catch (e) {
      throw TidalApiException('Failed to get album: $e');
    }
  }

  // ==================== ARTIST ====================

  /// Get artist details with albums and tracks
  Future<ArtistDetail> getArtist(String artistId) async {
    try {
      final response = await _executeWithFallback((baseUrl) {
        return _dio.get(
          '$baseUrl${TidalEndpoints.artistPath}',
          queryParameters: {'f': int.parse(artistId)},  // 'f' gives full data with albums/tracks
        );
      });

      final data = response.data as Map<String, dynamic>;
      final albumsData = data['albums']?['items'] as List<dynamic>? ?? [];
      final tracksData = data['tracks'] as List<dynamic>? ?? [];

      // Construct artist from first track or album
      String artistName = 'Unknown';
      if (tracksData.isNotEmpty) {
        final firstTrack = tracksData.first as Map<String, dynamic>;
        final artist = firstTrack['artist'] as Map<String, dynamic>?;
        artistName = artist?['name'] as String? ?? 'Unknown';
      }
      final artistData = <String, dynamic>{
        'id': artistId,
        'name': artistName,
      };

      return ArtistDetail.fromTidalJson(artistData, albumsData);
    } catch (e) {
      throw TidalApiException('Failed to get artist: $e');
    }
  }

  /// Get artist info only
  Future<Artist> getArtistInfo(String artistId) async {
    try {
      final response = await _executeWithFallback((baseUrl) {
        return _dio.get(
          '$baseUrl${TidalEndpoints.artistPath}',
          queryParameters: {'id': int.parse(artistId)},  // 'id' gives basic artist info
        );
      });

      final data = response.data as Map<String, dynamic>;
      final artistData = data['artist'] as Map<String, dynamic>? ?? data;
      return Artist.fromTidalJson(artistData);
    } catch (e) {
      throw TidalApiException('Failed to get artist info: $e');
    }
  }

  // ==================== PLAYLIST ====================

  /// Get playlist details with tracks
  Future<PlaylistDetail> getPlaylist(String playlistId) async {
    try {
      final response = await _executeWithFallback((baseUrl) {
        return _dio.get(
          '$baseUrl${TidalEndpoints.playlistPath}',
          queryParameters: {'id': playlistId},
        );
      });

      final data = response.data as Map<String, dynamic>;
      
      // Try multiple paths for playlist data
      Map<String, dynamic> playlistData = {};
      if (data['playlist'] is Map) {
        playlistData = data['playlist'] as Map<String, dynamic>;
      } else if (data['data'] is Map) {
        playlistData = data['data'] as Map<String, dynamic>;
      } else if (data['title'] != null) {
        playlistData = data;
      } else {
        playlistData = data;
      }
      
      // Try multiple paths for tracks
      List<dynamic> rawTracks = [];
      if (data['items'] is List) {
        rawTracks = data['items'] as List;
      } else if (data['tracks'] is List) {
        rawTracks = data['tracks'] as List;
      } else if (data['tracks'] is Map && data['tracks']['items'] is List) {
        rawTracks = data['tracks']['items'] as List;
      } else if (playlistData['items'] is List) {
        rawTracks = playlistData['items'] as List;
      } else if (playlistData['tracks'] is List) {
        rawTracks = playlistData['tracks'] as List;
      }
      
      // Process tracks - handle nested wrappers
      final List<Map<String, dynamic>> tracksData = [];
      for (final item in rawTracks) {
        if (item is Map<String, dynamic>) {
          if (item['item'] is Map) {
            tracksData.add(item['item'] as Map<String, dynamic>);
          } else if (item['track'] is Map) {
            tracksData.add(item['track'] as Map<String, dynamic>);
          } else if (item['title'] != null) {
            tracksData.add(item);
          } else if (item['id'] != null) {
            tracksData.add(item);
          }
        }
      }
      
      // Ensure playlist has id
      if (playlistData['uuid'] == null && playlistData['id'] == null) {
        playlistData['uuid'] = playlistId;
      }

      return PlaylistDetail.fromTidalJson(playlistData, tracksData);
    } catch (e) {
      throw TidalApiException('Failed to get playlist: $e');
    }
  }

  // ==================== TRACK & STREAMING ====================

  /// Get track info
  Future<Track> getTrack(String trackId) async {
    try {
      final response = await _executeWithFallback((baseUrl) {
        return _dio.get(
          '$baseUrl${TidalEndpoints.infoPath}',
          queryParameters: {'id': int.parse(trackId)},
        );
      });

      final data = response.data as Map<String, dynamic>;
      final trackData = data['data'] as Map<String, dynamic>? ?? data;
      return Track.fromTidalJson(trackData);
    } catch (e) {
      throw TidalApiException('Failed to get track: $e');
    }
  }

  /// Get stream URL for a track - ALWAYS HIGHEST QUALITY
  /// Tries: Master -> HiFi -> High -> Standard
  Future<StreamInfo> getStreamInfo(String trackId, {TidalQuality? quality}) async {
    final requestedQuality = quality ?? preferredQuality;
    
    try {
      // Strip any prefix (like "deezer_") and parse to int
      final numericId = int.tryParse(trackId.replaceAll(RegExp(r'[^0-9]'), ''));
      if (numericId == null || numericId == 0) {
        throw TidalApiException('Invalid track ID: $trackId');
      }
      
      final response = await _executeWithFallback((baseUrl) {
        return _dio.get(
          '$baseUrl${TidalEndpoints.trackPath}',
          queryParameters: {
            'id': numericId,
            'quality': requestedQuality.apiValue,
          },
        );
      });

      final data = response.data as Map<String, dynamic>;
      final streamInfo = StreamInfo.fromJson(data);
      
      // Validate URL is not empty
      if (streamInfo.url.isEmpty) {
        throw TidalApiException('Empty stream URL for quality: ${requestedQuality.apiValue}');
      }
      
      return streamInfo;
    } catch (e) {
      // Try next lower quality level
      final fallbackQuality = switch (requestedQuality) {
        TidalQuality.master => TidalQuality.hifi,
        TidalQuality.hifi => TidalQuality.high,
        TidalQuality.high => TidalQuality.standard,
        TidalQuality.standard => null,
      };
      
      if (fallbackQuality != null) {
        return getStreamInfo(trackId, quality: fallbackQuality);
      }
      
      throw TidalApiException('Failed to get stream at any quality: $e');
    }
  }

  /// Get stream URL only (convenience method)
  /// Validates URL is not empty
  Future<String> getStreamUrl(String trackId) async {
    final streamInfo = await getStreamInfo(trackId);
    if (streamInfo.url.isEmpty) {
      throw TidalApiException('No stream URL available for track: $trackId');
    }
    return streamInfo.url;
  }

  /// Get lyrics for a track
  Future<Lyrics?> getLyrics(String trackId) async {
    try {
      final response = await _executeWithFallback((baseUrl) {
        return _dio.get(
          '$baseUrl${TidalEndpoints.lyricsPath}',
          queryParameters: {'id': int.parse(trackId)},
        );
      });

      final data = response.data as Map<String, dynamic>;
      final lyricsData = data['lyrics'] as Map<String, dynamic>? ?? data;
      return Lyrics.fromJson(lyricsData);
    } catch (e) {
      // Lyrics may not be available for all tracks
      return null;
    }
  }

  // ==================== DISCOVERY (Home Page) ====================

  /// Get trending/popular tracks (for home page)
  /// Uses search with popular keywords as fallback
  Future<List<Track>> getTrendingTracks({int limit = 20}) async {
    try {
      // Search for popular music terms
      return await searchTracks('top hits 2024', limit: limit);
    } catch (e) {
      // Return empty list on failure - home page will show other content
      return [];
    }
  }

  /// Get new albums (search for recent releases)
  Future<List<Album>> getNewAlbums({int limit = 20}) async {
    try {
      return await searchAlbums('new releases 2024', limit: limit);
    } catch (e) {
      return [];
    }
  }

  /// Get popular playlists (not directly available in hifi-api)
  Future<List<Playlist>> getPopularPlaylists({int limit = 20}) async {
    // hifi-api doesn't have a playlists discovery endpoint
    // Return empty - user can search for playlists
    return [];
  }

  /// Get featured content for home page
  Future<Map<String, dynamic>> getHomeContent() async {
    try {
      // Fetch multiple content types in parallel
      final results = await Future.wait([
        searchTracks('popular', limit: 10),
        searchTracks('hip hop', limit: 10),
        searchTracks('pop hits', limit: 10),
        searchTracks('r&b', limit: 10),
      ]);

      return {
        'trending': results[0],
        'hipHop': results[1],
        'pop': results[2],
        'rnb': results[3],
      };
    } catch (e) {
      return {};
    }
  }

  // ==================== COVER ART ====================

  /// Get album cover URL from track ID
  Future<String?> getCoverUrl(String trackId) async {
    try {
      final response = await _executeWithFallback((baseUrl) {
        return _dio.get(
          '$baseUrl${TidalEndpoints.coverPath}',
          queryParameters: {'id': int.parse(trackId)},
        );
      });

      final data = response.data as Map<String, dynamic>;
      final covers = data['covers'] as List<dynamic>?;
      if (covers != null && covers.isNotEmpty) {
        final cover = covers.first as Map<String, dynamic>;
        return cover['1280'] as String? ?? cover['640'] as String?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ==================== UTILITY ====================

  /// Check endpoint health
  Future<bool> checkHealth() async {
    try {
      final response = await _dio.get(
        _currentEndpoint,
        options: Options(
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Get current active endpoint
  String get activeEndpoint => _currentEndpoint;

  /// Set preferred streaming quality
  void setQuality(TidalQuality quality) {
    preferredQuality = quality;
  }
}

/// Stream information with quality details
class StreamInfo {
  final String url;
  final String codec;
  final int bitDepth;
  final int sampleRate;
  final String quality;
  final int bitrate;

  StreamInfo({
    required this.url,
    this.codec = 'FLAC',
    this.bitDepth = 16,
    this.sampleRate = 44100,
    this.quality = 'LOSSLESS',
    this.bitrate = 1411,
  });

  factory StreamInfo.fromJson(Map<String, dynamic> json) {
    // hifi-api returns the stream data in 'data' field
    final streamData = json['data'] as Map<String, dynamic>? ?? json;
    
    // The manifest is base64-encoded (JSON or DASH XML)
    String streamUrl = '';
    final manifestBase64 = streamData['manifest'] as String?;
    final manifestMimeType = streamData['manifestMimeType'] as String?;
    
    if (manifestBase64 != null && manifestBase64.isNotEmpty) {
      try {
        // Decode base64 manifest
        final manifestContent = utf8.decode(base64Decode(manifestBase64));
        
        // Check if it's JSON format (vnd.tidal.bts) - LOSSLESS quality
        if (manifestMimeType == 'application/vnd.tidal.bts' || 
            manifestContent.startsWith('{')) {
          try {
            final manifest = jsonDecode(manifestContent) as Map<String, dynamic>;
            final urls = manifest['urls'] as List<dynamic>?;
            if (urls != null && urls.isNotEmpty) {
              streamUrl = urls.first as String;
            }
          } catch (_) {}
        }
        
        // Handle DASH manifest (HI_RES_LOSSLESS format) - same as hifi.ts
        if (streamUrl.isEmpty && 
            (manifestMimeType == 'application/dash+xml' || 
             manifestContent.contains('<MPD'))) {
          
          // Try initialization URL (full audio file)
          final initMatch = RegExp(r'initialization="([^"]+)"').firstMatch(manifestContent);
          if (initMatch != null) {
            String initUrl = initMatch.group(1)!
                .replaceAll('&amp;', '&')
                .replaceAll('&lt;', '<')
                .replaceAll('&gt;', '>');
            if (initUrl.startsWith('http')) {
              streamUrl = initUrl;
            }
          }
          
          // Try media template URL (segments)
          if (streamUrl.isEmpty) {
            final mediaMatch = RegExp(r'media="([^"]+)"').firstMatch(manifestContent);
            if (mediaMatch != null) {
              String mediaUrl = mediaMatch.group(1)!
                  .replaceAll('&amp;', '&')
                  .replaceAll(RegExp(r'\$Number\$'), '1');
              if (mediaUrl.startsWith('http')) {
                streamUrl = mediaUrl;
              }
            }
          }
          
          // Last resort: find any HTTPS URL ending in .mp4 or .flac
          if (streamUrl.isEmpty) {
            final urlMatch = RegExp(r'https://[^"<\s]+\.(mp4|flac)[^"<\s]*').firstMatch(manifestContent);
            if (urlMatch != null) {
              streamUrl = urlMatch.group(0)!.replaceAll('&amp;', '&');
            }
          }
        }
        
      } catch (e) {
        // If decoding fails completely, leave url empty
      }
    }
    
    // Fallback to direct url field if present
    if (streamUrl.isEmpty) {
      streamUrl = streamData['url'] as String? ?? '';
    }
    
    return StreamInfo(
      url: streamUrl,
      codec: streamData['codec'] as String? ?? 'FLAC',
      bitDepth: streamData['bitDepth'] as int? ?? streamData['bit_depth'] as int? ?? 16,
      sampleRate: streamData['sampleRate'] as int? ?? streamData['sample_rate'] as int? ?? 44100,
      quality: streamData['audioQuality'] as String? ?? streamData['quality'] as String? ?? 'LOSSLESS',
      bitrate: streamData['bitrate'] as int? ?? 1411,
    );
  }

  String get qualityLabel {
    if (bitDepth >= 24) return 'Master';
    if (codec == 'FLAC') return 'HiFi';
    return 'High';
  }

  bool get isMasterQuality => bitDepth >= 24;
  bool get isHiFiQuality => codec == 'FLAC' && bitDepth == 16;
}

/// Lyrics data
class Lyrics {
  final String trackId;
  final String lyrics;
  final List<LyricLine> syncedLyrics;
  final bool isSynced;

  Lyrics({
    required this.trackId,
    required this.lyrics,
    this.syncedLyrics = const [],
    this.isSynced = false,
  });

  factory Lyrics.fromJson(Map<String, dynamic> json) {
    // hifi-api returns lyrics in different format
    final lyricsText = json['lyrics'] as String? ?? 
                       json['subtitles'] as String? ?? '';
    
    final syncedData = json['subtitles'] as String?;
    List<LyricLine> syncedLines = [];
    
    if (syncedData != null && syncedData.contains('[')) {
      // Parse LRC format
      syncedLines = _parseLrcLyrics(syncedData);
    }
    
    return Lyrics(
      trackId: (json['trackId'] ?? '').toString(),
      lyrics: lyricsText,
      syncedLyrics: syncedLines,
      isSynced: syncedLines.isNotEmpty,
    );
  }
  
  static List<LyricLine> _parseLrcLyrics(String lrc) {
    final lines = <LyricLine>[];
    final regex = RegExp(r'\[(\d+):(\d+)\.(\d+)\](.*)');
    
    for (final line in lrc.split('\n')) {
      final match = regex.firstMatch(line);
      if (match != null) {
        final minutes = int.parse(match.group(1)!);
        final seconds = int.parse(match.group(2)!);
        final ms = int.parse(match.group(3)!);
        final text = match.group(4)?.trim() ?? '';
        
        final timeMs = (minutes * 60 * 1000) + (seconds * 1000) + (ms * 10);
        lines.add(LyricLine(startTimeMs: timeMs, text: text));
      }
    }
    
    return lines;
  }
}

/// Single lyric line with timestamp
class LyricLine {
  final int startTimeMs;
  final String text;

  LyricLine({required this.startTimeMs, required this.text});

  factory LyricLine.fromJson(Map<String, dynamic> json) {
    return LyricLine(
      startTimeMs: json['startTimeMs'] as int? ?? json['time'] as int? ?? 0,
      text: json['text'] as String? ?? json['line'] as String? ?? '',
    );
  }
}

/// TIDAL API Exception
class TidalApiException implements Exception {
  final String message;
  TidalApiException(this.message);

  @override
  String toString() => 'TidalApiException: $message';
}
