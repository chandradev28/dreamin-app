import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../../providers/providers.dart';

/// Mini Player Widget - Responsive
class MiniPlayer extends ConsumerWidget {
  final VoidCallback? onTap;

  const MiniPlayer({super.key, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerProvider);
    final responsive = Responsive(context);

    if (!playerState.hasTrack) {
      return const SizedBox.shrink();
    }

    final track = playerState.currentTrack!;
    final height = responsive.miniPlayerHeight;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.76),
          border: const Border(
            top: BorderSide(
              color: Color(0x14FFFFFF),
              width: 0.5,
            ),
          ),
        ),
        child: Column(
          children: [
            // Progress bar
            LinearProgressIndicator(
              value: playerState.progress,
              backgroundColor: AppTheme.surfaceLighter,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppTheme.primaryColor,
              ),
              minHeight: 2,
            ),
            // Player content
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: responsive.horizontalPadding,
                ),
                child: Row(
                  children: [
                    // Album art
                    Container(
                      width: responsive.trackThumbnailSize,
                      height: responsive.trackThumbnailSize,
                      decoration: BoxDecoration(
                        borderRadius: AppTheme.radiusSmall,
                        color: AppTheme.surfaceLight,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: track.coverArtUrl != null
                          ? CachedNetworkImage(
                              imageUrl: track.coverArtUrl!,
                              fit: BoxFit.cover,
                            )
                          : const Icon(
                              Icons.music_note,
                              color: AppTheme.secondaryColor,
                            ),
                    ),
                    SizedBox(width: responsive.cardSpacing),
                    // Track info
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            track.title,
                            style: responsive.value(
                              mobile: AppTheme.titleSmall,
                              tablet: AppTheme.titleMedium,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            track.artist,
                            style: AppTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // Controls
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Favorite button
                        Consumer(
                          builder: (context, ref, child) {
                            final favState = ref.watch(favoritesProvider);
                            final isFav = favState.isFavorite(track);
                            return IconButton(
                              icon: Icon(
                                isFav ? Icons.favorite : Icons.favorite_border,
                                size: responsive.value(
                                    mobile: 24.0, tablet: 28.0),
                              ),
                              onPressed: () {
                                ref
                                    .read(favoritesProvider.notifier)
                                    .toggleFavorite(track);
                              },
                              color: isFav
                                  ? AppTheme.accentColor
                                  : AppTheme.secondaryColor,
                            );
                          },
                        ),
                        // Play/Pause
                        IconButton(
                          icon: Icon(
                            playerState.isPlaying
                                ? Icons.pause
                                : Icons.play_arrow,
                            size: responsive.value(mobile: 32.0, tablet: 36.0),
                          ),
                          onPressed: () {
                            ref.read(playerProvider.notifier).togglePlayPause();
                          },
                          color: AppTheme.primaryColor,
                        ),
                        // Next
                        IconButton(
                          icon: Icon(
                            Icons.skip_next,
                            size: responsive.value(mobile: 28.0, tablet: 32.0),
                          ),
                          onPressed: () {
                            ref.read(playerProvider.notifier).skipNext();
                          },
                          color: AppTheme.primaryColor,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
