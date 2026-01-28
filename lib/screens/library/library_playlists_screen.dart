import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import '../../widgets/playlist_options_sheet.dart';
import '../playlist/playlist_detail_screen.dart';

/// Library Playlists Screen - Shows saved playlists
class LibraryPlaylistsScreen extends ConsumerWidget {
  const LibraryPlaylistsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedPlaylistsState = ref.watch(savedPlaylistsProvider);
    final playlists = savedPlaylistsState.playlists;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Playlists',
          style: AppTheme.titleLarge.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.sort, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: playlists.isEmpty ? _buildEmptyState() : _buildPlaylistGrid(context, playlists),
    );
  }

  Widget _buildPlaylistGrid(BuildContext context, List<Playlist> playlists) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: playlists.length,
      itemBuilder: (context, index) {
        final playlist = playlists[index];
        return _PlaylistGridItem(playlist: playlist);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.queue_music_outlined,
              size: 64,
              color: Colors.white.withOpacity(0.4),
            ),
            const SizedBox(height: 32),
            Text(
              "You haven't added any playlists yet. Tap the + icon on any playlist to add it to your collection.",
              style: AppTheme.bodyMedium.copyWith(
                color: Colors.white.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Playlist Grid Item with 3-dot menu
class _PlaylistGridItem extends StatelessWidget {
  final Playlist playlist;

  const _PlaylistGridItem({required this.playlist});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PlaylistDetailScreen(playlistId: playlist.id, playlist: playlist),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Playlist Cover with 3-dot overlay
          Expanded(
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: AppTheme.surfaceColor,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: playlist.coverArtUrl != null
                      ? CachedNetworkImage(
                          imageUrl: playlist.coverArtUrl!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          placeholder: (_, __) => Container(color: AppTheme.surfaceColor),
                          errorWidget: (_, __, ___) => const Icon(
                            Icons.queue_music,
                            color: AppTheme.tertiaryColor,
                            size: 40,
                          ),
                        )
                      : const Center(
                          child: Icon(Icons.queue_music, color: AppTheme.tertiaryColor, size: 40),
                        ),
                ),
                // 3-dot menu overlay
                Positioned(
                  top: 6,
                  right: 6,
                  child: GestureDetector(
                    onTap: () => PlaylistOptionsSheet.show(context, playlist),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.more_horiz, color: Colors.white, size: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Playlist Title
          Text(
            playlist.title,
            style: AppTheme.bodyMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          // Creator Name
          Text(
            playlist.creatorName ?? 'Playlist',
            style: AppTheme.bodySmall.copyWith(color: AppTheme.secondaryColor),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
