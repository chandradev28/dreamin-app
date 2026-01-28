import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/theme/app_theme.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../screens/album/album_detail_screen.dart';
import '../screens/artist/artist_detail_screen.dart';

/// Album Options Bottom Sheet - Tidal Style
/// Shows when user taps 3-dot menu on any album
class AlbumOptionsSheet extends ConsumerWidget {
  final Album album;

  const AlbumOptionsSheet({super.key, required this.album});

  static void show(BuildContext context, Album album) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => AlbumOptionsSheet(album: album),
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

          // Album header
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
                  child: album.coverArtUrl != null
                      ? CachedNetworkImage(
                          imageUrl: album.coverArtUrl!,
                          fit: BoxFit.cover,
                        )
                      : const Icon(Icons.album, color: AppTheme.secondaryColor),
                ),
                const SizedBox(width: 12),
                // Album info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        album.title,
                        style: AppTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        album.artist,
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
              // Fetch album tracks and play
              try {
                final tidalService = ref.read(tidalServiceProvider);
                final albumDetail = await tidalService.getAlbum(album.id);
                if (albumDetail.tracks.isNotEmpty) {
                  ref.read(playerProvider.notifier).playQueue(
                    albumDetail.tracks,
                    source: 'Album: ${album.title}',
                  );
                }
              } catch (e) {
                print('Error playing album: $e');
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
                final albumDetail = await tidalService.getAlbum(album.id);
                if (albumDetail.tracks.isNotEmpty) {
                  final shuffled = List<Track>.from(albumDetail.tracks)..shuffle();
                  ref.read(playerProvider.notifier).playQueue(
                    shuffled,
                    source: 'Album: ${album.title} (Shuffled)',
                  );
                }
              } catch (e) {
                print('Error shuffling album: $e');
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
                final albumDetail = await tidalService.getAlbum(album.id);
                for (final track in albumDetail.tracks) {
                  ref.read(playerProvider.notifier).addToQueue(track);
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Added ${albumDetail.tracks.length} tracks to queue'),
                    backgroundColor: AppTheme.surfaceLight,
                  ),
                );
              } catch (e) {
                print('Error adding album to queue: $e');
              }
            },
          ),

          // Add to collection (toggleable)
          Builder(
            builder: (context) {
              final isAlbumSaved = ref.watch(isAlbumSavedProvider(album.id));
              return _OptionTile(
                icon: isAlbumSaved ? Icons.check : Icons.add,
                label: isAlbumSaved ? 'Remove from collection' : 'Add to collection',
                iconColor: isAlbumSaved ? AppTheme.primaryColor : null,
                onTap: () {
                  ref.read(savedAlbumsProvider.notifier).toggleAlbum(album);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isAlbumSaved ? 'Removed from collection' : 'Added to collection'),
                      backgroundColor: AppTheme.surfaceLight,
                    ),
                  );
                },
              );
            },
          ),

          _OptionTile(
            icon: Icons.album_outlined,
            label: 'View album',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AlbumDetailScreen(albumId: album.id, album: album),
                ),
              );
            },
          ),

          _OptionTile(
            icon: Icons.person_outline,
            label: 'View artist',
            onTap: () {
              Navigator.pop(context);
              if (album.artistId.isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ArtistDetailScreen(artistId: album.artistId),
                  ),
                );
              }
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
