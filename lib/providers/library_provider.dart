import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/database.dart';
import '../models/models.dart';
import 'providers.dart';

// ============================================================================
// SAVED ALBUMS STATE
// ============================================================================

/// State for saved albums
class SavedAlbumsState {
  final List<Album> albums;
  final Set<String> savedAlbumIds;
  final bool isLoading;

  const SavedAlbumsState({
    this.albums = const [],
    this.savedAlbumIds = const {},
    this.isLoading = false,
  });

  SavedAlbumsState copyWith({
    List<Album>? albums,
    Set<String>? savedAlbumIds,
    bool? isLoading,
  }) {
    return SavedAlbumsState(
      albums: albums ?? this.albums,
      savedAlbumIds: savedAlbumIds ?? this.savedAlbumIds,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Notifier for saved albums
class SavedAlbumsNotifier extends StateNotifier<SavedAlbumsState> {
  final AppDatabase _database;

  SavedAlbumsNotifier(this._database) : super(const SavedAlbumsState()) {
    loadSavedAlbums();
  }

  /// Load all saved albums from database
  Future<void> loadSavedAlbums() async {
    state = state.copyWith(isLoading: true);

    try {
      final savedAlbums = await _database.getAllSavedAlbums();
      final albums = <Album>[];
      final savedIds = <String>{};

      for (final saved in savedAlbums) {
        try {
          final json = jsonDecode(saved.albumJson) as Map<String, dynamic>;
          albums.add(Album.fromTidalJson(json));
          savedIds.add(saved.albumId);
        } catch (e) {
          // Skip invalid entries
        }
      }

      state = state.copyWith(
        albums: albums,
        savedAlbumIds: savedIds,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  /// Check if album is saved
  bool isAlbumSaved(String albumId) {
    return state.savedAlbumIds.contains(albumId);
  }

  /// Save album to library
  Future<void> saveAlbum(Album album) async {
    if (state.savedAlbumIds.contains(album.id)) return;

    final albumJson = jsonEncode(album.toJson());
    await _database.saveAlbum(
      albumId: album.id,
      source: album.source.index,
      albumJson: albumJson,
    );

    state = state.copyWith(
      albums: [album, ...state.albums],
      savedAlbumIds: {...state.savedAlbumIds, album.id},
    );
  }

  /// Remove album from library
  Future<void> removeAlbum(String albumId, int source) async {
    await _database.removeSavedAlbum(albumId, source);

    state = state.copyWith(
      albums: state.albums.where((a) => a.id != albumId).toList(),
      savedAlbumIds: state.savedAlbumIds.where((id) => id != albumId).toSet(),
    );
  }

  /// Toggle album saved state
  Future<void> toggleAlbum(Album album) async {
    if (isAlbumSaved(album.id)) {
      await removeAlbum(album.id, album.source.index);
    } else {
      await saveAlbum(album);
    }
  }
}

// ============================================================================
// PROVIDERS
// ============================================================================

/// Provider for saved albums notifier
final savedAlbumsProvider =
    StateNotifierProvider<SavedAlbumsNotifier, SavedAlbumsState>((ref) {
  final database = ref.watch(databaseProvider);
  return SavedAlbumsNotifier(database);
});

/// Provider to check if specific album is saved
final isAlbumSavedProvider = Provider.family<bool, String>((ref, albumId) {
  final state = ref.watch(savedAlbumsProvider);
  return state.savedAlbumIds.contains(albumId);
});

// ============================================================================
// SAVED PLAYLISTS STATE
// ============================================================================

/// State for saved playlists
class SavedPlaylistsState {
  final List<Playlist> playlists;
  final Set<String> savedPlaylistIds;
  final bool isLoading;

  const SavedPlaylistsState({
    this.playlists = const [],
    this.savedPlaylistIds = const {},
    this.isLoading = false,
  });

  SavedPlaylistsState copyWith({
    List<Playlist>? playlists,
    Set<String>? savedPlaylistIds,
    bool? isLoading,
  }) {
    return SavedPlaylistsState(
      playlists: playlists ?? this.playlists,
      savedPlaylistIds: savedPlaylistIds ?? this.savedPlaylistIds,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Notifier for saved playlists
class SavedPlaylistsNotifier extends StateNotifier<SavedPlaylistsState> {
  final AppDatabase _database;

  SavedPlaylistsNotifier(this._database) : super(const SavedPlaylistsState()) {
    loadSavedPlaylists();
  }

  /// Load all saved playlists from database
  Future<void> loadSavedPlaylists() async {
    state = state.copyWith(isLoading: true);

    try {
      final saved = await _database.getAllSavedPlaylists();
      final playlists = <Playlist>[];
      final savedIds = <String>{};

      for (final s in saved) {
        try {
          final json = jsonDecode(s.playlistJson) as Map<String, dynamic>;
          playlists.add(Playlist.fromTidalJson(json));
          savedIds.add(s.playlistId);
        } catch (e) {
          // Skip invalid entries
        }
      }

      state = state.copyWith(
        playlists: playlists,
        savedPlaylistIds: savedIds,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  /// Check if playlist is saved
  bool isPlaylistSaved(String playlistId) {
    return state.savedPlaylistIds.contains(playlistId);
  }

  /// Save playlist to library
  Future<void> savePlaylist(Playlist playlist) async {
    if (state.savedPlaylistIds.contains(playlist.id)) return;

    final playlistJson = jsonEncode(playlist.toJson());
    await _database.savePlaylist(
      playlistId: playlist.id,
      source: playlist.source.index,
      playlistJson: playlistJson,
    );

    state = state.copyWith(
      playlists: [playlist, ...state.playlists],
      savedPlaylistIds: {...state.savedPlaylistIds, playlist.id},
    );
  }

  /// Remove playlist from library
  Future<void> removePlaylist(String playlistId, int source) async {
    await _database.removeSavedPlaylist(playlistId, source);

    state = state.copyWith(
      playlists: state.playlists.where((p) => p.id != playlistId).toList(),
      savedPlaylistIds:
          state.savedPlaylistIds.where((id) => id != playlistId).toSet(),
    );
  }

  /// Toggle playlist saved state
  Future<void> togglePlaylist(Playlist playlist) async {
    if (isPlaylistSaved(playlist.id)) {
      await removePlaylist(playlist.id, playlist.source.index);
    } else {
      await savePlaylist(playlist);
    }
  }
}

/// Provider for saved playlists notifier
final savedPlaylistsProvider =
    StateNotifierProvider<SavedPlaylistsNotifier, SavedPlaylistsState>((ref) {
  final database = ref.watch(databaseProvider);
  return SavedPlaylistsNotifier(database);
});

/// Provider to check if specific playlist is saved
final isPlaylistSavedProvider =
    Provider.family<bool, String>((ref, playlistId) {
  final state = ref.watch(savedPlaylistsProvider);
  return state.savedPlaylistIds.contains(playlistId);
});

// ============================================================================
// SAVED ARTISTS STATE
// ============================================================================

class SavedArtistsState {
  final List<Artist> artists;
  final Set<String> savedArtistIds;
  final bool isLoading;

  const SavedArtistsState({
    this.artists = const [],
    this.savedArtistIds = const {},
    this.isLoading = false,
  });

  SavedArtistsState copyWith({
    List<Artist>? artists,
    Set<String>? savedArtistIds,
    bool? isLoading,
  }) {
    return SavedArtistsState(
      artists: artists ?? this.artists,
      savedArtistIds: savedArtistIds ?? this.savedArtistIds,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class SavedArtistsNotifier extends StateNotifier<SavedArtistsState> {
  static const _storageKey = 'saved_artists';

  SavedArtistsNotifier() : super(const SavedArtistsState()) {
    loadSavedArtists();
  }

  Future<void> loadSavedArtists() async {
    state = state.copyWith(isLoading: true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawArtists = prefs.getStringList(_storageKey) ?? const [];
      final artists = <Artist>[];
      final savedIds = <String>{};

      for (final rawArtist in rawArtists) {
        try {
          final json = jsonDecode(rawArtist) as Map<String, dynamic>;
          final artist = Artist(
            id: json['id']?.toString() ?? '',
            name: json['name'] as String? ?? 'Unknown Artist',
            imageUrl: json['imageUrl'] as String?,
            albumCount: json['albumCount'] as int?,
            source: MusicSource.values[json['source'] as int? ?? 0],
            bio: json['bio'] as String?,
          );
          if (artist.id.isEmpty) {
            continue;
          }
          artists.add(artist);
          savedIds.add(artist.id);
        } catch (_) {}
      }

      state = state.copyWith(
        artists: artists,
        savedArtistIds: savedIds,
        isLoading: false,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  bool isArtistSaved(String artistId) {
    return state.savedArtistIds.contains(artistId);
  }

  Future<void> _persist(List<Artist> artists) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = artists
        .map(
          (artist) => jsonEncode({
            'id': artist.id,
            'name': artist.name,
            'imageUrl': artist.imageUrl,
            'albumCount': artist.albumCount,
            'source': artist.source.index,
            'bio': artist.bio,
          }),
        )
        .toList();
    await prefs.setStringList(_storageKey, encoded);
  }

  Future<void> saveArtist(Artist artist) async {
    if (state.savedArtistIds.contains(artist.id)) {
      return;
    }

    final artists = [artist, ...state.artists];
    await _persist(artists);
    state = state.copyWith(
      artists: artists,
      savedArtistIds: {...state.savedArtistIds, artist.id},
    );
  }

  Future<void> removeArtist(String artistId) async {
    final artists =
        state.artists.where((artist) => artist.id != artistId).toList();
    await _persist(artists);
    state = state.copyWith(
      artists: artists,
      savedArtistIds:
          state.savedArtistIds.where((id) => id != artistId).toSet(),
    );
  }

  Future<void> toggleArtist(Artist artist) async {
    if (isArtistSaved(artist.id)) {
      await removeArtist(artist.id);
    } else {
      await saveArtist(artist);
    }
  }
}

final savedArtistsProvider =
    StateNotifierProvider<SavedArtistsNotifier, SavedArtistsState>((ref) {
  return SavedArtistsNotifier();
});

final isArtistSavedProvider = Provider.family<bool, String>((ref, artistId) {
  final state = ref.watch(savedArtistsProvider);
  return state.savedArtistIds.contains(artistId);
});
