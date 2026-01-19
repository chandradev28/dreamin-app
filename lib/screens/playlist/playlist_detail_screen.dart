import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import '../../widgets/track_options_sheet.dart';
import '../scaffold_with_mini_player.dart';

/// Playlist Detail Screen - TIDAL Style Design
/// Centered cover art, action icons, proper button styling
class PlaylistDetailScreen extends ConsumerWidget {
  final String playlistId;
  final Playlist? playlist;

  const PlaylistDetailScreen({
    super.key,
    required this.playlistId,
    this.playlist,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final responsive = Responsive(context);
    final playlistDetail = ref.watch(playlistDetailProvider(playlistId));

    return ScaffoldWithMiniPlayer(
      body: playlistDetail.when(
        loading: () => _buildLoadingState(context, responsive),
        error: (error, _) => _buildErrorState(context, error.toString(), responsive),
        data: (data) {
          if (data == null) {
            return _buildErrorState(context, 'Playlist not found', responsive);
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
            Text(
              'Failed to load playlist',
              style: AppTheme.titleMedium.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: AppTheme.bodySmall.copyWith(color: AppTheme.secondaryColor),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    PlaylistDetail playlistDetail,
    Responsive responsive,
  ) {
    final playerState = ref.watch(playerProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final coverSize = screenWidth * 0.55; // 55% of screen width like Tidal

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
                icon: const Icon(Icons.sort, color: Colors.white),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onPressed: () {},
              ),
            ],
          ),

          // Header Content (Centered Cover + Info)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: responsive.horizontalPadding),
              child: Column(
                children: [
                  const SizedBox(height: 8),

                  // Centered Cover Art with Shadow
                  Container(
                    width: coverSize,
                    height: coverSize,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: playlistDetail.coverArtUrl != null
                          ? CachedNetworkImage(
                              imageUrl: playlistDetail.coverArtUrl!,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(
                                color: AppTheme.surfaceColor,
                                child: const Icon(Icons.playlist_play, size: 60, color: AppTheme.secondaryColor),
                              ),
                              errorWidget: (_, __, ___) => Container(
                                color: AppTheme.surfaceColor,
                                child: const Icon(Icons.playlist_play, size: 60, color: AppTheme.secondaryColor),
                              ),
                            )
                          : Container(
                              color: AppTheme.surfaceColor,
                              child: const Icon(Icons.playlist_play, size: 60, color: AppTheme.secondaryColor),
                            ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Playlist Title (Centered)
                  Text(
                    playlistDetail.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 8),

                  // Creator Name with Chevron (Tidal Style)
                  if (playlistDetail.creatorName != null)
                    GestureDetector(
                      onTap: () {
                        // TODO: Navigate to creator profile
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'by ${playlistDetail.creatorName}',
                            style: const TextStyle(
                              color: AppTheme.secondaryColor,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.chevron_right,
                            color: AppTheme.secondaryColor,
                            size: 18,
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 12),

                  // Description (if available)
                  if (playlistDetail.description != null && playlistDetail.description!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        playlistDetail.description!,
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

                  const SizedBox(height: 12),

                  // Stats Row (UPPERCASE like Tidal)
                  Text(
                    _buildStatsText(playlistDetail),
                    style: const TextStyle(
                      color: AppTheme.secondaryColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Play / Shuffle Buttons (Tidal Style)
                  Row(
                    children: [
                      // Play Button (Outlined)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: playlistDetail.tracks.isNotEmpty
                              ? () {
                                  ref.read(playerProvider.notifier).playQueue(
                                    playlistDetail.tracks,
                                    startIndex: 0,
                                    source: 'Playlist: ${playlistDetail.title}',
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
                              Text(
                                'Play',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Shuffle Button (Filled)
                      Expanded(
                        child: ElevatedButton(
                          onPressed: playlistDetail.tracks.isNotEmpty
                              ? () {
                                  final shuffled = List<Track>.from(playlistDetail.tracks)..shuffle();
                                  ref.read(playerProvider.notifier).playQueue(
                                    shuffled,
                                    startIndex: 0,
                                    source: 'Playlist: ${playlistDetail.title} (Shuffled)',
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
                              Text(
                                'Shuffle',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Action Icons Row (Add, Download, Share)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _ActionIconButton(
                        icon: Icons.favorite_border,
                        label: 'Add',
                        onTap: () {
                          // TODO: Add to favorites
                        },
                      ),
                      const SizedBox(width: 48),
                      _ActionIconButton(
                        icon: Icons.download_outlined,
                        label: 'Download',
                        onTap: () {
                          // TODO: Download playlist
                        },
                      ),
                      const SizedBox(width: 48),
                      _ActionIconButton(
                        icon: Icons.share_outlined,
                        label: 'Share',
                        onTap: () {
                          // TODO: Share playlist
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Track List
          if (playlistDetail.tracks.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: Text(
                  'No tracks in this playlist',
                  style: TextStyle(color: AppTheme.secondaryColor),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final track = playlistDetail.tracks[index];
                  final isPlaying = playerState.currentTrack?.id == track.id;

                  return _PlaylistTrackTile(
                    track: track,
                    isPlaying: isPlaying,
                    onTap: () {
                      ref.read(playerProvider.notifier).playQueue(
                        playlistDetail.tracks,
                        startIndex: index,
                        source: 'Playlist: ${playlistDetail.title}',
                      );
                    },
                    onMoreTap: () {
                      TrackOptionsSheet.show(context, track);
                    },
                  );
                },
                childCount: playlistDetail.tracks.length,
              ),
            ),

          // Bottom Spacing
          SliverToBoxAdapter(
            child: SizedBox(height: responsive.miniPlayerHeight + responsive.bottomNavHeight + 20),
          ),
        ],
      ),
    );
  }

  String _buildStatsText(PlaylistDetail playlist) {
    final trackCount = playlist.trackCount;
    final duration = playlist.formattedDuration;
    
    String statsText = '$trackCount TRACKS';
    if (duration.isNotEmpty) {
      statsText += ' (${duration.toUpperCase()})';
    }
    
    return statsText;
  }
}

/// Action Icon Button (Add, Download, Share)
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
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

/// Playlist Track Tile - Tidal Style
class _PlaylistTrackTile extends StatelessWidget {
  final Track track;
  final bool isPlaying;
  final VoidCallback onTap;
  final VoidCallback onMoreTap;

  const _PlaylistTrackTile({
    required this.track,
    required this.isPlaying,
    required this.onTap,
    required this.onMoreTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: SizedBox(
          width: 50,
          height: 50,
          child: track.coverArtUrl != null
              ? CachedNetworkImage(
                  imageUrl: track.coverArtUrl!,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    color: AppTheme.surfaceColor,
                    child: const Icon(Icons.music_note, color: AppTheme.secondaryColor, size: 24),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    color: AppTheme.surfaceColor,
                    child: const Icon(Icons.music_note, color: AppTheme.secondaryColor, size: 24),
                  ),
                )
              : Container(
                  color: AppTheme.surfaceColor,
                  child: const Icon(Icons.music_note, color: AppTheme.secondaryColor, size: 24),
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
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      subtitle: Text(
        track.artist,
        style: const TextStyle(
          color: AppTheme.secondaryColor,
          fontSize: 13,
        ),
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
