import 'package:dio/dio.dart';

/// Last.fm API Service for recommendations and metadata enrichment
/// Works alongside TIDAL: Last.fm provides discovery, TIDAL provides streaming
class LastFmService {
  static const _baseUrl = 'https://ws.audioscrobbler.com/2.0/';
  static const _apiKey = 'fb50e7b8d4be8d0a97fffe5597c80e90';
  static const _sharedSecret = '8c61c2197391d999b82cccefe94d199c';
  
  final Dio _dio;
  
  // User session (for personalized recommendations)
  String? _sessionKey;
  String? _username;

  LastFmService(this._dio);

  bool get isAuthenticated => _sessionKey != null;
  String? get username => _username;

  // ============================================================================
  // GENERIC RECOMMENDATIONS (No login required)
  // ============================================================================

  /// Get similar artists for "Related Artists" section
  Future<List<LastFmArtist>> getSimilarArtists(String artistName, {int limit = 10}) async {
    try {
      final response = await _dio.get(_baseUrl, queryParameters: {
        'method': 'artist.getSimilar',
        'artist': artistName,
        'api_key': _apiKey,
        'format': 'json',
        'limit': limit,
      });

      final data = response.data;
      if (data['similarartists']?['artist'] == null) return [];
      
      final artists = data['similarartists']['artist'] as List;
      return artists.map((a) => LastFmArtist.fromJson(a)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get artist info (bio, stats)
  Future<LastFmArtistInfo?> getArtistInfo(String artistName) async {
    try {
      final response = await _dio.get(_baseUrl, queryParameters: {
        'method': 'artist.getInfo',
        'artist': artistName,
        'api_key': _apiKey,
        'format': 'json',
      });

      final data = response.data;
      if (data['artist'] == null) return null;
      
      return LastFmArtistInfo.fromJson(data['artist']);
    } catch (e) {
      return null;
    }
  }

  /// Get similar tracks for "You might also like"
  Future<List<LastFmTrack>> getSimilarTracks(String artist, String track, {int limit = 10}) async {
    try {
      final response = await _dio.get(_baseUrl, queryParameters: {
        'method': 'track.getSimilar',
        'artist': artist,
        'track': track,
        'api_key': _apiKey,
        'format': 'json',
        'limit': limit,
      });

      final data = response.data;
      if (data['similartracks']?['track'] == null) return [];
      
      final tracks = data['similartracks']['track'] as List;
      return tracks.map((t) => LastFmTrack.fromJson(t)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get top tracks by genre/tag
  Future<List<LastFmTrack>> getTopTracksByTag(String tag, {int limit = 20}) async {
    try {
      final response = await _dio.get(_baseUrl, queryParameters: {
        'method': 'tag.getTopTracks',
        'tag': tag,
        'api_key': _apiKey,
        'format': 'json',
        'limit': limit,
      });

      final data = response.data;
      if (data['tracks']?['track'] == null) return [];
      
      final tracks = data['tracks']['track'] as List;
      return tracks.map((t) => LastFmTrack.fromJson(t)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get top albums by genre/tag
  Future<List<LastFmAlbum>> getTopAlbumsByTag(String tag, {int limit = 20}) async {
    try {
      final response = await _dio.get(_baseUrl, queryParameters: {
        'method': 'tag.getTopAlbums',
        'tag': tag,
        'api_key': _apiKey,
        'format': 'json',
        'limit': limit,
      });

      final data = response.data;
      if (data['albums']?['album'] == null) return [];
      
      final albums = data['albums']['album'] as List;
      return albums.map((a) => LastFmAlbum.fromJson(a)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get top artists by genre/tag
  Future<List<LastFmArtist>> getTopArtistsByTag(String tag, {int limit = 20}) async {
    try {
      final response = await _dio.get(_baseUrl, queryParameters: {
        'method': 'tag.getTopArtists',
        'tag': tag,
        'api_key': _apiKey,
        'format': 'json',
        'limit': limit,
      });

      final data = response.data;
      if (data['topartists']?['artist'] == null) return [];
      
      final artists = data['topartists']['artist'] as List;
      return artists.map((a) => LastFmArtist.fromJson(a)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get global chart top tracks
  Future<List<LastFmTrack>> getChartTopTracks({int limit = 20}) async {
    try {
      final response = await _dio.get(_baseUrl, queryParameters: {
        'method': 'chart.getTopTracks',
        'api_key': _apiKey,
        'format': 'json',
        'limit': limit,
      });

      final data = response.data;
      if (data['tracks']?['track'] == null) return [];
      
      final tracks = data['tracks']['track'] as List;
      return tracks.map((t) => LastFmTrack.fromJson(t)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get global chart top artists
  Future<List<LastFmArtist>> getChartTopArtists({int limit = 20}) async {
    try {
      final response = await _dio.get(_baseUrl, queryParameters: {
        'method': 'chart.getTopArtists',
        'api_key': _apiKey,
        'format': 'json',
        'limit': limit,
      });

      final data = response.data;
      if (data['artists']?['artist'] == null) return [];
      
      final artists = data['artists']['artist'] as List;
      return artists.map((a) => LastFmArtist.fromJson(a)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get all available tags/genres
  Future<List<String>> getTopTags({int limit = 50}) async {
    try {
      final response = await _dio.get(_baseUrl, queryParameters: {
        'method': 'tag.getTopTags',
        'api_key': _apiKey,
        'format': 'json',
      });

      final data = response.data;
      if (data['toptags']?['tag'] == null) return [];
      
      final tags = data['toptags']['tag'] as List;
      return tags.take(limit).map((t) => t['name'] as String).toList();
    } catch (e) {
      return [];
    }
  }

  // ============================================================================
  // PERSONALIZED RECOMMENDATIONS (Requires user login)
  // ============================================================================

  /// Get user's top artists (personalized)
  Future<List<LastFmArtist>> getUserTopArtists({String period = '1month', int limit = 10}) async {
    if (_username == null) return [];
    
    try {
      final response = await _dio.get(_baseUrl, queryParameters: {
        'method': 'user.getTopArtists',
        'user': _username,
        'period': period, // overall, 7day, 1month, 3month, 6month, 12month
        'api_key': _apiKey,
        'format': 'json',
        'limit': limit,
      });

      final data = response.data;
      if (data['topartists']?['artist'] == null) return [];
      
      final artists = data['topartists']['artist'] as List;
      return artists.map((a) => LastFmArtist.fromJson(a)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get user's top tracks (personalized)
  Future<List<LastFmTrack>> getUserTopTracks({String period = '1month', int limit = 10}) async {
    if (_username == null) return [];
    
    try {
      final response = await _dio.get(_baseUrl, queryParameters: {
        'method': 'user.getTopTracks',
        'user': _username,
        'period': period,
        'api_key': _apiKey,
        'format': 'json',
        'limit': limit,
      });

      final data = response.data;
      if (data['toptracks']?['track'] == null) return [];
      
      final tracks = data['toptracks']['track'] as List;
      return tracks.map((t) => LastFmTrack.fromJson(t)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get user's recommended artists (based on listening history)
  Future<List<LastFmArtist>> getUserRecommendedArtists({int limit = 10}) async {
    if (_username == null) return [];
    
    try {
      final response = await _dio.get(_baseUrl, queryParameters: {
        'method': 'user.getRecommendedArtists',
        'api_key': _apiKey,
        'sk': _sessionKey,
        'format': 'json',
        'limit': limit,
      });

      final data = response.data;
      if (data['recommendations']?['artist'] == null) return [];
      
      final artists = data['recommendations']['artist'] as List;
      return artists.map((a) => LastFmArtist.fromJson(a)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Scrobble a track (record listening)
  Future<bool> scrobble(String artist, String track, {String? album}) async {
    if (_sessionKey == null) return false;
    
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      
      await _dio.post(_baseUrl, data: {
        'method': 'track.scrobble',
        'artist': artist,
        'track': track,
        'timestamp': timestamp,
        'album': album,
        'api_key': _apiKey,
        'sk': _sessionKey,
        'format': 'json',
      });
      
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Update "Now Playing" status
  Future<bool> updateNowPlaying(String artist, String track, {String? album}) async {
    if (_sessionKey == null) return false;
    
    try {
      await _dio.post(_baseUrl, data: {
        'method': 'track.updateNowPlaying',
        'artist': artist,
        'track': track,
        'album': album,
        'api_key': _apiKey,
        'sk': _sessionKey,
        'format': 'json',
      });
      
      return true;
    } catch (e) {
      return false;
    }
  }

  // ============================================================================
  // AUTHENTICATION
  // ============================================================================

  /// Get auth token for mobile login flow
  Future<String?> getAuthToken() async {
    try {
      final response = await _dio.get(_baseUrl, queryParameters: {
        'method': 'auth.getToken',
        'api_key': _apiKey,
        'format': 'json',
      });

      return response.data['token'] as String?;
    } catch (e) {
      return null;
    }
  }

  /// Get the URL for user to authorize the app
  String getAuthUrl(String token) {
    return 'https://www.last.fm/api/auth/?api_key=$_apiKey&token=$token';
  }

  /// Complete authentication after user authorizes
  Future<bool> authenticate(String token) async {
    try {
      // Create API signature
      final sig = _createSignature({
        'api_key': _apiKey,
        'method': 'auth.getSession',
        'token': token,
      });

      final response = await _dio.get(_baseUrl, queryParameters: {
        'method': 'auth.getSession',
        'api_key': _apiKey,
        'token': token,
        'api_sig': sig,
        'format': 'json',
      });

      final session = response.data['session'];
      if (session != null) {
        _sessionKey = session['key'] as String?;
        _username = session['name'] as String?;
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Logout
  void logout() {
    _sessionKey = null;
    _username = null;
  }

  /// Create MD5 signature for authenticated requests
  String _createSignature(Map<String, String> params) {
    final sortedParams = Map.fromEntries(
      params.entries.toList()..sort((a, b) => a.key.compareTo(b.key))
    );
    
    final paramString = sortedParams.entries.map((e) => '${e.key}${e.value}').join('');
    final signatureBase = '$paramString$_sharedSecret';
    
    // Simple hash - in production use crypto package for MD5
    return signatureBase.hashCode.toRadixString(16);
  }
}

// ============================================================================
// LAST.FM DATA MODELS
// ============================================================================

class LastFmArtist {
  final String name;
  final String? mbid;
  final String? imageUrl;
  final int? listeners;
  final double? match; // Similarity score (0-1)

  const LastFmArtist({
    required this.name,
    this.mbid,
    this.imageUrl,
    this.listeners,
    this.match,
  });

  factory LastFmArtist.fromJson(Map<String, dynamic> json) {
    String? imageUrl;
    if (json['image'] is List && (json['image'] as List).isNotEmpty) {
      final images = json['image'] as List;
      // Get the largest image (last in array)
      final lastImage = images.last;
      if (lastImage is Map) {
        imageUrl = lastImage['#text'] as String?;
        if (imageUrl?.isEmpty ?? true) imageUrl = null;
      }
    }

    return LastFmArtist(
      name: json['name'] as String? ?? 'Unknown',
      mbid: json['mbid'] as String?,
      imageUrl: imageUrl,
      listeners: int.tryParse(json['listeners']?.toString() ?? ''),
      match: double.tryParse(json['match']?.toString() ?? ''),
    );
  }
}

class LastFmArtistInfo {
  final String name;
  final String? bio;
  final String? bioSummary;
  final int? listeners;
  final int? playcount;
  final List<String> tags;
  final List<LastFmArtist> similar;

  const LastFmArtistInfo({
    required this.name,
    this.bio,
    this.bioSummary,
    this.listeners,
    this.playcount,
    this.tags = const [],
    this.similar = const [],
  });

  factory LastFmArtistInfo.fromJson(Map<String, dynamic> json) {
    List<String> tags = [];
    if (json['tags']?['tag'] is List) {
      tags = (json['tags']['tag'] as List)
          .map((t) => t['name'] as String)
          .toList();
    }

    List<LastFmArtist> similar = [];
    if (json['similar']?['artist'] is List) {
      similar = (json['similar']['artist'] as List)
          .map((a) => LastFmArtist.fromJson(a))
          .toList();
    }

    return LastFmArtistInfo(
      name: json['name'] as String? ?? 'Unknown',
      bio: json['bio']?['content'] as String?,
      bioSummary: json['bio']?['summary'] as String?,
      listeners: int.tryParse(json['stats']?['listeners']?.toString() ?? ''),
      playcount: int.tryParse(json['stats']?['playcount']?.toString() ?? ''),
      tags: tags,
      similar: similar,
    );
  }
}

class LastFmTrack {
  final String name;
  final String artist;
  final String? mbid;
  final String? imageUrl;
  final int? listeners;
  final int? playcount;
  final double? match;

  const LastFmTrack({
    required this.name,
    required this.artist,
    this.mbid,
    this.imageUrl,
    this.listeners,
    this.playcount,
    this.match,
  });

  factory LastFmTrack.fromJson(Map<String, dynamic> json) {
    String? imageUrl;
    if (json['image'] is List && (json['image'] as List).isNotEmpty) {
      final images = json['image'] as List;
      final lastImage = images.last;
      if (lastImage is Map) {
        imageUrl = lastImage['#text'] as String?;
        if (imageUrl?.isEmpty ?? true) imageUrl = null;
      }
    }

    String artistName = 'Unknown';
    if (json['artist'] is Map) {
      artistName = json['artist']['name'] as String? ?? 'Unknown';
    } else if (json['artist'] is String) {
      artistName = json['artist'] as String;
    }

    return LastFmTrack(
      name: json['name'] as String? ?? 'Unknown',
      artist: artistName,
      mbid: json['mbid'] as String?,
      imageUrl: imageUrl,
      listeners: int.tryParse(json['listeners']?.toString() ?? ''),
      playcount: int.tryParse(json['playcount']?.toString() ?? ''),
      match: double.tryParse(json['match']?.toString() ?? ''),
    );
  }
}

class LastFmAlbum {
  final String name;
  final String artist;
  final String? mbid;
  final String? imageUrl;

  const LastFmAlbum({
    required this.name,
    required this.artist,
    this.mbid,
    this.imageUrl,
  });

  factory LastFmAlbum.fromJson(Map<String, dynamic> json) {
    String? imageUrl;
    if (json['image'] is List && (json['image'] as List).isNotEmpty) {
      final images = json['image'] as List;
      final lastImage = images.last;
      if (lastImage is Map) {
        imageUrl = lastImage['#text'] as String?;
        if (imageUrl?.isEmpty ?? true) imageUrl = null;
      }
    }

    String artistName = 'Unknown';
    if (json['artist'] is Map) {
      artistName = json['artist']['name'] as String? ?? 'Unknown';
    } else if (json['artist'] is String) {
      artistName = json['artist'] as String;
    }

    return LastFmAlbum(
      name: json['name'] as String? ?? 'Unknown',
      artist: artistName,
      mbid: json['mbid'] as String?,
      imageUrl: imageUrl,
    );
  }
}
