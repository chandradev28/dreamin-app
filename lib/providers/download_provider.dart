import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../services/download_service.dart';
import '../data/database.dart';
import 'database_provider.dart';

/// Download state - tracks queue and current download progress
class DownloadState {
  final List<Track> queue;
  final Track? currentDownload;
  final double currentProgress;
  final String? currentStatus;
  final Set<String> downloadedTrackIds;
  final bool isDownloading;
  
  const DownloadState({
    this.queue = const [],
    this.currentDownload,
    this.currentProgress = 0,
    this.currentStatus,
    this.downloadedTrackIds = const {},
    this.isDownloading = false,
  });
  
  DownloadState copyWith({
    List<Track>? queue,
    Track? currentDownload,
    double? currentProgress,
    String? currentStatus,
    Set<String>? downloadedTrackIds,
    bool? isDownloading,
    bool clearCurrentDownload = false,
  }) {
    return DownloadState(
      queue: queue ?? this.queue,
      currentDownload: clearCurrentDownload ? null : (currentDownload ?? this.currentDownload),
      currentProgress: currentProgress ?? this.currentProgress,
      currentStatus: currentStatus ?? this.currentStatus,
      downloadedTrackIds: downloadedTrackIds ?? this.downloadedTrackIds,
      isDownloading: isDownloading ?? this.isDownloading,
    );
  }
  
  bool isDownloaded(String trackId) => downloadedTrackIds.contains(trackId);
  bool isInQueue(String trackId) => queue.any((t) => t.id == trackId);
  bool isCurrentlyDownloading(String trackId) => currentDownload?.id == trackId;
}

/// Download notifier - manages download queue and operations
class DownloadNotifier extends StateNotifier<DownloadState> {
  final AppDatabase _database;
  final DownloadService _downloadService = DownloadService.instance;
  bool _isProcessing = false;
  
  DownloadNotifier(this._database) : super(const DownloadState()) {
    _loadDownloadedTracks();
  }
  
  /// Load already downloaded track IDs from database
  Future<void> _loadDownloadedTracks() async {
    try {
      final cached = await _database.getAllCachedTracks();
      final ids = cached.map((c) => c.trackId).toSet();
      state = state.copyWith(downloadedTrackIds: ids);
    } catch (e) {
      // Ignore errors on initial load
    }
  }
  
  /// Add track to download queue
  void addToQueue(Track track) {
    // Skip if already downloaded or in queue
    if (state.isDownloaded(track.id) || state.isInQueue(track.id)) {
      return;
    }
    
    state = state.copyWith(
      queue: [...state.queue, track],
    );
    
    _processQueue();
  }
  
  /// Add multiple tracks to queue (album/playlist download)
  void addAllToQueue(List<Track> tracks) {
    final newTracks = tracks.where(
      (t) => !state.isDownloaded(t.id) && !state.isInQueue(t.id)
    ).toList();
    
    if (newTracks.isEmpty) return;
    
    state = state.copyWith(
      queue: [...state.queue, ...newTracks],
    );
    
    _processQueue();
  }
  
  /// Remove track from queue
  void removeFromQueue(Track track) {
    state = state.copyWith(
      queue: state.queue.where((t) => t.id != track.id).toList(),
    );
  }
  
  /// Cancel current download
  void cancelCurrent() {
    if (state.currentDownload != null) {
      state = state.copyWith(
        clearCurrentDownload: true,
        isDownloading: false,
        currentProgress: 0,
        currentStatus: null,
      );
    }
  }
  
  /// Process download queue
  Future<void> _processQueue() async {
    if (_isProcessing || state.queue.isEmpty) return;
    
    _isProcessing = true;
    
    while (state.queue.isNotEmpty) {
      final track = state.queue.first;
      
      state = state.copyWith(
        currentDownload: track,
        currentProgress: 0,
        currentStatus: 'Starting...',
        isDownloading: true,
        queue: state.queue.skip(1).toList(),
      );
      
      final result = await _downloadService.downloadTrack(
        track,
        onProgress: (progress) {
          state = state.copyWith(
            currentProgress: progress,
            currentStatus: '${(progress * 100).toInt()}%',
          );
        },
        onStatus: (status) {
          state = state.copyWith(currentStatus: status);
        },
      );
      
      if (result.success && result.filePath != null) {
        // Save to database
        await _database.cacheTrack(
          trackId: track.id,
          source: track.source.index,
          trackJson: jsonEncode(track.toJson()),
          filePath: result.filePath!,
          fileSize: result.fileSize ?? 0,
        );
        
        // Update downloaded set
        state = state.copyWith(
          downloadedTrackIds: {...state.downloadedTrackIds, track.id},
        );
      }
    }
    
    // Queue empty, reset state
    state = state.copyWith(
      clearCurrentDownload: true,
      isDownloading: false,
      currentProgress: 0,
      currentStatus: null,
    );
    
    _isProcessing = false;
  }
  
  /// Delete a downloaded track
  Future<void> deleteDownload(Track track) async {
    await _database.removeCachedTrack(track.id, track.source.index);
    
    state = state.copyWith(
      downloadedTrackIds: state.downloadedTrackIds
          .where((id) => id != track.id)
          .toSet(),
    );
  }
  
  /// Refresh downloaded tracks list
  Future<void> refresh() async {
    await _loadDownloadedTracks();
  }
}

/// Provider for download state
final downloadProvider = StateNotifierProvider<DownloadNotifier, DownloadState>((ref) {
  final database = ref.watch(databaseProvider);
  return DownloadNotifier(database);
});
