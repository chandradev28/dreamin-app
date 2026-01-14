import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../../providers/providers.dart';

/// Library Screen - Responsive with Real Data
class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final responsive = Responsive(context);
    final favoritesState = ref.watch(favoritesProvider);
    final historyState = ref.watch(historyProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(responsive.horizontalPadding),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Library',
                      style: responsive.value(
                        mobile: AppTheme.headlineMedium,
                        tablet: AppTheme.headlineLarge,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      iconSize: responsive.value(mobile: 24.0, tablet: 28.0),
                      onPressed: () {
                        // Create new playlist
                        _showCreatePlaylistDialog(context, ref);
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Library Categories
            SliverToBoxAdapter(
              child: Column(
                children: [
                  _LibraryTile(
                    icon: Icons.favorite,
                    iconColor: AppTheme.accentColor,
                    title: 'Favorites',
                    subtitle: '${favoritesState.favorites.length} tracks',
                    onTap: () {},
                  ),
                  _LibraryTile(
                    icon: Icons.history,
                    iconColor: AppTheme.tidalBadge,
                    title: 'Recently Played',
                    subtitle: '${historyState.recentlyPlayed.length} tracks',
                    onTap: () {},
                  ),
                  _LibraryTile(
                    icon: Icons.trending_up,
                    iconColor: AppTheme.successColor,
                    title: 'Most Played',
                    subtitle: 'Your top tracks',
                    onTap: () {},
                  ),
                  _LibraryTile(
                    icon: Icons.download,
                    iconColor: AppTheme.qobuzBadge,
                    title: 'Downloads',
                    subtitle: 'Available offline',
                    onTap: () {},
                  ),
                ],
              ),
            ),

            // Divider
            SliverToBoxAdapter(
              child: Divider(
                height: responsive.sectionSpacing,
                indent: responsive.horizontalPadding,
                endIndent: responsive.horizontalPadding,
              ),
            ),

            // Recently Played Preview
            if (historyState.recentlyPlayed.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: responsive.horizontalPadding,
                    vertical: responsive.value(mobile: 8.0, tablet: 12.0),
                  ),
                  child: Text('Recently Played', style: AppTheme.headlineSmall),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index >= 5) return null;
                    final track = historyState.recentlyPlayed[index];
                    final playerState = ref.watch(playerProvider);
                    final favState = ref.watch(favoritesProvider);
                    
                    return Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: responsive.horizontalPadding,
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          width: responsive.trackThumbnailSize,
                          height: responsive.trackThumbnailSize,
                          decoration: BoxDecoration(
                            borderRadius: AppTheme.radiusSmall,
                            color: AppTheme.surfaceLight,
                            image: track.coverArtUrl != null
                                ? DecorationImage(
                                    image: NetworkImage(track.coverArtUrl!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: track.coverArtUrl == null
                              ? const Icon(Icons.music_note, color: AppTheme.secondaryColor)
                              : null,
                        ),
                        title: Text(
                          track.title,
                          style: playerState.currentTrack?.id == track.id
                              ? AppTheme.titleSmall.copyWith(color: AppTheme.accentColor)
                              : AppTheme.titleSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          track.artist,
                          style: AppTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: IconButton(
                          icon: Icon(
                            favState.favoriteIds.contains('${track.id}_${track.source.name}')
                                ? Icons.favorite
                                : Icons.favorite_border,
                            size: 20,
                          ),
                          color: favState.favoriteIds.contains('${track.id}_${track.source.name}')
                              ? AppTheme.accentColor
                              : AppTheme.secondaryColor,
                          onPressed: () {
                            ref.read(favoritesProvider.notifier).toggleFavorite(track);
                          },
                        ),
                        onTap: () {
                          ref.read(playerProvider.notifier).playQueue(
                            historyState.recentlyPlayed,
                            startIndex: index,
                          );
                        },
                      ),
                    );
                  },
                  childCount: historyState.recentlyPlayed.length.clamp(0, 5),
                ),
              ),
            ],

            // Bottom spacing
            SliverToBoxAdapter(
              child: SizedBox(height: responsive.miniPlayerHeight + responsive.bottomNavHeight + 20),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreatePlaylistDialog(BuildContext context, WidgetRef ref) {
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
          decoration: const InputDecoration(
            hintText: 'Playlist name',
          ),
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
                await database.createPlaylist(controller.text);
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

class _LibraryTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _LibraryTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);
    final iconSize = responsive.value(mobile: 48.0, tablet: 56.0);

    return ListTile(
      contentPadding: EdgeInsets.symmetric(
        horizontal: responsive.horizontalPadding,
        vertical: responsive.value(mobile: 4.0, tablet: 8.0),
      ),
      leading: Container(
        width: iconSize,
        height: iconSize,
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.15),
          borderRadius: AppTheme.radiusMedium,
        ),
        child: Icon(
          icon,
          color: iconColor,
          size: iconSize * 0.5,
        ),
      ),
      title: Text(
        title,
        style: responsive.value(
          mobile: AppTheme.titleMedium,
          tablet: AppTheme.titleLarge,
        ),
      ),
      subtitle: Text(subtitle, style: AppTheme.bodySmall),
      trailing: Icon(
        Icons.chevron_right,
        color: AppTheme.secondaryColor,
        size: responsive.value(mobile: 24.0, tablet: 28.0),
      ),
      onTap: onTap,
    );
  }
}
