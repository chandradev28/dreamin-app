import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import '../../widgets/widgets.dart';

/// Playlist Detail Screen - Shows playlist info and track list
class PlaylistDetailScreen extends ConsumerWidget {
  final String playlistId;
  final Playlist? playlist; // Optional: pass for immediate display

  const PlaylistDetailScreen({
    super.key,
    required this.playlistId,
    this.playlist,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlistDetailAsync = ref.watch(playlistDetailProvider(playlistId));
    final responsive = Responsive(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: playlistDetailAsync.when(
        loading: () => _buildLoadingState(context, responsive),
        error: (error, stack) => _buildErrorState(context, error.toString(), responsive),
        data: (playlistDetail) => _buildContent(context, ref, playlistDetail, responsive),
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context, Responsive responsive) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          backgroundColor: AppTheme.backgroundColor,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        SliverFillRemaining(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (playlist != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                    child: playlist!.coverArtUrl != null
                        ? CachedNetworkImage(
                            imageUrl: playlist!.coverArtUrl!,
                            width: 150,
                            height: 150,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            width: 150,
                            height: 150,
                            color: AppTheme.surfaceColor,
                            child: const Icon(Icons.playlist_play, size: 60),
                          ),
                  ),
                  const SizedBox(height: 16),
                  Text(playlist!.title, style: AppTheme.titleLarge),
                  const SizedBox(height: 8),
                ],
                const CircularProgressIndicator(color: AppTheme.primaryColor),
                const SizedBox(height: 16),
                Text('Loading playlist...', style: AppTheme.bodyMedium),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context, String error, Responsive responsive) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          backgroundColor: AppTheme.backgroundColor,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        SliverFillRemaining(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: AppTheme.errorColor),
                const SizedBox(height: 16),
                Text('Failed to load playlist', style: AppTheme.titleLarge),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    error,
                    style: AppTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    PlaylistDetail playlistDetail,
    Responsive responsive,
  ) {
    final playerState = ref.watch(playerProvider);
    final favState = ref.watch(favoritesProvider);

    return CustomScrollView(
      slivers: [
        // Collapsible App Bar with Playlist Art
        SliverAppBar(
          expandedHeight: responsive.value(mobile: 300.0, tablet: 400.0),
          pinned: true,
          backgroundColor: AppTheme.backgroundColor,
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white),
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                // Playlist Art
                playlistDetail.coverArtUrl != null
                    ? CachedNetworkImage(
                        imageUrl: playlistDetail.coverArtUrl!,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        color: AppTheme.surfaceColor,
                        child: const Icon(Icons.playlist_play, size: 100, color: AppTheme.secondaryColor),
                      ),
                // Gradient overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        AppTheme.backgroundColor.withOpacity(0.8),
                        AppTheme.backgroundColor,
                      ],
                      stops: const [0.3, 0.7, 1.0],
                    ),
                  ),
                ),
                // Playlist Info at bottom
                Positioned(
                  left: responsive.horizontalPadding,
                  right: responsive.horizontalPadding,
                  bottom: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        playlistDetail.title,
                        style: responsive.value(
                          mobile: AppTheme.headlineMedium,
                          tablet: AppTheme.headlineLarge,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (playlistDetail.creatorName != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'by ${playlistDetail.creatorName}',
                          style: AppTheme.titleMedium.copyWith(
                            color: AppTheme.secondaryColor,
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        '${playlistDetail.trackCount} tracks${playlistDetail.formattedDuration.isNotEmpty ? ' • ${playlistDetail.formattedDuration}' : ''}',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.secondaryColor,
                        ),
                      ),
                      if (playlistDetail.description != null && playlistDetail.description!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          playlistDetail.description!,
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.secondaryColor,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Play All / Shuffle buttons
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: responsive.horizontalPadding,
              vertical: 16,
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: playlistDetail.tracks.isNotEmpty
                        ? () {
                            ref.read(playerProvider.notifier).playQueue(
                              playlistDetail.tracks,
                              startIndex: 0,
                            );
                          }
                        : null,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Play All'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: playlistDetail.tracks.isNotEmpty
                        ? () {
                            final shuffled = List<Track>.from(playlistDetail.tracks)..shuffle();
                            ref.read(playerProvider.notifier).playQueue(
                              shuffled,
                              startIndex: 0,
                            );
                          }
                        : null,
                    icon: const Icon(Icons.shuffle),
                    label: const Text('Shuffle'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryColor,
                      side: const BorderSide(color: AppTheme.primaryColor),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Tracks List
        if (playlistDetail.tracks.isEmpty)
          const SliverFillRemaining(
            child: Center(
              child: Text('No tracks in this playlist', style: TextStyle(color: AppTheme.secondaryColor)),
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final track = playlistDetail.tracks[index];
                return TrackListTile(
                  track: track,
                  isPlaying: playerState.currentTrack?.id == track.id,
                  isFavorite: favState.favoriteIds.contains('${track.id}_${track.source.name}'),
                  onTap: () {
                    ref.read(playerProvider.notifier).playQueue(
                      playlistDetail.tracks,
                      startIndex: index,
                    );
                  },
                  onFavoriteTap: () {
                    ref.read(favoritesProvider.notifier).toggleFavorite(track);
                  },
                );
              },
              childCount: playlistDetail.tracks.length,
            ),
          ),

        // Bottom spacing
        SliverToBoxAdapter(
          child: SizedBox(height: responsive.miniPlayerHeight + responsive.bottomNavHeight + 20),
        ),
      ],
    );
  }
}
