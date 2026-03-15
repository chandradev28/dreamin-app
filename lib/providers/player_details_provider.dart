import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../services/lastfm_service.dart';
import '../services/recommendation_service.dart';
import '../services/tidal_service.dart';
import 'music_provider.dart';
import 'player_provider.dart';

final _trackInfoCache = <String, TrackInfo?>{};
final _lyricsCache = <String, Lyrics?>{};
final _nextUpCache = <String, List<Track>>{};
final _suggestedCache = <String, List<Track>>{};

final playerTrackInfoProvider =
    FutureProvider.autoDispose.family<TrackInfo?, Track>((ref, track) async {
  final cacheKey = _trackKey(track);
  if (_trackInfoCache.containsKey(cacheKey)) {
    return _trackInfoCache[cacheKey];
  }

  final tidalService = ref.watch(tidalServiceProvider);
  final result = track.source == MusicSource.tidal
      ? await tidalService.getTrackInfo(track.id)
      : null;
  _trackInfoCache[cacheKey] = result;
  return result;
});

final playerLyricsProvider =
    FutureProvider.autoDispose.family<Lyrics?, Track>((ref, track) async {
  final cacheKey = _trackKey(track);
  if (_lyricsCache.containsKey(cacheKey)) {
    return _lyricsCache[cacheKey];
  }

  final tidalService = ref.watch(tidalServiceProvider);
  final result = track.source == MusicSource.tidal
      ? await tidalService.getLyrics(track.id)
      : null;
  _lyricsCache[cacheKey] = result;
  return result;
});

final playerNextUpProvider =
    FutureProvider.autoDispose.family<List<Track>, Track>((ref, track) async {
  final cacheKey = _trackKey(track);
  if (_nextUpCache.containsKey(cacheKey)) {
    return _nextUpCache[cacheKey]!;
  }

  final tidalService = ref.watch(tidalServiceProvider);
  final result = await _loadNextUpFromArtist(tidalService, track);
  _nextUpCache[cacheKey] = result;
  return result;
});

final playerSuggestedTracksProvider =
    FutureProvider.autoDispose.family<List<Track>, Track>((ref, track) async {
  final cacheKey = _trackKey(track);
  if (_suggestedCache.containsKey(cacheKey)) {
    return _suggestedCache[cacheKey]!;
  }

  final tidalService = ref.watch(tidalServiceProvider);
  final lastFmService = ref.watch(lastFmServiceProvider);
  final recommendationService = ref.watch(recommendationServiceProvider);
  final history = ref.watch(historyProvider).history;

  final result = await _loadSuggestedTracks(
    tidalService: tidalService,
    lastFmService: lastFmService,
    recommendationService: recommendationService,
    history: history,
    track: track,
  );
  _suggestedCache[cacheKey] = result;
  return result;
});

String _trackKey(Track track) => '${track.id}_${track.source.name}';

Future<List<Track>> _loadNextUpFromArtist(
  TidalService tidalService,
  Track track,
) async {
  final collected = <Track>[];

  try {
    if (_isNumericId(track.albumId)) {
      final album = await tidalService.getAlbum(track.albumId);
      collected.addAll(
        album.tracks.where(
          (candidate) =>
              candidate.artistId == track.artistId ||
              candidate.artist.toLowerCase() == track.artist.toLowerCase(),
        ),
      );
    }
  } catch (_) {}

  try {
    if (_isNumericId(track.artistId)) {
      final artist = await tidalService.getArtist(track.artistId);
      collected.addAll(artist.topTracks);
    }
  } catch (_) {}

  if (collected.length < 12) {
    try {
      final searchResults =
          await tidalService.searchTracks(track.artist, limit: 20);
      collected.addAll(
        searchResults.where(
          (candidate) =>
              candidate.artistId == track.artistId ||
              candidate.artist.toLowerCase() == track.artist.toLowerCase(),
        ),
      );
    } catch (_) {}
  }

  return _dedupeTracks(collected, exclude: track, limit: 18);
}

Future<List<Track>> _loadSuggestedTracks({
  required TidalService tidalService,
  required LastFmService lastFmService,
  required RecommendationService recommendationService,
  required List<Track> history,
  required Track track,
}) async {
  final collected = <Track>[];

  try {
    final similarTracks = await lastFmService
        .getSimilarTracks(track.artist, track.title, limit: 8);
    collected.addAll(await _resolveLastFmTracks(tidalService, similarTracks));
  } catch (_) {}

  if (collected.length < 8) {
    try {
      final similarArtists =
          await lastFmService.getSimilarArtists(track.artist, limit: 6);
      collected.addAll(
          await _resolveArtistSuggestions(tidalService, similarArtists));
    } catch (_) {}
  }

  if (collected.length < 10) {
    try {
      final recommendations =
          await recommendationService.getRecommendations(limit: 20);
      collected.addAll(
        recommendations.where(
          (candidate) =>
              candidate.artistId != track.artistId &&
              candidate.artist.toLowerCase() != track.artist.toLowerCase(),
        ),
      );
    } catch (_) {}
  }

  if (collected.length < 12) {
    final recentArtists = history
        .map((item) => item.artist)
        .where((artist) => artist.isNotEmpty)
        .toSet()
        .where((artist) => artist.toLowerCase() != track.artist.toLowerCase())
        .take(3);

    for (final artist in recentArtists) {
      try {
        collected.addAll(await tidalService.searchTracks(artist, limit: 4));
      } catch (_) {}
    }
  }

  return _dedupeTracks(collected, exclude: track, limit: 18);
}

Future<List<Track>> _resolveLastFmTracks(
  TidalService tidalService,
  List<LastFmTrack> similarTracks,
) async {
  final resolved = <Track>[];

  for (final candidate in similarTracks.take(6)) {
    try {
      final query = '${candidate.artist} ${candidate.name}';
      final matches = await tidalService.searchTracks(query, limit: 5);
      final exact = matches.where(
        (track) =>
            track.title.toLowerCase() == candidate.name.toLowerCase() &&
            track.artist.toLowerCase() == candidate.artist.toLowerCase(),
      );
      if (exact.isNotEmpty) {
        resolved.add(exact.first);
      } else if (matches.isNotEmpty) {
        resolved.add(matches.first);
      }
    } catch (_) {}
  }

  return resolved;
}

Future<List<Track>> _resolveArtistSuggestions(
  TidalService tidalService,
  List<LastFmArtist> similarArtists,
) async {
  final resolved = <Track>[];

  for (final candidate in similarArtists.take(4)) {
    try {
      final artists =
          await tidalService.searchArtists(candidate.name, limit: 3);
      final bestArtist = artists.isNotEmpty ? artists.first : null;
      if (bestArtist == null || !_isNumericId(bestArtist.id)) {
        continue;
      }

      final detail = await tidalService.getArtist(bestArtist.id);
      resolved.addAll(detail.topTracks.take(3));
    } catch (_) {}
  }

  return resolved;
}

List<Track> _dedupeTracks(
  List<Track> tracks, {
  Track? exclude,
  int limit = 20,
}) {
  final seen = <String>{};
  final deduped = <Track>[];
  final excludedKey =
      exclude == null ? null : '${exclude.id}_${exclude.source.name}';

  for (final track in tracks) {
    final key = '${track.id}_${track.source.name}';
    if (key == excludedKey || seen.contains(key)) {
      continue;
    }
    seen.add(key);
    deduped.add(track);
    if (deduped.length >= limit) {
      break;
    }
  }

  return deduped;
}

bool _isNumericId(String? value) {
  return value != null && value.isNotEmpty && int.tryParse(value) != null;
}
