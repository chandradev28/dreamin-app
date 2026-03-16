import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/theme/app_theme.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../screens/artist/artist_detail_screen.dart';

class ArtistOptionsSheet extends ConsumerWidget {
  final Artist artist;

  const ArtistOptionsSheet({super.key, required this.artist});

  static void show(BuildContext context, Artist artist) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => ArtistOptionsSheet(artist: artist),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSaved = ref.watch(isArtistSavedProvider(artist.id));

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppTheme.surfaceLight,
                  backgroundImage: artist.imageUrl != null
                      ? CachedNetworkImageProvider(artist.imageUrl!)
                      : null,
                  child: artist.imageUrl == null
                      ? const Icon(
                          Icons.person,
                          color: AppTheme.secondaryColor,
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    artist.name,
                    style: AppTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.surfaceLight),
          _ArtistOptionTile(
            icon: Icons.play_arrow_rounded,
            label: 'Play top tracks',
            onTap: () async {
              Navigator.pop(context);
              final detail = await ref.read(tidalServiceProvider).getArtist(
                    artist.id,
                  );
              if (detail.topTracks.isNotEmpty) {
                ref.read(playerProvider.notifier).playQueue(
                      detail.topTracks,
                      source: 'Artist: ${artist.name}',
                    );
              }
            },
          ),
          _ArtistOptionTile(
            icon: Icons.shuffle_rounded,
            label: 'Shuffle top tracks',
            onTap: () async {
              Navigator.pop(context);
              final detail = await ref.read(tidalServiceProvider).getArtist(
                    artist.id,
                  );
              if (detail.topTracks.isNotEmpty) {
                final tracks = List<Track>.from(detail.topTracks)..shuffle();
                ref.read(playerProvider.notifier).playQueue(
                      tracks,
                      source: 'Artist: ${artist.name} (Shuffled)',
                    );
              }
            },
          ),
          _ArtistOptionTile(
            icon: Icons.playlist_add_rounded,
            label: 'Add top tracks to queue',
            onTap: () async {
              Navigator.pop(context);
              final detail = await ref.read(tidalServiceProvider).getArtist(
                    artist.id,
                  );
              if (detail.topTracks.isNotEmpty) {
                for (final track in detail.topTracks) {
                  ref.read(playerProvider.notifier).addToQueue(track);
                }
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Added ${detail.topTracks.length} tracks to queue',
                    ),
                  ),
                );
              }
            },
          ),
          _ArtistOptionTile(
            icon: isSaved ? Icons.check : Icons.add,
            label: isSaved ? 'Remove from collection' : 'Add to collection',
            iconColor: isSaved ? AppTheme.primaryColor : null,
            onTap: () async {
              await ref
                  .read(savedArtistsProvider.notifier)
                  .toggleArtist(artist);
              if (!context.mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isSaved ? 'Removed from collection' : 'Added to collection',
                  ),
                ),
              );
            },
          ),
          _ArtistOptionTile(
            icon: Icons.person_outline,
            label: 'View artist',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ArtistDetailScreen(
                    artistId: artist.id,
                    artist: artist,
                  ),
                ),
              );
            },
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }
}

class _ArtistOptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;

  const _ArtistOptionTile({
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
