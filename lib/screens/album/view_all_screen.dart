import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../../models/models.dart';
import '../../widgets/album_options_sheet.dart';
import '../../widgets/playlist_options_sheet.dart';
import '../album/album_detail_screen.dart';
import '../artist/artist_detail_screen.dart';
import '../playlist/playlist_detail_screen.dart';

/// View All Screen - Grid display for albums/artists/playlists
/// Shows 20 items max in a 2-column grid layout (TIDAL style)
class ViewAllScreen extends StatelessWidget {
  final String title;
  final List<Album>? albums;
  final List<Artist>? artists;
  final List<Playlist>? playlists;

  const ViewAllScreen({
    super.key,
    required this.title,
    this.albums,
    this.artists,
    this.playlists,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);

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
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: _buildContent(context, responsive),
      ),
    );
  }

  Widget _buildContent(BuildContext context, Responsive responsive) {
    if (albums != null && albums!.isNotEmpty) {
      return _buildAlbumGrid(context, responsive);
    } else if (artists != null && artists!.isNotEmpty) {
      return _buildArtistGrid(context, responsive);
    } else if (playlists != null && playlists!.isNotEmpty) {
      return _buildPlaylistGrid(context, responsive);
    }
    return const Center(
      child: Text(
        'No items to display',
        style: TextStyle(color: AppTheme.secondaryColor),
      ),
    );
  }

  Widget _buildAlbumGrid(BuildContext context, Responsive responsive) {
    final items = albums!;

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 16,
        mainAxisSpacing: 20,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final album = items[index];
        return _AlbumGridItem(
          album: album,
          onTap: () => _navigateToAlbum(context, album),
        );
      },
    );
  }

  Widget _buildArtistGrid(BuildContext context, Responsive responsive) {
    final items = artists!;

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: 16,
        mainAxisSpacing: 20,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final artist = items[index];
        return _ArtistGridItem(
          artist: artist,
          onTap: () => _navigateToArtist(context, artist),
        );
      },
    );
  }

  Widget _buildPlaylistGrid(BuildContext context, Responsive responsive) {
    final items = playlists!;

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 16,
        mainAxisSpacing: 20,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final playlist = items[index];
        return _PlaylistGridItem(
          playlist: playlist,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PlaylistDetailScreen(
                    playlistId: playlist.id, playlist: playlist),
              ),
            );
          },
        );
      },
    );
  }

  void _navigateToAlbum(BuildContext context, Album album) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AlbumDetailScreen(
          albumId: album.id,
          album: album,
        ),
      ),
    );
  }

  void _navigateToArtist(BuildContext context, Artist artist) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ArtistDetailScreen(
          artistId: artist.id,
          artist: artist,
        ),
      ),
    );
  }
}

// ============================================================================
// ALBUM GRID ITEM
// ============================================================================

class _AlbumGridItem extends StatelessWidget {
  final Album album;
  final VoidCallback onTap;

  const _AlbumGridItem({required this.album, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Album Cover with 3-dot overlay
          AspectRatio(
            aspectRatio: 1,
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
                          placeholder: (_, __) => Container(
                            color: AppTheme.surfaceColor,
                            child: const Icon(Icons.album,
                                color: AppTheme.tertiaryColor, size: 40),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: AppTheme.surfaceColor,
                            child: const Icon(Icons.album,
                                color: AppTheme.tertiaryColor, size: 40),
                          ),
                        )
                      : const Icon(Icons.album,
                          color: AppTheme.tertiaryColor, size: 40),
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
                      child: const Icon(Icons.more_horiz,
                          color: Colors.white, size: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Album Title
          Row(
            children: [
              Expanded(
                child: Text(
                  album.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (album.isExplicit)
                Container(
                  margin: const EdgeInsets.only(left: 4),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
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
          const SizedBox(height: 2),
          // Artist Name
          Text(
            album.artist,
            style: const TextStyle(
              color: AppTheme.secondaryColor,
              fontSize: 13,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          // Year
          if (album.year != null)
            Text(
              album.year.toString(),
              style: TextStyle(
                color: AppTheme.tertiaryColor,
                fontSize: 12,
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================================
// ARTIST GRID ITEM
// ============================================================================

class _ArtistGridItem extends StatelessWidget {
  final Artist artist;
  final VoidCallback onTap;

  const _ArtistGridItem({required this.artist, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          // Artist Image (Circular)
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.surfaceColor,
              ),
              clipBehavior: Clip.antiAlias,
              child: artist.imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: artist.imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: AppTheme.surfaceColor,
                        child: const Icon(Icons.person,
                            color: AppTheme.tertiaryColor, size: 40),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: AppTheme.surfaceColor,
                        child: const Icon(Icons.person,
                            color: AppTheme.tertiaryColor, size: 40),
                      ),
                    )
                  : const Icon(Icons.person,
                      color: AppTheme.tertiaryColor, size: 40),
            ),
          ),
          const SizedBox(height: 10),
          // Artist Name
          Text(
            artist.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// PLAYLIST GRID ITEM
// ============================================================================

class _PlaylistGridItem extends StatelessWidget {
  final Playlist playlist;
  final VoidCallback onTap;

  const _PlaylistGridItem({required this.playlist, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Playlist Cover with 3-dot overlay
          AspectRatio(
            aspectRatio: 1,
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
                          placeholder: (_, __) => Container(
                            color: AppTheme.surfaceColor,
                            child: const Icon(Icons.playlist_play,
                                color: AppTheme.tertiaryColor, size: 40),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: AppTheme.surfaceColor,
                            child: const Icon(Icons.playlist_play,
                                color: AppTheme.tertiaryColor, size: 40),
                          ),
                        )
                      : const Icon(Icons.playlist_play,
                          color: AppTheme.tertiaryColor, size: 40),
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
                      child: const Icon(Icons.more_horiz,
                          color: Colors.white, size: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Playlist Title
          Text(
            playlist.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          // Creator Name
          if (playlist.creatorName != null)
            Text(
              playlist.creatorName!,
              style: const TextStyle(
                color: AppTheme.secondaryColor,
                fontSize: 13,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }
}
