/// TIDAL API endpoints with intelligent failover
/// Production-grade endpoint management with health tracking
class TidalEndpoints {
  /// All available endpoints - ordered by reliability
  /// Keep this pool limited to hosts that are currently healthy for the
  /// app's hifi-api request pattern.
  static const List<String> endpoints = [
    'https://hifi-one.spotisaver.net',
    'https://hifi-two.spotisaver.net',
    'https://hifi.geeked.wtf',
    'https://wolf.qqdl.site',
    'https://maus.qqdl.site',
    'https://vogel.qqdl.site',
    'https://katze.qqdl.site',
    'https://hund.qqdl.site',
    'https://ohio-1.monochrome.tf',
    'https://frankfurt-1.monochrome.tf',
  ];

  /// Streaming should prefer endpoints that consistently return full media
  /// rather than metadata-only or short preview-like responses.
  static const List<String> streamEndpoints = [
    'https://hifi-one.spotisaver.net',
    'https://hifi-two.spotisaver.net',
    'https://hifi.geeked.wtf',
    'https://wolf.qqdl.site',
    'https://maus.qqdl.site',
    'https://vogel.qqdl.site',
    'https://katze.qqdl.site',
    'https://hund.qqdl.site',
    'https://ohio-1.monochrome.tf',
    'https://frankfurt-1.monochrome.tf',
  ];

  /// Monochrome publishes live TIDAL host lists through these workers.
  /// Dreamin can consume them at runtime to discover currently healthy hosts.
  static const List<String> workerFeeds = [
    'https://tidal-uptime.jiffy-puffs-1j.workers.dev/',
    'https://tidal-uptime.props-76styles.workers.dev/',
  ];

  /// Hosts excluded from dynamic promotion after direct app-style testing.
  static const Set<String> excludedDynamicHosts = {
    'https://api.monochrome.tf',
    'https://arran.monochrome.tf',
    'https://triton.squid.wtf',
    'https://tidal.kinoplus.online',
    'https://eu-central.monochrome.tf',
    'https://us-west.monochrome.tf',
    'https://monochrome-api.samidy.com',
    'https://singapore-1.monochrome.tf',
  };

  /// Removed from rotation after repeated failures in direct app-style tests:
  /// - api.monochrome.tf (403 on track stream route)
  /// - arran.monochrome.tf (502 on info/track routes)
  /// - eu-central/us-west.monochrome.tf (metadata only, track route 403)
  /// - monochrome-api.samidy.com (metadata only, track route 403)
  /// - triton.squid.wtf (502)
  /// - tidal.kinoplus.online (403/429 on key routes)
  /// - singapore-1.monochrome.tf (artist route timed out in direct tests)
  /// - hifi.401658.xyz redirects to GitHub, not an API

  // Core API paths (hifi-api format)
  static const String searchPath =
      '/search/'; // Use ?s= for tracks, ?a= for artists, ?al= for albums
  static const String albumPath = '/album/'; // Use ?id=
  static const String artistPath = '/artist/'; // Use ?id= or ?f= for full data
  static const String playlistPath = '/playlist/'; // Use ?id=
  static const String trackPath = '/track/'; // Use ?id= for stream URL
  static const String lyricsPath = '/lyrics/'; // Use ?id=
  static const String coverPath = '/cover/'; // Use ?id= or ?q=
  static const String mixPath = '/mix/'; // Use ?id=
  static const String infoPath = '/info/'; // Use ?id= for track info

  // Quality options (for stream requests)
  static const String qualityMaster =
      'HI_RES_LOSSLESS'; // 24-bit/up to 192kHz MQA
  static const String qualityHifi = 'LOSSLESS'; // 16-bit/44.1kHz FLAC
  static const String qualityHigh = 'HIGH'; // 320kbps AAC
  static const String qualityStandard = 'LOW'; // 128kbps AAC
}

/// Subsonic API configuration (scaffolded for future)
class SubsonicConfig {
  final String serverUrl;
  final String username;
  final String password;
  final String apiVersion;

  const SubsonicConfig({
    required this.serverUrl,
    required this.username,
    required this.password,
    this.apiVersion = '1.16.1',
  });

  /// Generate authentication parameters
  Map<String, String> get authParams => {
        'u': username,
        'p': password,
        'v': apiVersion,
        'c': 'DreaminApp',
        'f': 'json',
      };
}

/// Qobuz API endpoints (24-bit Hi-Res streaming via proxies)
/// Quality 7 = 24-bit FLAC (highest quality)
class QobuzEndpoints {
  /// Primary endpoints - ordered by reliability
  /// dab and dabmusic have full search + stream, squid is stream only
  static const List<String> searchEndpoints = [
    'https://dab.yeet.su',
    'https://dabmusic.xyz',
  ];

  /// Stream endpoints (can use any of these with track_id)
  static const List<String> streamEndpoints = [
    'https://dab.yeet.su',
    'https://dabmusic.xyz',
    'https://qobuz.squid.wtf', // Stream only, no search
  ];

  // API paths
  static const String searchPath = '/api/search'; // ?q=query
  static const String streamPath =
      '/api/stream'; // ?track_id=&quality=7 (dab/dabmusic)
  static const String downloadPath =
      '/api/download-music'; // ?track_id= (squid)

  // Quality levels for stream endpoint
  static const int quality24bit = 7; // 24-bit/up to 192kHz FLAC
  static const int quality16bit = 6; // 16-bit/44.1kHz FLAC (CD quality)
  static const int quality320mp3 = 5; // 320kbps MP3
}
