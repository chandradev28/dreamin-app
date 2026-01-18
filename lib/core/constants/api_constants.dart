/// TIDAL API endpoints with intelligent failover
/// Production-grade endpoint management with health tracking
class TidalEndpoints {
  /// All available endpoints - ordered by reliability
  /// Primary endpoints (squid.wtf) first, then qqdl.site cluster, then others
  static const List<String> endpoints = [
    'https://triton.squid.wtf',         // Primary - fastest, most reliable
    'https://tidal.kinoplus.online',    // Backup primary
    'https://hund.qqdl.site',           // qqdl cluster
    'https://katze.qqdl.site',
    'https://maus.qqdl.site',
    'https://vogel.qqdl.site',
    'https://wolf.qqdl.site',
    'https://tidal-api.binimum.org',    // Additional fallback
  ];
  
  /// Dead endpoints (do not include in rotation)
  /// hifi.401658.xyz - redirects to GitHub, not an API

  // Core API paths (hifi-api format)
  static const String searchPath = '/search/';      // Use ?s= for tracks, ?a= for artists, ?al= for albums
  static const String albumPath = '/album/';        // Use ?id=
  static const String artistPath = '/artist/';      // Use ?id= or ?f= for full data
  static const String playlistPath = '/playlist/';  // Use ?id=
  static const String trackPath = '/track/';        // Use ?id= for stream URL
  static const String lyricsPath = '/lyrics/';      // Use ?id=
  static const String coverPath = '/cover/';        // Use ?id= or ?q=
  static const String mixPath = '/mix/';            // Use ?id=
  static const String infoPath = '/info/';          // Use ?id= for track info
  
  // Quality options (for stream requests)
  static const String qualityMaster = 'HI_RES_LOSSLESS';  // 24-bit/up to 192kHz MQA
  static const String qualityHifi = 'LOSSLESS';           // 16-bit/44.1kHz FLAC
  static const String qualityHigh = 'HIGH';               // 320kbps AAC
  static const String qualityStandard = 'LOW';            // 128kbps AAC
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

/// Qobuz API endpoints (scaffolded for future - 24-bit hi-res)
class QobuzEndpoints {
  /// Primary endpoints
  static const List<String> endpoints = [
    'https://squid.lucida.to',
    'https://dab.lucida.to',
    'https://dabmusic.lucida.to',
  ];

  static const String searchPath = '/api/search';
  static const String albumPath = '/api/album';
  static const String artistPath = '/api/artist';
  static const String trackPath = '/api/track';
  static const String streamPath = '/api/stream';
  
  // Qobuz delivers TRUE 24-bit/192kHz
  static const String quality24bit = 'HI_RES_24';
  static const String quality16bit = 'HI_RES';
}
