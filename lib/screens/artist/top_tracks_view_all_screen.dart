import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_theme.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';

/// Top Tracks View All Screen - Shows artist's top 20 tracks in a list
class TopTracksViewAllScreen extends ConsumerWidget {
  final String title;
  final List<Track> tracks;
  final String artistName;

  const TopTracksViewAllScreen({
    super.key,
    required this.title,
    required this.tracks,
    required this.artistName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerProvider);
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.shuffle, color: Colors.white),
            onPressed: () {
              final shuffled = List<Track>.from(tracks)..shuffle();
              ref.read(playerProvider.notifier).playQueue(shuffled, startIndex: 0);
            },
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: tracks.length,
        itemBuilder: (context, index) {
          final track = tracks[index];
          final isPlaying = playerState.currentTrack?.id == track.id;
          
          return _TrackListItem(
            track: track,
            index: index + 1,
            isPlaying: isPlaying,
            onTap: () {
              ref.read(playerProvider.notifier).playQueue(
                tracks,
                startIndex: index,
              );
            },
          );
        },
      ),
    );
  }
}

class _TrackListItem extends StatelessWidget {
  final Track track;
  final int index;
  final bool isPlaying;
  final VoidCallback onTap;

  const _TrackListItem({
    required this.track,
    required this.index,
    required this.isPlaying,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: SizedBox(
        width: 56,
        child: Row(
          children: [
            SizedBox(
              width: 24,
              child: Text(
                '$index',
                style: TextStyle(
                  color: isPlaying ? AppTheme.accentColor : AppTheme.secondaryColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                width: 48,
                height: 48,
                child: track.coverArtUrl != null
                    ? CachedNetworkImage(
                        imageUrl: track.coverArtUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: AppTheme.surfaceColor,
                          child: const Icon(Icons.music_note, color: Colors.white38, size: 20),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: AppTheme.surfaceColor,
                          child: const Icon(Icons.music_note, color: Colors.white38, size: 20),
                        ),
                      )
                    : Container(
                        color: AppTheme.surfaceColor,
                        child: const Icon(Icons.music_note, color: Colors.white38, size: 20),
                      ),
              ),
            ),
          ],
        ),
      ),
      title: Text(
        track.title,
        style: TextStyle(
          color: isPlaying ? AppTheme.accentColor : Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        track.artist,
        style: TextStyle(
          color: AppTheme.secondaryColor,
          fontSize: 13,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (track.isExplicit)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.grey.shade700,
                borderRadius: BorderRadius.circular(2),
              ),
              child: const Text(
                'E',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.favorite_border, size: 20),
            onPressed: () {},
            color: AppTheme.secondaryColor,
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, size: 20),
            onPressed: () {},
            color: AppTheme.secondaryColor,
          ),
        ],
      ),
    );
  }
}
