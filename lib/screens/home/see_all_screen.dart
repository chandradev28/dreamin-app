import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../album/album_detail_screen.dart';
import '../playlist/playlist_detail_screen.dart';

/// Generic "See All" Screen - TIDAL Style
/// Shows a list view of playlists or albums (max 30 items)
class SeeAllScreen extends StatelessWidget {
  final String title;
  final List<dynamic> items; // Can be List<Playlist> or List<Album>
  final SeeAllType type;

  const SeeAllScreen({
    super.key,
    required this.title,
    required this.items,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);
    final limitedItems = items.take(30).toList();

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
          style: AppTheme.titleLarge.copyWith(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: EdgeInsets.only(
          top: 8,
          bottom: responsive.miniPlayerHeight + responsive.bottomNavHeight + 20,
        ),
        itemCount: limitedItems.length,
        itemBuilder: (context, index) {
          final item = limitedItems[index];
          if (type == SeeAllType.playlist && item is Playlist) {
            return _PlaylistListTile(playlist: item);
          } else if (type == SeeAllType.album && item is Album) {
            return _AlbumListTile(album: item);
          } else if (type == SeeAllType.track && item is Track) {
            return _TrackListTile(track: item, tracks: limitedItems.cast<Track>(), index: index);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

enum SeeAllType { playlist, album, track }

/// Playlist List Tile - TIDAL Style
class _PlaylistListTile extends StatelessWidget {
  final Playlist playlist;

  const _PlaylistListTile({required this.playlist});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PlaylistDetailScreen(
            playlistId: playlist.id,
            playlist: playlist,
          ),
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: playlist.coverArtUrl != null
            ? CachedNetworkImage(
                imageUrl: playlist.coverArtUrl!,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  width: 56,
                  height: 56,
                  color: AppTheme.surfaceLight,
                  child: const Icon(Icons.queue_music, color: AppTheme.secondaryColor),
                ),
                errorWidget: (_, __, ___) => Container(
                  width: 56,
                  height: 56,
                  color: AppTheme.surfaceLight,
                  child: const Icon(Icons.queue_music, color: AppTheme.secondaryColor),
                ),
              )
            : Container(
                width: 56,
                height: 56,
                color: AppTheme.surfaceLight,
                child: const Icon(Icons.queue_music, color: AppTheme.secondaryColor),
              ),
      ),
      title: Text(
        playlist.title,
        style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w600),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        'by ${playlist.creatorName ?? "TIDAL"}',
        style: AppTheme.bodySmall.copyWith(color: AppTheme.secondaryColor),
        maxLines: 1,
      ),
      trailing: IconButton(
        icon: const Icon(Icons.more_horiz, color: AppTheme.secondaryColor),
        onPressed: () {},
      ),
    );
  }
}

/// Album List Tile - TIDAL Style
class _AlbumListTile extends StatelessWidget {
  final Album album;

  const _AlbumListTile({required this.album});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AlbumDetailScreen(
            albumId: album.id,
            album: album,
          ),
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: album.coverArtUrl != null
            ? CachedNetworkImage(
                imageUrl: album.coverArtUrl!,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  width: 56,
                  height: 56,
                  color: AppTheme.surfaceLight,
                  child: const Icon(Icons.album, color: AppTheme.secondaryColor),
                ),
                errorWidget: (_, __, ___) => Container(
                  width: 56,
                  height: 56,
                  color: AppTheme.surfaceLight,
                  child: const Icon(Icons.album, color: AppTheme.secondaryColor),
                ),
              )
            : Container(
                width: 56,
                height: 56,
                color: AppTheme.surfaceLight,
                child: const Icon(Icons.album, color: AppTheme.secondaryColor),
              ),
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              album.title,
              style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (album.isExplicit) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(3),
              ),
              child: const Text(
                'E',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
      subtitle: Text(
        album.artist,
        style: AppTheme.bodySmall.copyWith(color: AppTheme.secondaryColor),
        maxLines: 1,
      ),
      trailing: IconButton(
        icon: const Icon(Icons.more_horiz, color: AppTheme.secondaryColor),
        onPressed: () {},
      ),
    );
  }
}

/// Track List Tile - TIDAL Style
class _TrackListTile extends ConsumerWidget {
  final Track track;
  final List<Track> tracks;
  final int index;

  const _TrackListTile({
    required this.track,
    required this.tracks,
    required this.index,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      onTap: () => ref.read(playerProvider.notifier).playQueue(tracks, startIndex: index),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: track.coverArtUrl != null
            ? CachedNetworkImage(
                imageUrl: track.coverArtUrl!,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  width: 56,
                  height: 56,
                  color: AppTheme.surfaceLight,
                  child: const Icon(Icons.music_note, color: AppTheme.secondaryColor),
                ),
                errorWidget: (_, __, ___) => Container(
                  width: 56,
                  height: 56,
                  color: AppTheme.surfaceLight,
                  child: const Icon(Icons.music_note, color: AppTheme.secondaryColor),
                ),
              )
            : Container(
                width: 56,
                height: 56,
                color: AppTheme.surfaceLight,
                child: const Icon(Icons.music_note, color: AppTheme.secondaryColor),
              ),
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              track.title,
              style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (track.isExplicit) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(3),
              ),
              child: const Text(
                'E',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
      subtitle: Text(
        track.artist,
        style: AppTheme.bodySmall.copyWith(color: AppTheme.secondaryColor),
        maxLines: 1,
      ),
      trailing: IconButton(
        icon: const Icon(Icons.more_horiz, color: AppTheme.secondaryColor),
        onPressed: () {},
      ),
    );
  }
}
