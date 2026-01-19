import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import '../../widgets/track_options_sheet.dart';
import '../album/album_detail_screen.dart';
import '../album/view_all_screen.dart';
import '../scaffold_with_mini_player.dart';
import 'top_tracks_view_all_screen.dart';

/// Artist Detail Screen - TIDAL Style Design
/// Sections: Header, Top Tracks (30), Albums, EP & Singles, Live Albums, Playlists
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
    final responsive = Responsive(context);
    final artistDetail = ref.watch(artistDetailProvider(artistId));

    return ScaffoldWithMiniPlayer(
      body: artistDetail.when(
        loading: () => _buildLoadingState(context, responsive),
        error: (error, _) => _buildErrorState(context, error.toString(), responsive),
        data: (data) {
          if (data == null) {
            return _buildErrorState(context, 'Artist not found', responsive);
          }
          return _buildContent(context, ref, data, responsive);
        },
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context, Responsive responsive) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryColor),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error, Responsive responsive) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppTheme.secondaryColor, size: 48),
            const SizedBox(height: 16),
            Text('Failed to load artist', style: AppTheme.titleMedium.copyWith(color: Colors.white)),
            const SizedBox(height: 8),
            Text(error, style: AppTheme.bodySmall.copyWith(color: AppTheme.secondaryColor), textAlign: TextAlign.center),
          ],
        ),
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
    final screenWidth = MediaQuery.of(context).size.width;
    final imageSize = screenWidth * 0.45;

    // Filter albums by type (excluding compilations as per user request)
    final albums = artistDetail.albums.where((a) => a.albumType == AlbumType.album).toList();
    final epsSingles = artistDetail.albums.where((a) => 
        a.albumType == AlbumType.ep || a.albumType == AlbumType.single).toList();
    final liveAlbums = artistDetail.albums.where((a) => a.albumType == AlbumType.live).toList();

    // Top 30 tracks
    final topTracks = artistDetail.topTracks.take(30).toList();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            backgroundColor: AppTheme.backgroundColor,
            elevation: 0,
            pinned: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.search, color: Colors.white),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onPressed: () {},
              ),
            ],
          ),

          // ==================== HEADER SECTION ====================
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: responsive.horizontalPadding),
              child: Column(
                children: [
                  // Circular Artist Image
                  Container(
                    width: imageSize,
                    height: imageSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
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
                              placeholder: (_, __) => _buildAvatarPlaceholder(artistDetail.name),
                              errorWidget: (_, __, ___) => _buildAvatarPlaceholder(artistDetail.name),
                            )
                          : _buildAvatarPlaceholder(artistDetail.name),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Artist Name
                  Text(
                    artistDetail.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 8),

                  // Fans count placeholder (API may not provide this)
                  Text(
                    '${artistDetail.albumCount ?? artistDetail.albums.length} albums',
                    style: const TextStyle(
                      color: AppTheme.secondaryColor,
                      fontSize: 14,
                    ),
                  ),

                  // Bio (if available)
                  if (artistDetail.bio != null && artistDetail.bio!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        artistDetail.bio!,
                        style: TextStyle(
                          color: AppTheme.secondaryColor.withOpacity(0.8),
                          fontSize: 13,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Play / Shuffle Buttons (Tidal Style)
                  Row(
                    children: [
                      // Play Button (Outlined)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: topTracks.isNotEmpty
                              ? () {
                                  ref.read(playerProvider.notifier).playQueue(
                                    topTracks,
                                    startIndex: 0,
                                    source: 'Artist: ${artistDetail.name}',
                                  );
                                }
                              : null,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white, width: 1),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.play_arrow, size: 22),
                              SizedBox(width: 6),
                              Text('Play', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Shuffle Button (Filled)
                      Expanded(
                        child: ElevatedButton(
                          onPressed: topTracks.isNotEmpty
                              ? () {
                                  final shuffled = List<Track>.from(topTracks)..shuffle();
                                  ref.read(playerProvider.notifier).playQueue(
                                    shuffled,
                                    startIndex: 0,
                                    source: 'Artist: ${artistDetail.name} (Shuffled)',
                                  );
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.shuffle, size: 20),
                              SizedBox(width: 6),
                              Text('Shuffle', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Action Icons Row (Radio, Follow, Share)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _ActionIconButton(
                        icon: Icons.radio,
                        label: 'Radio',
                        onTap: () {},
                      ),
                      const SizedBox(width: 48),
                      _ActionIconButton(
                        icon: Icons.add,
                        label: 'Follow',
                        onTap: () {},
                      ),
                      const SizedBox(width: 48),
                      _ActionIconButton(
                        icon: Icons.share_outlined,
                        label: 'Share',
                        onTap: () {},
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),

          // ==================== TOP TRACKS SECTION ====================
          if (topTracks.isNotEmpty) ...[
            _buildSectionHeader(
              context,
              'Top Tracks',
              onSeeAll: topTracks.length > 5
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TopTracksViewAllScreen(
                            title: 'Top Tracks',
                            artistName: artistDetail.name,
                            tracks: topTracks,
                          ),
                        ),
                      );
                    }
                  : null,
            ),

            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final track = topTracks[index];
                  final isPlaying = playerState.currentTrack?.id == track.id;

                  return _TrackTile(
                    track: track,
                    index: index + 1,
                    isPlaying: isPlaying,
                    onTap: () {
                      ref.read(playerProvider.notifier).playQueue(
                        topTracks,
                        startIndex: index,
                        source: 'Artist: ${artistDetail.name}',
                      );
                    },
                    onMoreTap: () {
                      TrackOptionsSheet.show(context, track);
                    },
                  );
                },
                childCount: topTracks.length.clamp(0, 5), // Show only 5, See All for more
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],

          // ==================== ALBUMS SECTION ====================
          if (albums.isNotEmpty) ...[
            _buildSectionHeader(
              context,
              'Albums',
              onSeeAll: albums.length > 4
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ViewAllScreen(
                            title: 'Albums by ${artistDetail.name}',
                            albums: albums,
                          ),
                        ),
                      );
                    }
                  : null,
            ),

            SliverToBoxAdapter(
              child: SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: albums.length.clamp(0, 10),
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: _AlbumCard(
                        album: albums[index],
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AlbumDetailScreen(albumId: albums[index].id),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],

          // ==================== EP & SINGLES SECTION ====================
          if (epsSingles.isNotEmpty) ...[
            _buildSectionHeader(
              context,
              'EP & Singles',
              onSeeAll: epsSingles.length > 4
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ViewAllScreen(
                            title: 'EPs & Singles by ${artistDetail.name}',
                            albums: epsSingles,
                          ),
                        ),
                      );
                    }
                  : null,
            ),

            SliverToBoxAdapter(
              child: SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: epsSingles.length.clamp(0, 10),
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: _AlbumCard(
                        album: epsSingles[index],
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AlbumDetailScreen(albumId: epsSingles[index].id),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],

          // ==================== LIVE ALBUMS SECTION ====================
          if (liveAlbums.isNotEmpty) ...[
            _buildSectionHeader(
              context,
              'Live Albums',
              onSeeAll: liveAlbums.length > 4
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ViewAllScreen(
                            title: 'Live Albums by ${artistDetail.name}',
                            albums: liveAlbums,
                          ),
                        ),
                      );
                    }
                  : null,
            ),

            SliverToBoxAdapter(
              child: SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: liveAlbums.length.clamp(0, 10),
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: _AlbumCard(
                        album: liveAlbums[index],
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AlbumDetailScreen(albumId: liveAlbums[index].id),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],

          // ==================== PLAYLISTS SECTION ====================
          // Note: This would require fetching artist-related playlists
          // Placeholder for now - can be implemented when API supports it
          // SliverToBoxAdapter(child: _buildPlaylistsSection(artistDetail)),

          // Bottom Spacing
          SliverToBoxAdapter(
            child: SizedBox(height: responsive.miniPlayerHeight + responsive.bottomNavHeight + 20),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarPlaceholder(String name) {
    return Container(
      color: AppTheme.surfaceLight,
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(
            color: AppTheme.primaryColor,
            fontSize: 60,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildSectionHeader(
    BuildContext context,
    String title, {
    VoidCallback? onSeeAll,
  }) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (onSeeAll != null)
              GestureDetector(
                onTap: onSeeAll,
                child: Row(
                  children: const [
                    Icon(Icons.chevron_right, color: AppTheme.secondaryColor, size: 24),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// WIDGETS
// ============================================================================

/// Action Icon Button (Radio, Follow, Share)
class _ActionIconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionIconButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 26),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

/// Track Tile for Top Tracks list
class _TrackTile extends StatelessWidget {
  final Track track;
  final int index;
  final bool isPlaying;
  final VoidCallback onTap;
  final VoidCallback onMoreTap;

  const _TrackTile({
    required this.track,
    required this.index,
    required this.isPlaying,
    required this.onTap,
    required this.onMoreTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: ClipRRect(
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
                    child: const Icon(Icons.music_note, color: AppTheme.secondaryColor, size: 20),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    color: AppTheme.surfaceColor,
                    child: const Icon(Icons.music_note, color: AppTheme.secondaryColor, size: 20),
                  ),
                )
              : Container(
                  color: AppTheme.surfaceColor,
                  child: const Icon(Icons.music_note, color: AppTheme.secondaryColor, size: 20),
                ),
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              track.title,
              style: TextStyle(
                color: isPlaying ? AppTheme.primaryColor : Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (track.isExplicit)
            Container(
              margin: const EdgeInsets.only(left: 6),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.grey.shade700,
                borderRadius: BorderRadius.circular(2),
              ),
              child: const Text(
                'E',
                style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      subtitle: Text(
        track.artist,
        style: const TextStyle(color: AppTheme.secondaryColor, fontSize: 13),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: GestureDetector(
        onTap: onMoreTap,
        child: const Padding(
          padding: EdgeInsets.all(8),
          child: Icon(Icons.more_vert, color: AppTheme.secondaryColor, size: 22),
        ),
      ),
    );
  }
}

/// Album Card for horizontal scroll
class _AlbumCard extends StatelessWidget {
  final Album album;
  final VoidCallback onTap;

  const _AlbumCard({
    required this.album,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 140,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Album Cover
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: AppTheme.surfaceColor,
              ),
              clipBehavior: Clip.antiAlias,
              child: album.coverArtUrl != null
                  ? CachedNetworkImage(
                      imageUrl: album.coverArtUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => const Center(
                        child: Icon(Icons.album, color: AppTheme.secondaryColor, size: 40),
                      ),
                      errorWidget: (_, __, ___) => const Center(
                        child: Icon(Icons.album, color: AppTheme.secondaryColor, size: 40),
                      ),
                    )
                  : const Center(
                      child: Icon(Icons.album, color: AppTheme.secondaryColor, size: 40),
                    ),
            ),

            const SizedBox(height: 8),

            // Album Title
            Text(
              album.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 2),

            // Artist Name
            Text(
              album.artist,
              style: const TextStyle(
                color: AppTheme.secondaryColor,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
