import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import '../../widgets/album_options_sheet.dart';
import '../album/album_detail_screen.dart';

/// Library Albums Screen - Shows saved albums
class LibraryAlbumsScreen extends ConsumerWidget {
  const LibraryAlbumsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedAlbumsState = ref.watch(savedAlbumsProvider);
    final albums = savedAlbumsState.albums;

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
          'Albums',
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
      body: albums.isEmpty ? _buildEmptyState() : _buildAlbumGrid(context, albums),
    );
  }

  Widget _buildAlbumGrid(BuildContext context, List<Album> albums) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: albums.length,
      itemBuilder: (context, index) {
        final album = albums[index];
        return _AlbumGridItem(album: album);
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
            // Vinyl/CD icon in circle
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Center(
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.4),
                      width: 2,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              "You haven't added any albums yet. Tap the + icon on any album to add it to your collection.",
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

/// Album Grid Item with 3-dot menu
class _AlbumGridItem extends StatelessWidget {
  final Album album;

  const _AlbumGridItem({required this.album});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AlbumDetailScreen(albumId: album.id, album: album),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Album Cover with 3-dot overlay
          Expanded(
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: AppTheme.surfaceColor,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: album.coverArtUrl != null
                      ? CachedNetworkImage(
                          imageUrl: album.coverArtUrl!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          placeholder: (_, __) => Container(color: AppTheme.surfaceColor),
                          errorWidget: (_, __, ___) => const Icon(
                            Icons.album,
                            color: AppTheme.tertiaryColor,
                            size: 40,
                          ),
                        )
                      : const Center(
                          child: Icon(Icons.album, color: AppTheme.tertiaryColor, size: 40),
                        ),
                ),
                // 3-dot menu overlay
                Positioned(
                  top: 6,
                  right: 6,
                  child: GestureDetector(
                    onTap: () => AlbumOptionsSheet.show(context, album),
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
          // Album Title
          Text(
            album.title,
            style: AppTheme.bodyMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          // Artist Name
          Text(
            album.artist,
            style: AppTheme.bodySmall.copyWith(color: AppTheme.secondaryColor),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
