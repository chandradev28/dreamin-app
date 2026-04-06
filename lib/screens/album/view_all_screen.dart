import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/album_options_sheet.dart';
import '../../widgets/playlist_options_sheet.dart';
import '../album/album_detail_screen.dart';
import '../artist/artist_detail_screen.dart';
import '../playlist/playlist_detail_screen.dart';
import '../scaffold_with_mini_player.dart';

/// View All Screen - Grid display for albums/artists/playlists
/// Shows 20 items max in a 2-column grid layout (TIDAL style)
class ViewAllScreen extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final responsive = Responsive(context);

    return ScaffoldWithMiniPlayer(
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
        child: _buildContent(context, responsive, ref),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    Responsive responsive,
    WidgetRef ref,
  ) {
    if (albums != null && albums!.isNotEmpty) {
      return _buildAlbumGrid(context, responsive, ref);
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

  Widget _buildAlbumGrid(
    BuildContext context,
    Responsive responsive,
    WidgetRef ref,
  ) {
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
          onTap: () => _navigateToAlbum(context, ref, album),
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

  Future<void> _navigateToAlbum(
    BuildContext context,
    WidgetRef ref,
    Album album,
  ) async {
    final resolvedAlbum = await _resolveAlbumForNavigation(ref, album);
    if (!context.mounted) {
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AlbumDetailScreen(
          albumId: resolvedAlbum.id,
          album: resolvedAlbum,
        ),
      ),
    );
  }

  Future<Album> _resolveAlbumForNavigation(WidgetRef ref, Album album) async {
    if (album.source != MusicSource.qobuz) {
      return album;
    }

    final musicService = ref.read(musicServiceProvider);
    try {
      final query = '${album.artist} ${album.title}'.trim();
      final candidates = await musicService.searchAlbums(query, limit: 25);
      final resolved = _pickBestAlbumMatch(
        candidates,
        artistName: album.artist,
        title: album.title,
      );
      if (resolved != null) {
        return resolved;
      }
    } catch (_) {}

    return album;
  }

  Album? _pickBestAlbumMatch(
    List<Album> albums, {
    required String artistName,
    required String title,
  }) {
    if (albums.isEmpty) {
      return null;
    }

    final normalizedArtist = _normalizeArtistName(artistName);
    final normalizedTitle = _normalizeAlbumTitle(title);

    for (final album in albums) {
      if (_normalizeArtistName(album.artist) == normalizedArtist &&
          _normalizeAlbumTitle(album.title) == normalizedTitle) {
        return album;
      }
    }

    for (final album in albums) {
      if (_normalizeArtistName(album.artist) == normalizedArtist) {
        final candidateTitle = _normalizeAlbumTitle(album.title);
        if (candidateTitle.contains(normalizedTitle) ||
            normalizedTitle.contains(candidateTitle)) {
          return album;
        }
      }
    }

    return null;
  }

  String _normalizeArtistName(String name) {
    return name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
  }

  String _normalizeAlbumTitle(String title) {
    var normalized = title.toLowerCase();
    normalized = normalized.replaceAll(RegExp(r'\((.*?)\)|\[(.*?)\]'), ' ');
    normalized = normalized.replaceAll(
      RegExp(
        r'\b(remaster(ed)?|deluxe|expanded|edition|version|mono|stereo|anniversary|bonus|track|disc|single|ep|album)\b',
      ),
      ' ',
    );
    normalized = normalized.replaceAll(RegExp(r'[^a-z0-9]+'), ' ');
    return normalized.replaceAll(RegExp(r'\s+'), ' ').trim();
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
