import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import '../../widgets/widgets.dart';

/// Album Detail Screen - Shows album info and track list
class AlbumDetailScreen extends ConsumerWidget {
  final String albumId;
  final Album? album; // Optional: pass album for immediate display while loading

  const AlbumDetailScreen({
    super.key,
    required this.albumId,
    this.album,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final albumDetailAsync = ref.watch(albumDetailProvider(albumId));
    final responsive = Responsive(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: albumDetailAsync.when(
        loading: () => _buildLoadingState(context, responsive),
        error: (error, stack) => _buildErrorState(context, error.toString(), responsive),
        data: (albumDetail) => albumDetail == null
            ? _buildErrorState(context, 'Album not found', responsive)
            : _buildContent(context, ref, albumDetail, responsive),
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context, Responsive responsive) {
    return CustomScrollView(
      slivers: [
        // App bar with back button
        SliverAppBar(
          backgroundColor: AppTheme.backgroundColor,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        // Loading content
        SliverFillRemaining(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (album != null) ...[
                  // Show album preview while loading
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                    child: album!.coverArtUrl != null
                        ? CachedNetworkImage(
                            imageUrl: album!.coverArtUrl!,
                            width: 150,
                            height: 150,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            width: 150,
                            height: 150,
                            color: AppTheme.surfaceColor,
                            child: const Icon(Icons.album, size: 60),
                          ),
                  ),
                  const SizedBox(height: 16),
                  Text(album!.title, style: AppTheme.titleLarge),
                  const SizedBox(height: 8),
                ],
                const CircularProgressIndicator(color: AppTheme.primaryColor),
                const SizedBox(height: 16),
                Text('Loading tracks...', style: AppTheme.bodyMedium),
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
                Text('Failed to load album', style: AppTheme.titleLarge),
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
    AlbumDetail albumDetail,
    Responsive responsive,
  ) {
    final playerState = ref.watch(playerProvider);
    final favState = ref.watch(favoritesProvider);

    return CustomScrollView(
      slivers: [
        // Collapsible App Bar with Album Art
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
                // Album Art
                albumDetail.coverArtUrl != null
                    ? CachedNetworkImage(
                        imageUrl: albumDetail.coverArtUrl!,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        color: AppTheme.surfaceColor,
                        child: const Icon(Icons.album, size: 100, color: AppTheme.secondaryColor),
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
                // Album Info at bottom
                Positioned(
                  left: responsive.horizontalPadding,
                  right: responsive.horizontalPadding,
                  bottom: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        albumDetail.title,
                        style: responsive.value(
                          mobile: AppTheme.headlineMedium,
                          tablet: AppTheme.headlineLarge,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        albumDetail.artist,
                        style: AppTheme.titleMedium.copyWith(
                          color: AppTheme.secondaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${albumDetail.trackCount} tracks${albumDetail.year != null ? ' • ${albumDetail.year}' : ''}',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.secondaryColor,
                        ),
                      ),
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
                // Play All button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: albumDetail.tracks.isNotEmpty
                        ? () {
                            ref.read(playerProvider.notifier).playQueue(
                              albumDetail.tracks,
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
                // Shuffle button
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: albumDetail.tracks.isNotEmpty
                        ? () {
                            final shuffled = List<Track>.from(albumDetail.tracks)..shuffle();
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
        if (albumDetail.tracks.isEmpty)
          const SliverFillRemaining(
            child: Center(
              child: Text('No tracks available', style: TextStyle(color: AppTheme.secondaryColor)),
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final track = albumDetail.tracks[index];
                return TrackListTile(
                  track: track,
                  index: index + 1,
                  isPlaying: playerState.currentTrack?.id == track.id,
                  isFavorite: favState.isFavorite(track),
                  onTap: () {
                    ref.read(playerProvider.notifier).playQueue(
                      albumDetail.tracks,
                      startIndex: index,
                    );
                  },
                  onFavoriteTap: () {
                    ref.read(favoritesProvider.notifier).toggleFavorite(track);
                  },
                );
              },
              childCount: albumDetail.tracks.length,
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
