import 'package:equatable/equatable.dart';
import 'music_source.dart';
import 'track.dart';

/// Album Type - distinguishes between different release types
enum AlbumType {
  album,
  ep,
  single,
  compilation,
  live,
}

class Album extends Equatable {
  final String id;
  final String title;
  final String artist;
  final String artistId;
  final String? coverArtUrl;
  final int? year;
  final int trackCount;
  final MusicSource source;
  final AudioQuality? quality;
  final Duration? duration;
  final bool isExplicit;
  final AlbumType albumType;

  const Album({
    required this.id,
    required this.title,
    required this.artist,
    required this.artistId,
    this.coverArtUrl,
    this.year,
    required this.trackCount,
    required this.source,
    this.quality,
    this.duration,
    this.isExplicit = false,
    this.albumType = AlbumType.album,
  });

  String get formattedDuration {
    if (duration == null) return '';
    final hours = duration!.inHours;
    final minutes = duration!.inMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  factory Album.fromTidalJson(Map<String, dynamic> json) {
    final artists = json['artists'] as List<dynamic>? ?? [];
    final artistName = artists.isNotEmpty
        ? (artists.first['name'] as String? ?? 'Unknown Artist')
        : (json['artist']?['name'] as String? ?? 'Unknown Artist');
    final artistId = artists.isNotEmpty
        ? (artists.first['id']?.toString() ?? '')
        : (json['artist']?['id']?.toString() ?? '');

    // Try multiple image fields
    final cover = json['cover'] as String? 
        ?? json['image'] as String?
        ?? json['squareImage'] as String?;
    String? coverUrl;
    if (cover != null && cover.isNotEmpty) {
      if (cover.contains('-')) {
        final formattedCover = cover.replaceAll('-', '/');
        coverUrl = 'https://resources.tidal.com/images/$formattedCover/640x640.jpg';
      } else if (cover.startsWith('http')) {
        coverUrl = cover;
      } else {
        coverUrl = 'https://resources.tidal.com/images/$cover/640x640.jpg';
      }
    }

    // Parse album type from API response
    AlbumType albumType = AlbumType.album;
    final typeStr = (json['type'] as String? ?? '').toLowerCase();
    if (typeStr.contains('ep') || typeStr == 'ep') {
      albumType = AlbumType.ep;
    } else if (typeStr.contains('single') || typeStr == 'single') {
      albumType = AlbumType.single;
    } else if (typeStr.contains('compilation') || typeStr.contains('greatest') || typeStr.contains('best')) {
      albumType = AlbumType.compilation;
    } else if (typeStr.contains('live') || (json['title'] as String? ?? '').toLowerCase().contains('live')) {
      albumType = AlbumType.live;
    }

    return Album(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? 'Unknown Album',
      artist: artistName,
      artistId: artistId,
      coverArtUrl: coverUrl,
      year: json['releaseDate'] != null
          ? int.tryParse((json['releaseDate'] as String).split('-').first)
          : null,
      trackCount: json['numberOfTracks'] as int? ?? 0,
      source: MusicSource.tidal,
      quality: const AudioQuality(bitDepth: 16, sampleRate: 44100),
      duration: json['duration'] != null
          ? Duration(seconds: json['duration'] as int)
          : null,
      isExplicit: json['explicit'] as bool? ?? false,
      albumType: albumType,
    );
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artists': [{'id': artistId, 'name': artist}],
      'cover': coverArtUrl,
      'releaseDate': year != null ? '$year-01-01' : null,
      'numberOfTracks': trackCount,
      'duration': duration?.inSeconds,
      'explicit': isExplicit,
      'type': albumType.name,
    };
  }

  @override
  List<Object?> get props => [id, source, albumType];
}

class AlbumDetail extends Album {
  final List<Track> tracks;
  final String? description;
  final String? copyright;

  const AlbumDetail({
    required super.id,
    required super.title,
    required super.artist,
    required super.artistId,
    super.coverArtUrl,
    super.year,
    required super.trackCount,
    required super.source,
    super.quality,
    super.duration,
    super.isExplicit,
    required this.tracks,
    this.description,
    this.copyright,
  });

  factory AlbumDetail.fromTidalJson(
    Map<String, dynamic> albumJson,
    List<dynamic> tracksJson,
  ) {
    final album = Album.fromTidalJson(albumJson);
    final tracks = tracksJson
        .map((t) => Track.fromTidalJson(t as Map<String, dynamic>))
        .toList();

    return AlbumDetail(
      id: album.id,
      title: album.title,
      artist: album.artist,
      artistId: album.artistId,
      coverArtUrl: album.coverArtUrl,
      year: album.year,
      trackCount: album.trackCount,
      source: album.source,
      quality: album.quality,
      duration: album.duration,
      isExplicit: album.isExplicit,
      tracks: tracks,
      description: albumJson['description'] as String?,
      copyright: albumJson['copyright'] as String?,
    );
  }
}
