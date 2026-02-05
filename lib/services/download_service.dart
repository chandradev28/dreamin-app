import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../models/models.dart';
import 'tidal_service.dart';
import 'qobuz_service.dart';
import 'subsonic_service.dart';

/// Download Service
/// Handles downloading audio files for offline playback
class DownloadService {
  static DownloadService? _instance;
  static DownloadService get instance => _instance ??= DownloadService._();
  
  DownloadService._();
  
  final http.Client _client = http.Client();
  
  // Service instances for stream URL resolution
  TidalService? _tidalService;
  final QobuzServiceImpl _qobuzService = QobuzServiceImpl();
  SubsonicServiceImpl? _subsonicService;
  
  /// Initialize with Tidal service (requires credentials)
  void initTidal(TidalService service) {
    _tidalService = service;
  }
  
  /// Initialize with Subsonic service
  void initSubsonic(SubsonicServiceImpl service) {
    _subsonicService = service;
  }
  
  /// Get the downloads directory path
  Future<Directory> get _downloadDir async {
    final appDir = await getApplicationDocumentsDirectory();
    final downloadDir = Directory(p.join(appDir.path, 'downloads'));
    if (!await downloadDir.exists()) {
      await downloadDir.create(recursive: true);
    }
    return downloadDir;
  }
  
  /// Get file extension based on source quality
  String _getExtension(MusicSource source) {
    switch (source) {
      case MusicSource.qobuz:
        return '.flac'; // Qobuz streams FLAC
      case MusicSource.tidal:
        return '.flac'; // TIDAL HI_RES is FLAC
      case MusicSource.subsonic:
        return '.mp3'; // Subsonic typically MP3
      default:
        return '.flac';
    }
  }
  
  /// Get stream URL for a track
  Future<String?> _getStreamUrl(Track track) async {
    switch (track.source) {
      case MusicSource.tidal:
        if (_tidalService == null) return null;
        final streamInfo = await _tidalService!.getStreamInfo(track.id);
        return streamInfo?.url;
        
      case MusicSource.qobuz:
        return await _qobuzService.getStreamUrl(track.id);
        
      case MusicSource.subsonic:
        if (_subsonicService == null) return null;
        return _subsonicService!.getStreamUrl(track.id);
        
      default:
        return null;
    }
  }
  
  /// Download a track with progress callback
  /// Returns file path on success, null on failure
  Future<DownloadResult> downloadTrack(
    Track track, {
    void Function(double progress)? onProgress,
    void Function(String status)? onStatus,
  }) async {
    try {
      onStatus?.call('Getting stream URL...');
      
      // Get stream URL
      final streamUrl = await _getStreamUrl(track);
      if (streamUrl == null) {
        return DownloadResult.error('Could not get stream URL');
      }
      
      onStatus?.call('Starting download...');
      
      // Prepare file path
      final dir = await _downloadDir;
      final cleanId = track.id.replaceAll(':', '_').replaceAll('/', '_');
      final ext = _getExtension(track.source);
      final filePath = p.join(dir.path, '$cleanId$ext');
      final file = File(filePath);
      
      // Check if already downloaded
      if (await file.exists()) {
        final size = await file.length();
        if (size > 0) {
          return DownloadResult.success(filePath, size);
        }
      }
      
      // Download with progress tracking
      final request = http.Request('GET', Uri.parse(streamUrl));
      final response = await _client.send(request);
      
      if (response.statusCode != 200) {
        return DownloadResult.error('HTTP ${response.statusCode}');
      }
      
      final totalBytes = response.contentLength ?? 0;
      int receivedBytes = 0;
      
      final sink = file.openWrite();
      
      await for (final chunk in response.stream) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        
        if (totalBytes > 0) {
          final progress = receivedBytes / totalBytes;
          onProgress?.call(progress);
        }
      }
      
      await sink.close();
      
      final fileSize = await file.length();
      
      if (fileSize == 0) {
        await file.delete();
        return DownloadResult.error('Downloaded file is empty');
      }
      
      onStatus?.call('Download complete');
      return DownloadResult.success(filePath, fileSize);
      
    } catch (e) {
      return DownloadResult.error(e.toString());
    }
  }
  
  /// Delete a downloaded track file
  Future<bool> deleteDownload(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
  
  /// Get total size of all downloads in bytes
  Future<int> getTotalDownloadSize() async {
    try {
      final dir = await _downloadDir;
      if (!await dir.exists()) return 0;
      
      int total = 0;
      await for (final entity in dir.list()) {
        if (entity is File) {
          total += await entity.length();
        }
      }
      return total;
    } catch (e) {
      return 0;
    }
  }
  
  /// Clear all downloads
  Future<void> clearAllDownloads() async {
    try {
      final dir = await _downloadDir;
      if (await dir.exists()) {
        await for (final entity in dir.list()) {
          if (entity is File) {
            await entity.delete();
          }
        }
      }
    } catch (e) {
      // Ignore errors
    }
  }
}

/// Result of a download operation
class DownloadResult {
  final bool success;
  final String? filePath;
  final int? fileSize;
  final String? error;
  
  DownloadResult._({
    required this.success,
    this.filePath,
    this.fileSize,
    this.error,
  });
  
  factory DownloadResult.success(String path, int size) {
    return DownloadResult._(
      success: true,
      filePath: path,
      fileSize: size,
    );
  }
  
  factory DownloadResult.error(String message) {
    return DownloadResult._(
      success: false,
      error: message,
    );
  }
}
