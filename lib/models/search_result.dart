import 'track.dart';
import 'album.dart';
import 'artist.dart';
import 'playlist.dart';
import 'music_source.dart';

class SearchResult {
  final List<Track> tracks;
  final List<Album> albums;
  final List<Artist> artists;
  final List<Playlist> playlists;
  final MusicSource source;

  const SearchResult({
    this.tracks = const [],
    this.albums = const [],
    this.artists = const [],
    this.playlists = const [],
    this.source = MusicSource.tidal,
  });

  bool get isEmpty => tracks.isEmpty && albums.isEmpty && artists.isEmpty && playlists.isEmpty;
  bool get isNotEmpty => !isEmpty;

  int get totalCount => tracks.length + albums.length + artists.length + playlists.length;

  factory SearchResult.fromTidalJson(Map<String, dynamic> json) {
    final tracksData = json['tracks']?['items'] as List<dynamic>? ?? [];
    final albumsData = json['albums']?['items'] as List<dynamic>? ?? [];
    final artistsData = json['artists']?['items'] as List<dynamic>? ?? [];
    final playlistsData = json['playlists']?['items'] as List<dynamic>? ?? [];

    return SearchResult(
      tracks: tracksData
          .map((t) => Track.fromTidalJson(t as Map<String, dynamic>))
          .toList(),
      albums: albumsData
          .map((a) => Album.fromTidalJson(a as Map<String, dynamic>))
          .toList(),
      artists: artistsData
          .map((a) => Artist.fromTidalJson(a as Map<String, dynamic>))
          .toList(),
      playlists: playlistsData
          .map((p) => Playlist.fromTidalJson(p as Map<String, dynamic>))
          .toList(),
      source: MusicSource.tidal,
    );
  }

  SearchResult copyWith({
    List<Track>? tracks,
    List<Album>? albums,
    List<Artist>? artists,
    List<Playlist>? playlists,
    MusicSource? source,
  }) {
    return SearchResult(
      tracks: tracks ?? this.tracks,
      albums: albums ?? this.albums,
      artists: artists ?? this.artists,
      playlists: playlists ?? this.playlists,
      source: source ?? this.source,
    );
  }
}
