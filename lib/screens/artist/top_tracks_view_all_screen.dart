import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/track_options_sheet.dart';
import '../scaffold_with_mini_player.dart';

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

    return ScaffoldWithMiniPlayer(
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
          style: AppTheme.headlineSmall.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.shuffle, color: Colors.white),
            onPressed: tracks.isEmpty
                ? null
                : () {
                    final shuffled = List<Track>.from(tracks)..shuffle();
                    ref.read(playerProvider.notifier).playQueue(
                          shuffled,
                          startIndex: 0,
                          source: 'Artist: $artistName (Shuffled)',
                        );
                  },
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 36),
        itemCount: tracks.length,
        separatorBuilder: (_, __) => const SizedBox(height: 2),
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
                    source: 'Artist: $artistName',
                  );
            },
          );
        },
      ),
    );
  }
}

class _TrackListItem extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider);
    final isFavorite = favorites.isFavorite(track);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        child: Row(
          children: [
            SizedBox(
              width: 26,
              child: Text(
                '$index',
                textAlign: TextAlign.center,
                style: AppTheme.bodyLarge.copyWith(
                  color: isPlaying ? Colors.white : AppTheme.secondaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                width: 56,
                height: 56,
                child: track.coverArtUrl != null
                    ? CachedNetworkImage(
                        imageUrl: track.coverArtUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => _placeholder(),
                        errorWidget: (_, __, ___) => _placeholder(),
                      )
                    : _placeholder(),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          track.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.titleLarge.copyWith(
                            color: isPlaying ? Colors.white : Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (track.isExplicit) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: const Text(
                            'E',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    track.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.secondaryColor,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                size: 23,
                color:
                    isFavorite ? AppTheme.accentColor : AppTheme.secondaryColor,
              ),
              onPressed: () =>
                  ref.read(favoritesProvider.notifier).toggleFavorite(track),
            ),
            IconButton(
              icon: const Icon(
                Icons.more_vert,
                size: 22,
                color: AppTheme.secondaryColor,
              ),
              onPressed: () => TrackOptionsSheet.show(context, track),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: AppTheme.surfaceColor,
      child: const Icon(Icons.music_note, color: Colors.white38, size: 22),
    );
  }
}
