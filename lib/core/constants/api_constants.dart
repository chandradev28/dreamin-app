/// TIDAL API endpoints with intelligent failover
/// Production-grade endpoint management with health tracking
class TidalEndpoints {
  /// All available endpoints - ordered by reliability
  /// Mixed endpoint set:
  /// - triton/kinoplus can return DASH master manifests for some tracks
  /// - monochrome exposes hifi-api with confirmed 24-bit TIDAL stream metadata
  /// - qqdl cluster reliably returns direct playable URLs
  static const List<String> endpoints = [
    'https://triton.squid.wtf',
    'https://tidal.kinoplus.online',
    'https://api.monochrome.tf',
    'https://hund.qqdl.site', // qqdl cluster (working)
    'https://katze.qqdl.site',
    'https://maus.qqdl.site',
    'https://vogel.qqdl.site',
    'https://wolf.qqdl.site',
  ];

  /// Dead endpoints (do not include in rotation)
  /// hifi.401658.xyz - redirects to GitHub, not an API

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
