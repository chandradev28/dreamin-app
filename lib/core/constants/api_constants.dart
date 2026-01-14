/// TIDAL API endpoints with automatic fallback
class TidalEndpoints {
  /// Primary endpoints with fallback support
  static const List<String> endpoints = [
    'https://hund.lucida.to',
    'https://katze.lucida.to',
    'https://maus.lucida.to',
    'https://vogel.lucida.to',
    'https://wolf.lucida.to',
    'https://kinoplus.lucida.to',
    'https://binimum.lucida.to',
  ];

  // Core API paths
  static const String searchPath = '/api/search';
  static const String albumPath = '/api/album';
  static const String artistPath = '/api/artist';
  static const String playlistPath = '/api/playlist';
  static const String trackPath = '/api/track';
  static const String streamPath = '/api/stream';
  static const String lyricsPath = '/api/lyrics';
  
  // Discovery paths
  static const String newAlbumsPath = '/api/albums/new';
  static const String popularPlaylistsPath = '/api/playlists/popular';
  static const String featuredPlaylistsPath = '/api/playlists/featured';
  static const String trendingPath = '/api/tracks/trending';
  static const String genresPath = '/api/genres';
  static const String moodsPath = '/api/moods';
  
  // Quality options (for stream requests)
  static const String qualityMaster = 'HI_RES';      // 24-bit/up to 192kHz MQA
  static const String qualityHifi = 'LOSSLESS';      // 16-bit/44.1kHz FLAC
  static const String qualityHigh = 'HIGH';          // 320kbps AAC
  static const String qualityStandard = 'LOW';       // 128kbps AAC
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
