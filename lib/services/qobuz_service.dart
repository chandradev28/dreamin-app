import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import '../models/models.dart';
import 'music_service.dart';

class QobuzAuthConfig {
  final String userToken;
  final String userId;
  final String appId;
  final String appSecret;

  const QobuzAuthConfig({
    required this.userToken,
    required this.userId,
    required this.appId,
    required this.appSecret,
  });

  bool get isComplete =>
      userToken.trim().isNotEmpty &&
      userId.trim().isNotEmpty &&
      appId.trim().isNotEmpty &&
      appSecret.trim().isNotEmpty;
}

class QobuzAccountInfo {
  final String userId;
  final String displayName;
  final String login;
  final String email;
  final String countryCode;
  final String subscriptionLabel;
  final String startDate;
  final String endDate;
  final bool losslessStreaming;
  final bool hiResStreaming;

  const QobuzAccountInfo({
    required this.userId,
    required this.displayName,
    required this.login,
    required this.email,
    required this.countryCode,
    required this.subscriptionLabel,
    required this.startDate,
    required this.endDate,
    required this.losslessStreaming,
    required this.hiResStreaming,
  });
}

class QobuzResolvedAuth {
  final QobuzAuthConfig authConfig;
  final QobuzAccountInfo accountInfo;
  final bool usedWebPlayerCredentials;

  const QobuzResolvedAuth({
    required this.authConfig,
    required this.accountInfo,
    required this.usedWebPlayerCredentials,
  });
}

class QobuzLoginResult {
  final String userToken;
  final QobuzAccountInfo accountInfo;

  const QobuzLoginResult({
    required this.userToken,
    required this.accountInfo,
  });
}

class QobuzWebPlayerCredentials {
  final String appId;
  final String appSecret;
  final bool isWebPlayer;

  const QobuzWebPlayerCredentials({
    required this.appId,
    required this.appSecret,
    this.isWebPlayer = false,
  });
}

/// Qobuz Service Implementation
/// Uses qobuz.squid.wtf as primary with dab.yeet.su and dabmusic.xyz as fallbacks
/// Provides 24-bit Hi-Res FLAC streaming
///
/// Based on working reference implementation that properly handles:
/// - URI encoding
/// - Pagination for search results
/// - Fallback stream endpoints
class QobuzServiceImpl implements MusicService {
  static const String _officialApiBase = 'https://www.qobuz.com/api.json/0.2';
  static const String _webPlayerBase = 'https://play.qobuz.com';
  static const List<QobuzWebPlayerCredentials> _builtInCredentialCandidates = [
    QobuzWebPlayerCredentials(
      appId: '312369995',
      appSecret: 'e79f8b9be485692b0e5f9dd895826368',
    ),
  ];
  static const String _searchUrl = 'https://qobuz.squid.wtf/api/get-music';
  static const String _albumUrl = 'https://qobuz.squid.wtf/api/get-album';
  static const String _artistUrl = 'https://qobuz.squid.wtf/api/get-artist';
  static const String _playlistUrl = 'https://qobuz.squid.wtf/api/get-playlist';

  // Stream endpoints with fallback (tries in order)
  static const List<Map<String, String>> _streamEndpoints = [
    {
      'name': 'squid',
      'url': 'https://qobuz.squid.wtf/api/download-music',
      'param': 'track_id'
    },
    {
      'name': 'dab',
      'url': 'https://dab.yeet.su/api/stream',
      'param': 'trackId',
      'quality': '7'
    },
    {
      'name': 'dabmusic',
      'url': 'https://dabmusic.xyz/api/stream',
      'param': 'trackId',
      'quality': '7'
    },
  ];

  static int _lastWorkingStreamIndex = 0;
  static QobuzWebPlayerCredentials? _cachedWebPlayerCredentials;
  static final http.Client _client = http.Client();
  final QobuzAuthConfig? authConfig;

  QobuzServiceImpl({this.authConfig});

  @override
  MusicSource get source => MusicSource.qobuz;

  bool get _hasOfficialAuth => authConfig?.isComplete == true;

  static Future<QobuzResolvedAuth> resolveTokenLogin({
    required String userToken,
    String userId = '',
    String appId = '',
    String appSecret = '',
  }) async {
    final cleanedToken = userToken.trim();
    if (cleanedToken.isEmpty) {
      throw Exception('Qobuz token is required');
    }

    final hasCustomCredentials =
        appId.trim().isNotEmpty && appSecret.trim().isNotEmpty;
    final candidates = <QobuzWebPlayerCredentials>[];
    final seen = <String>{};
    final errors = <String>[];

    void addCandidate(QobuzWebPlayerCredentials candidate) {
      final key = '${candidate.appId}:${candidate.appSecret}';
      if (seen.add(key)) {
        candidates.add(candidate);
      }
    }

    if (hasCustomCredentials) {
      addCandidate(
        QobuzWebPlayerCredentials(
          appId: appId.trim(),
          appSecret: appSecret.trim(),
        ),
      );
    } else {
      try {
        final webPlayer = await fetchWebPlayerCredentials();
        addCandidate(webPlayer);
      } catch (e) {
        errors.add(e.toString());
      }
      for (final candidate in _builtInCredentialCandidates) {
        addCandidate(candidate);
      }
    }

    if (candidates.isEmpty) {
      throw Exception(
        errors.isNotEmpty
            ? errors.first
            : 'Could not resolve Qobuz app credentials for token login',
      );
    }

    for (final credentials in candidates) {
      try {
        final loginResult = await _loginWithToken(
          appId: credentials.appId,
          token: cleanedToken,
        );
        final resolvedToken = loginResult.userToken.trim().isNotEmpty
            ? loginResult.userToken
            : cleanedToken;
        final resolvedUserId = userId.trim().isNotEmpty
            ? userId.trim()
            : loginResult.accountInfo.userId;
        final provisionalConfig = QobuzAuthConfig(
          userToken: resolvedToken,
          userId: resolvedUserId,
          appId: credentials.appId,
          appSecret: credentials.appSecret,
        );

        final provisionalService =
            QobuzServiceImpl(authConfig: provisionalConfig);
        final info = await provisionalService._resolveValidatedAccountInfo(
          loginResult.accountInfo,
        );

        return QobuzResolvedAuth(
          authConfig: QobuzAuthConfig(
            userToken: resolvedToken,
            userId: info.userId,
            appId: credentials.appId,
            appSecret: credentials.appSecret,
          ),
          accountInfo: info,
          usedWebPlayerCredentials:
              !hasCustomCredentials && credentials.isWebPlayer,
        );
      } catch (e) {
        errors.add(e.toString());
      }
    }

    throw Exception(
      errors.isNotEmpty
          ? errors.last
          : 'Qobuz token login failed with all known credentials',
    );
  }

  static Future<QobuzLoginResult> _loginWithToken({
    required String appId,
    required String token,
  }) async {
    final uri = Uri.parse('$_officialApiBase/user/login').replace(
      queryParameters: {
        'user_auth_token': token,
      },
    );
    final response = await _client.get(
      uri,
      headers: {
        'User-Agent': 'Dreamin/1.0',
        'X-App-Id': appId,
      },
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('Qobuz token login failed: ${response.statusCode}');
    }

    final root = json.decode(response.body) as Map<String, dynamic>;
    final user = root['user'] as Map<String, dynamic>? ?? root;
    final returnedToken = (root['user_auth_token'] ?? token).toString();
    return QobuzLoginResult(
      userToken: returnedToken,
      accountInfo: _accountInfoFromUserRoot(user),
    );
  }

  static Future<QobuzWebPlayerCredentials> fetchWebPlayerCredentials() async {
    final cached = _cachedWebPlayerCredentials;
    if (cached != null) {
      return cached;
    }

    final htmlResponse = await _client.get(
      Uri.parse('$_webPlayerBase/login'),
      headers: {'User-Agent': 'Mozilla/5.0'},
    ).timeout(const Duration(seconds: 20));

    if (htmlResponse.statusCode != 200) {
      throw Exception(
        'Failed to load Qobuz web player login page: ${htmlResponse.statusCode}',
      );
    }

    final html = htmlResponse.body;
    final bundleMatch = RegExp(
      r'<script src="(?<bundle>/resources/\d+\.\d+\.\d+-[a-z]\d{3}/bundle\.js)',
    ).firstMatch(html);
    final bundlePath = bundleMatch?.namedGroup('bundle');
    if (bundlePath == null || bundlePath.isEmpty) {
      throw Exception('Could not locate Qobuz web player bundle');
    }

    final bundleResponse = await _client.get(
      Uri.parse('$_webPlayerBase$bundlePath'),
      headers: {'User-Agent': 'Mozilla/5.0'},
    ).timeout(const Duration(seconds: 20));

    if (bundleResponse.statusCode != 200) {
      throw Exception(
        'Failed to load Qobuz web player bundle: ${bundleResponse.statusCode}',
      );
    }

    final bundle = bundleResponse.body;
    final appIdMatch = RegExp(
      r'production:\{api:\{appId:"(?<appId>.*?)",appSecret:',
    ).firstMatch(bundle);
    final appId = appIdMatch?.namedGroup('appId')?.trim() ?? '';
    if (appId.isEmpty) {
      throw Exception('Could not extract Qobuz web player app ID');
    }

    final seedMatch = RegExp(
      r'\):[a-z]\.initialSeed\("(?<seed>.*?)",window\.utimezone\.(?<timezone>[a-z]+)\)',
    ).firstMatch(bundle);
    final seed = seedMatch?.namedGroup('seed') ?? '';
    final timezone = seedMatch?.namedGroup('timezone') ?? '';
    if (seed.isEmpty || timezone.isEmpty) {
      throw Exception('Could not extract Qobuz web player seed');
    }

    final timezoneTitle =
        timezone.substring(0, 1).toUpperCase() + timezone.substring(1);
    final appSecret = _extractWebPlayerAppSecret(
      bundle: bundle,
      seed: seed,
      timezoneTitle: timezoneTitle,
    );
    if (appSecret.isEmpty) {
      throw Exception('Could not decode Qobuz web player app secret');
    }

    final credentials = QobuzWebPlayerCredentials(
      appId: appId,
      appSecret: appSecret,
      isWebPlayer: true,
    );
    _cachedWebPlayerCredentials = credentials;
    return credentials;
  }

  static String _extractWebPlayerAppSecret({
    required String bundle,
    required String seed,
    required String timezoneTitle,
  }) {
    final escapedTimezone = RegExp.escape(timezoneTitle);
    final patterns = <RegExp>[
      RegExp(
        'name:".*?/$escapedTimezone",info:"(?<info>.*?)",extras:"(?<extras>.*?)"',
      ),
      RegExp(
        'name:".*?/$escapedTimezone",info:\\\\"(?<info>.*?)\\\\",extras:\\\\"(?<extras>.*?)\\\\"',
      ),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(bundle);
      final info = match?.namedGroup('info') ?? '';
      final extras = match?.namedGroup('extras') ?? '';
      if (info.isEmpty || extras.isEmpty) {
        continue;
      }

      final encodedSecret = seed + info + extras;
      if (encodedSecret.length <= 44) {
        continue;
      }

      try {
        final decoded = utf8.decode(
          base64Decode(encodedSecret.substring(0, encodedSecret.length - 44)),
        );
        if (decoded.isNotEmpty) {
          return decoded;
        }
      } catch (_) {}
    }

    throw Exception('Could not extract Qobuz web player app secret');
  }

  // ============== HELPER FUNCTIONS ==============

  /// Extract cover URL from Qobuz image object
  /// Returns the highest quality available (large > small > thumbnail)
  static String? _extractCoverUrl(Map<String, dynamic>? image) {
    if (image == null) return null;
    return image['large'] as String? ??
        image['small'] as String? ??
        image['thumbnail'] as String?;
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static int? _asSampleRateHz(dynamic value) {
    if (value is num) {
      final raw = value.toDouble();
      if (raw <= 384) {
        return (raw * 1000).round();
      }
      return raw.round();
    }
    if (value is String) {
      final parsed = double.tryParse(value);
      if (parsed != null) {
        return parsed <= 384 ? (parsed * 1000).round() : parsed.round();
      }
    }
    return null;
  }

  static QobuzAccountInfo _accountInfoFromUserRoot(Map<String, dynamic> root) {
    final subscription = root['subscription'] as Map<String, dynamic>? ?? {};
    final credential = root['credential'] as Map<String, dynamic>? ?? {};
    final parameters = credential['parameters'] as Map<String, dynamic>? ?? {};

    return QobuzAccountInfo(
      userId: (root['id'] ?? '').toString(),
      displayName: (root['display_name'] ?? root['login'] ?? '').toString(),
      login: (root['login'] ?? '').toString(),
      email: (root['email'] ?? '').toString(),
      countryCode: (root['country_code'] ?? '').toString(),
      subscriptionLabel: (parameters['label'] ??
              credential['description'] ??
              subscription['offer'] ??
              'Qobuz')
          .toString(),
      startDate: (subscription['start_date'] ?? '').toString(),
      endDate: (subscription['end_date'] ?? '').toString(),
      losslessStreaming: parameters['lossless_streaming'] == true,
      hiResStreaming: parameters['hires_streaming'] == true,
    );
  }

  Map<String, String> _officialHeaders({bool authenticated = true}) {
    final headers = <String, String>{
      'User-Agent': 'Dreamin/1.0',
    };

    if (_hasOfficialAuth) {
      headers['X-App-Id'] = authConfig!.appId;
      if (authenticated) {
        headers['X-User-Auth-Token'] = authConfig!.userToken;
      }
    }

    return headers;
  }

  Uri _officialUri(String path, Map<String, String> params) {
    final query = <String, String>{
      ...params,
      if (_hasOfficialAuth) 'app_id': authConfig!.appId,
    };
    return Uri.parse('$_officialApiBase$path').replace(queryParameters: query);
  }

  String _fileSignature(String formatId, String trackId, String timestamp) {
    final secret = authConfig?.appSecret ?? '';
    final payload = 'trackgetFileUrlformat_id'
        '$formatId'
        'intentstreamtrack_id'
        '$trackId'
        '$timestamp'
        '$secret';
    return md5.convert(utf8.encode(payload)).toString();
  }

  Future<QobuzAccountInfo> getAccountInfo() async {
    if (!_hasOfficialAuth) {
      throw Exception('Qobuz credentials are missing');
    }

    final uri = _officialUri('/user/get', {
      'user_id': authConfig!.userId,
    });
    final response = await _client
        .get(uri, headers: _officialHeaders())
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception(
          'Qobuz account validation failed: ${response.statusCode}');
    }

    final root = json.decode(response.body) as Map<String, dynamic>;
    final subscription = root['subscription'] as Map<String, dynamic>? ?? {};
    final credential = root['credential'] as Map<String, dynamic>? ?? {};
    final parameters = credential['parameters'] as Map<String, dynamic>? ?? {};

    return QobuzAccountInfo(
      userId: (root['id'] ?? authConfig!.userId).toString(),
      displayName: (root['display_name'] ?? root['login'] ?? '').toString(),
      login: (root['login'] ?? '').toString(),
      email: (root['email'] ?? '').toString(),
      countryCode: (root['country_code'] ?? '').toString(),
      subscriptionLabel: (parameters['label'] ??
              credential['description'] ??
              subscription['offer'] ??
              'Qobuz')
          .toString(),
      startDate: (subscription['start_date'] ?? '').toString(),
      endDate: (subscription['end_date'] ?? '').toString(),
      losslessStreaming: parameters['lossless_streaming'] == true,
      hiResStreaming: parameters['hires_streaming'] == true,
    );
  }

  Future<QobuzAccountInfo> _getAccountInfoWithTokenOnlyFallback({
    String userIdHint = '',
  }) async {
    if (authConfig == null || authConfig!.appId.trim().isEmpty) {
      throw Exception('Qobuz app credentials are missing');
    }
    if (authConfig!.userToken.trim().isEmpty) {
      throw Exception('Qobuz token is missing');
    }

    final params = <String, String>{
      'app_id': authConfig!.appId,
      if (userIdHint.trim().isNotEmpty) 'user_id': userIdHint.trim(),
    };
    final uri = Uri.parse('$_officialApiBase/user/get')
        .replace(queryParameters: params.isEmpty ? null : params);
    final response = await _client.get(
      uri,
      headers: {
        'User-Agent': 'Dreamin/1.0',
        'X-App-Id': authConfig!.appId,
        'X-User-Auth-Token': authConfig!.userToken,
      },
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception(
        'Qobuz token validation failed: ${response.statusCode}',
      );
    }

    final root = json.decode(response.body) as Map<String, dynamic>;
    final subscription = root['subscription'] as Map<String, dynamic>? ?? {};
    final credential = root['credential'] as Map<String, dynamic>? ?? {};
    final parameters = credential['parameters'] as Map<String, dynamic>? ?? {};

    return QobuzAccountInfo(
      userId: (root['id'] ?? userIdHint).toString(),
      displayName: (root['display_name'] ?? root['login'] ?? '').toString(),
      login: (root['login'] ?? '').toString(),
      email: (root['email'] ?? '').toString(),
      countryCode: (root['country_code'] ?? '').toString(),
      subscriptionLabel: (parameters['label'] ??
              credential['description'] ??
              subscription['offer'] ??
              'Qobuz')
          .toString(),
      startDate: (subscription['start_date'] ?? '').toString(),
      endDate: (subscription['end_date'] ?? '').toString(),
      losslessStreaming: parameters['lossless_streaming'] == true,
      hiResStreaming: parameters['hires_streaming'] == true,
    );
  }

  Future<QobuzAccountInfo> _resolveValidatedAccountInfo(
    QobuzAccountInfo loginInfo,
  ) async {
    await _validateOfficialPlayback();
    try {
      return await getAccountInfo();
    } catch (_) {
      return loginInfo;
    }
  }

  Future<void> _validateOfficialPlayback() async {
    if (!_hasOfficialAuth) {
      throw Exception('Qobuz credentials are missing');
    }

    final timestamp =
        (DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000).toString();
    final signature = _fileSignature('5', '197432204', timestamp);
    final uri = _officialUri('/track/getFileUrl', {
      'track_id': '197432204',
      'format_id': '5',
      'intent': 'stream',
      'request_ts': timestamp,
      'request_sig': signature,
    });
    final response = await _client
        .get(uri, headers: _officialHeaders())
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception(
        'Qobuz playback validation failed: ${response.statusCode}',
      );
    }

    final payload = json.decode(response.body) as Map<String, dynamic>;
    final url = payload['url'];
    if (url is! String || url.isEmpty) {
      throw Exception('Qobuz playback validation returned no stream URL');
    }
  }

  // ============== SEARCH ==============

  @override
  Future<SearchResult> search(String query, {int limit = 30}) async {
    if (query.trim().isEmpty) {
      return const SearchResult(
          tracks: [],
          albums: [],
          artists: [],
          playlists: [],
          source: MusicSource.qobuz);
    }

    print('[Qobuz] Searching for: $query');

    final List<Track> allTracks = [];
    final List<Album> allAlbums = [];
    final List<Artist> allArtists = [];
    final List<Playlist> allPlaylists = [];
    String? lastError;

    if (_hasOfficialAuth) {
      try {
        final uri = _officialUri('/catalog/search', {
          'query': query,
          'limit': limit.clamp(1, 50).toString(),
          'offset': '0',
        });
        final response = await _client
            .get(uri, headers: _officialHeaders())
            .timeout(const Duration(seconds: 15));

        if (response.statusCode != 200) {
          throw Exception('HTTP ${response.statusCode}');
        }

        final searchData = json.decode(response.body) as Map<String, dynamic>;
        final trackItems = searchData['tracks']?['items'] as List? ?? [];
        final albumItems = searchData['albums']?['items'] as List? ?? [];
        final artistItems = searchData['artists']?['items'] as List? ?? [];
        final playlistItems = searchData['playlists']?['items'] as List? ?? [];

        for (final track in trackItems) {
          final qTrack = _trackFromJson(track as Map<String, dynamic>);
          if (!allTracks.any((t) => t.id == qTrack.id)) {
            allTracks.add(qTrack);
          }
        }
        for (final album in albumItems) {
          final qAlbum = _albumFromJson(album as Map<String, dynamic>);
          if (!allAlbums.any((a) => a.id == qAlbum.id)) {
            allAlbums.add(qAlbum);
          }
        }
        for (final artist in artistItems) {
          allArtists.add(_artistFromJson(artist as Map<String, dynamic>));
        }
        for (final playlist in playlistItems) {
          allPlaylists.add(_playlistFromJson(playlist as Map<String, dynamic>));
        }

        return SearchResult(
          tracks: allTracks,
          albums: allAlbums,
          artists: allArtists,
          playlists: allPlaylists,
          source: MusicSource.qobuz,
        );
      } catch (e) {
        print('[Qobuz] Official search failed, falling back to proxy: $e');
      }
    }

    // Fetch multiple pages (API returns ~10 per page)
    const int maxPages = 3;
    const int pageSize = 10;

    try {
      for (int page = 0; page < maxPages; page++) {
        final int offset = page * pageSize;

        // Build URL with proper encoding
        final uri = Uri.parse(
            '$_searchUrl?q=${Uri.encodeComponent(query)}&offset=$offset');
        print('[Qobuz] Request: $uri');

        final response = await _client.get(uri).timeout(
              const Duration(seconds: 15),
              onTimeout: () => throw TimeoutException('Search timed out'),
            );

        print('[Qobuz] Response status: ${response.statusCode}');

        if (response.statusCode != 200) {
          lastError = 'HTTP ${response.statusCode}';
          print('[Qobuz] Search page $page failed: ${response.statusCode}');
          break;
        }

        final data = json.decode(response.body);
        final searchData = data['data'] ?? data;

        // Parse tracks
        final trackItems = searchData['tracks']?['items'] as List? ?? [];
        for (final track in trackItems) {
          final qTrack = _trackFromJson(track as Map<String, dynamic>);
          if (!allTracks.any((t) => t.id == qTrack.id)) {
            allTracks.add(qTrack);
          }
        }

        // Parse albums
        final albumItems = searchData['albums']?['items'] as List? ?? [];
        for (final album in albumItems) {
          final qAlbum = _albumFromJson(album as Map<String, dynamic>);
          if (!allAlbums.any((a) => a.id == qAlbum.id)) {
            allAlbums.add(qAlbum);
          }
        }

        // Parse artists and playlists only on first page
        if (page == 0) {
          final artistItems = searchData['artists']?['items'] as List? ?? [];
          for (final artist in artistItems) {
            allArtists.add(_artistFromJson(artist as Map<String, dynamic>));
          }

          final playlistItems =
              searchData['playlists']?['items'] as List? ?? [];
          for (final playlist in playlistItems) {
            allPlaylists
                .add(_playlistFromJson(playlist as Map<String, dynamic>));
          }
        }

        print(
            '[Qobuz] Page ${page + 1}: ${trackItems.length} tracks, ${albumItems.length} albums');

        // Stop if no more results
        if (trackItems.isEmpty && albumItems.isEmpty) break;

        // Stop if we have enough
        if (allTracks.length >= limit && allAlbums.length >= limit) break;
      }

      print(
          '[Qobuz] Total: ${allTracks.length} tracks, ${allAlbums.length} albums, ${allArtists.length} artists');

      return SearchResult(
        tracks: allTracks,
        albums: allAlbums,
        artists: allArtists,
        playlists: allPlaylists,
        source: MusicSource.qobuz,
      );
    } catch (e) {
      lastError = e.toString();
      print('[Qobuz] Search error: $e');

      // Return partial results if any
      if (allTracks.isNotEmpty || allAlbums.isNotEmpty) {
        return SearchResult(
          tracks: allTracks,
          albums: allAlbums,
          artists: allArtists,
          playlists: allPlaylists,
          source: MusicSource.qobuz,
        );
      }

      // Throw exception if completely failed
      throw Exception('Qobuz search failed: $lastError');
    }
  }

  @override
  Future<List<Track>> searchTracks(String query, {int limit = 30}) async {
    final result = await search(query, limit: limit);
    return result.tracks.take(limit).toList();
  }

  @override
  Future<List<Album>> searchAlbums(String query, {int limit = 20}) async {
    final result = await search(query, limit: limit);
    return result.albums.take(limit).toList();
  }

  @override
  Future<List<Artist>> searchArtists(String query, {int limit = 20}) async {
    final result = await search(query, limit: limit);
    return result.artists.take(limit).toList();
  }

  @override
  Future<List<Playlist>> searchPlaylists(String query, {int limit = 20}) async {
    final result = await search(query, limit: limit);
    return result.playlists.take(limit).toList();
  }

  // ============== ALBUM DETAILS ==============

  @override
  Future<AlbumDetail?> getAlbum(String id) async {
    // Strip qobuz: prefix if present
    final albumId = id.replaceFirst('qobuz:', '');
    print('[Qobuz] Getting album: $albumId');

    try {
      final uri = _hasOfficialAuth
          ? _officialUri('/album/get', {
              'album_id': albumId,
            })
          : Uri.parse('$_albumUrl?album_id=${Uri.encodeComponent(albumId)}');
      final response = await _client
          .get(
            uri,
            headers: _hasOfficialAuth ? _officialHeaders() : null,
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        print('[Qobuz] Album fetch failed: ${response.statusCode}');
        return null;
      }

      final data = json.decode(response.body);
      final albumData = data['data'] ?? data;
      final tracksData = albumData['tracks']?['items'] as List? ?? [];

      if (tracksData.isEmpty) {
        print('[Qobuz] No tracks in album');
        return null;
      }

      // Get album cover for all tracks
      final albumImage = albumData['image'] as Map<String, dynamic>?;
      final albumCover = _extractCoverUrl(albumImage);

      // Parse album info
      final artistData = albumData['artist'] as Map<String, dynamic>?;
      final artistName = artistData?['name'] ?? 'Unknown Artist';
      final artistId = artistData?['id']?.toString() ?? '';

      // Parse year
      int? year;
      final releaseDate = albumData['release_date_original'] as String?;
      if (releaseDate != null && releaseDate.length >= 4) {
        year = int.tryParse(releaseDate.substring(0, 4));
      }

      // Parse tracks
      final tracks = tracksData
          .map((t) =>
              _trackFromJson(t as Map<String, dynamic>, albumCover: albumCover))
          .toList();

      print('[Qobuz] Found ${tracks.length} tracks in album');

      return AlbumDetail(
        id: 'qobuz:$albumId',
        title: albumData['title'] ?? 'Unknown Album',
        artist: artistName,
        artistId: artistId,
        coverArtUrl: albumCover,
        year: year,
        trackCount: tracks.length,
        source: MusicSource.qobuz,
        tracks: tracks,
        description: albumData['description'],
        copyright: albumData['copyright'],
      );
    } catch (e) {
      print('[Qobuz] Album fetch error: $e');
      return null;
    }
  }

  // ============== ARTIST DETAILS ==============

  @override
  Future<ArtistDetail?> getArtist(String id) async {
    final artistId = id.replaceFirst('qobuz:', '');
    print('[Qobuz] Getting artist: $artistId');

    try {
      if (_hasOfficialAuth) {
        try {
          final uri = _officialUri('/artist/get', {
            'artist_id': artistId,
          });
          final response = await _client
              .get(uri, headers: _officialHeaders())
              .timeout(const Duration(seconds: 15));

          if (response.statusCode == 200) {
            final artistData =
                json.decode(response.body) as Map<String, dynamic>;
            final artistName = _parseQobuzArtistName(artistData['name']);
            final imageUrl =
                _extractCoverUrl(artistData['image'] as Map<String, dynamic>?);
            final bio = _extractQobuzBiography(artistData);
            final albumCount = (artistData['albums_count'] as num?)?.toInt();
            List<Playlist> playlists = const [];
            try {
              playlists = _extractQobuzArtistPlaylists(artistData);
            } catch (e) {
              print('[Qobuz] Artist playlists extraction failed: $e');
            }
            List<Album> albums = const [];
            try {
              albums =
                  await _fetchOfficialArtistReleaseList(artistId, artistName);
            } catch (e) {
              print('[Qobuz] Official release list failed: $e');
            }

            SearchResult searchResult = const SearchResult(
              source: MusicSource.qobuz,
            );
            if (artistName != 'Unknown Artist') {
              try {
                searchResult = await search(artistName, limit: 50);
              } catch (_) {}
            }

            final fallbackAlbums = _filterAlbumsForArtist(
              searchResult.albums,
              artistId: artistId,
              artistName: artistName,
            );
            final topTracks = _filterTracksForArtist(
              searchResult.tracks,
              artistId: artistId,
              artistName: artistName,
              limit: 30,
            );
            List<Artist> relatedArtists = const [];
            try {
              relatedArtists = await _fetchOfficialRelatedArtists(
                artistData['similar_artist_ids'] as List?,
              );
            } catch (e) {
              print('[Qobuz] Official related artists failed: $e');
            }

            return ArtistDetail(
              id: 'qobuz:$artistId',
              name: artistName,
              imageUrl: imageUrl,
              albumCount: albumCount,
              source: MusicSource.qobuz,
              albums: albums.isNotEmpty ? albums : fallbackAlbums,
              topTracks: topTracks,
              bio: bio,
              playlists: playlists,
              relatedArtists: relatedArtists,
            );
          }
        } catch (e) {
          print('[Qobuz] Official artist fetch failed, falling back: $e');
        }
      }

      final uri =
          Uri.parse('$_artistUrl?artist_id=${Uri.encodeComponent(artistId)}');
      final response =
          await _client.get(uri).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        print('[Qobuz] Artist fetch failed: ${response.statusCode}');
        return null;
      }

      final data = json.decode(response.body);

      // API structure: { success: true, data: { artist: { ... } } }
      final artistData = data['data']?['artist'] ?? data['data'] ?? data;

      // Name can be string or object {display: "..."}
      String artistName = 'Unknown Artist';
      final nameField = artistData['name'];
      if (nameField is String) {
        artistName = nameField;
      } else if (nameField is Map) {
        artistName = nameField['display'] ?? 'Unknown Artist';
      }

      // Image is in images.portrait or image object
      final images = artistData['images'] as Map<String, dynamic>?;
      final legacyImage = artistData['image'] as Map<String, dynamic>?;
      String? imageUrl;
      if (images != null && images['portrait'] != null) {
        final portrait = images['portrait'];
        if (portrait is String) {
          imageUrl = portrait;
        } else if (portrait is Map) {
          imageUrl =
              portrait['large'] ?? portrait['small'] ?? portrait['thumbnail'];
        }
      } else {
        imageUrl = _extractCoverUrl(legacyImage);
      }

      final albums = <Album>[];
      final topTracks = <Track>[];
      final playlists = <Playlist>[];
      final seenAlbumIds = <String>{};
      final seenTrackIds = <String>{};
      final seenPlaylistIds = <String>{};

      // Parse albums from releases array
      // API structure: releases: [{type: 'album', items: [...]}, {type: 'live', items: []}, ...]
      final releases = artistData['releases'] as List? ?? [];
      for (final release in releases) {
        if (release is Map<String, dynamic>) {
          final releaseType = release['type'];
          final items = release['items'] as List? ?? [];
          for (final albumData in items) {
            try {
              if (albumData is Map<String, dynamic>) {
                final album = _albumFromQobuzArtist(
                  albumData,
                  artistName,
                  releaseType: releaseType?.toString(),
                );
                if (seenAlbumIds.add(album.id)) {
                  albums.add(album);
                }
              }
            } catch (e) {
              print('[Qobuz] Failed to parse album: $e');
            }
          }
        }
      }

      // Parse top tracks - direct array under artist
      final topTracksData = artistData['top_tracks'] as List? ?? [];
      for (final trackData in topTracksData) {
        try {
          if (trackData is Map<String, dynamic>) {
            final track = _trackFromQobuzArtist(trackData);
            if (seenTrackIds.add(track.id)) {
              topTracks.add(track);
            }
          }
        } catch (e) {
          print('[Qobuz] Failed to parse top track: $e');
        }
      }

      // Fallback: parse tracks_appears_on
      if (topTracks.isEmpty) {
        final appearsOnData = artistData['tracks_appears_on'] as List? ?? [];
        for (final trackData in appearsOnData) {
          try {
            if (trackData is Map<String, dynamic>) {
              final track = _trackFromQobuzArtist(trackData);
              if (seenTrackIds.add(track.id)) {
                topTracks.add(track);
              }
            }
          } catch (e) {
            print('[Qobuz] Failed to parse appears_on track: $e');
          }
        }
      }

      // If no tracks from API, search for artist's popular tracks
      if (topTracks.isEmpty && artistName != 'Unknown Artist') {
        print('[Qobuz] No tracks in response, searching for: $artistName');
        try {
          final searchResult = await search(artistName, limit: 30);
          // Filter tracks by this artist
          final artistTracks = searchResult.tracks
              .where(
                (t) => _artistMatches(
                  candidateArtistId: t.artistId,
                  candidateArtistName: t.artist,
                  artistId: artistId,
                  artistName: artistName,
                ),
              )
              .take(20)
              .toList();
          for (final track in artistTracks) {
            if (seenTrackIds.add(track.id)) {
              topTracks.add(track);
            }
          }
          print('[Qobuz] Found ${topTracks.length} tracks via search');
        } catch (e) {
          print('[Qobuz] Track search failed: $e');
        }
      }

      final playlistData = artistData['playlists'];
      if (playlistData is Map<String, dynamic>) {
        final items = playlistData['items'] as List? ?? [];
        for (final item in items) {
          if (item is Map<String, dynamic>) {
            final playlist = _playlistFromJson(item);
            if (seenPlaylistIds.add(playlist.id)) {
              playlists.add(playlist);
            }
          }
        }
      } else if (playlistData is List) {
        for (final item in playlistData) {
          if (item is Map<String, dynamic>) {
            final playlist = _playlistFromJson(item);
            if (seenPlaylistIds.add(playlist.id)) {
              playlists.add(playlist);
            }
          }
        }
      }
      final bio = _extractQobuzBiography(artistData);
      final albumCount = (artistData['albums_count'] as num?)?.toInt();

      print(
          '[Qobuz] Artist loaded: $artistName - ${albums.length} albums, ${topTracks.length} tracks');

      return ArtistDetail(
        id: 'qobuz:$artistId',
        name: artistName,
        imageUrl: imageUrl,
        albumCount: albumCount,
        source: MusicSource.qobuz,
        albums: albums,
        topTracks: topTracks,
        bio: bio,
        playlists: playlists,
      );
    } catch (e) {
      print('[Qobuz] Artist fetch error: $e');
      return null;
    }
  }

  Future<List<Album>> _fetchOfficialArtistReleaseList(
    String artistId,
    String artistName,
  ) async {
    const pageSize = 100;
    final albums = <Album>[];
    final seenAlbumIds = <String>{};
    var offset = 0;
    var hasMore = true;

    while (hasMore && offset < 300) {
      final uri = _officialUri('/artist/getReleasesList', {
        'artist_id': artistId,
        'release_type': 'album,epSingle,live,compilation,other',
        'sort': 'release_date_by_priority',
        'order': 'desc',
        'track_size': '1',
        'limit': pageSize.toString(),
        'offset': offset.toString(),
      });
      final response = await _client
          .get(uri, headers: _officialHeaders())
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw Exception(
          'Qobuz release list failed with status ${response.statusCode}',
        );
      }

      final payload = json.decode(response.body) as Map<String, dynamic>;
      final items = payload['items'] as List? ?? const [];
      for (final item in items) {
        if (item is! Map<String, dynamic>) {
          continue;
        }
        final album = _albumFromQobuzArtist(
          item,
          artistName,
          releaseType: item['release_type']?.toString(),
        );
        if (seenAlbumIds.add(album.id)) {
          albums.add(album);
        }
      }

      final pageHasMore = payload['has_more'] == true;
      if (!pageHasMore || items.length < pageSize) {
        hasMore = false;
      } else {
        offset += pageSize;
      }
    }

    return albums;
  }

  Future<List<Artist>> _fetchOfficialRelatedArtists(List? ids) async {
    if (!_hasOfficialAuth || ids == null || ids.isEmpty) {
      return const [];
    }

    final uniqueIds = ids
        .map((id) => id?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet()
        .take(8)
        .toList();

    final results = await Future.wait<Artist?>([
      for (final relatedArtistId in uniqueIds)
        () async {
          try {
            final uri = _officialUri('/artist/get', {
              'artist_id': relatedArtistId,
            });
            final response = await _client
                .get(uri, headers: _officialHeaders())
                .timeout(const Duration(seconds: 15));
            if (response.statusCode != 200) {
              return null;
            }

            final payload = json.decode(response.body) as Map<String, dynamic>;
            return _artistFromJson(payload);
          } catch (_) {
            return null;
          }
        }(),
    ]);

    final artists = <Artist>[];
    final seenIds = <String>{};
    for (final artist in results) {
      if (artist == null || artist.id.isEmpty) {
        continue;
      }
      if (seenIds.add(artist.id)) {
        artists.add(artist);
      }
    }
    return artists;
  }

  List<Playlist> _extractQobuzArtistPlaylists(Map<String, dynamic> artistData) {
    final playlistContainer = artistData['playlists'];
    final playlistItems = playlistContainer is Map<String, dynamic>
        ? playlistContainer['items'] as List? ?? const []
        : playlistContainer is List
            ? playlistContainer
            : const [];

    final playlists = <Playlist>[];
    final seenIds = <String>{};
    for (final item in playlistItems) {
      if (item is! Map<String, dynamic>) {
        continue;
      }
      final playlist = _playlistFromJson(item);
      if (seenIds.add(playlist.id)) {
        playlists.add(playlist);
      }
    }
    return playlists;
  }

  List<Album> _filterAlbumsForArtist(
    List<Album> albums, {
    required String artistId,
    required String artistName,
  }) {
    final filtered = <Album>[];
    final seenIds = <String>{};
    for (final album in albums) {
      if (!_artistMatches(
        candidateArtistId: album.artistId,
        candidateArtistName: album.artist,
        artistId: artistId,
        artistName: artistName,
      )) {
        continue;
      }
      if (seenIds.add(album.id)) {
        filtered.add(album);
      }
    }
    return filtered;
  }

  List<Track> _filterTracksForArtist(
    List<Track> tracks, {
    required String artistId,
    required String artistName,
    int limit = 30,
  }) {
    final filtered = <Track>[];
    final seenIds = <String>{};
    for (final track in tracks) {
      if (!_artistMatches(
        candidateArtistId: track.artistId,
        candidateArtistName: track.artist,
        artistId: artistId,
        artistName: artistName,
      )) {
        continue;
      }
      if (seenIds.add(track.id)) {
        filtered.add(track);
      }
      if (filtered.length >= limit) {
        break;
      }
    }
    return filtered;
  }

  bool _artistMatches({
    required String? candidateArtistId,
    required String candidateArtistName,
    required String artistId,
    required String artistName,
  }) {
    if (candidateArtistId != null &&
        candidateArtistId.isNotEmpty &&
        candidateArtistId == artistId) {
      return true;
    }
    return _normalizeArtistName(candidateArtistName) ==
        _normalizeArtistName(artistName);
  }

  String _normalizeArtistName(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
  }

  String _parseQobuzArtistName(dynamic nameField) {
    if (nameField is String && nameField.trim().isNotEmpty) {
      return nameField;
    }
    if (nameField is Map) {
      final display = nameField['display']?.toString().trim();
      if (display != null && display.isNotEmpty) {
        return display;
      }
      final direct = nameField['name']?.toString().trim();
      if (direct != null && direct.isNotEmpty) {
        return direct;
      }
    }
    return 'Unknown Artist';
  }

  String? _extractQobuzBiography(Map<String, dynamic> artistData) {
    final biography = artistData['biography'];
    if (biography is Map) {
      final content = biography['content'] ?? biography['summary'];
      if (content != null) {
        return content.toString();
      }
    } else if (biography is String && biography.trim().isNotEmpty) {
      return biography;
    }

    final information = artistData['information'];
    if (information is String && information.trim().isNotEmpty) {
      return information;
    }
    return null;
  }

  // ============== PLAYLIST DETAILS ==============

  @override
  Future<PlaylistDetail?> getPlaylist(String id) async {
    final playlistId = id.replaceFirst('qobuz:', '');
    print('[Qobuz] Getting playlist: $playlistId');

    final List<Track> allTracks = [];
    const int limit = 100;
    int offset = 0;
    bool hasMore = true;
    String? playlistName;
    String? playlistCover;
    String? description;

    try {
      while (hasMore) {
        final uri = _hasOfficialAuth
            ? _officialUri('/playlist/get', {
                'playlist_id': playlistId,
                'extra': 'tracks',
                'limit': limit.toString(),
                'offset': offset.toString(),
              })
            : Uri.parse(
                '$_playlistUrl?playlist_id=${Uri.encodeComponent(playlistId)}&limit=$limit&offset=$offset');

        final response = await _client
            .get(
              uri,
              headers: _hasOfficialAuth ? _officialHeaders() : null,
            )
            .timeout(const Duration(seconds: 20));

        if (response.statusCode != 200) {
          print('[Qobuz] Playlist fetch failed: ${response.statusCode}');
          break;
        }

        final data = json.decode(response.body);
        final playlistData = data['data'] ?? data;

        // Get playlist info on first page
        if (offset == 0) {
          playlistName = playlistData['name'] ?? 'Unknown Playlist';
          description = playlistData['description'];
          final images = playlistData['images'] as Map<String, dynamic>?;
          if (images != null) {
            playlistCover =
                images['large'] ?? images['small'] ?? images['thumbnail'];
          }
        }

        // Try multiple paths for tracks
        List? tracks;
        final tracksContainer = playlistData['tracks'] ?? data['tracks'];
        if (tracksContainer is Map) {
          tracks = tracksContainer['items'] as List?;
        } else if (tracksContainer is List) {
          tracks = tracksContainer;
        }

        if (tracks == null || tracks.isEmpty) {
          hasMore = false;
          break;
        }

        print('[Qobuz] Got ${tracks.length} tracks at offset $offset');

        for (final item in tracks) {
          final trackData = item['item'] ?? item['track'] ?? item;
          allTracks.add(_trackFromJson(trackData as Map<String, dynamic>));
        }

        offset += limit;
        if (tracks.length < limit) hasMore = false;
        if (allTracks.length >= 1000) hasMore = false; // Safety limit
      }

      print('[Qobuz] Loaded ${allTracks.length} total tracks from playlist');

      return PlaylistDetail(
        id: 'qobuz:$playlistId',
        title: playlistName ?? 'Unknown Playlist',
        description: description ?? '',
        coverArtUrl: playlistCover,
        trackCount: allTracks.length,
        source: MusicSource.qobuz,
        tracks: allTracks,
      );
    } catch (e) {
      print('[Qobuz] Playlist fetch error: $e');
      return null;
    }
  }

  /// Resolve stream URL + quality metadata for playback badge rendering.
  Future<QobuzStreamInfo?> getStreamInfo(
    String trackId, {
    AudioQuality? fallbackQuality,
  }) async {
    final candidates = await getStreamCandidates(
      trackId,
      fallbackQuality: fallbackQuality,
    );
    return candidates.isEmpty ? null : candidates.first;
  }

  Future<List<QobuzStreamInfo>> getStreamCandidates(
    String trackId, {
    AudioQuality? fallbackQuality,
  }) async {
    final cleanId = trackId.replaceFirst('qobuz:', '');
    print('[Qobuz] Getting stream info for track: $cleanId');
    final candidates = <QobuzStreamInfo>[];
    final seenUrls = <String>{};

    if (_hasOfficialAuth) {
      final officialCandidates = await _getOfficialStreamCandidates(
        cleanId,
        fallbackQuality: fallbackQuality,
      );
      for (final candidate in officialCandidates) {
        if (seenUrls.add(candidate.url)) {
          candidates.add(candidate);
        }
      }
      return candidates;
    }

    final endpoints = [
      ..._streamEndpoints.sublist(_lastWorkingStreamIndex),
      ..._streamEndpoints.sublist(0, _lastWorkingStreamIndex),
    ];
    final proxyQualities = _proxyQualityParams();

    for (int i = 0; i < endpoints.length; i++) {
      final endpoint = endpoints[i];
      final endpointQualityParams =
          endpoint['quality'] != null ? proxyQualities : <String?>[null];

      for (final qualityParam in endpointQualityParams) {
        try {
          String url = '${endpoint['url']}?${endpoint['param']}=$cleanId';
          if (qualityParam != null) {
            url += '&quality=$qualityParam';
          }

          print('[Qobuz] Trying ${endpoint['name']}: $url');

          final response = await _client.get(Uri.parse(url)).timeout(
                const Duration(seconds: 8),
              );

          if (response.statusCode != 200) {
            print(
                '[Qobuz] ${endpoint['name']} returned ${response.statusCode}');
            continue;
          }

          final raw = json.decode(response.body);
          final root = raw is Map<String, dynamic> ? raw : <String, dynamic>{};
          final payload = root['data'] is Map<String, dynamic>
              ? root['data'] as Map<String, dynamic>
              : root;

          final streamUrl = payload['url'] ?? root['url'];
          if (streamUrl is! String ||
              streamUrl.isEmpty ||
              !seenUrls.add(streamUrl)) {
            continue;
          }

          final bitDepthFromResponse = _asInt(
            payload['maximum_bit_depth'] ??
                payload['bit_depth'] ??
                payload['bitDepth'] ??
                payload['audio_info']?['maximum_bit_depth'] ??
                root['maximum_bit_depth'] ??
                root['bit_depth'] ??
                root['bitDepth'],
          );

          final sampleRateFromResponse = _asInt(
            payload['maximum_sampling_rate'] ??
                payload['sample_rate'] ??
                payload['sampleRate'] ??
                payload['audio_info']?['maximum_sampling_rate'] ??
                root['maximum_sampling_rate'] ??
                root['sample_rate'] ??
                root['sampleRate'],
          );

          final inferredBitDepth = bitDepthFromResponse ??
              ((qualityParam == '7') ? 24 : (fallbackQuality?.bitDepth ?? 16));
          final inferredSampleRate = sampleRateFromResponse ??
              (inferredBitDepth >= 24
                  ? (qualityParam == '27'
                      ? 192000
                      : (fallbackQuality?.sampleRate ?? 96000))
                  : (fallbackQuality?.sampleRate ?? 44100));

          final originalIndex =
              _streamEndpoints.indexWhere((e) => e['name'] == endpoint['name']);
          if (originalIndex != -1) {
            _lastWorkingStreamIndex = originalIndex;
          }

          final qualityCode =
              inferredBitDepth >= 24 ? 'HI_RES_LOSSLESS' : 'LOSSLESS';
          print(
            '[Qobuz] Stream quality: $qualityCode (${inferredBitDepth}-bit/${inferredSampleRate}Hz) via ${endpoint['name'] ?? 'unknown'}',
          );

          candidates.add(
            QobuzStreamInfo(
              url: streamUrl,
              bitDepth: inferredBitDepth,
              sampleRate: inferredSampleRate,
              qualityCode: qualityCode,
              endpoint: endpoint['name'] ?? 'unknown',
            ),
          );
        } catch (e) {
          print('[Qobuz] ${endpoint['name'] ?? 'unknown'} failed: $e');
        }
      }
    }

    if (candidates.isEmpty) {
      print('[Qobuz] All stream endpoints failed for track: $cleanId');
    }
    return candidates;
  }

  List<String> _preferredFormats() {
    return const ['27', '7', '6', '5'];
  }

  List<String> _proxyQualityParams() {
    return const ['7', '6', '5'];
  }

  Future<List<QobuzStreamInfo>> _getOfficialStreamCandidates(
    String trackId, {
    AudioQuality? fallbackQuality,
  }) async {
    if (!_hasOfficialAuth) {
      return const [];
    }

    final candidates = <QobuzStreamInfo>[];
    final seenUrls = <String>{};
    for (final format in _preferredFormats()) {
      try {
        final timestamp =
            (DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000).toString();
        final signature = _fileSignature(format, trackId, timestamp);
        final uri = _officialUri('/track/getFileUrl', {
          'track_id': trackId,
          'format_id': format,
          'intent': 'stream',
          'request_ts': timestamp,
          'request_sig': signature,
        });
        final response = await _client
            .get(uri, headers: _officialHeaders())
            .timeout(const Duration(seconds: 6));

        if (response.statusCode != 200) {
          continue;
        }

        final payload = json.decode(response.body) as Map<String, dynamic>;
        final streamUrl = payload['url'];
        if (streamUrl is! String ||
            streamUrl.isEmpty ||
            !seenUrls.add(streamUrl)) {
          continue;
        }

        final bitDepth = _asInt(payload['bit_depth']) ??
            (format == '27' || format == '7'
                ? 24
                : (fallbackQuality?.bitDepth ?? 16));
        final sampleRate = _asSampleRateHz(payload['sampling_rate']) ??
            (bitDepth >= 24
                ? (format == '27' ? 192000 : 96000)
                : (fallbackQuality?.sampleRate ?? 44100));
        final qualityCode = bitDepth >= 24 ? 'HI_RES_LOSSLESS' : 'LOSSLESS';

        print(
          '[Qobuz] Official stream quality: $qualityCode (${bitDepth}-bit/${sampleRate}Hz)',
        );

        candidates.add(
          QobuzStreamInfo(
            url: streamUrl,
            bitDepth: bitDepth,
            sampleRate: sampleRate,
            qualityCode: qualityCode,
            endpoint: 'official',
          ),
        );
      } catch (e) {
        print('[Qobuz] Official getFileUrl failed for format $format: $e');
      }
    }

    return candidates;
  }

  @override
  Future<String?> getStreamUrl(String trackId) async {
    final info = await getStreamInfo(trackId);
    return info?.url;
  }

  @override
  String getCoverArt(String? id, {int size = 300}) {
    // Cover art URLs are already full URLs in Qobuz responses
    // This method is for compatibility with other services
    return '';
  }

  // ============== DISCOVERY (search-based for home) ==============

  @override
  Future<List<Album>> getNewAlbums({int limit = 20}) async {
    try {
      final result = await search('new releases', limit: limit);
      return result.albums;
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<Playlist>> getPopularPlaylists({int limit = 20}) async {
    try {
      final result = await search('best hits', limit: limit);
      return result.playlists;
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<Track>> getRandomTracks({int limit = 20}) async {
    try {
      final result = await search('popular', limit: limit);
      return result.tracks;
    } catch (_) {
      return [];
    }
  }

  // ============== MODEL CONVERSIONS ==============

  Track _trackFromJson(Map<String, dynamic> json, {String? albumCover}) {
    // Extract cover art from album.image object
    final albumImage = json['album']?['image'] as Map<String, dynamic>?;
    final String? cover = _extractCoverUrl(albumImage) ?? albumCover;

    // Determine quality from bit depth
    final int bitDepth = json['maximum_bit_depth'] ?? 16;

    return Track(
      id: 'qobuz:${json['id']}',
      title: json['title'] ?? 'Unknown',
      artist: json['performer']?['name'] ??
          json['artist']?['name'] ??
          'Unknown Artist',
      artistId: json['performer']?['id']?.toString() ??
          json['artist']?['id']?.toString() ??
          '',
      album: json['album']?['title'] ?? 'Unknown Album',
      albumId: 'qobuz:${json['album']?['id'] ?? ''}',
      duration: Duration(seconds: json['duration'] ?? 0),
      trackNumber: json['track_number'] ?? 1,
      coverArtUrl: cover,
      isExplicit: false,
      source: MusicSource.qobuz,
      quality: bitDepth >= 24
          ? const AudioQuality(bitDepth: 24, sampleRate: 96000)
          : const AudioQuality(bitDepth: 16, sampleRate: 44100),
    );
  }

  Album _albumFromJson(Map<String, dynamic> json) {
    final image = json['image'] as Map<String, dynamic>?;

    int? year;
    final releaseDate =
        (json['release_date_original'] ?? json['release_date'])?.toString();
    if (releaseDate != null && releaseDate.length >= 4) {
      year = int.tryParse(releaseDate.substring(0, 4));
    }

    return Album(
      id: 'qobuz:${json['id']}',
      title: _buildQobuzAlbumTitle(json),
      artist: _parseQobuzArtistName(json['artist']?['name']),
      artistId: json['artist']?['id']?.toString() ?? '',
      coverArtUrl: _extractCoverUrl(image),
      year: year,
      trackCount: (json['tracks_count'] as num?)?.toInt() ?? 0,
      source: MusicSource.qobuz,
      albumType: _inferQobuzAlbumType(json),
    );
  }

  Artist _artistFromJson(Map<String, dynamic> json) {
    final image = json['image'] as Map<String, dynamic>?;

    return Artist(
      id: 'qobuz:${json['id']}',
      name: _parseQobuzArtistName(json['name']),
      imageUrl: _extractCoverUrl(image),
      albumCount: (json['albums_count'] as num?)?.toInt(),
      source: MusicSource.qobuz,
    );
  }

  Playlist _playlistFromJson(Map<String, dynamic> json) {
    // Playlists have images in a different structure
    final images = json['images'] as Map<String, dynamic>?;
    String? cover;
    if (images != null) {
      cover = images['large'] ?? images['small'] ?? images['thumbnail'];
    }

    return Playlist(
      id: 'qobuz:${json['id']}',
      title: json['name'] ?? 'Unknown Playlist',
      description: json['description'] ?? '',
      coverArtUrl: cover,
      trackCount: (json['tracks_count'] as num?)?.toInt() ?? 0,
      creatorName: json['owner']?['name']?.toString(),
      source: MusicSource.qobuz,
    );
  }

  /// Parse album from artist endpoint response
  /// Artist endpoint returns different structure: name can be {display: "..."} or string
  Album _albumFromQobuzArtist(
    Map<String, dynamic> json,
    String artistName, {
    String? releaseType,
  }) {
    final image = json['image'] as Map<String, dynamic>?;

    int? year;
    final releaseDate = json['release_date_original'] ?? json['release_date'];
    if (releaseDate is String && releaseDate.length >= 4) {
      year = int.tryParse(releaseDate.substring(0, 4));
    }

    // Artist in artist endpoint albums may not have full data
    String albumArtist = artistName;
    final artistData = json['artist'];
    if (artistData is Map) {
      final nameField = artistData['name'];
      if (nameField is String) {
        albumArtist = nameField;
      } else if (nameField is Map) {
        albumArtist = nameField['display'] ?? artistName;
      }
    }

    return Album(
      id: 'qobuz:${json['id']}',
      title: _buildQobuzAlbumTitle(json),
      artist: albumArtist,
      artistId: json['artist']?['id']?.toString() ?? '',
      coverArtUrl: _extractCoverUrl(image),
      year: year,
      trackCount: (json['tracks_count'] as num?)?.toInt() ?? 0,
      source: MusicSource.qobuz,
      albumType: _inferQobuzAlbumType(json, releaseType: releaseType),
    );
  }

  String _buildQobuzAlbumTitle(Map<String, dynamic> json) {
    final baseTitle =
        (json['title'] ?? json['name'] ?? 'Unknown Album').toString().trim();
    final version = (json['version'] ?? '').toString().trim();
    if (version.isEmpty) {
      return baseTitle;
    }

    final lowerBaseTitle = baseTitle.toLowerCase();
    final lowerVersion = version.toLowerCase();
    if (lowerBaseTitle.contains(lowerVersion)) {
      return baseTitle;
    }
    return '$baseTitle ($version)';
  }

  AlbumType _inferQobuzAlbumType(
    Map<String, dynamic> json, {
    String? releaseType,
  }) {
    final type = (releaseType ??
            json['release_type'] ??
            json['product_type'] ??
            json['album_type'] ??
            json['type'] ??
            '')
        .toString()
        .toLowerCase();
    final title =
        (json['title'] ?? json['name'] ?? '').toString().toLowerCase();

    if (type.contains('live') || title.contains('live')) {
      return AlbumType.live;
    }
    if (type.contains('ep')) {
      return AlbumType.ep;
    }
    if (type.contains('single')) {
      return AlbumType.single;
    }
    if (type.contains('compilation') ||
        type.contains('best') ||
        type.contains('greatest')) {
      return AlbumType.compilation;
    }
    if (type.contains('other')) {
      return AlbumType.other;
    }
    return AlbumType.album;
  }

  /// Parse track from artist endpoint response (top_tracks, tracks_appears_on)
  /// Has different structure: artist.name can be {display: "..."}
  Track _trackFromQobuzArtist(Map<String, dynamic> json) {
    // Extract cover from album.image
    final albumImage = json['album']?['image'] as Map<String, dynamic>?;
    final cover = _extractCoverUrl(albumImage);

    // Extract artist name - can be string or {display: "..."}
    String artistName = 'Unknown Artist';
    final artistData = json['artist'] ?? json['performer'];
    if (artistData is Map) {
      final nameField = artistData['name'];
      if (nameField is String) {
        artistName = nameField;
      } else if (nameField is Map) {
        artistName = nameField['display'] ?? 'Unknown Artist';
      }
    }

    // Get bit depth for quality
    final audioInfo = json['audio_info'] as Map<String, dynamic>?;
    final int bitDepth =
        audioInfo?['maximum_bit_depth'] ?? json['maximum_bit_depth'] ?? 16;

    return Track(
      id: 'qobuz:${json['id']}',
      title: json['title'] ?? 'Unknown',
      artist: artistName,
      artistId: json['artist']?['id']?.toString() ?? '',
      album: json['album']?['title'] ?? 'Unknown Album',
      albumId: 'qobuz:${json['album']?['id'] ?? ''}',
      duration: Duration(seconds: json['duration'] ?? 0),
      trackNumber: json['physical_support']?['track_number'] ??
          json['track_number'] ??
          1,
      coverArtUrl: cover,
      isExplicit: json['parental_warning'] == true,
      source: MusicSource.qobuz,
      quality: bitDepth >= 24
          ? const AudioQuality(bitDepth: 24, sampleRate: 96000)
          : const AudioQuality(bitDepth: 16, sampleRate: 44100),
    );
  }
}

class QobuzStreamInfo {
  final String url;
  final int bitDepth;
  final int sampleRate;
  final String qualityCode;
  final String endpoint;

  const QobuzStreamInfo({
    required this.url,
    required this.bitDepth,
    required this.sampleRate,
    required this.qualityCode,
    required this.endpoint,
  });
}
