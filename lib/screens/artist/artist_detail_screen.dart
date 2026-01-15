import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import '../../widgets/widgets.dart';
import '../album/album_detail_screen.dart';

/// Artist Detail Screen - Echo/Deezer Style
/// Shows: Circular image, Name, Bio, Top Tracks, Albums, Related Playlists
class ArtistDetailScreen extends ConsumerWidget {
  final String artistId;
  final Artist? artist;

  const ArtistDetailScreen({
    super.key,
    required this.artistId,
    this.artist,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final artistDetailAsync = ref.watch(artistDetailProvider(artistId));
    final responsive = Responsive(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: artistDetailAsync.when(
        loading: () => _buildLoadingState(context, responsive),
        error: (error, stack) => _buildErrorState(context, error.toString(), responsive),
        data: (artistDetail) => _buildContent(context, ref, artistDetail, responsive),
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context, Responsive responsive) {
    return SafeArea(
      child: Column(
        children: [
          // Header
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: responsive.horizontalPadding,
              vertical: 8,
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () {},
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (artist != null) ...[
                    // Artist circle preview
                    Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.surfaceColor,
                        image: artist!.imageUrl != null
                            ? DecorationImage(
                                image: CachedNetworkImageProvider(artist!.imageUrl!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: artist!.imageUrl == null
                          ? Center(
                              child: Text(
                                artist!.name.isNotEmpty ? artist!.name[0].toUpperCase() : '?',
                                style: AppTheme.displayLarge,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(height: 16),
                    Text(artist!.name, style: AppTheme.headlineMedium),
                    const SizedBox(height: 16),
                  ],
                  const CircularProgressIndicator(color: AppTheme.primaryColor),
                  const SizedBox(height: 16),
                  Text('Loading artist...', style: AppTheme.bodyMedium),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error, Responsive responsive) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: responsive.horizontalPadding,
              vertical: 8,
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: AppTheme.errorColor),
                  const SizedBox(height: 16),
                  Text('Failed to load artist', style: AppTheme.titleLarge),
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
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    ArtistDetail artistDetail,
    Responsive responsive,
  ) {
    final playerState = ref.watch(playerProvider);
    final favState = ref.watch(favoritesProvider);

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          // Header with back button
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: responsive.horizontalPadding,
                vertical: 8,
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),

          // Artist Image (Large Circular) - Echo Style
          SliverToBoxAdapter(
            child: Center(
              child: Container(
                width: responsive.value(mobile: 180.0, tablet: 220.0),
                height: responsive.value(mobile: 180.0, tablet: 220.0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.surfaceColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: artistDetail.imageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: artistDetail.imageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            color: AppTheme.surfaceLight,
                            child: Icon(
                              Icons.person,
                              size: 80,
                              color: AppTheme.secondaryColor,
                            ),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: AppTheme.surfaceLight,
                            child: Center(
                              child: Text(
                                artistDetail.name.isNotEmpty
                                    ? artistDetail.name[0].toUpperCase()
                                    : '?',
                                style: AppTheme.displayLarge.copyWith(
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ),
                          ),
                        )
                      : Container(
                          color: AppTheme.surfaceLight,
                          child: Center(
                            child: Text(
                              artistDetail.name.isNotEmpty
                                  ? artistDetail.name[0].toUpperCase()
                                  : '?',
                              style: AppTheme.displayLarge.copyWith(
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                        ),
                ),
              ),
            ),
          ),

          // Artist Name with Icon
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, color: AppTheme.secondaryColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    artistDetail.name,
                    style: AppTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          // Action Buttons (Follow, Bookmark, Share)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: responsive.horizontalPadding),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Follow Button
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Follow'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryColor,
                      side: BorderSide(color: AppTheme.secondaryColor.withOpacity(0.3)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Bookmark
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.secondaryColor.withOpacity(0.3)),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.bookmark_border, size: 20),
                      onPressed: () {},
                      color: AppTheme.secondaryColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Share
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.secondaryColor.withOpacity(0.3)),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.share, size: 20),
                      onPressed: () {},
                      color: AppTheme.secondaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bio Section
          if (artistDetail.bio != null && artistDetail.bio!.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(responsive.horizontalPadding),
                child: Text(
                  artistDetail.bio!,
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.secondaryColor,
                    height: 1.5,
                  ),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),

          // Search and Filter buttons
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: responsive.horizontalPadding,
                vertical: 8,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.surfaceColor,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.search, size: 20),
                      onPressed: () {},
                      color: AppTheme.secondaryColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.surfaceColor,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.tune, size: 20),
                      onPressed: () {},
                      color: AppTheme.secondaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // TOP SECTION - Horizontal scrollable tracks (Echo style)
          if (artistDetail.topTracks.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  responsive.horizontalPadding,
                  16,
                  responsive.horizontalPadding,
                  12,
                ),
                child: Row(
                  children: [
                    Text('Top', style: AppTheme.titleLarge),
                    const Spacer(),
                    // Shuffle button
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.surfaceColor,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.shuffle, size: 18),
                        onPressed: () {
                          final shuffled = List<Track>.from(artistDetail.topTracks)..shuffle();
                          ref.read(playerProvider.notifier).playQueue(shuffled, startIndex: 0);
                        },
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.arrow_forward, color: AppTheme.secondaryColor),
                  ],
                ),
              ),
            ),
            // Horizontal scrollable top tracks
            SliverToBoxAdapter(
              child: SizedBox(
                height: responsive.value(mobile: 80.0, tablet: 90.0),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: responsive.horizontalPadding),
                  itemCount: artistDetail.topTracks.length.clamp(0, 10),
                  itemBuilder: (context, index) {
                    final track = artistDetail.topTracks[index];
                    final isPlaying = playerState.currentTrack?.id == track.id;
                    return _TopTrackCard(
                      track: track,
                      index: index + 1,
                      isPlaying: isPlaying,
                      onTap: () {
                        ref.read(playerProvider.notifier).playQueue(
                          artistDetail.topTracks,
                          startIndex: index,
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],

          // HIGHLIGHT SECTION (First Album)
          if (artistDetail.albums.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  responsive.horizontalPadding,
                  24,
                  responsive.horizontalPadding,
                  12,
                ),
                child: Text('Highlight', style: AppTheme.titleLarge),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: responsive.horizontalPadding),
                child: _HighlightAlbumCard(
                  album: artistDetail.albums.first,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AlbumDetailScreen(
                          albumId: artistDetail.albums.first.id,
                          album: artistDetail.albums.first,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],

          // ALBUMS SECTION
          if (artistDetail.albums.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  responsive.horizontalPadding,
                  24,
                  responsive.horizontalPadding,
                  12,
                ),
                child: Row(
                  children: [
                    Text('Albums', style: AppTheme.titleLarge),
                    const Spacer(),
                    Icon(Icons.arrow_forward, color: AppTheme.secondaryColor),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: responsive.value(mobile: 180.0, tablet: 220.0),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: responsive.horizontalPadding),
                  itemCount: artistDetail.albums.length,
                  itemBuilder: (context, index) {
                    final album = artistDetail.albums[index];
                    return _AlbumCard(
                      album: album,
                      width: responsive.value(mobile: 120.0, tablet: 150.0),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => AlbumDetailScreen(
                              albumId: album.id,
                              album: album,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],

          // Bottom spacing
          SliverToBoxAdapter(
            child: SizedBox(height: responsive.miniPlayerHeight + responsive.bottomNavHeight + 40),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// CUSTOM WIDGETS FOR ARTIST DETAIL
// ============================================================================

/// Top Track Card - Horizontal scrollable (Echo style)
class _TopTrackCard extends StatelessWidget {
  final Track track;
  final int index;
  final bool isPlaying;
  final VoidCallback onTap;

  const _TopTrackCard({
    required this.track,
    required this.index,
    required this.isPlaying,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: AppTheme.spacingM),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isPlaying ? AppTheme.primaryColor.withOpacity(0.15) : AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusS),
        ),
        child: Row(
          children: [
            // Track image
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusS),
              child: track.coverArtUrl != null
                  ? CachedNetworkImage(
                      imageUrl: track.coverArtUrl!,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        width: 56,
                        height: 56,
                        color: AppTheme.surfaceLight,
                        child: const Icon(Icons.music_note, color: AppTheme.secondaryColor),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        width: 56,
                        height: 56,
                        color: AppTheme.surfaceLight,
                        child: const Icon(Icons.music_note, color: AppTheme.secondaryColor),
                      ),
                    )
                  : Container(
                      width: 56,
                      height: 56,
                      color: AppTheme.surfaceLight,
                      child: const Icon(Icons.music_note, color: AppTheme.secondaryColor),
                    ),
            ),
            const SizedBox(width: 12),
            // Track info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$index.',
                    style: AppTheme.labelSmall.copyWith(color: AppTheme.secondaryColor),
                  ),
                  Text(
                    track.title,
                    style: isPlaying
                        ? AppTheme.bodyMedium.copyWith(color: AppTheme.primaryColor)
                        : AppTheme.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    track.formattedDuration,
                    style: AppTheme.bodySmall,
                  ),
                ],
              ),
            ),
            // More button
            IconButton(
              icon: const Icon(Icons.more_horiz, size: 20),
              onPressed: () {},
              color: AppTheme.secondaryColor,
            ),
          ],
        ),
      ),
    );
  }
}

/// Highlight Album Card (Featured album)
class _HighlightAlbumCard extends StatelessWidget {
  final Album album;
  final VoidCallback onTap;

  const _HighlightAlbumCard({
    required this.album,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
        ),
        child: Row(
          children: [
            // Album cover
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusS),
              child: album.coverArtUrl != null
                  ? CachedNetworkImage(
                      imageUrl: album.coverArtUrl!,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 80,
                      height: 80,
                      color: AppTheme.surfaceLight,
                      child: const Icon(Icons.album, size: 32),
                    ),
            ),
            const SizedBox(width: 16),
            // Album info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    album.title,
                    style: AppTheme.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${album.trackCount} Songs${album.year != null ? ' • ${album.year}' : ''}',
                    style: AppTheme.bodySmall.copyWith(color: AppTheme.secondaryColor),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Album Card (for horizontal list)
class _AlbumCard extends StatelessWidget {
  final Album album;
  final double width;
  final VoidCallback onTap;

  const _AlbumCard({
    required this.album,
    required this.width,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        margin: const EdgeInsets.only(right: AppTheme.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Album cover
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
              child: album.coverArtUrl != null
                  ? CachedNetworkImage(
                      imageUrl: album.coverArtUrl!,
                      width: width,
                      height: width,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        width: width,
                        height: width,
                        color: AppTheme.surfaceLight,
                        child: const Icon(Icons.album, color: AppTheme.secondaryColor),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        width: width,
                        height: width,
                        color: AppTheme.surfaceLight,
                        child: const Icon(Icons.album, color: AppTheme.secondaryColor),
                      ),
                    )
                  : Container(
                      width: width,
                      height: width,
                      color: AppTheme.surfaceLight,
                      child: const Icon(Icons.album, size: 40, color: AppTheme.secondaryColor),
                    ),
            ),
            const SizedBox(height: 8),
            // Title
            Text(
              album.title,
              style: AppTheme.bodyMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            // Info
            Text(
              '${album.trackCount} Songs${album.year != null ? ' • ${album.year}' : ''}',
              style: AppTheme.bodySmall.copyWith(color: AppTheme.secondaryColor),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
