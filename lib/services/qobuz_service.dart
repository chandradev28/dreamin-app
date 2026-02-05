import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';
import 'music_service.dart';

/// Qobuz Service Implementation
/// Uses qobuz.squid.wtf as primary with dab.yeet.su and dabmusic.xyz as fallbacks
/// Provides 24-bit Hi-Res FLAC streaming
/// 
/// Based on working reference implementation that properly handles:
/// - URI encoding
/// - Pagination for search results
/// - Fallback stream endpoints
class QobuzServiceImpl implements MusicService {
  static const String _searchUrl = 'https://qobuz.squid.wtf/api/get-music';
  static const String _albumUrl = 'https://qobuz.squid.wtf/api/get-album';
  static const String _artistUrl = 'https://qobuz.squid.wtf/api/get-artist';
  static const String _playlistUrl = 'https://qobuz.squid.wtf/api/get-playlist';
  
  // Stream endpoints with fallback (tries in order)
  static const List<Map<String, String>> _streamEndpoints = [
    {'name': 'squid', 'url': 'https://qobuz.squid.wtf/api/download-music', 'param': 'track_id'},
    {'name': 'dab', 'url': 'https://dab.yeet.su/api/stream', 'param': 'trackId', 'quality': '7'},
    {'name': 'dabmusic', 'url': 'https://dabmusic.xyz/api/stream', 'param': 'trackId', 'quality': '7'},
  ];
  
  static int _lastWorkingStreamIndex = 0;
  static final http.Client _client = http.Client();

  @override
  MusicSource get source => MusicSource.qobuz;

  // ============== HELPER FUNCTIONS ==============

  /// Extract cover URL from Qobuz image object
  /// Returns the highest quality available (large > small > thumbnail)
  static String? _extractCoverUrl(Map<String, dynamic>? image) {
    if (image == null) return null;
    return image['large'] as String? ??
           image['small'] as String? ??
           image['thumbnail'] as String?;
  }

  // ============== SEARCH ==============

  @override
  Future<SearchResult> search(String query, {int limit = 30}) async {
    if (query.trim().isEmpty) {
      return const SearchResult(tracks: [], albums: [], artists: [], playlists: [], source: MusicSource.qobuz);
    }
    
    print('[Qobuz] Searching for: $query');
    
    final List<Track> allTracks = [];
    final List<Album> allAlbums = [];
    final List<Artist> allArtists = [];
    final List<Playlist> allPlaylists = [];
    String? lastError;
    
    // Fetch multiple pages (API returns ~10 per page)
    const int maxPages = 3;
    const int pageSize = 10;
    
    try {
      for (int page = 0; page < maxPages; page++) {
        final int offset = page * pageSize;
        
        // Build URL with proper encoding
        final uri = Uri.parse('$_searchUrl?q=${Uri.encodeComponent(query)}&offset=$offset');
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
          
          final playlistItems = searchData['playlists']?['items'] as List? ?? [];
          for (final playlist in playlistItems) {
            allPlaylists.add(_playlistFromJson(playlist as Map<String, dynamic>));
          }
        }
        
        print('[Qobuz] Page ${page + 1}: ${trackItems.length} tracks, ${albumItems.length} albums');
        
        // Stop if no more results
        if (trackItems.isEmpty && albumItems.isEmpty) break;
        
        // Stop if we have enough
        if (allTracks.length >= limit && allAlbums.length >= limit) break;
      }
      
      print('[Qobuz] Total: ${allTracks.length} tracks, ${allAlbums.length} albums, ${allArtists.length} artists');
      
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
      final uri = Uri.parse('$_albumUrl?album_id=${Uri.encodeComponent(albumId)}');
      final response = await _client.get(uri).timeout(const Duration(seconds: 15));
      
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
          .map((t) => _trackFromJson(t as Map<String, dynamic>, albumCover: albumCover))
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
      final uri = Uri.parse('$_artistUrl?artist_id=${Uri.encodeComponent(artistId)}');
      final response = await _client.get(uri).timeout(const Duration(seconds: 15));
      
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
          imageUrl = portrait['large'] ?? portrait['small'] ?? portrait['thumbnail'];
        }
      } else {
        imageUrl = _extractCoverUrl(legacyImage);
      }
      
      final albums = <Album>[];
      final topTracks = <Track>[];
      
      // Parse albums from releases array
      // API structure: releases: [{type: 'album', items: [...]}, {type: 'live', items: []}, ...]
      final releases = artistData['releases'] as List? ?? [];
      for (final release in releases) {
        if (release is Map<String, dynamic>) {
          final releaseType = release['type'];
          // Include albums, EPs, singles
          if (releaseType == 'album' || releaseType == 'epSingle' || releaseType == 'live') {
            final items = release['items'] as List? ?? [];
            for (final albumData in items) {
              try {
                if (albumData is Map<String, dynamic>) {
                  albums.add(_albumFromQobuzArtist(albumData, artistName));
                }
              } catch (e) {
                print('[Qobuz] Failed to parse album: $e');
              }
            }
          }
        }
      }
      
      // Parse top tracks - direct array under artist
      final topTracksData = artistData['top_tracks'] as List? ?? [];
      for (final trackData in topTracksData) {
        try {
          if (trackData is Map<String, dynamic>) {
            topTracks.add(_trackFromQobuzArtist(trackData));
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
              topTracks.add(_trackFromQobuzArtist(trackData));
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
              .where((t) => t.artist.toLowerCase().contains(artistName.toLowerCase()) ||
                           artistName.toLowerCase().contains(t.artist.toLowerCase()))
              .take(20)
              .toList();
          topTracks.addAll(artistTracks);
          print('[Qobuz] Found ${topTracks.length} tracks via search');
        } catch (e) {
          print('[Qobuz] Track search failed: $e');
        }
      }
      
      // Get bio from biography object
      String? bio;
      final biography = artistData['biography'];
      if (biography is Map) {
        bio = biography['content'] ?? biography['summary'];
      } else if (biography is String) {
        bio = biography;
      }
      
      print('[Qobuz] Artist loaded: $artistName - ${albums.length} albums, ${topTracks.length} tracks');
      
      return ArtistDetail(
        id: 'qobuz:$artistId',
        name: artistName,
        imageUrl: imageUrl,
        source: MusicSource.qobuz,
        albums: albums,
        topTracks: topTracks,
        bio: bio,
      );
    } catch (e) {
      print('[Qobuz] Artist fetch error: $e');
      return null;
    }
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
        final uri = Uri.parse(
          '$_playlistUrl?playlist_id=${Uri.encodeComponent(playlistId)}&limit=$limit&offset=$offset'
        );
        
        final response = await _client.get(uri).timeout(const Duration(seconds: 20));
        
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
            playlistCover = images['large'] ?? images['small'] ?? images['thumbnail'];
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

  // ============== STREAMING ==============

  @override
  Future<String?> getStreamUrl(String trackId) async {
    // Strip qobuz: prefix if present
    final cleanId = trackId.replaceFirst('qobuz:', '');
    print('[Qobuz] Getting stream URL for track: $cleanId');
    
    // Build ordered list (last working first)
    final endpoints = [
      ..._streamEndpoints.sublist(_lastWorkingStreamIndex),
      ..._streamEndpoints.sublist(0, _lastWorkingStreamIndex),
    ];
    
    for (int i = 0; i < endpoints.length; i++) {
      final endpoint = endpoints[i];
      
      try {
        String url = '${endpoint['url']}?${endpoint['param']}=$cleanId';
        if (endpoint['quality'] != null) {
          url += '&quality=${endpoint['quality']}';
        }
        
        print('[Qobuz] Trying ${endpoint['name']}: $url');
        
        final response = await _client.get(Uri.parse(url)).timeout(
          const Duration(seconds: 8),
        );
        
        if (response.statusCode != 200) {
          print('[Qobuz] ${endpoint['name']} returned ${response.statusCode}');
          continue;
        }
        
        final data = json.decode(response.body);
        final streamUrl = data['url'] ?? data['data']?['url'];
        
        if (streamUrl != null && streamUrl is String && streamUrl.isNotEmpty) {
          // Update last working endpoint
          final originalIndex = _streamEndpoints
              .indexWhere((e) => e['name'] == endpoint['name']);
          if (originalIndex != -1) {
            _lastWorkingStreamIndex = originalIndex;
          }
          
          print('[Qobuz] ✓ Got 24-bit stream from ${endpoint['name']}');
          return streamUrl;
        }
      } catch (e) {
        print('[Qobuz] ${endpoint['name']} failed: $e');
      }
    }
    
    print('[Qobuz] ✗ All stream endpoints failed for track: $cleanId');
    return null;
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
      artist: json['performer']?['name'] ?? json['artist']?['name'] ?? 'Unknown Artist',
      artistId: json['performer']?['id']?.toString() ?? json['artist']?['id']?.toString() ?? '',
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
    final releaseDate = json['release_date_original'] as String?;
    if (releaseDate != null && releaseDate.length >= 4) {
      year = int.tryParse(releaseDate.substring(0, 4));
    }
    
    return Album(
      id: 'qobuz:${json['id']}',
      title: json['title'] ?? json['name'] ?? 'Unknown Album',
      artist: json['artist']?['name'] ?? 'Unknown Artist',
      artistId: json['artist']?['id']?.toString() ?? '',
      coverArtUrl: _extractCoverUrl(image),
      year: year,
      trackCount: json['tracks_count'] ?? 0,
      source: MusicSource.qobuz,
    );
  }

  Artist _artistFromJson(Map<String, dynamic> json) {
    final image = json['image'] as Map<String, dynamic>?;
    
    return Artist(
      id: 'qobuz:${json['id']}',
      name: json['name'] ?? 'Unknown Artist',
      imageUrl: _extractCoverUrl(image),
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
      trackCount: json['tracks_count'] ?? 0,
      source: MusicSource.qobuz,
    );
  }

  /// Parse album from artist endpoint response
  /// Artist endpoint returns different structure: name can be {display: "..."} or string
  Album _albumFromQobuzArtist(Map<String, dynamic> json, String artistName) {
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
      title: json['title'] ?? json['name'] ?? 'Unknown Album',
      artist: albumArtist,
      artistId: json['artist']?['id']?.toString() ?? '',
      coverArtUrl: _extractCoverUrl(image),
      year: year,
      trackCount: json['tracks_count'] ?? 0,
      source: MusicSource.qobuz,
    );
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
    final int bitDepth = audioInfo?['maximum_bit_depth'] ?? json['maximum_bit_depth'] ?? 16;
    
    return Track(
      id: 'qobuz:${json['id']}',
      title: json['title'] ?? 'Unknown',
      artist: artistName,
      artistId: json['artist']?['id']?.toString() ?? '',
      album: json['album']?['title'] ?? 'Unknown Album',
      albumId: 'qobuz:${json['album']?['id'] ?? ''}',
      duration: Duration(seconds: json['duration'] ?? 0),
      trackNumber: json['physical_support']?['track_number'] ?? json['track_number'] ?? 1,
      coverArtUrl: cover,
      isExplicit: json['parental_warning'] == true,
      source: MusicSource.qobuz,
      quality: bitDepth >= 24 
          ? const AudioQuality(bitDepth: 24, sampleRate: 96000)
          : const AudioQuality(bitDepth: 16, sampleRate: 44100),
    );
  }
}
