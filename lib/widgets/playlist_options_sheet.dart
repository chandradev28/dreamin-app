import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/theme/app_theme.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../screens/playlist/playlist_detail_screen.dart';

/// Playlist Options Bottom Sheet - Tidal Style
/// Shows when user taps 3-dot menu on any playlist
class PlaylistOptionsSheet extends ConsumerWidget {
  final Playlist playlist;

  const PlaylistOptionsSheet({super.key, required this.playlist});

  static void show(BuildContext context, Playlist playlist) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => PlaylistOptionsSheet(playlist: playlist),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

          // Playlist header
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
                  child: playlist.coverArtUrl != null
                      ? CachedNetworkImage(
                          imageUrl: playlist.coverArtUrl!,
                          fit: BoxFit.cover,
                        )
                      : const Icon(Icons.playlist_play, color: AppTheme.secondaryColor),
                ),
                const SizedBox(width: 12),
                // Playlist info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        playlist.title,
                        style: AppTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'by ${playlist.creatorName ?? 'Unknown'}',
                        style: AppTheme.bodySmall.copyWith(color: AppTheme.secondaryColor),
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
            icon: Icons.play_arrow_rounded,
            label: 'Play',
            onTap: () async {
              Navigator.pop(context);
              try {
                final tidalService = ref.read(tidalServiceProvider);
                final playlistDetail = await tidalService.getPlaylist(playlist.id);
                if (playlistDetail.tracks.isNotEmpty) {
                  ref.read(playerProvider.notifier).playQueue(
                    playlistDetail.tracks,
                    source: 'Playlist: ${playlist.title}',
                  );
                }
              } catch (e) {
                print('Error playing playlist: $e');
              }
            },
          ),

          _OptionTile(
            icon: Icons.shuffle,
            label: 'Shuffle',
            onTap: () async {
              Navigator.pop(context);
              try {
                final tidalService = ref.read(tidalServiceProvider);
                final playlistDetail = await tidalService.getPlaylist(playlist.id);
                if (playlistDetail.tracks.isNotEmpty) {
                  final shuffled = List<Track>.from(playlistDetail.tracks)..shuffle();
                  ref.read(playerProvider.notifier).playQueue(
                    shuffled,
                    source: 'Playlist: ${playlist.title} (Shuffled)',
                  );
                }
              } catch (e) {
                print('Error shuffling playlist: $e');
              }
            },
          ),

          _OptionTile(
            icon: Icons.playlist_add,
            label: 'Add to queue',
            onTap: () async {
              Navigator.pop(context);
              try {
                final tidalService = ref.read(tidalServiceProvider);
                final playlistDetail = await tidalService.getPlaylist(playlist.id);
                for (final track in playlistDetail.tracks) {
                  ref.read(playerProvider.notifier).addToQueue(track);
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Added ${playlistDetail.tracks.length} tracks to queue'),
                    backgroundColor: AppTheme.surfaceLight,
                  ),
                );
              } catch (e) {
                print('Error adding playlist to queue: $e');
              }
            },
          ),

          // Add to collection (toggleable)
          Builder(
            builder: (context) {
              final isSaved = ref.watch(isPlaylistSavedProvider(playlist.id));
              return _OptionTile(
                icon: isSaved ? Icons.check : Icons.add,
                label: isSaved ? 'Remove from collection' : 'Add to collection',
                iconColor: isSaved ? AppTheme.primaryColor : null,
                onTap: () {
                  ref.read(savedPlaylistsProvider.notifier).togglePlaylist(playlist);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isSaved ? 'Removed from collection' : 'Added to collection'),
                      backgroundColor: AppTheme.surfaceLight,
                    ),
                  );
                },
              );
            },
          ),

          _OptionTile(
            icon: Icons.queue_music,
            label: 'View playlist',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PlaylistDetailScreen(playlistId: playlist.id, playlist: playlist),
                ),
              );
            },
          ),

          _OptionTile(
            icon: Icons.share_outlined,
            label: 'Share',
            onTap: () {
              Navigator.pop(context);
              // TODO: Implement share
            },
          ),

          const SizedBox(height: 16),
          // Safe area for bottom padding
          SizedBox(height: MediaQuery.of(context).padding.bottom),
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
    return ListTile(
      leading: Icon(icon, color: iconColor ?? Colors.white, size: 24),
      title: Text(label, style: AppTheme.bodyLarge),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
    );
  }
}
