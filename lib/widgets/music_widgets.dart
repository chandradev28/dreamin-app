import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/responsive.dart';
import '../models/models.dart';
import 'track_options_sheet.dart';

/// Album Card Widget - Responsive
class AlbumCard extends StatelessWidget {
  final Album album;
  final VoidCallback? onTap;
  final double? width;

  const AlbumCard({
    super.key,
    required this.album,
    this.onTap,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);
    final cardWidth = width ?? responsive.albumCardWidth;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: cardWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Album Cover
            AspectRatio(
              aspectRatio: 1,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: AppTheme.radiusMedium,
                  color: AppTheme.surfaceLight,
                ),
                clipBehavior: Clip.antiAlias,
                child: album.coverArtUrl != null
                    ? CachedNetworkImage(
                        imageUrl: album.coverArtUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.secondaryColor,
                          ),
                        ),
                        errorWidget: (context, url, error) => const Icon(
                          Icons.album,
                          color: AppTheme.secondaryColor,
                          size: 40,
                        ),
                      )
                    : const Icon(
                        Icons.album,
                        color: AppTheme.secondaryColor,
                        size: 40,
                      ),
              ),
            ),
            SizedBox(height: responsive.value(mobile: 8.0, tablet: 10.0)),
            // Title
            Text(
              album.title,
              style: responsive.value(
                mobile: AppTheme.titleSmall,
                tablet: AppTheme.titleMedium,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            // Artist
            Text(
              album.artist,
              style: AppTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// Playlist Card Widget - Responsive
class PlaylistCard extends StatelessWidget {
  final Playlist playlist;
  final VoidCallback? onTap;
  final double? width;

  const PlaylistCard({
    super.key,
    required this.playlist,
    this.onTap,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);
    final cardWidth = width ?? responsive.playlistCardWidth;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: cardWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Playlist Cover
            AspectRatio(
              aspectRatio: 1,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: AppTheme.radiusMedium,
                  color: AppTheme.surfaceLight,
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (playlist.coverArtUrl != null)
                      CachedNetworkImage(
                        imageUrl: playlist.coverArtUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.secondaryColor,
                          ),
                        ),
                        errorWidget: (context, url, error) => const Icon(
                          Icons.playlist_play,
                          color: AppTheme.secondaryColor,
                          size: 40,
                        ),
                      )
                    else
                      const Icon(
                        Icons.playlist_play,
                        color: AppTheme.secondaryColor,
                        size: 40,
                      ),
                    // Source badge
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: SourceBadge(source: playlist.source),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: responsive.value(mobile: 8.0, tablet: 10.0)),
            // Title
            Text(
              playlist.title,
              style: responsive.value(
                mobile: AppTheme.titleSmall,
                tablet: AppTheme.titleMedium,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            // Creator
            Text(
              playlist.creatorName ?? playlist.source.displayName,
              style: AppTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// Track List Tile Widget - Responsive
class TrackListTile extends StatelessWidget {
  final Track track;
  final int? index;
  final bool isPlaying;
  final bool isFavorite;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteTap;
  final VoidCallback? onMoreTap;

  const TrackListTile({
    super.key,
    required this.track,
    this.index,
    this.isPlaying = false,
    this.isFavorite = false,
    this.onTap,
    this.onFavoriteTap,
    this.onMoreTap,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);
    final thumbnailSize = responsive.trackThumbnailSize;

    return ListTile(
      contentPadding: EdgeInsets.symmetric(
        horizontal: responsive.horizontalPadding,
        vertical: responsive.value(mobile: 4.0, tablet: 6.0),
      ),
      onTap: onTap,
      leading: SizedBox(
        width: thumbnailSize,
        height: thumbnailSize,
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: AppTheme.radiusSmall,
                color: AppTheme.surfaceLight,
              ),
              clipBehavior: Clip.antiAlias,
              child: track.coverArtUrl != null
                  ? CachedNetworkImage(
                      imageUrl: track.coverArtUrl!,
                      fit: BoxFit.cover,
                      width: thumbnailSize,
                      height: thumbnailSize,
                    )
                  : Icon(
                      Icons.music_note,
                      color: AppTheme.secondaryColor,
                      size: thumbnailSize * 0.5,
                    ),
            ),
            if (isPlaying)
              Container(
                decoration: BoxDecoration(
                  borderRadius: AppTheme.radiusSmall,
                  color: Colors.black54,
                ),
                child: Center(
                  child: Icon(
                    Icons.equalizer,
                    color: AppTheme.accentColor,
                    size: thumbnailSize * 0.5,
                  ),
                ),
              ),
          ],
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              track.title,
              style: isPlaying
                  ? AppTheme.titleSmall.copyWith(color: AppTheme.accentColor)
                  : AppTheme.titleSmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (track.isExplicit)
            Container(
              margin: const EdgeInsets.only(left: 6),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: AppTheme.secondaryColor,
                borderRadius: BorderRadius.circular(2),
              ),
              child: Text(
                'E',
                style: AppTheme.labelSmall.copyWith(
                  color: AppTheme.backgroundColor,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      subtitle: Row(
        children: [
          SourceBadge(source: track.source, small: true),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              track.artist,
              style: AppTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      trailing: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.more_vert, size: 20),
          onPressed: onMoreTap ?? () => TrackOptionsSheet.show(context, track),
          color: AppTheme.secondaryColor,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ),
    );
  }
}

/// Artist Card Widget - Responsive
class ArtistCard extends StatelessWidget {
  final Artist artist;
  final VoidCallback? onTap;
  final double? size;

  const ArtistCard({
    super.key,
    required this.artist,
    this.onTap,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);
    final double cardSize = size ?? responsive.value(mobile: 100.0, tablet: 120.0, desktop: 140.0);

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: cardSize,
        child: Column(
          children: [
            // Artist Image (circular)
            Container(
              width: cardSize,
              height: cardSize,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.surfaceLight,
              ),
              clipBehavior: Clip.antiAlias,
              child: artist.imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: artist.imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.secondaryColor,
                        ),
                      ),
                      errorWidget: (context, url, error) => Icon(
                        Icons.person,
                        color: AppTheme.secondaryColor,
                        size: cardSize * 0.4,
                      ),
                    )
                  : Icon(
                      Icons.person,
                      color: AppTheme.secondaryColor,
                      size: cardSize * 0.4,
                    ),
            ),
            SizedBox(height: responsive.value(mobile: 8.0, tablet: 10.0)),
            // Name
            Text(
              artist.name,
              style: AppTheme.titleSmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Source Badge Widget
class SourceBadge extends StatelessWidget {
  final MusicSource source;
  final bool small;

  const SourceBadge({
    super.key,
    required this.source,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = switch (source) {
      MusicSource.tidal => AppTheme.tidalBadge,
      MusicSource.subsonic => AppTheme.hifiBadge,
      MusicSource.qobuz => AppTheme.qobuzBadge,
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 4 : 6,
        vertical: small ? 1 : 2,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color, width: 0.5),
      ),
      child: Text(
        source.displayName,
        style: (small ? AppTheme.labelSmall : AppTheme.labelMedium).copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Section Header Widget - Responsive
class SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onViewAllTap;

  const SectionHeader({
    super.key,
    required this.title,
    this.onViewAllTap,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.horizontalPadding,
        vertical: responsive.value(mobile: 12.0, tablet: 16.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: responsive.value(
              mobile: AppTheme.headlineSmall,
              tablet: AppTheme.headlineMedium,
            ),
          ),
          if (onViewAllTap != null)
            TextButton(
              onPressed: onViewAllTap,
              child: Text(
                'View all',
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.secondaryColor,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Responsive Horizontal Scroll List
class HorizontalScrollList<T> extends StatelessWidget {
  final List<T> items;
  final Widget Function(T item, double width) itemBuilder;
  final double? itemWidth;
  final double? height;

  const HorizontalScrollList({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.itemWidth,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);
    final width = itemWidth ?? responsive.albumCardWidth;
    // Calculate height: card width + spacing + text lines
    final calculatedHeight = height ?? (width + responsive.value(mobile: 55.0, tablet: 65.0));

    return SizedBox(
      height: calculatedHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: responsive.horizontalPadding),
        itemCount: items.length,
        separatorBuilder: (context, index) => SizedBox(width: responsive.cardSpacing),
        itemBuilder: (context, index) => itemBuilder(items[index], width),
      ),
    );
  }
}

/// Responsive Grid View
class ResponsiveGrid<T> extends StatelessWidget {
  final List<T> items;
  final Widget Function(T item, double width) itemBuilder;
  final double childAspectRatio;
  final EdgeInsetsGeometry? padding;

  const ResponsiveGrid({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.childAspectRatio = 0.75,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);
    final itemWidth = responsive.gridItemWidth();

    return GridView.builder(
      padding: padding ?? EdgeInsets.all(responsive.horizontalPadding),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: responsive.gridColumns,
        mainAxisSpacing: responsive.cardSpacing,
        crossAxisSpacing: responsive.cardSpacing,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) => itemBuilder(items[index], itemWidth),
    );
  }
}

/// Loading Shimmer Widget
class LoadingShimmer extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const LoadingShimmer({
    super.key,
    this.width = double.infinity,
    this.height = 100,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: borderRadius ?? AppTheme.radiusMedium,
      ),
    );
  }
}

/// For You Section (Recommendations)
class ForYouSection extends StatelessWidget {
  final List<Track> tracks;
  final void Function(Track track, int index) onTrackTap;

  const ForYouSection({
    super.key,
    required this.tracks,
    required this.onTrackTap,
  });

  @override
  Widget build(BuildContext context) {
    if (tracks.isEmpty) return const SizedBox.shrink();

    final responsive = Responsive(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'For You'),
        SizedBox(
          height: responsive.value(mobile: 180.0, tablet: 220.0),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: responsive.horizontalPadding),
            itemCount: tracks.length.clamp(0, 10),
            separatorBuilder: (_, __) => SizedBox(width: responsive.cardSpacing),
            itemBuilder: (context, index) {
              final track = tracks[index];
              final cardWidth = responsive.value(mobile: 140.0, tablet: 160.0);
              
              return GestureDetector(
                onTap: () => onTrackTap(track, index),
                child: SizedBox(
                  width: cardWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AspectRatio(
                        aspectRatio: 1,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: AppTheme.radiusMedium,
                            color: AppTheme.surfaceLight,
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              if (track.coverArtUrl != null)
                                CachedNetworkImage(
                                  imageUrl: track.coverArtUrl!,
                                  fit: BoxFit.cover,
                                ),
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withOpacity(0.7),
                                    ],
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    color: AppTheme.primaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.play_arrow,
                                    color: AppTheme.backgroundColor,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        track.title,
                        style: AppTheme.titleSmall,
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
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Track Card Widget - For horizontal scroll lists (Echo-style)
class TrackCard extends StatelessWidget {
  final Track track;
  final double width;
  final VoidCallback? onTap;

  const TrackCard({
    super.key,
    required this.track,
    required this.width,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover Art with play button overlay
            Stack(
              children: [
                Container(
                  width: width,
                  height: width,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                    color: AppTheme.surfaceColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                    child: track.coverArtUrl != null
                        ? CachedNetworkImage(
                            imageUrl: track.coverArtUrl!,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => _TrackPlaceholder(title: track.title),
                            errorWidget: (_, __, ___) => _TrackPlaceholder(title: track.title),
                          )
                        : _TrackPlaceholder(title: track.title),
                  ),
                ),
                // Play button overlay
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.3),
                        ],
                      ),
                    ),
                    child: Center(
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingS),
            // Track Title
            Text(
              track.title,
              style: AppTheme.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            // Artist & Duration
            Text(
              '${_formatDuration(track.duration)} • ${track.artist}',
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

/// Track card placeholder
class _TrackPlaceholder extends StatelessWidget {
  final String title;

  const _TrackPlaceholder({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.surfaceColor,
      child: Center(
        child: Icon(
          Icons.music_note_rounded,
          color: AppTheme.primaryColor.withOpacity(0.5),
          size: 40,
        ),
      ),
    );
  }
}
