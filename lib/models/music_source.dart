// Music Source Enum
enum MusicSource {
  tidal,
  subsonic,
  qobuz;

  String get displayName {
    switch (this) {
      case MusicSource.tidal:
        return 'TIDAL';
      case MusicSource.subsonic:
        return 'HiFi';
      case MusicSource.qobuz:
        return 'Qobuz';
    }
  }

  String get icon {
    switch (this) {
      case MusicSource.tidal:
        return '🎵';
      case MusicSource.subsonic:
        return '🏠';
      case MusicSource.qobuz:
        return '🎧';
    }
  }
}

// Audio Quality
class AudioQuality {
  final int bitDepth; // 16 or 24
  final int sampleRate; // 44100, 48000, 96000, 192000
  final String format; // FLAC, etc.

  const AudioQuality({
    required this.bitDepth,
    required this.sampleRate,
    this.format = 'FLAC',
  });

  String get displayString {
    if (bitDepth == 24) {
      return '24-bit/${(sampleRate / 1000).toStringAsFixed(1)}kHz';
    }
    return '16-bit/${(sampleRate / 1000).toStringAsFixed(1)}kHz';
  }

  bool get isHiRes => bitDepth == 24;

  static const AudioQuality standard = AudioQuality(
    bitDepth: 16,
    sampleRate: 44100,
  );

  static const AudioQuality hiRes = AudioQuality(
    bitDepth: 24,
    sampleRate: 96000,
  );
}

// Quality Preference
enum QualityPreference {
  maximum, // 24-bit from Qobuz
  high, // 16-bit from TIDAL
  original, // From Subsonic
}

enum QobuzStreamQuality {
  maxHiRes,
  hiRes,
  cd,
  mp3;

  String get displayName {
    switch (this) {
      case QobuzStreamQuality.maxHiRes:
        return 'Max Hi-Res';
      case QobuzStreamQuality.hiRes:
        return 'Hi-Res';
      case QobuzStreamQuality.cd:
        return 'CD Quality';
      case QobuzStreamQuality.mp3:
        return 'MP3';
    }
  }

  String get description {
    switch (this) {
      case QobuzStreamQuality.maxHiRes:
        return '24-bit / up to 192kHz';
      case QobuzStreamQuality.hiRes:
        return '24-bit / up to 96kHz';
      case QobuzStreamQuality.cd:
        return '16-bit / 44.1kHz';
      case QobuzStreamQuality.mp3:
        return '320kbps';
    }
  }
}
