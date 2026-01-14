import 'package:equatable/equatable.dart';
import 'music_source.dart';

class Track extends Equatable {
  final String id;
  final String title;
  final String artist;
  final String artistId;
  final String album;
  final String albumId;
  final Duration duration;
  final int trackNumber;
  final String? genre;
  final int? year;
  final String? coverArtUrl;
  final MusicSource source;
  final AudioQuality? quality;
  final bool isExplicit;

  const Track({
    required this.id,
    required this.title,
    required this.artist,
    required this.artistId,
    required this.album,
    required this.albumId,
    required this.duration,
    required this.trackNumber,
    this.genre,
    this.year,
    this.coverArtUrl,
    required this.source,
    this.quality,
    this.isExplicit = false,
  });

  String get formattedDuration {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  Track copyWith({
    String? id,
    String? title,
    String? artist,
    String? artistId,
    String? album,
    String? albumId,
    Duration? duration,
    int? trackNumber,
    String? genre,
    int? year,
    String? coverArtUrl,
    MusicSource? source,
    AudioQuality? quality,
    bool? isExplicit,
  }) {
    return Track(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      artistId: artistId ?? this.artistId,
      album: album ?? this.album,
      albumId: albumId ?? this.albumId,
      duration: duration ?? this.duration,
      trackNumber: trackNumber ?? this.trackNumber,
      genre: genre ?? this.genre,
      year: year ?? this.year,
      coverArtUrl: coverArtUrl ?? this.coverArtUrl,
      source: source ?? this.source,
      quality: quality ?? this.quality,
      isExplicit: isExplicit ?? this.isExplicit,
    );
  }

  factory Track.fromTidalJson(Map<String, dynamic> json) {
    final artists = json['artists'] as List<dynamic>? ?? [];
    final artistName = artists.isNotEmpty 
        ? (artists.first['name'] as String? ?? 'Unknown Artist')
        : 'Unknown Artist';
    final artistId = artists.isNotEmpty
        ? (artists.first['id']?.toString() ?? '')
        : '';
    
    final album = json['album'] as Map<String, dynamic>? ?? {};
    final albumTitle = album['title'] as String? ?? 'Unknown Album';
    final albumId = album['id']?.toString() ?? '';
    
    final cover = album['cover'] as String?;
    String? coverUrl;
    if (cover != null) {
      final formattedCover = cover.replaceAll('-', '/');
      coverUrl = 'https://resources.tidal.com/images/$formattedCover/640x640.jpg';
    }

    return Track(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? 'Unknown Title',
      artist: artistName,
      artistId: artistId,
      album: albumTitle,
      albumId: albumId,
      duration: Duration(seconds: json['duration'] as int? ?? 0),
      trackNumber: json['trackNumber'] as int? ?? 1,
      genre: null,
      year: album['releaseDate'] != null 
          ? int.tryParse((album['releaseDate'] as String).split('-').first)
          : null,
      coverArtUrl: coverUrl,
      source: MusicSource.tidal,
      quality: const AudioQuality(bitDepth: 16, sampleRate: 44100),
      isExplicit: json['explicit'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'artistId': artistId,
      'album': album,
      'albumId': albumId,
      'duration': duration.inSeconds,
      'trackNumber': trackNumber,
      'genre': genre,
      'year': year,
      'coverArtUrl': coverArtUrl,
      'source': source.name,
      'isExplicit': isExplicit,
    };
  }

  @override
  List<Object?> get props => [id, source];
}
