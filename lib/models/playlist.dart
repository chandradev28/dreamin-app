import 'package:equatable/equatable.dart';
import 'music_source.dart';
import 'track.dart';

class Playlist extends Equatable {
  final String id;
  final String title;
  final String? description;
  final String? coverArtUrl;
  final int trackCount;
  final Duration? duration;
  final String? creatorName;
  final MusicSource source;
  final int? likesCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Playlist({
    required this.id,
    required this.title,
    this.description,
    this.coverArtUrl,
    required this.trackCount,
    this.duration,
    this.creatorName,
    required this.source,
    this.likesCount,
    this.createdAt,
    this.updatedAt,
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

  String get formattedLikes {
    if (likesCount == null) return '';
    if (likesCount! >= 1000000) {
      return '${(likesCount! / 1000000).toStringAsFixed(1)}M likes';
    } else if (likesCount! >= 1000) {
      return '${(likesCount! / 1000).toStringAsFixed(0)}K likes';
    }
    return '$likesCount likes';
  }

  factory Playlist.fromTidalJson(Map<String, dynamic> json) {
    final image = json['image'] as String? ?? json['squareImage'] as String?;
    String? coverUrl;
    if (image != null) {
      final formattedImage = image.replaceAll('-', '/');
      coverUrl = 'https://resources.tidal.com/images/$formattedImage/640x640.jpg';
    }

    return Playlist(
      id: json['uuid']?.toString() ?? json['id']?.toString() ?? '',
      title: json['title'] as String? ?? 'Unknown Playlist',
      description: json['description'] as String?,
      coverArtUrl: coverUrl,
      trackCount: json['numberOfTracks'] as int? ?? 0,
      duration: json['duration'] != null
          ? Duration(seconds: json['duration'] as int)
          : null,
      creatorName: json['creator']?['name'] as String?,
      source: MusicSource.tidal,
      likesCount: json['popularity'] as int?,
      createdAt: json['created'] != null
          ? DateTime.tryParse(json['created'] as String)
          : null,
      updatedAt: json['lastUpdated'] != null
          ? DateTime.tryParse(json['lastUpdated'] as String)
          : null,
    );
  }

  @override
  List<Object?> get props => [id, source];
}

class PlaylistDetail extends Playlist {
  final List<Track> tracks;

  const PlaylistDetail({
    required super.id,
    required super.title,
    super.description,
    super.coverArtUrl,
    required super.trackCount,
    super.duration,
    super.creatorName,
    required super.source,
    super.likesCount,
    super.createdAt,
    super.updatedAt,
    required this.tracks,
  });

  factory PlaylistDetail.fromTidalJson(
    Map<String, dynamic> playlistJson,
    List<dynamic> tracksJson,
  ) {
    final playlist = Playlist.fromTidalJson(playlistJson);
    final tracks = tracksJson.map((item) {
      final trackData = item['item'] as Map<String, dynamic>? ?? item as Map<String, dynamic>;
      return Track.fromTidalJson(trackData);
    }).toList();

    return PlaylistDetail(
      id: playlist.id,
      title: playlist.title,
      description: playlist.description,
      coverArtUrl: playlist.coverArtUrl,
      trackCount: playlist.trackCount,
      duration: playlist.duration,
      creatorName: playlist.creatorName,
      source: playlist.source,
      likesCount: playlist.likesCount,
      createdAt: playlist.createdAt,
      updatedAt: playlist.updatedAt,
      tracks: tracks,
    );
  }
}
