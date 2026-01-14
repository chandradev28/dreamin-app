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
  master('HI_RES');

  final String apiValue;
  const TidalQuality(this.apiValue);
}

/// TIDAL API Service - ACTIVE
/// Always streams HIGHEST QUALITY available (HiFi/Master)
class TidalService {
  final Dio _dio;
  int _currentEndpointIndex = 0;
  final Map<int, int> _endpointFailureCount = {};
  
  /// Default to Master quality, falls back to HiFi
  TidalQuality preferredQuality = TidalQuality.master;

  TidalService() : _dio = Dio() {
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

  /// Search for tracks, albums, and artists
  Future<SearchResult> search(String query, {int limit = 20}) async {
    try {
      final response = await _executeWithFallback((baseUrl) {
        return _dio.get(
          '$baseUrl${TidalEndpoints.searchPath}',
          queryParameters: {
            'q': query,
            'limit': limit,
            'type': 'tracks,albums,artists',
          },
        );
      });

      return SearchResult.fromTidalJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw TidalApiException('Search failed: $e');
    }
  }

  /// Search only tracks
  Future<List<Track>> searchTracks(String query, {int limit = 20}) async {
    try {
      final response = await _executeWithFallback((baseUrl) {
        return _dio.get(
          '$baseUrl${TidalEndpoints.searchPath}',
          queryParameters: {
            'q': query,
            'limit': limit,
            'type': 'tracks',
          },
        );
      });

      final data = response.data as Map<String, dynamic>;
      final tracks = data['tracks'] as List<dynamic>? ?? [];
      return tracks.map((t) => Track.fromTidalJson(t as Map<String, dynamic>)).toList();
    } catch (e) {
      throw TidalApiException('Track search failed: $e');
    }
  }

  /// Search only albums
  Future<List<Album>> searchAlbums(String query, {int limit = 20}) async {
    try {
      final response = await _executeWithFallback((baseUrl) {
        return _dio.get(
          '$baseUrl${TidalEndpoints.searchPath}',
          queryParameters: {
            'q': query,
            'limit': limit,
            'type': 'albums',
          },
        );
      });

      final data = response.data as Map<String, dynamic>;
      final albums = data['albums'] as List<dynamic>? ?? [];
      return albums.map((a) => Album.fromTidalJson(a as Map<String, dynamic>)).toList();
    } catch (e) {
      throw TidalApiException('Album search failed: $e');
    }
  }

  /// Search only artists
  Future<List<Artist>> searchArtists(String query, {int limit = 20}) async {
    try {
      final response = await _executeWithFallback((baseUrl) {
        return _dio.get(
          '$baseUrl${TidalEndpoints.searchPath}',
          queryParameters: {
            'q': query,
            'limit': limit,
            'type': 'artists',
          },
        );
      });

      final data = response.data as Map<String, dynamic>;
      final artists = data['artists'] as List<dynamic>? ?? [];
      return artists.map((a) => Artist.fromTidalJson(a as Map<String, dynamic>)).toList();
    } catch (e) {
      throw TidalApiException('Artist search failed: $e');
    }
  }

  // ==================== ALBUM ====================

  /// Get album details with all tracks
  Future<AlbumDetail> getAlbum(String albumId) async {
    try {
      final response = await _executeWithFallback((baseUrl) {
        return _dio.get('$baseUrl${TidalEndpoints.albumPath}/$albumId');
      });

      final data = response.data as Map<String, dynamic>;
      final albumData = data['album'] as Map<String, dynamic>? ?? data;
      final tracksData = data['tracks'] as List<dynamic>? ?? 
          albumData['tracks']?['items'] as List<dynamic>? ?? [];

      return AlbumDetail.fromTidalJson(albumData, tracksData);
    } catch (e) {
      throw TidalApiException('Failed to get album: $e');
    }
  }

  /// Get album tracks only
  Future<List<Track>> getAlbumTracks(String albumId) async {
    try {
      final response = await _executeWithFallback((baseUrl) {
        return _dio.get('$baseUrl${TidalEndpoints.albumPath}/$albumId/tracks');
      });

      final data = response.data;
      if (data is List) {
        return data.map((t) => Track.fromTidalJson(t as Map<String, dynamic>)).toList();
      }
      final items = (data as Map<String, dynamic>)['items'] as List<dynamic>? ?? [];
      return items.map((t) => Track.fromTidalJson(t as Map<String, dynamic>)).toList();
    } catch (e) {
      throw TidalApiException('Failed to get album tracks: $e');
    }
  }

  // ==================== ARTIST ====================

  /// Get artist details with top albums
  Future<ArtistDetail> getArtist(String artistId) async {
    try {
      final response = await _executeWithFallback((baseUrl) {
        return _dio.get('$baseUrl${TidalEndpoints.artistPath}/$artistId');
      });

      final data = response.data as Map<String, dynamic>;
      final artistData = data['artist'] as Map<String, dynamic>? ?? data;
      final albumsData = data['albums'] as List<dynamic>? ?? 
          artistData['albums']?['items'] as List<dynamic>? ?? [];

      return ArtistDetail.fromTidalJson(artistData, albumsData);
    } catch (e) {
      throw TidalApiException('Failed to get artist: $e');
    }
  }

  /// Get artist's top tracks
  Future<List<Track>> getArtistTopTracks(String artistId, {int limit = 10}) async {
    try {
      final response = await _executeWithFallback((baseUrl) {
        return _dio.get(
          '$baseUrl${TidalEndpoints.artistPath}/$artistId/toptracks',
          queryParameters: {'limit': limit},
        );
      });

      final data = response.data;
      if (data is List) {
        return data.map((t) => Track.fromTidalJson(t as Map<String, dynamic>)).toList();
      }
      final items = (data as Map<String, dynamic>)['items'] as List<dynamic>? ?? [];
      return items.map((t) => Track.fromTidalJson(t as Map<String, dynamic>)).toList();
    } catch (e) {
      throw TidalApiException('Failed to get artist top tracks: $e');
    }
  }

  /// Get artist's albums
  Future<List<Album>> getArtistAlbums(String artistId, {int limit = 20}) async {
    try {
      final response = await _executeWithFallback((baseUrl) {
        return _dio.get(
          '$baseUrl${TidalEndpoints.artistPath}/$artistId/albums',
          queryParameters: {'limit': limit},
        );
      });

      final data = response.data;
      if (data is List) {
        return data.map((a) => Album.fromTidalJson(a as Map<String, dynamic>)).toList();
      }
      final items = (data as Map<String, dynamic>)['items'] as List<dynamic>? ?? [];
      return items.map((a) => Album.fromTidalJson(a as Map<String, dynamic>)).toList();
    } catch (e) {
      throw TidalApiException('Failed to get artist albums: $e');
    }
  }

  /// Get similar artists
  Future<List<Artist>> getSimilarArtists(String artistId, {int limit = 10}) async {
    try {
      final response = await _executeWithFallback((baseUrl) {
        return _dio.get(
          '$baseUrl${TidalEndpoints.artistPath}/$artistId/similar',
          queryParameters: {'limit': limit},
        );
      });

      final data = response.data;
      if (data is List) {
        return data.map((a) => Artist.fromTidalJson(a as Map<String, dynamic>)).toList();
      }
      final items = (data as Map<String, dynamic>)['items'] as List<dynamic>? ?? [];
      return items.map((a) => Artist.fromTidalJson(a as Map<String, dynamic>)).toList();
    } catch (e) {
      throw TidalApiException('Failed to get similar artists: $e');
    }
  }

  // ==================== PLAYLIST ====================

  /// Get playlist details with tracks
  Future<PlaylistDetail> getPlaylist(String playlistId) async {
    try {
      final response = await _executeWithFallback((baseUrl) {
        return _dio.get('$baseUrl${TidalEndpoints.playlistPath}/$playlistId');
      });

      final data = response.data as Map<String, dynamic>;
      final playlistData = data['playlist'] as Map<String, dynamic>? ?? data;
      final tracksData = data['tracks'] as List<dynamic>? ?? 
          playlistData['tracks']?['items'] as List<dynamic>? ?? [];

      return PlaylistDetail.fromTidalJson(playlistData, tracksData);
    } catch (e) {
      throw TidalApiException('Failed to get playlist: $e');
    }
  }

  // ==================== TRACK ====================

  /// Get track details
  Future<Track> getTrack(String trackId) async {
    try {
      final response = await _executeWithFallback((baseUrl) {
        return _dio.get('$baseUrl${TidalEndpoints.trackPath}/$trackId');
      });

      return Track.fromTidalJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw TidalApiException('Failed to get track: $e');
    }
  }

  // ==================== STREAMING (HIGHEST QUALITY) ====================

  /// Get stream URL for a track - ALWAYS HIGHEST QUALITY
  /// Tries Master (24-bit) first, falls back to HiFi (16-bit FLAC)
  Future<StreamInfo> getStreamInfo(String trackId, {TidalQuality? quality}) async {
    final requestedQuality = quality ?? preferredQuality;
    
    try {
      final response = await _executeWithFallback((baseUrl) {
        return _dio.get(
          '$baseUrl${TidalEndpoints.streamPath}/$trackId',
          queryParameters: {
            'quality': requestedQuality.apiValue,
          },
        );
      });

      final data = response.data as Map<String, dynamic>;
      return StreamInfo.fromJson(data);
    } catch (e) {
      // If Master quality fails, try HiFi
      if (requestedQuality == TidalQuality.master) {
        return getStreamInfo(trackId, quality: TidalQuality.hifi);
      }
      throw TidalApiException('Failed to get stream: $e');
    }
  }

  /// Get stream URL only (convenience method)
  Future<String> getStreamUrl(String trackId) async {
    final streamInfo = await getStreamInfo(trackId);
    return streamInfo.url;
  }

  /// Get lyrics for a track
  Future<Lyrics?> getLyrics(String trackId) async {
    try {
      final response = await _executeWithFallback((baseUrl) {
        return _dio.get('$baseUrl${TidalEndpoints.lyricsPath}/$trackId');
      });

      final data = response.data as Map<String, dynamic>;
      return Lyrics.fromJson(data);
    } catch (e) {
      // Lyrics may not be available for all tracks
      return null;
    }
  }

  // ==================== DISCOVERY ====================

  /// Get new albums (for home page)
  Future<List<Album>> getNewAlbums({int limit = 20}) async {
    try {
      final response = await _executeWithFallback((baseUrl) {
        return _dio.get(
          '$baseUrl${TidalEndpoints.newAlbumsPath}',
          queryParameters: {'limit': limit},
        );
      });

      final data = response.data;
      if (data is List) {
        return data.map((a) => Album.fromTidalJson(a as Map<String, dynamic>)).toList();
      }
      final items = (data as Map<String, dynamic>)['items'] as List<dynamic>? ?? [];
      return items.map((a) => Album.fromTidalJson(a as Map<String, dynamic>)).toList();
    } catch (e) {
      throw TidalApiException('Failed to get new albums: $e');
    }
  }

  /// Get popular playlists (for home page)
  Future<List<Playlist>> getPopularPlaylists({int limit = 20}) async {
    try {
      final response = await _executeWithFallback((baseUrl) {
        return _dio.get(
          '$baseUrl${TidalEndpoints.popularPlaylistsPath}',
          queryParameters: {'limit': limit},
        );
      });

      final data = response.data;
      if (data is List) {
        return data.map((p) => Playlist.fromTidalJson(p as Map<String, dynamic>)).toList();
      }
      final items = (data as Map<String, dynamic>)['items'] as List<dynamic>? ?? [];
      return items.map((p) => Playlist.fromTidalJson(p as Map<String, dynamic>)).toList();
    } catch (e) {
      throw TidalApiException('Failed to get popular playlists: $e');
    }
  }

  /// Get featured playlists (for home page)
  Future<List<Playlist>> getFeaturedPlaylists({int limit = 20}) async {
    try {
      final response = await _executeWithFallback((baseUrl) {
        return _dio.get(
          '$baseUrl${TidalEndpoints.featuredPlaylistsPath}',
          queryParameters: {'limit': limit},
        );
      });

      final data = response.data;
      if (data is List) {
        return data.map((p) => Playlist.fromTidalJson(p as Map<String, dynamic>)).toList();
      }
      final items = (data as Map<String, dynamic>)['items'] as List<dynamic>? ?? [];
      return items.map((p) => Playlist.fromTidalJson(p as Map<String, dynamic>)).toList();
    } catch (e) {
      throw TidalApiException('Failed to get featured playlists: $e');
    }
  }

  /// Get trending tracks
  Future<List<Track>> getTrendingTracks({int limit = 20}) async {
    try {
      final response = await _executeWithFallback((baseUrl) {
        return _dio.get(
          '$baseUrl${TidalEndpoints.trendingPath}',
          queryParameters: {'limit': limit},
        );
      });

      final data = response.data;
      if (data is List) {
        return data.map((t) => Track.fromTidalJson(t as Map<String, dynamic>)).toList();
      }
      final items = (data as Map<String, dynamic>)['items'] as List<dynamic>? ?? [];
      return items.map((t) => Track.fromTidalJson(t as Map<String, dynamic>)).toList();
    } catch (e) {
      throw TidalApiException('Failed to get trending tracks: $e');
    }
  }

  /// Get genres
  Future<List<String>> getGenres() async {
    try {
      final response = await _executeWithFallback((baseUrl) {
        return _dio.get('$baseUrl${TidalEndpoints.genresPath}');
      });

      final data = response.data;
      if (data is List) {
        return data.map((g) => g.toString()).toList();
      }
      return [];
    } catch (e) {
      throw TidalApiException('Failed to get genres: $e');
    }
  }

  /// Get moods/playlists by mood
  Future<List<Playlist>> getMoodPlaylists(String mood, {int limit = 20}) async {
    try {
      final response = await _executeWithFallback((baseUrl) {
        return _dio.get(
          '$baseUrl${TidalEndpoints.moodsPath}/$mood',
          queryParameters: {'limit': limit},
        );
      });

      final data = response.data;
      if (data is List) {
        return data.map((p) => Playlist.fromTidalJson(p as Map<String, dynamic>)).toList();
      }
      final items = (data as Map<String, dynamic>)['items'] as List<dynamic>? ?? [];
      return items.map((p) => Playlist.fromTidalJson(p as Map<String, dynamic>)).toList();
    } catch (e) {
      throw TidalApiException('Failed to get mood playlists: $e');
    }
  }

  // ==================== UTILITY ====================

  /// Check endpoint health
  Future<bool> checkHealth() async {
    try {
      final response = await _dio.get(
        '$_currentEndpoint/api/health',
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
    return StreamInfo(
      url: json['url'] as String? ?? '',
      codec: json['codec'] as String? ?? 'FLAC',
      bitDepth: json['bitDepth'] as int? ?? json['bit_depth'] as int? ?? 16,
      sampleRate: json['sampleRate'] as int? ?? json['sample_rate'] as int? ?? 44100,
      quality: json['quality'] as String? ?? 'LOSSLESS',
      bitrate: json['bitrate'] as int? ?? 1411,
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
    final syncedData = json['syncedLyrics'] as List<dynamic>? ?? [];
    return Lyrics(
      trackId: json['trackId'] as String? ?? '',
      lyrics: json['lyrics'] as String? ?? json['text'] as String? ?? '',
      syncedLyrics: syncedData.map((l) => LyricLine.fromJson(l as Map<String, dynamic>)).toList(),
      isSynced: json['isSynced'] as bool? ?? syncedData.isNotEmpty,
    );
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
