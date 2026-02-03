import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import '../../widgets/track_options_sheet.dart';
import '../album/album_detail_screen.dart';
import '../playlist/playlist_detail_screen.dart';
import 'see_all_screen.dart';

/// Home Screen - Source-Aware Homepage
/// TIDAL: Songs of the Year, Playlists, Albums
/// Qobuz: Hi-Res Focus, Genre Collections, New Releases
/// Subsonic: Personal Library Content
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeData = ref.watch(homeDataProvider);
    final responsive = Responsive(context);
    final sourceTheme = ref.watch(sourceThemeProvider);
    final activeSource = ref.watch(sourceSelectionProvider).activeSource;
    final isQobuz = activeSource == ActiveSource.qobuz;
    final isSubsonic = activeSource == ActiveSource.subsonic;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: sourceTheme.gradient,
        ),
        child: RefreshIndicator(
          onRefresh: () => ref.read(homeDataProvider.notifier).refresh(),
          color: AppTheme.primaryColor,
          backgroundColor: sourceTheme.surface,
          child: CustomScrollView(
            slivers: [
              // App Bar
              SliverAppBar(
                floating: true,
                backgroundColor: Colors.transparent,
                toolbarHeight: responsive.value(mobile: 56.0, tablet: 64.0),
                title: Text(
                  'Home',
                  style: responsive.value(
                    mobile: AppTheme.headlineMedium,
                    tablet: AppTheme.headlineLarge,
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.cast_outlined),
                    onPressed: () {},
                  ),
                  SizedBox(width: responsive.value(mobile: 8.0, tablet: 16.0)),
                ],
              ),

              // Content
              if (homeData.isLoading)
                SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: sourceTheme.accent,
                    ),
                  ),
                )
              else if (homeData.error != null)
                SliverFillRemaining(
                  child: _ErrorWidget(
                    message: homeData.error!,
                    onRetry: () => ref.read(homeDataProvider.notifier).refresh(),
                  ),
                )
            else ...[
              // DEBUG BANNER - shows what data we have
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: homeData.error != null ? Colors.red.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: homeData.error != null ? Colors.red : Colors.orange),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DEBUG: Source=${activeSource.name} | '
                        'Albums=${homeData.newAlbums.length} | '
                        'Tracks=${homeData.trendingTracks.length} | '
                        'Jazz=${homeData.jazzAlbums.length}',
                        style: TextStyle(fontSize: 11, color: homeData.error != null ? Colors.red : Colors.orange),
                      ),
                      if (homeData.error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'ERROR: ${homeData.error!.length > 200 ? homeData.error!.substring(0, 200) : homeData.error}',
                            style: const TextStyle(fontSize: 10, color: Colors.red),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              // ============================================================
              // SECTION 1: SONGS OF THE YEAR (TIDAL only - Qobuz has no playlists)
              // ============================================================
              if (!isQobuz && homeData.songsOfTheYear.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: _TidalSectionHeader(
                    title: 'Songs of the Year',
                    onSeeAll: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => SeeAllScreen(
                        title: 'Songs of the Year',
                        searchQuery: 'songs of the year',
                        type: SeeAllType.playlist,
                        initialItems: homeData.songsOfTheYear,
                      ),
                    )),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: responsive.value(mobile: 220.0, tablet: 280.0),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(horizontal: responsive.horizontalPadding),
                      itemCount: homeData.songsOfTheYear.length.clamp(0, 10),
                      itemBuilder: (context, index) {
                        final playlist = homeData.songsOfTheYear[index];
                        // Extract year from title (e.g., "2000! Songs of the Year" -> "2000")
                        final yearMatch = RegExp(r'^(\d{4})').firstMatch(playlist.title);
                        final year = yearMatch?.group(1) ?? '';
                        return _SongsOfTheYearCard(
                          playlist: playlist,
                          year: year,
                          width: responsive.value(mobile: 160.0, tablet: 200.0),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => PlaylistDetailScreen(
                                  playlistId: playlist.id,
                                  playlist: playlist,
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

              // ============================================================
              // SECTION 2: TRENDING/POPULAR TRACKS (Bento Box)
              // ============================================================
              if (homeData.trendingTracks.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      responsive.horizontalPadding,
                      responsive.sectionSpacing,
                      responsive.horizontalPadding,
                      0,
                    ),
                    child: _RecommendedTracksBentoBox(
                      tracks: homeData.trendingTracks.take(5).toList(),
                      onTrackTap: (track, index) {
                        ref.read(playerProvider.notifier).playQueue(
                          homeData.trendingTracks,
                          startIndex: index,
                        );
                      },
                      onSeeAll: () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => SeeAllScreen(
                          title: 'Recommended new tracks',
                          searchQuery: 'trending ${DateTime.now().year}',
                          type: SeeAllType.track,
                          initialItems: homeData.trendingTracks,
                        ),
                      )),
                    ),
                  ),
                ),
              ],

              // ============================================================
              // SECTION 3: POPULAR PLAYLISTS (TIDAL only - Qobuz has no playlists)
              // ============================================================
              if (!isQobuz && homeData.popularPlaylists.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: _TidalSectionHeader(
                    title: 'Popular playlists on TIDAL',
                    onSeeAll: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => SeeAllScreen(
                        title: 'Popular playlists on TIDAL',
                        searchQuery: 'top hits',
                        type: SeeAllType.playlist,
                        initialItems: homeData.popularPlaylists,
                      ),
                    )),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: responsive.value(mobile: 200.0, tablet: 260.0),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(horizontal: responsive.horizontalPadding),
                      itemCount: homeData.popularPlaylists.length.clamp(0, 10),
                      itemBuilder: (context, index) {
                        final playlist = homeData.popularPlaylists[index];
                        return _PlaylistCard(
                          playlist: playlist,
                          width: responsive.value(mobile: 150.0, tablet: 180.0),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => PlaylistDetailScreen(
                                  playlistId: playlist.id,
                                  playlist: playlist,
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

              // ============================================================
              // SECTION 4: FEATURED/SUGGESTED NEW ALBUMS
              // ============================================================
              if (homeData.newAlbums.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: _TidalSectionHeader(
                    title: isQobuz ? 'Featured Albums' : 'Suggested new albums for you',
                    onSeeAll: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => SeeAllScreen(
                        title: isQobuz ? 'Featured Albums' : 'Suggested new albums for you',
                        searchQuery: isQobuz ? 'pop' : 'new album ${DateTime.now().year}',
                        type: SeeAllType.album,
                        initialItems: homeData.newAlbums,
                      ),
                    )),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: responsive.value(mobile: 220.0, tablet: 280.0),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(horizontal: responsive.horizontalPadding),
                      itemCount: homeData.newAlbums.length.clamp(0, 10),
                      itemBuilder: (context, index) {
                        final album = homeData.newAlbums[index];
                        return _AlbumCard(
                          album: album,
                          width: responsive.value(mobile: 150.0, tablet: 180.0),
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

              // ============================================================
              // SECTION 5: NEW RELEASES / ALBUMS YOU'LL ENJOY
              // ============================================================
              if (homeData.albumsYouLlEnjoy.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: _TidalSectionHeader(
                    title: isQobuz ? 'New Releases' : "Albums you'll enjoy",
                    onSeeAll: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => SeeAllScreen(
                        title: isQobuz ? 'New Releases' : "Albums you'll enjoy",
                        searchQuery: isQobuz ? 'new' : 'best albums',
                        type: SeeAllType.album,
                        initialItems: homeData.albumsYouLlEnjoy,
                      ),
                    )),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: responsive.value(mobile: 220.0, tablet: 280.0),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(horizontal: responsive.horizontalPadding),
                      itemCount: homeData.albumsYouLlEnjoy.length.clamp(0, 10),
                      itemBuilder: (context, index) {
                        final album = homeData.albumsYouLlEnjoy[index];
                        return _AlbumCard(
                          album: album,
                          width: responsive.value(mobile: 150.0, tablet: 180.0),
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

              // ============================================================
              // SECTION 6: JAZZ COLLECTION (Qobuz only)
              // ============================================================
              if (isQobuz && homeData.jazzAlbums.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: _TidalSectionHeader(
                    title: 'Jazz Collection',
                    onSeeAll: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => SeeAllScreen(
                        title: 'Jazz Collection',
                        searchQuery: 'jazz',
                        type: SeeAllType.album,
                        initialItems: homeData.jazzAlbums,
                      ),
                    )),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: responsive.value(mobile: 220.0, tablet: 280.0),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(horizontal: responsive.horizontalPadding),
                      itemCount: homeData.jazzAlbums.length.clamp(0, 10),
                      itemBuilder: (context, index) {
                        final album = homeData.jazzAlbums[index];
                        return _AlbumCard(
                          album: album,
                          width: responsive.value(mobile: 150.0, tablet: 180.0),
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

              // ============================================================
              // SECTION 7: CLASSICAL PICKS (Qobuz only)
              // ============================================================
              if (isQobuz && homeData.classicalAlbums.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: _TidalSectionHeader(
                    title: 'Classical Picks',
                    onSeeAll: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => SeeAllScreen(
                        title: 'Classical Picks',
                        searchQuery: 'classical',
                        type: SeeAllType.album,
                        initialItems: homeData.classicalAlbums,
                      ),
                    )),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: responsive.value(mobile: 220.0, tablet: 280.0),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(horizontal: responsive.horizontalPadding),
                      itemCount: homeData.classicalAlbums.length.clamp(0, 10),
                      itemBuilder: (context, index) {
                        final album = homeData.classicalAlbums[index];
                        return _AlbumCard(
                          album: album,
                          width: responsive.value(mobile: 150.0, tablet: 180.0),
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

              // ============================================================
              // SECTION 8: ROCK ESSENTIALS (Qobuz only)
              // ============================================================
              if (isQobuz && homeData.rockAlbums.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: _TidalSectionHeader(
                    title: 'Rock Essentials',
                    onSeeAll: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => SeeAllScreen(
                        title: 'Rock Essentials',
                        searchQuery: 'rock',
                        type: SeeAllType.album,
                        initialItems: homeData.rockAlbums,
                      ),
                    )),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: responsive.value(mobile: 220.0, tablet: 280.0),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(horizontal: responsive.horizontalPadding),
                      itemCount: homeData.rockAlbums.length.clamp(0, 10),
                      itemBuilder: (context, index) {
                        final album = homeData.rockAlbums[index];
                        return _AlbumCard(
                          album: album,
                          width: responsive.value(mobile: 150.0, tablet: 180.0),
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

              // Bottom spacing for mini player (minimal)
              SliverToBoxAdapter(
                child: SizedBox(
                  height: responsive.miniPlayerHeight + 16,
                ),
              ),
            ],
          ],
        ),
      ),
      ),
    );
  }
}

// ============================================================================
// TIDAL-STYLE WIDGETS
// ============================================================================

/// TIDAL Section Header with arrow button
class _TidalSectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;

  const _TidalSectionHeader({
    required this.title,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        responsive.horizontalPadding,
        responsive.sectionSpacing,
        responsive.horizontalPadding,
        12,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: AppTheme.titleLarge.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (onSeeAll != null)
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.surfaceLight,
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_forward, size: 18),
                onPressed: onSeeAll,
                color: Colors.white,
                padding: EdgeInsets.zero,
              ),
            ),
        ],
      ),
    );
  }
}

/// Songs of the Year card (large with year number overlay)
class _SongsOfTheYearCard extends StatelessWidget {
  final Playlist playlist;
  final String year;
  final double width;
  final VoidCallback onTap;

  const _SongsOfTheYearCard({
    required this.playlist,
    required this.year,
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
            // Card with year overlay
            Container(
              width: width,
              height: width,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
                color: AppTheme.surfaceColor,
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  // Cover image
                  if (playlist.coverArtUrl != null)
                    CachedNetworkImage(
                      imageUrl: playlist.coverArtUrl!,
                      width: width,
                      height: width,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: AppTheme.surfaceLight,
                        child: const Center(child: Icon(Icons.queue_music, size: 40)),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: AppTheme.surfaceLight,
                        child: const Center(child: Icon(Icons.queue_music, size: 40)),
                      ),
                    )
                  else
                    Container(
                      color: AppTheme.surfaceLight,
                      child: const Center(child: Icon(Icons.queue_music, size: 40)),
                    ),
                  // Year overlay (top left)
                  if (year.isNotEmpty)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            year,
                            style: AppTheme.headlineLarge.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.7),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                          ),
                          Text(
                            'Songs of the Year',
                            style: AppTheme.labelSmall.copyWith(
                              color: Colors.white.withOpacity(0.9),
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.7),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  // TIDAL badge (top right)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(
                        Icons.music_note,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Title
            Text(
              playlist.title,
              style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              'by TIDAL',
              style: AppTheme.bodySmall.copyWith(color: AppTheme.secondaryColor),
            ),
          ],
        ),
      ),
    );
  }
}

/// Recommended Tracks Bento Box (TIDAL style with gradient)
class _RecommendedTracksBentoBox extends StatelessWidget {
  final List<Track> tracks;
  final void Function(Track track, int index) onTrackTap;
  final VoidCallback? onSeeAll;

  const _RecommendedTracksBentoBox({
    required this.tracks,
    required this.onTrackTap,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFD4A574), // Gold/tan color like TIDAL
            const Color(0xFF8B7355),
            AppTheme.surfaceColor,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Text(
                  'Recommended new tracks',
                  style: AppTheme.titleLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              if (onSeeAll != null)
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.2),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_forward, size: 18),
                    onPressed: onSeeAll,
                    color: Colors.white,
                    padding: EdgeInsets.zero,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          // Track list
          ...tracks.asMap().entries.map((entry) {
            final index = entry.key;
            final track = entry.value;
            return _BentoTrackTile(
              track: track,
              onTap: () => onTrackTap(track, index),
            );
          }),
        ],
      ),
    );
  }
}

/// Track tile for bento box
class _BentoTrackTile extends StatelessWidget {
  final Track track;
  final VoidCallback onTap;

  const _BentoTrackTile({
    required this.track,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            // Album art
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: track.coverArtUrl != null
                  ? CachedNetworkImage(
                      imageUrl: track.coverArtUrl!,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        width: 48,
                        height: 48,
                        color: AppTheme.surfaceLight,
                      ),
                      errorWidget: (_, __, ___) => Container(
                        width: 48,
                        height: 48,
                        color: AppTheme.surfaceLight,
                        child: const Icon(Icons.music_note, size: 24),
                      ),
                    )
                  : Container(
                      width: 48,
                      height: 48,
                      color: AppTheme.surfaceLight,
                      child: const Icon(Icons.music_note, size: 24),
                    ),
            ),
            const SizedBox(width: 12),
            // Track info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          track.title,
                          style: AppTheme.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (track.isExplicit) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: const Text(
                            'E',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    track.artist,
                    style: AppTheme.bodySmall.copyWith(
                      color: Colors.white.withOpacity(0.7),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // More button
            IconButton(
              icon: const Icon(Icons.more_horiz),
              onPressed: () => TrackOptionsSheet.show(context, track),
              color: Colors.white.withOpacity(0.7),
            ),
          ],
        ),
      ),
    );
  }
}

/// Playlist Card
class _PlaylistCard extends StatelessWidget {
  final Playlist playlist;
  final double width;
  final VoidCallback onTap;

  const _PlaylistCard({
    required this.playlist,
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
            // Cover
            Container(
              width: width,
              height: width,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
                color: AppTheme.surfaceColor,
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  if (playlist.coverArtUrl != null)
                    CachedNetworkImage(
                      imageUrl: playlist.coverArtUrl!,
                      width: width,
                      height: width,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: AppTheme.surfaceLight,
                        child: const Center(child: Icon(Icons.queue_music, size: 40)),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: AppTheme.surfaceLight,
                        child: const Center(child: Icon(Icons.queue_music, size: 40)),
                      ),
                    )
                  else
                    Container(
                      color: AppTheme.surfaceLight,
                      child: const Center(child: Icon(Icons.queue_music, size: 40)),
                    ),
                  // TIDAL badge
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(
                        Icons.music_note,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Title
            Text(
              playlist.title,
              style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              'by TIDAL',
              style: AppTheme.bodySmall.copyWith(color: AppTheme.secondaryColor),
            ),
          ],
        ),
      ),
    );
  }
}

/// Album Card
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
            // Cover
            Container(
              width: width,
              height: width,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
                color: AppTheme.surfaceColor,
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  if (album.coverArtUrl != null)
                    CachedNetworkImage(
                      imageUrl: album.coverArtUrl!,
                      width: width,
                      height: width,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: AppTheme.surfaceLight,
                        child: const Center(child: Icon(Icons.album, size: 40)),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: AppTheme.surfaceLight,
                        child: const Center(child: Icon(Icons.album, size: 40)),
                      ),
                    )
                  else
                    Container(
                      color: AppTheme.surfaceLight,
                      child: const Center(child: Icon(Icons.album, size: 40)),
                    ),
                  // Explicit badge if applicable
                  if (album.isExplicit)
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: const Text(
                          'E',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Title
            Text(
              album.title,
              style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              album.artist,
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

/// Error Widget
class _ErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorWidget({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppTheme.errorColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: AppTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.secondaryColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
