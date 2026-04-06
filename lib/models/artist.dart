import 'package:equatable/equatable.dart';
import 'music_source.dart';
import 'album.dart';
import 'playlist.dart';
import 'track.dart';

class Artist extends Equatable {
  final String id;
  final String name;
  final String? imageUrl;
  final int? albumCount;
  final MusicSource source;
  final String? bio;

  const Artist({
    required this.id,
    required this.name,
    this.imageUrl,
    this.albumCount,
    required this.source,
    this.bio,
  });

  factory Artist.fromTidalJson(Map<String, dynamic> json) {
    // Try direct coverUrl first (640x640 or 750x750), then construct from picture UUID
    String? imageUrl = json['coverUrl'] as String?;

    if (imageUrl == null) {
      final picture = json['picture'] as String?;
      if (picture != null) {
        final formattedPicture = picture.replaceAll('-', '/');
        imageUrl =
            'https://resources.tidal.com/images/$formattedPicture/640x640.jpg';
      }
    }

    return Artist(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? 'Unknown Artist',
      imageUrl: imageUrl,
      albumCount: json['albumCount'] as int?,
      source: MusicSource.tidal,
      bio: json['bio'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, source];
}

class ArtistDetail extends Artist {
  final List<Album> albums;
  final List<Album>? topAlbums;
  final List<Track> topTracks;
  final List<Playlist> playlists;
  final List<Artist> relatedArtists;

  const ArtistDetail({
    required super.id,
    required super.name,
    super.imageUrl,
    super.albumCount,
    required super.source,
    super.bio,
    required this.albums,
    this.topAlbums,
    this.topTracks = const [],
    this.playlists = const [],
    this.relatedArtists = const [],
  });

  factory ArtistDetail.fromTidalJson(
    Map<String, dynamic> artistJson,
    List<dynamic> albumsJson, {
    List<dynamic>? tracksJson,
  }) {
    final artist = Artist.fromTidalJson(artistJson);
    final albums = albumsJson
        .map((a) => Album.fromTidalJson(a as Map<String, dynamic>))
        .toList();
    final tracks = tracksJson
            ?.map((t) => Track.fromTidalJson(t as Map<String, dynamic>))
            .toList() ??
        <Track>[];

    return ArtistDetail(
      id: artist.id,
      name: artist.name,
      imageUrl: artist.imageUrl,
      albumCount: artist.albumCount,
      source: artist.source,
      bio: artist.bio,
      albums: albums,
      topTracks: tracks,
      playlists: const [],
      relatedArtists: const [],
    );
  }
}
