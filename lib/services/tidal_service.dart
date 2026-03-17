import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import '../core/constants/api_constants.dart';
import '../models/models.dart';
import 'music_service.dart';

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

/// TIDAL API Service - PRODUCTION GRADE
/// Uses hifi-api format with intelligent endpoint failover
/// Features: Health tracking, DNS failure detection, fast failover
class TidalService {
  final Dio _dio;
  int _currentEndpointIndex;

  /// Per-endpoint health tracking
  /// Key: endpoint index, Value: failure count
  final Map<int, int> _endpointFailureCount = {};

  /// Endpoints temporarily disabled due to DNS/connection failures
  /// Key: endpoint index, Value: timestamp when it can be retried
  final Map<int, DateTime> _endpointCooldown = {};

  /// Prefer master first now that DASH manifests are supported.
  TidalQuality preferredQuality = TidalQuality.master;

  TidalService()
      : _dio = Dio(),
        _currentEndpointIndex = 0 {
    // Fast timeouts for quick failover (DNS failures detected in ~3s)
    _dio.options.connectTimeout = const Duration(seconds: 3);
    _dio.options.receiveTimeout = const Duration(seconds: 5);
    _dio.options.headers = {
      'Accept': 'application/json',
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
    };
  }

  String get _currentEndpoint =>
      TidalEndpoints.endpoints[_currentEndpointIndex];

  /// Check if endpoint is available (not in cooldown)
  bool _isEndpointAvailable(int index) {
    final cooldownUntil = _endpointCooldown[index];
    if (cooldownUntil == null) return true;
    if (DateTime.now().isAfter(cooldownUntil)) {
      _endpointCooldown.remove(index);
      return true;
    }
    return false;
  }

  /// Find next available endpoint
  int _findNextAvailableEndpoint(int startIndex) {
    final endpointCount = TidalEndpoints.endpoints.length;
    for (int i = 0; i < endpointCount; i++) {
      final index = (startIndex + i) % endpointCount;
      if (_isEndpointAvailable(index)) {
        return index;
      }
    }
    // All endpoints in cooldown - clear cooldowns and start fresh
    _endpointCooldown.clear();
    return 0;
  }

  /// Mark endpoint as failed with cooldown
  void _markEndpointFailed(int index, {bool isDnsFailure = false}) {
    final failures = (_endpointFailureCount[index] ?? 0) + 1;
    _endpointFailureCount[index] = failures;

    // DNS failures get longer cooldown (likely persistent issue)
    final cooldownSeconds = isDnsFailure
        ? 60 // DNS failure: 60 seconds cooldown
        : (failures * 5).clamp(5, 30); // Other failures: 5-30 seconds

    _endpointCooldown[index] =
        DateTime.now().add(Duration(seconds: cooldownSeconds));
    print(
        'âš ï¸ Endpoint ${TidalEndpoints.endpoints[index]} failed (${isDnsFailure ? "DNS" : "connection"}) - cooldown ${cooldownSeconds}s');
  }

  /// Mark endpoint as successful - reset failure count
  void _markEndpointSuccess(int index) {
    _endpointFailureCount[index] = 0;
    _endpointCooldown.remove(index);
  }

  /// Execute request with intelligent fallback
  /// - DNS failures: immediate skip + long cooldown
  /// - Connection errors: short cooldown
  /// - Success: reset health
  Future<Response<T>> _executeWithFallback<T>(
    Future<Response<T>> Function(String baseUrl) request,
  ) async {
    final endpointCount = TidalEndpoints.endpoints.length;
    int attempts = 0;
    Exception? lastError;
    String lastErrorType = '';

    while (attempts < endpointCount) {
      // Find next available endpoint
      _currentEndpointIndex = _findNextAvailableEndpoint(_currentEndpointIndex);
      final endpoint = TidalEndpoints.endpoints[_currentEndpointIndex];

      try {
        print('ðŸ“¡ Trying endpoint: $endpoint');
        final response = await request(endpoint);
        _markEndpointSuccess(_currentEndpointIndex);
        return response;
      } on DioException catch (e) {
        lastError = e;

        // Detect DNS failures - immediate skip with long cooldown
        if (e.type == DioExceptionType.unknown &&
            e.message?.contains('Failed host lookup') == true) {
          lastErrorType = 'DNS';
          _markEndpointFailed(_currentEndpointIndex, isDnsFailure: true);
        }
        // Connection timeout/refused
        else if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.connectionError) {
          lastErrorType = 'Connection';
          _markEndpointFailed(_currentEndpointIndex, isDnsFailure: false);
        }
        // Other errors (bad response, etc.)
        else {
          lastErrorType = 'Response';
          _markEndpointFailed(_currentEndpointIndex, isDnsFailure: false);
        }

        attempts++;
        _currentEndpointIndex = (_currentEndpointIndex + 1) % endpointCount;
      } catch (e) {
        lastError = e as Exception;
        lastErrorType = 'Unknown';
        _markEndpointFailed(_currentEndpointIndex, isDnsFailure: false);
        attempts++;
        _currentEndpointIndex = (_currentEndpointIndex + 1) % endpointCount;
      }
    }

    throw TidalApiException(
        'All endpoints failed ($lastErrorType): $lastError');
  }

  // ==================== SEARCH ====================

  /// Search for tracks
  Future<List<Track>> searchTracks(String query, {int limit = 25}) async {
    try {
      final response = await _executeWithFallback((baseUrl) {
        return _dio.get(
          '$baseUrl${TidalEndpoints.searchPath}',
          queryParameters: {'s': query}, // hifi-api uses 's' for track search
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
          if (trackIsrc != null &&
              trackIsrc.toUpperCase() == isrc.toUpperCase()) {
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
          queryParameters: {'al': query}, // hifi-api uses 'al' for album search
        );
      });

      final data = response.data;
      List<dynamic> items = [];

      if (data is Map<String, dynamic>) {
        // Try various response structures
        if (data['data'] is Map && data['data']['albums'] is List) {
          items = data['data']['albums'] as List;
        } else if (data['data'] is Map &&
            data['data']['albums'] is Map &&
            data['data']['albums']['items'] is List) {
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
          queryParameters: {'a': query}, // hifi-api uses 'a' for artist search
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
          queryParameters: {'p': query}, // 'p' for playlist search
        );
      });

      final data = response.data;
      List<dynamic> items = [];

      if (data is Map<String, dynamic>) {
        if (data['data'] is Map &&
            data['data']['playlists'] is Map &&
            data['data']['playlists']['items'] is List) {
          items = data['data']['playlists']['items'] as List;
        } else if (data['data'] is Map && data['data']['playlists'] is List) {
          items = data['data']['playlists'] as List;
        } else if (data['playlists'] is Map &&
            data['playlists']['items'] is List) {
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
    // Validate artistId is a valid numeric ID
    final parsedId = int.tryParse(artistId);
    if (parsedId == null) {
      throw TidalApiException('Invalid artist ID: $artistId');
    }

    try {
      // First get basic artist info with ?id= to get picture/cover
      final artistResponse = await _executeWithFallback((baseUrl) {
        return _dio.get(
          '$baseUrl${TidalEndpoints.artistPath}',
          queryParameters: {'id': parsedId},
        );
      });

      final artistResponseData = artistResponse.data as Map<String, dynamic>;

      // Extract artist data - API returns {artist: {...}, cover: {...}}
      final artistData =
          artistResponseData['artist'] as Map<String, dynamic>? ?? {};
      final coverData = artistResponseData['cover'] as Map<String, dynamic>?;

      // Add cover URL to artist data if available (direct URL is better)
      if (coverData != null && coverData['750'] != null) {
        artistData['coverUrl'] = coverData['750'];
      }

      // Now get full data with albums and tracks using ?f=
      final response = await _executeWithFallback((baseUrl) {
        return _dio.get(
          '$baseUrl${TidalEndpoints.artistPath}',
          queryParameters: {'f': parsedId},
        );
      });

      final data = response.data as Map<String, dynamic>;
      final albumsData = data['albums']?['items'] as List<dynamic>? ?? [];
      final tracksData = data['tracks'] as List<dynamic>? ?? [];

      return ArtistDetail.fromTidalJson(artistData, albumsData,
          tracksJson: tracksData);
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
          queryParameters: {
            'id': int.parse(artistId)
          }, // 'id' gives basic artist info
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

  /// Get playlist details with ALL tracks (handles pagination)
  /// API returns max 100 tracks per request, so we paginate to fetch all
  Future<PlaylistDetail> getPlaylist(String playlistId) async {
    try {
      // First request to get playlist metadata and first batch of tracks
      final response = await _executeWithFallback((baseUrl) {
        return _dio.get(
          '$baseUrl${TidalEndpoints.playlistPath}',
          queryParameters: {'id': playlistId},
        );
      });

      final data = response.data as Map<String, dynamic>;

      // Extract playlist metadata
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

      // Get total track count from playlist metadata
      final int totalTracks = playlistData['numberOfTracks'] as int? ?? 0;

      // Collect all tracks with pagination
      List<Map<String, dynamic>> allTracksData = [];
      int offset = 0;
      const int pageSize = 100; // API returns max 100 per request

      // Process first batch
      allTracksData.addAll(_extractTracksFromResponse(data, playlistData));

      // Fetch remaining pages if needed
      while (allTracksData.length < totalTracks &&
          offset + pageSize < totalTracks) {
        offset += pageSize;

        try {
          final pageResponse = await _executeWithFallback((baseUrl) {
            return _dio.get(
              '$baseUrl${TidalEndpoints.playlistPath}',
              queryParameters: {
                'id': playlistId,
                'offset': offset,
              },
            );
          });

          final pageData = pageResponse.data as Map<String, dynamic>;
          final pageTracks = _extractTracksFromResponse(pageData, {});

          if (pageTracks.isEmpty) break; // No more tracks
          allTracksData.addAll(pageTracks);
        } catch (e) {
          // If pagination fails, continue with what we have
          break;
        }
      }

      // Ensure playlist has id
      if (playlistData['uuid'] == null && playlistData['id'] == null) {
        playlistData['uuid'] = playlistId;
      }

      return PlaylistDetail.fromTidalJson(playlistData, allTracksData);
    } catch (e) {
      throw TidalApiException('Failed to get playlist: $e');
    }
  }

  /// Helper to extract tracks from API response (handles various formats)
  List<Map<String, dynamic>> _extractTracksFromResponse(
    Map<String, dynamic> data,
    Map<String, dynamic> playlistData,
  ) {
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

    return tracksData;
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

  /// Get extended track metadata from the info endpoint.
  Future<TrackInfo?> getTrackInfo(String trackId) async {
    try {
      final response = await _executeWithFallback((baseUrl) {
        return _dio.get(
          '$baseUrl${TidalEndpoints.infoPath}',
          queryParameters: {'id': int.parse(trackId)},
        );
      });

      final data = response.data as Map<String, dynamic>;
      final trackData = data['data'] as Map<String, dynamic>? ?? data;
      return TrackInfo.fromJson(trackData);
    } catch (_) {
      return null;
    }
  }

  /// Get stream URL for a track with quality fallback.
  /// Avoids DASH segment URLs that can cause short playback and auto-skips.
  Future<StreamInfo> getStreamInfo(String trackId,
      {TidalQuality? quality}) async {
    // Parse track ID - ensure it's numeric
    final numericId = int.tryParse(trackId.replaceAll(RegExp(r'[^0-9]'), ''));
    if (numericId == null || numericId == 0) {
      throw TidalApiException('Invalid track ID: $trackId');
    }

    // Default to preferredQuality (hifi/LOSSLESS by default).
    final requestedQuality = quality ?? preferredQuality;

    print(
        '[TIDAL] Getting stream for track $numericId (quality: ${requestedQuality.apiValue})');

    try {
      final primary = await _fetchStreamInfo(numericId, requestedQuality);
      print('[TIDAL] Got stream URL from primary quality');
      return primary;
    } catch (e) {
      // If higher quality fails (or returns non-playable DASH segments), retry LOSSLESS.
      if (requestedQuality != TidalQuality.hifi) {
        print(
            '[TIDAL] ${requestedQuality.apiValue} failed, retrying LOSSLESS...');
        try {
          final fallback = await _fetchStreamInfo(numericId, TidalQuality.hifi);
          print('[TIDAL] Got LOSSLESS fallback stream URL');
          return fallback;
        } catch (fallbackError) {
          print('[TIDAL] LOSSLESS fallback failed: $fallbackError');
          throw TidalApiException(
            'Failed to get stream (primary + LOSSLESS fallback): $fallbackError',
          );
        }
      }

      print('[TIDAL] Stream error: $e');
      throw TidalApiException('Failed to get stream: $e');
    }
  }

  Future<StreamInfo> _fetchStreamInfo(
      int numericId, TidalQuality quality) async {
    final response = await _executeStreamWithFallback((baseUrl) {
      print('[TIDAL] Trying stream endpoint: $baseUrl');
      return _dio.get(
        '$baseUrl${TidalEndpoints.trackPath}',
        queryParameters: {
          'id': numericId,
          'quality': quality.apiValue,
        },
      );
    });

    final data = response.data as Map<String, dynamic>;
    var streamInfo = StreamInfo.fromJson(data);
    if (streamInfo.url.isEmpty &&
        streamInfo.isDashManifest &&
        streamInfo.dashManifestContent != null) {
      final dashPath = await _materializeDashManifest(
        numericId,
        streamInfo.dashManifestContent!,
      );
      streamInfo = StreamInfo(
        url: dashPath,
        codec: streamInfo.codec,
        bitDepth: streamInfo.bitDepth,
        sampleRate: streamInfo.sampleRate,
        quality: streamInfo.quality,
        bitrate: streamInfo.bitrate,
        isDashManifest: true,
        dashManifestContent: streamInfo.dashManifestContent,
      );
    }

    if (streamInfo.url.isEmpty) {
      throw TidalApiException('No playable stream URL in response');
    }

    return streamInfo;
  }

  Future<Response<T>> _executeStreamWithFallback<T>(
    Future<Response<T>> Function(String baseUrl) request,
  ) async {
    Exception? lastError;
    for (final endpoint in TidalEndpoints.streamEndpoints) {
      try {
        return await request(endpoint);
      } on DioException catch (e) {
        lastError = e;
      } catch (e) {
        lastError = e as Exception;
      }
    }
    throw TidalApiException('All stream endpoints failed: $lastError');
  }

  Future<String> _materializeDashManifest(
      int trackId, String manifestContent) async {
    final dir = Directory('${Directory.systemTemp.path}\\dreamin_tidal_dash');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final file = File('${dir.path}\\$trackId.mpd');
    await file.writeAsString(manifestContent, flush: true);
    return file.path;
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

  // ==================== VIDEO COVERS (Direct CDN Access) ====================

  /// Get video cover URL from cover UUID (animated album art)
  /// Video covers are served directly from Tidal's CDN - no proxy needed!
  /// @param coverUuid The cover UUID from album/track data (e.g., "a1b2c3d4-e5f6-7890-abcd-ef1234567890")
  /// @param size Video size (default 640, options: 160, 320, 480, 640, 750, 1280)
  /// @return MP4 video URL or null if UUID invalid
  String? getVideoCoverUrl(String? coverUuid, {int size = 640}) {
    if (coverUuid == null || coverUuid.isEmpty) return null;

    // Already a full URL? Return as-is
    if (coverUuid.startsWith('http')) return coverUuid;

    // Convert UUID format: a1b2c3d4-e5f6-7890-abcd-ef1234567890 -> a1b2c3d4/e5f6/7890/abcd/ef1234567890
    final pathUuid = coverUuid.replaceAll('-', '/');
    return 'https://resources.tidal.com/videos/$pathUuid/${size}x$size.mp4';
  }

  /// Get static image cover URL from cover UUID
  /// Covers are served directly from Tidal's CDN - no proxy needed!
  /// @param coverUuid The cover UUID from album/track data
  /// @param size Image size (default 640, options: 80, 160, 320, 480, 640, 750, 1280)
  /// @return JPG image URL or null if UUID invalid
  String? getStaticCoverUrl(String? coverUuid, {int size = 640}) {
    if (coverUuid == null || coverUuid.isEmpty) return null;

    // Already a full URL? Return as-is
    if (coverUuid.startsWith('http')) return coverUuid;

    // Convert UUID format: a1b2c3d4-e5f6-7890-abcd-ef1234567890 -> a1b2c3d4/e5f6/7890/abcd/ef1234567890
    final pathUuid = coverUuid.replaceAll('-', '/');
    return 'https://resources.tidal.com/images/$pathUuid/${size}x$size.jpg';
  }

  /// Get artist picture URL from picture UUID
  /// @param pictureUuid The picture UUID from artist data
  /// @param size Image size (default 750, options: 160, 320, 480, 640, 750)
  String? getArtistPictureUrl(String? pictureUuid, {int size = 750}) {
    if (pictureUuid == null || pictureUuid.isEmpty) return null;

    // Already a full URL? Return as-is
    if (pictureUuid.startsWith('http')) return pictureUuid;

    // Convert UUID format: a1b2c3d4-e5f6-7890-abcd-ef1234567890 -> a1b2c3d4/e5f6/7890/abcd/ef1234567890
    final pathUuid = pictureUuid.replaceAll('-', '/');
    return 'https://resources.tidal.com/images/$pathUuid/${size}x$size.jpg';
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
  final bool isDashManifest;
  final String? dashManifestContent;

  StreamInfo({
    required this.url,
    this.codec = 'FLAC',
    this.bitDepth = 16,
    this.sampleRate = 44100,
    this.quality = 'LOSSLESS',
    this.bitrate = 1411,
    this.isDashManifest = false,
    this.dashManifestContent,
  });

  factory StreamInfo.fromJson(Map<String, dynamic> json) {
    // hifi-api returns the stream data in 'data' field
    final streamData = json['data'] as Map<String, dynamic>? ?? json;

    // The manifest is base64-encoded (JSON or DASH XML)
    String streamUrl = '';
    String? dashManifestContent;
    final manifestBase64 = streamData['manifest'] as String?;
    final manifestMimeType = streamData['manifestMimeType'] as String?;

    if (manifestBase64 != null && manifestBase64.isNotEmpty) {
      try {
        // Decode base64 manifest
        final manifestContent = utf8.decode(base64Decode(manifestBase64));

        // JSON manifest (vnd.tidal.bts) usually contains full direct URLs.
        if (manifestMimeType == 'application/vnd.tidal.bts' ||
            manifestContent.startsWith('{')) {
          try {
            final manifest =
                jsonDecode(manifestContent) as Map<String, dynamic>;
            final urls = manifest['urls'] as List<dynamic>?;
            if (urls != null && urls.isNotEmpty) {
              final candidate = urls.first as String;
              if (!_isLikelyDashSegmentUrl(candidate)) {
                streamUrl = candidate;
              }
            }
          } catch (_) {}
        }

        // DASH manifest: do NOT use initialization/media segment URLs.
        // Those are chunks (e.g., /0.mp4, /1.mp4) and lead to short playback/skips.
        if (streamUrl.isEmpty &&
            (manifestMimeType == 'application/dash+xml' ||
                manifestContent.contains('<MPD'))) {
          dashManifestContent = manifestContent;
          final flacMatch = RegExp(r'https://[^"<\s]+\.flac[^"<\s]*')
              .firstMatch(manifestContent);
          if (flacMatch != null) {
            final candidate = flacMatch.group(0)!.replaceAll('&amp;', '&');
            if (!_isLikelyDashSegmentUrl(candidate)) {
              streamUrl = candidate;
            }
          }
        }
      } catch (_) {
        // Leave streamUrl empty; caller can retry with lower quality/other endpoint.
      }
    }

    // Fallback to direct url field if present.
    if (streamUrl.isEmpty) {
      final directUrl = streamData['url'] as String? ?? '';
      if (!_isLikelyDashSegmentUrl(directUrl)) {
        streamUrl = directUrl;
      }
    }

    // Final guard against partial segment URLs.
    if (_isLikelyDashSegmentUrl(streamUrl)) {
      streamUrl = '';
    }

    return StreamInfo(
      url: streamUrl,
      codec: streamData['codec'] as String? ?? 'FLAC',
      bitDepth: streamData['bitDepth'] as int? ??
          streamData['bit_depth'] as int? ??
          16,
      sampleRate: streamData['sampleRate'] as int? ??
          streamData['sample_rate'] as int? ??
          44100,
      quality: streamData['audioQuality'] as String? ??
          streamData['quality'] as String? ??
          'LOSSLESS',
      bitrate: streamData['bitrate'] as int? ?? 1411,
      isDashManifest: streamUrl.isEmpty &&
          dashManifestContent != null &&
          dashManifestContent.isNotEmpty,
      dashManifestContent: dashManifestContent,
    );
  }

  static bool _isLikelyDashSegmentUrl(String? url) {
    if (url == null || url.isEmpty || !url.startsWith('http')) {
      return false;
    }

    final uri = Uri.tryParse(url);
    if (uri == null) return false;

    final fileName = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : '';
    return RegExp(r'^\d+\.(mp4|m4s)$').hasMatch(fileName.toLowerCase());
  }

  String get qualityLabel {
    if (bitDepth >= 24) return 'Master';
    if (codec == 'FLAC') return 'HiFi';
    return 'High';
  }

  bool get isMasterQuality => bitDepth >= 24;
  bool get isHiFiQuality => codec == 'FLAC' && bitDepth == 16;
}

/// Extended track metadata from /info.
class TrackInfo {
  final String id;
  final String title;
  final String artist;
  final String artistId;
  final String album;
  final String albumId;
  final String? releaseDate;
  final String? copyright;
  final String? isrc;
  final int? bpm;
  final String? key;
  final String? keyScale;
  final String? audioQuality;
  final List<String> tags;
  final bool explicit;
  final int? popularity;
  final String? mixId;

  const TrackInfo({
    required this.id,
    required this.title,
    required this.artist,
    required this.artistId,
    required this.album,
    required this.albumId,
    this.releaseDate,
    this.copyright,
    this.isrc,
    this.bpm,
    this.key,
    this.keyScale,
    this.audioQuality,
    this.tags = const [],
    this.explicit = false,
    this.popularity,
    this.mixId,
  });

  factory TrackInfo.fromJson(Map<String, dynamic> json) {
    final artists = json['artists'] as List<dynamic>? ?? [];
    final artistMap =
        artists.isNotEmpty && artists.first is Map<String, dynamic>
            ? artists.first as Map<String, dynamic>
            : (json['artist'] as Map<String, dynamic>? ?? const {});
    final albumMap = json['album'] as Map<String, dynamic>? ?? const {};
    final tags = (json['mediaMetadata']?['tags'] as List<dynamic>? ?? const [])
        .map((tag) => tag.toString())
        .where((tag) => tag.isNotEmpty)
        .toList();

    return TrackInfo(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? 'Unknown Title',
      artist: artistMap['name'] as String? ?? 'Unknown Artist',
      artistId: artistMap['id']?.toString() ?? '',
      album: albumMap['title'] as String? ?? 'Unknown Album',
      albumId: albumMap['id']?.toString() ?? '',
      releaseDate: albumMap['releaseDate'] as String?,
      copyright: json['copyright'] as String?,
      isrc: json['isrc'] as String?,
      bpm: json['bpm'] as int?,
      key: json['key'] as String?,
      keyScale: json['keyScale'] as String?,
      audioQuality: json['audioQuality'] as String?,
      tags: tags,
      explicit: json['explicit'] as bool? ?? false,
      popularity: json['popularity'] as int?,
      mixId: (json['mixes'] as Map<String, dynamic>?)?['TRACK_MIX'] as String?,
    );
  }

  String? get musicalKey {
    if (key == null || key!.isEmpty) return null;
    if (keyScale == null || keyScale!.isEmpty) return key;
    final scale = keyScale!.toLowerCase() == 'minor' ? 'minor' : 'major';
    return '$key $scale';
  }

  String? get qualityLabel {
    if (audioQuality == null || audioQuality!.isEmpty) return null;
    switch (audioQuality) {
      case 'HI_RES_LOSSLESS':
        return 'MAX';
      case 'LOSSLESS':
        return 'HIGH';
      default:
        return audioQuality;
    }
  }
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
    final lyricsText =
        json['lyrics'] as String? ?? json['subtitles'] as String? ?? '';

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

// ============================================================================
// TIDAL SERVICE IMPL - Implements MusicService interface
// ============================================================================

/// TidalServiceImpl - Wrapper that implements MusicService interface
/// Delegates to the existing TidalService for actual API calls
class TidalServiceImpl implements MusicService {
  final TidalService _service = TidalService();

  @override
  MusicSource get source => MusicSource.tidal;

  // ============== SEARCH ==============

  @override
  Future<SearchResult> search(String query, {int limit = 30}) async {
    return _service.search(query, limit: limit);
  }

  @override
  Future<List<Track>> searchTracks(String query, {int limit = 30}) async {
    return _service.searchTracks(query, limit: limit);
  }

  @override
  Future<List<Album>> searchAlbums(String query, {int limit = 20}) async {
    return _service.searchAlbums(query, limit: limit);
  }

  @override
  Future<List<Artist>> searchArtists(String query, {int limit = 20}) async {
    return _service.searchArtists(query, limit: limit);
  }

  @override
  Future<List<Playlist>> searchPlaylists(String query, {int limit = 20}) async {
    return _service.searchPlaylists(query, limit: limit);
  }

  // ============== DETAILS ==============

  @override
  Future<AlbumDetail?> getAlbum(String id) async {
    final result = await _service.getAlbum(id);
    return result;
  }

  @override
  Future<ArtistDetail?> getArtist(String id) async {
    final result = await _service.getArtist(id);
    return result;
  }

  @override
  Future<PlaylistDetail?> getPlaylist(String id) async {
    final result = await _service.getPlaylist(id);
    return result;
  }

  // ============== STREAMING ==============

  @override
  Future<String?> getStreamUrl(String trackId) async {
    return _service.getStreamUrl(trackId);
  }

  @override
  String getCoverArt(String? id, {int size = 300}) {
    if (id == null || id.isEmpty) return '';
    // TIDAL cover URLs are typically returned directly in the API response
    // This is for when we only have an ID
    return id.startsWith('http') ? id : '';
  }

  // ============== DISCOVERY ==============

  @override
  Future<List<Album>> getNewAlbums({int limit = 20}) async {
    return _service.getNewAlbums(limit: limit);
  }

  @override
  Future<List<Playlist>> getPopularPlaylists({int limit = 20}) async {
    return _service.getPopularPlaylists(limit: limit);
  }

  @override
  Future<List<Track>> getRandomTracks({int limit = 20}) async {
    return _service.getTrendingTracks(limit: limit);
  }

  // ============== TIDAL-SPECIFIC (keep access to underlying service) ==============

  /// Get the underlying TidalService for TIDAL-specific operations
  TidalService get tidalService => _service;

  /// Get stream info with quality options (TIDAL-specific)
  Future<StreamInfo?> getStreamInfo(String trackId, {TidalQuality? quality}) {
    return _service.getStreamInfo(trackId, quality: quality);
  }

  /// Get lyrics (TIDAL-specific)
  Future<Lyrics?> getLyrics(String trackId) {
    return _service.getLyrics(trackId);
  }

  Future<TrackInfo?> getTrackInfo(String trackId) {
    return _service.getTrackInfo(trackId);
  }
}
