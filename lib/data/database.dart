import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

part 'database.g.dart';

/// History entries table
class HistoryEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get trackId => text()();
  IntColumn get source => integer()(); // MusicSource index
  TextColumn get trackJson => text()(); // Serialized track data
  DateTimeColumn get playedAt => dateTime()();
  IntColumn get playedDurationMs => integer()();
  TextColumn get genre => text().nullable()();
  TextColumn get artistId => text()();
}

/// Favorites table
class Favorites extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get trackId => text()();
  IntColumn get source => integer()();
  TextColumn get trackJson => text()();
  DateTimeColumn get addedAt => dateTime()();
}

/// Local playlists table
class LocalPlaylists extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get coverUrl => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

/// Playlist tracks table
class PlaylistTracks extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get playlistId => integer().references(LocalPlaylists, #id)();
  TextColumn get trackId => text()();
  IntColumn get source => integer()();
  TextColumn get trackJson => text()();
  IntColumn get position => integer()();
}

/// Cached tracks table
class CachedTracks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get trackId => text()();
  IntColumn get source => integer()();
  TextColumn get trackJson => text()();
  TextColumn get filePath => text()();
  IntColumn get fileSize => integer()();
  DateTimeColumn get cachedAt => dateTime()();
}

/// Play count tracking
class PlayCounts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get trackId => text()();
  IntColumn get source => integer()();
  TextColumn get artistId => text()();
  TextColumn get genre => text().nullable()();
  IntColumn get playCount => integer().withDefault(const Constant(0))();
  IntColumn get skipCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastPlayedAt => dateTime().nullable()();
}

/// Genre play frequency for recommendations
class GenreFrequency extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get genre => text()();
  IntColumn get playCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastPlayedAt => dateTime().nullable()();
}

/// Artist play frequency for recommendations
class ArtistFrequency extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get artistId => text()();
  TextColumn get artistName => text()();
  IntColumn get playCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastPlayedAt => dateTime().nullable()();
}

/// Saved albums table (Library)
class SavedAlbums extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get albumId => text()();
  IntColumn get source => integer()();
  TextColumn get albumJson => text()();
  DateTimeColumn get addedAt => dateTime()();
}

/// Saved playlists table (Library)
class SavedPlaylists extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get playlistId => text()();
  IntColumn get source => integer()();
  TextColumn get playlistJson => text()();
  DateTimeColumn get addedAt => dateTime()();
}

@DriftDatabase(tables: [
  HistoryEntries,
  Favorites,
  LocalPlaylists,
  PlaylistTracks,
  CachedTracks,
  PlayCounts,
  GenreFrequency,
  ArtistFrequency,
  SavedAlbums,
  SavedPlaylists,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          await m.createTable(savedAlbums);
        }
        if (from < 3) {
          await m.createTable(savedPlaylists);
        }
      },
    );
  }

  // ==================== HISTORY ====================

  Future<void> recordPlay({
    required String trackId,
    required int source,
    required String trackJson,
    required int playedDurationMs,
    String? genre,
    required String artistId,
  }) async {
    await into(historyEntries).insert(HistoryEntriesCompanion.insert(
      trackId: trackId,
      source: source,
      trackJson: trackJson,
      playedAt: DateTime.now(),
      playedDurationMs: playedDurationMs,
      genre: Value(genre),
      artistId: artistId,
    ));

    // Update play counts
    await _updatePlayCount(trackId, source, artistId, genre);
    
    // Update genre frequency
    if (genre != null) {
      await _updateGenreFrequency(genre);
    }
    
    // Update artist frequency
    await _updateArtistFrequency(artistId, '');
  }

  Future<void> _updatePlayCount(String trackId, int source, String artistId, String? genre) async {
    final existing = await (select(playCounts)
      ..where((t) => t.trackId.equals(trackId) & t.source.equals(source)))
      .getSingleOrNull();

    if (existing != null) {
      await (update(playCounts)..where((t) => t.id.equals(existing.id)))
        .write(PlayCountsCompanion(
          playCount: Value(existing.playCount + 1),
          lastPlayedAt: Value(DateTime.now()),
        ));
    } else {
      await into(playCounts).insert(PlayCountsCompanion.insert(
        trackId: trackId,
        source: source,
        artistId: artistId,
        genre: Value(genre),
        playCount: const Value(1),
        lastPlayedAt: Value(DateTime.now()),
      ));
    }
  }

  Future<void> _updateGenreFrequency(String genre) async {
    final existing = await (select(genreFrequency)
      ..where((t) => t.genre.equals(genre)))
      .getSingleOrNull();

    if (existing != null) {
      await (update(genreFrequency)..where((t) => t.id.equals(existing.id)))
        .write(GenreFrequencyCompanion(
          playCount: Value(existing.playCount + 1),
          lastPlayedAt: Value(DateTime.now()),
        ));
    } else {
      await into(genreFrequency).insert(GenreFrequencyCompanion.insert(
        genre: genre,
        playCount: const Value(1),
        lastPlayedAt: Value(DateTime.now()),
      ));
    }
  }

  Future<void> _updateArtistFrequency(String artistId, String artistName) async {
    final existing = await (select(artistFrequency)
      ..where((t) => t.artistId.equals(artistId)))
      .getSingleOrNull();

    if (existing != null) {
      await (update(artistFrequency)..where((t) => t.id.equals(existing.id)))
        .write(ArtistFrequencyCompanion(
          playCount: Value(existing.playCount + 1),
          lastPlayedAt: Value(DateTime.now()),
        ));
    } else {
      await into(artistFrequency).insert(ArtistFrequencyCompanion.insert(
        artistId: artistId,
        artistName: artistName,
        playCount: const Value(1),
        lastPlayedAt: Value(DateTime.now()),
      ));
    }
  }

  Future<void> recordSkip(String trackId, int source) async {
    final existing = await (select(playCounts)
      ..where((t) => t.trackId.equals(trackId) & t.source.equals(source)))
      .getSingleOrNull();

    if (existing != null) {
      await (update(playCounts)..where((t) => t.id.equals(existing.id)))
        .write(PlayCountsCompanion(
          skipCount: Value(existing.skipCount + 1),
        ));
    }
  }

  Future<List<HistoryEntry>> getRecentlyPlayed({int limit = 50}) async {
    return (select(historyEntries)
      ..orderBy([(t) => OrderingTerm.desc(t.playedAt)])
      ..limit(limit))
      .get();
  }

  Future<List<PlayCount>> getMostPlayed({int limit = 50}) async {
    return (select(playCounts)
      ..orderBy([(t) => OrderingTerm.desc(t.playCount)])
      ..limit(limit))
      .get();
  }

  Future<int> getTotalPlayCount() async {
    final result = await customSelect(
      'SELECT COUNT(*) as count FROM history_entries',
    ).getSingle();
    return result.read<int>('count');
  }

  Future<void> clearHistory() async {
    await delete(historyEntries).go();
  }

  // ==================== FAVORITES ====================

  Future<void> addFavorite({
    required String trackId,
    required int source,
    required String trackJson,
  }) async {
    final existing = await (select(favorites)
      ..where((t) => t.trackId.equals(trackId) & t.source.equals(source)))
      .getSingleOrNull();

    if (existing == null) {
      await into(favorites).insert(FavoritesCompanion.insert(
        trackId: trackId,
        source: source,
        trackJson: trackJson,
        addedAt: DateTime.now(),
      ));
    }
  }

  Future<void> removeFavorite(String trackId, int source) async {
    await (delete(favorites)
      ..where((t) => t.trackId.equals(trackId) & t.source.equals(source)))
      .go();
  }

  Future<bool> isFavorite(String trackId, int source) async {
    final result = await (select(favorites)
      ..where((t) => t.trackId.equals(trackId) & t.source.equals(source)))
      .getSingleOrNull();
    return result != null;
  }

  Future<List<Favorite>> getAllFavorites() async {
    return (select(favorites)
      ..orderBy([(t) => OrderingTerm.desc(t.addedAt)]))
      .get();
  }

  // ==================== PLAYLISTS ====================

  Future<int> createPlaylist(String name) async {
    return into(localPlaylists).insert(LocalPlaylistsCompanion.insert(
      name: name,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));
  }

  Future<void> deletePlaylist(int playlistId) async {
    await (delete(playlistTracks)..where((t) => t.playlistId.equals(playlistId))).go();
    await (delete(localPlaylists)..where((t) => t.id.equals(playlistId))).go();
  }

  Future<List<LocalPlaylist>> getAllPlaylists() async {
    return select(localPlaylists).get();
  }

  Future<void> addTrackToPlaylist({
    required int playlistId,
    required String trackId,
    required int source,
    required String trackJson,
  }) async {
    final count = await (select(playlistTracks)
      ..where((t) => t.playlistId.equals(playlistId)))
      .get();

    await into(playlistTracks).insert(PlaylistTracksCompanion.insert(
      playlistId: playlistId,
      trackId: trackId,
      source: source,
      trackJson: trackJson,
      position: count.length,
    ));

    await (update(localPlaylists)..where((t) => t.id.equals(playlistId)))
      .write(LocalPlaylistsCompanion(updatedAt: Value(DateTime.now())));
  }

  Future<List<PlaylistTrack>> getPlaylistTracks(int playlistId) async {
    return (select(playlistTracks)
      ..where((t) => t.playlistId.equals(playlistId))
      ..orderBy([(t) => OrderingTerm.asc(t.position)]))
      .get();
  }

  // ==================== RECOMMENDATIONS ====================

  Future<List<String>> getTopGenres({int limit = 5}) async {
    final results = await (select(genreFrequency)
      ..orderBy([(t) => OrderingTerm.desc(t.playCount)])
      ..limit(limit))
      .get();
    return results.map((r) => r.genre).toList();
  }

  Future<List<String>> getTopArtistIds({int limit = 10}) async {
    final results = await (select(artistFrequency)
      ..orderBy([(t) => OrderingTerm.desc(t.playCount)])
      ..limit(limit))
      .get();
    return results.map((r) => r.artistId).toList();
  }

  /// Get top artist names for search queries (personalization)
  Future<List<String>> getTopArtistNames({int limit = 10}) async {
    final results = await (select(artistFrequency)
      ..orderBy([(t) => OrderingTerm.desc(t.playCount)])
      ..limit(limit))
      .get();
    return results.map((r) => r.artistName).toList();
  }

  /// Get top artist data with full info (for artists screen)
  Future<List<ArtistFrequencyData>> getTopArtistData({int limit = 50}) async {
    return (select(artistFrequency)
      ..orderBy([(t) => OrderingTerm.desc(t.playCount)])
      ..limit(limit))
      .get();
  }

  Future<Map<String, int>> getListeningPatterns() async {
    // Get hour-based listening patterns
    final entries = await select(historyEntries).get();
    final Map<String, int> hourCounts = {};
    
    for (final entry in entries) {
      final hour = entry.playedAt.hour.toString().padLeft(2, '0');
      hourCounts[hour] = (hourCounts[hour] ?? 0) + 1;
    }
    
    return hourCounts;
  }

  // ==================== CACHE ====================

  Future<void> cacheTrack({
    required String trackId,
    required int source,
    required String trackJson,
    required String filePath,
    required int fileSize,
  }) async {
    await into(cachedTracks).insert(CachedTracksCompanion.insert(
      trackId: trackId,
      source: source,
      trackJson: trackJson,
      filePath: filePath,
      fileSize: fileSize,
      cachedAt: DateTime.now(),
    ));
  }

  Future<bool> isTrackCached(String trackId, int source) async {
    final result = await (select(cachedTracks)
      ..where((t) => t.trackId.equals(trackId) & t.source.equals(source)))
      .getSingleOrNull();
    return result != null;
  }

  Future<String?> getCachedPath(String trackId, int source) async {
    final result = await (select(cachedTracks)
      ..where((t) => t.trackId.equals(trackId) & t.source.equals(source)))
      .getSingleOrNull();
    return result?.filePath;
  }

  Future<void> removeCachedTrack(String trackId, int source) async {
    final cached = await (select(cachedTracks)
      ..where((t) => t.trackId.equals(trackId) & t.source.equals(source)))
      .getSingleOrNull();
    
    if (cached != null) {
      final file = File(cached.filePath);
      if (await file.exists()) {
        await file.delete();
      }
      await (delete(cachedTracks)..where((t) => t.id.equals(cached.id))).go();
    }
  }

  Future<int> getCacheSize() async {
    final result = await customSelect(
      'SELECT COALESCE(SUM(file_size), 0) as total FROM cached_tracks',
    ).getSingle();
    return result.read<int>('total');
  }

  Future<void> clearCache() async {
    final cached = await select(cachedTracks).get();
    for (final track in cached) {
      final file = File(track.filePath);
      if (await file.exists()) {
        await file.delete();
      }
    }
    await delete(cachedTracks).go();
  }

  Future<List<CachedTrack>> getAllCachedTracks() async {
    return select(cachedTracks).get();
  }

  // ==================== SAVED ALBUMS ====================

  Future<void> saveAlbum({
    required String albumId,
    required int source,
    required String albumJson,
  }) async {
    // Check if already saved
    final existing = await (select(savedAlbums)
      ..where((t) => t.albumId.equals(albumId) & t.source.equals(source)))
      .getSingleOrNull();
    
    if (existing == null) {
      await into(savedAlbums).insert(SavedAlbumsCompanion.insert(
        albumId: albumId,
        source: source,
        albumJson: albumJson,
        addedAt: DateTime.now(),
      ));
    }
  }

  Future<void> removeSavedAlbum(String albumId, int source) async {
    await (delete(savedAlbums)
      ..where((t) => t.albumId.equals(albumId) & t.source.equals(source)))
      .go();
  }

  Future<bool> isAlbumSaved(String albumId, int source) async {
    final result = await (select(savedAlbums)
      ..where((t) => t.albumId.equals(albumId) & t.source.equals(source)))
      .getSingleOrNull();
    return result != null;
  }

  Future<List<SavedAlbum>> getAllSavedAlbums() async {
    return (select(savedAlbums)
      ..orderBy([(t) => OrderingTerm.desc(t.addedAt)]))
      .get();
  }

  // ==================== SAVED PLAYLISTS ====================

  Future<void> savePlaylist({
    required String playlistId,
    required int source,
    required String playlistJson,
  }) async {
    final existing = await (select(savedPlaylists)
      ..where((t) => t.playlistId.equals(playlistId) & t.source.equals(source)))
      .getSingleOrNull();
    
    if (existing == null) {
      await into(savedPlaylists).insert(SavedPlaylistsCompanion.insert(
        playlistId: playlistId,
        source: source,
        playlistJson: playlistJson,
        addedAt: DateTime.now(),
      ));
    }
  }

  Future<void> removeSavedPlaylist(String playlistId, int source) async {
    await (delete(savedPlaylists)
      ..where((t) => t.playlistId.equals(playlistId) & t.source.equals(source)))
      .go();
  }

  Future<bool> isPlaylistSaved(String playlistId, int source) async {
    final result = await (select(savedPlaylists)
      ..where((t) => t.playlistId.equals(playlistId) & t.source.equals(source)))
      .getSingleOrNull();
    return result != null;
  }

  Future<List<SavedPlaylist>> getAllSavedPlaylists() async {
    return (select(savedPlaylists)
      ..orderBy([(t) => OrderingTerm.desc(t.addedAt)]))
      .get();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'dreamin.db'));
    return NativeDatabase.createInBackground(file);
  });
}
