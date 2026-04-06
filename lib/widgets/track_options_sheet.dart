import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:convert';
import '../core/theme/app_theme.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../screens/album/album_detail_screen.dart';
import '../screens/artist/artist_detail_screen.dart';

/// Track Options Bottom Sheet - Tidal Style
/// Shows when user taps 3-dot menu on any track
class TrackOptionsSheet extends ConsumerWidget {
  final Track track;
  final bool showGoToAlbum;

  const TrackOptionsSheet({
    super.key,
    required this.track,
    this.showGoToAlbum = true,
  });

  static void show(
    BuildContext context,
    Track track, {
    bool showGoToAlbum = true,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => TrackOptionsSheet(
        track: track,
        showGoToAlbum: showGoToAlbum,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favState = ref.watch(favoritesProvider);
    final isFavorite = favState.isFavorite(track);

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Track header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: [
                // Cover art
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: AppTheme.surfaceLight,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: track.coverArtUrl != null
                      ? CachedNetworkImage(
                          imageUrl: track.coverArtUrl!,
                          fit: BoxFit.cover,
                        )
                      : const Icon(Icons.music_note,
                          color: AppTheme.secondaryColor),
                ),
                const SizedBox(width: 12),
                // Track info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        track.title,
                        style: AppTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        track.artist,
                        style: AppTheme.bodySmall
                            .copyWith(color: AppTheme.secondaryColor),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppTheme.surfaceLight),

          // Options
          _OptionTile(
            icon: Icons.queue_play_next,
            label: 'Play next',
            onTap: () {
              ref.read(playerProvider.notifier).addToQueueNext(track);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Playing "${track.title}" next'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),

          _OptionTile(
            icon: Icons.playlist_add,
            label: 'Add to play queue',
            onTap: () {
              ref.read(playerProvider.notifier).addToQueue(track);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Added "${track.title}" to queue'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),

          _OptionTile(
            icon: isFavorite ? Icons.favorite : Icons.favorite_border,
            label:
                isFavorite ? 'Remove from Collection' : 'Add to My Collection',
            iconColor: isFavorite ? AppTheme.primaryColor : null,
            onTap: () {
              ref.read(favoritesProvider.notifier).toggleFavorite(track);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(isFavorite
                      ? 'Removed from Collection'
                      : 'Added to Collection'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),

          _OptionTile(
            icon: Icons.playlist_add_outlined,
            label: 'Add to playlist',
            onTap: () {
              Navigator.pop(context);
              _showAddToPlaylistDialog(context, ref, track);
            },
          ),

          // Download option
          Consumer(
            builder: (context, ref, _) {
              final downloadState = ref.watch(downloadProvider);
              final isDownloaded = downloadState.isDownloaded(track.id);
              final isDownloading =
                  downloadState.isCurrentlyDownloading(track.id);
              final isInQueue = downloadState.isInQueue(track.id);

              String label;
              IconData icon;
              Color? iconColor;

              if (isDownloaded) {
                label = 'Downloaded';
                icon = Icons.download_done_rounded;
                iconColor = AppTheme.primaryColor;
              } else if (isDownloading) {
                label =
                    'Downloading... ${(downloadState.currentProgress * 100).toInt()}%';
                icon = Icons.downloading_rounded;
                iconColor = AppTheme.primaryColor;
              } else if (isInQueue) {
                label = 'Queued for download';
                icon = Icons.hourglass_empty_rounded;
              } else {
                label = 'Download';
                icon = Icons.download_outlined;
              }

              return _OptionTile(
                icon: icon,
                label: label,
                iconColor: iconColor,
                onTap: (isDownloaded || isDownloading || isInQueue)
                    ? () {
                        Navigator.pop(context);
                      }
                    : () {
                        ref.read(downloadProvider.notifier).addToQueue(track);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Downloading "${track.title}"'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
              );
            },
          ),

          if (showGoToAlbum && track.albumId.isNotEmpty)
            _OptionTile(
              icon: Icons.album_outlined,
              label: 'Go to album',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        AlbumDetailScreen(albumId: track.albumId),
                  ),
                );
              },
            ),

          _OptionTile(
            icon: Icons.person_outline,
            label: 'Go to artist',
            onTap: () {
              Navigator.pop(context);
              // Check if artistId is a valid numeric ID (TIDAL IDs are numeric)
              final hasValidId = track.artistId.isNotEmpty &&
                  int.tryParse(track.artistId) != null;

              if (hasValidId) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ArtistDetailScreen(
                      artistId: track.artistId,
                    ),
                  ),
                );
              } else {
                // Show message if artist not available
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Artist page not available for this track'),
                    backgroundColor: AppTheme.surfaceLight,
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
          ),

          // Bottom safe area
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }

  void _showAddToPlaylistDialog(
      BuildContext context, WidgetRef ref, Track track) {
    final database = ref.read(databaseProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      builder: (context) => FutureBuilder(
        future: database.getAllPlaylists(),
        builder: (context, snapshot) {
          final playlists = snapshot.data ?? [];

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Add to playlist', style: AppTheme.titleLarge),
              ),
              if (playlists.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('No playlists yet',
                      style: AppTheme.bodyMedium
                          .copyWith(color: AppTheme.secondaryColor)),
                )
              else
                ...playlists.map((playlist) => ListTile(
                      leading: const Icon(Icons.playlist_play,
                          color: AppTheme.secondaryColor),
                      title: Text(playlist.name),
                      onTap: () async {
                        await database.addTrackToPlaylist(
                          playlistId: playlist.id,
                          trackId: track.id,
                          source: track.source.index,
                          trackJson: jsonEncode(track.toJson()),
                        );
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Added to "${playlist.name}"')),
                          );
                        }
                      },
                    )),
              // Create new playlist option
              ListTile(
                leading: const Icon(Icons.add, color: AppTheme.primaryColor),
                title: Text('Create new playlist',
                    style: TextStyle(color: AppTheme.primaryColor)),
                onTap: () {
                  Navigator.pop(context);
                  _showCreatePlaylistDialog(context, ref, track);
                },
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
            ],
          );
        },
      ),
    );
  }

  void _showCreatePlaylistDialog(
      BuildContext context, WidgetRef ref, Track track) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text('Create Playlist'),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: AppTheme.bodyLarge,
          decoration: const InputDecoration(hintText: 'Playlist name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                final database = ref.read(databaseProvider);
                final playlistId =
                    await database.createPlaylist(controller.text);
                await database.addTrackToPlaylist(
                  playlistId: playlistId,
                  trackId: track.id,
                  source: track.source.index,
                  trackJson: jsonEncode(track.toJson()),
                );
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            'Created "${controller.text}" and added track')),
                  );
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;

  const _OptionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: iconColor ?? Colors.white, size: 24),
            const SizedBox(width: 16),
            Text(label, style: AppTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}
