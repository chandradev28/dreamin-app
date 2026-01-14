import 'track.dart';
import 'album.dart';
import 'artist.dart';

class SearchResult {
  final List<Track> tracks;
  final List<Album> albums;
  final List<Artist> artists;

  const SearchResult({
    this.tracks = const [],
    this.albums = const [],
    this.artists = const [],
  });

  bool get isEmpty => tracks.isEmpty && albums.isEmpty && artists.isEmpty;
  bool get isNotEmpty => !isEmpty;

  int get totalCount => tracks.length + albums.length + artists.length;

  factory SearchResult.fromTidalJson(Map<String, dynamic> json) {
    final tracksData = json['tracks']?['items'] as List<dynamic>? ?? [];
    final albumsData = json['albums']?['items'] as List<dynamic>? ?? [];
    final artistsData = json['artists']?['items'] as List<dynamic>? ?? [];

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
    );
  }

  SearchResult copyWith({
    List<Track>? tracks,
    List<Album>? albums,
    List<Artist>? artists,
  }) {
    return SearchResult(
      tracks: tracks ?? this.tracks,
      albums: albums ?? this.albums,
      artists: artists ?? this.artists,
    );
  }
}
