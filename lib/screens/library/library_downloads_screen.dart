import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:convert';
import '../../core/theme/app_theme.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import '../../data/database.dart';
import '../../widgets/widgets.dart';
import '../scaffold_with_mini_player.dart';

/// Library Downloads Screen - TIDAL Style
class LibraryDownloadsScreen extends ConsumerWidget {
  const LibraryDownloadsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(downloadProvider);
    final database = ref.watch(databaseProvider);

    return ScaffoldWithMiniPlayer(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Downloaded',
          style: AppTheme.titleLarge.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: false,
      ),
      body: FutureBuilder<List<CachedTrack>>(
        future: database.getAllCachedTracks(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            );
          }

          final downloads = snapshot.data ?? const <CachedTrack>[];

          if (downloads.isEmpty) {
            return _buildEmptyState();
          }

          return _buildDownloadsList(downloads, ref);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Download icon in circle
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.arrow_downward_rounded,
                size: 36,
                color: Colors.white.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              "You haven't downloaded anything yet.",
              style: AppTheme.bodyLarge.copyWith(
                color: Colors.white.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              "To download content, tap the Download button on any album, mix, or playlist.",
              style: AppTheme.bodyMedium.copyWith(
                color: Colors.white.withOpacity(0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadsList(List<CachedTrack> downloads, WidgetRef ref) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: downloads.length,
      itemBuilder: (context, index) {
        final cached = downloads[index];
        try {
          final trackData = jsonDecode(cached.trackJson);
          final track = Track.fromJson(trackData);

          return ListTile(
            onTap: () {
              final tracks = downloads
                  .map((item) {
                    try {
                      final data = jsonDecode(item.trackJson);
                      return Track.fromJson(data);
                    } catch (_) {
                      return null;
                    }
                  })
                  .whereType<Track>()
                  .toList();

              final startIndex = tracks.indexWhere(
                (t) => t.id == track.id && t.source == track.source,
              );

              if (tracks.isNotEmpty && startIndex >= 0) {
                ref.read(playerProvider.notifier).playQueue(
                      tracks,
                      startIndex: startIndex,
                      source: 'Downloads',
                    );
              } else {
                ref.read(playerProvider.notifier).play(track);
              }
            },
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: track.coverArtUrl != null
                  ? CachedNetworkImage(
                      imageUrl: track.coverArtUrl!,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => _placeholderIcon(),
                      errorWidget: (_, __, ___) => _placeholderIcon(),
                    )
                  : _placeholderIcon(),
            ),
            title: Text(
              track.title,
              style: AppTheme.bodyLarge.copyWith(
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              track.artist,
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.secondaryColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: IconButton(
              icon:
                  const Icon(Icons.more_horiz, color: AppTheme.secondaryColor),
              onPressed: () => TrackOptionsSheet.show(context, track),
            ),
          );
        } catch (e) {
          return const SizedBox.shrink();
        }
      },
    );
  }

  Widget _placeholderIcon() {
    return Container(
      width: 48,
      height: 48,
      color: AppTheme.surfaceLight,
      child: const Icon(Icons.music_note,
          color: AppTheme.secondaryColor, size: 24),
    );
  }
}
