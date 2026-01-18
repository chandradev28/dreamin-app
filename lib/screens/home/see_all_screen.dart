import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../album/album_detail_screen.dart';
import '../playlist/playlist_detail_screen.dart';
import '../scaffold_with_mini_player.dart';

/// See All Screen - Loads 30 results from API
/// For playlists: Pass searchQuery to search for playlists
/// For albums: Pass searchQuery to search for albums  
/// For tracks: Pass searchQuery to search for tracks
class SeeAllScreen extends ConsumerStatefulWidget {
  final String title;
  final String searchQuery;
  final SeeAllType type;
  
  // Optional: pass initial items to show while loading
  final List<dynamic>? initialItems;

  const SeeAllScreen({
    super.key,
    required this.title,
    required this.searchQuery,
    required this.type,
    this.initialItems,
  });

  @override
  ConsumerState<SeeAllScreen> createState() => _SeeAllScreenState();
}

class _SeeAllScreenState extends ConsumerState<SeeAllScreen> {
  List<dynamic> _items = [];
  bool _isLoading = false;
  String? _error;
  bool _hasLoadedMore = false;

  @override
  void initState() {
    super.initState();
    // Show initial items immediately if available
    if (widget.initialItems != null && widget.initialItems!.isNotEmpty) {
      _items = List.from(widget.initialItems!);
      _isLoading = false;
    } else {
      // Only load from API if no initial items passed
      _loadData();
    }
  }

  Future<void> _loadData() async {
    if (_hasLoadedMore) return; // Already loaded more items
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final tidalService = ref.read(tidalServiceProvider);
      List<dynamic> apiResults = [];
      
      switch (widget.type) {
        case SeeAllType.playlist:
          apiResults = await tidalService.searchPlaylists(widget.searchQuery, limit: 30);
          break;
          
        case SeeAllType.album:
          apiResults = await tidalService.searchAlbums(widget.searchQuery, limit: 30);
          break;
          
        case SeeAllType.track:
          apiResults = await tidalService.searchTracks(widget.searchQuery, limit: 30);
          break;
      }
      
      if (mounted) {
        setState(() {
          // If we have initial items, keep them and only add NEW items from API
          if (widget.initialItems != null && widget.initialItems!.isNotEmpty) {
            final existingIds = _items.map((e) => _getItemId(e)).toSet();
            final newItems = apiResults.where((item) => !existingIds.contains(_getItemId(item))).toList();
            _items = [..._items, ...newItems.take(20)]; // Add up to 20 more unique items
          } else {
            _items = apiResults;
          }
          _isLoading = false;
          _hasLoadedMore = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  String _getItemId(dynamic item) {
    if (item is Playlist) return item.id;
    if (item is Album) return item.id;
    if (item is Track) return item.id;
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);

    return ScaffoldWithMiniPlayer(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // App Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: AppTheme.titleLarge.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: _buildContent(responsive),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(Responsive responsive) {
    if (_isLoading && _items.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryColor),
      );
    }

    if (_error != null && _items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppTheme.errorColor),
            const SizedBox(height: 16),
            Text('Failed to load', style: AppTheme.bodyLarge),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_items.isEmpty) {
      return Center(
        child: Text('No results found', style: AppTheme.bodyLarge),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppTheme.primaryColor,
      child: ListView.builder(
        padding: EdgeInsets.only(
          top: 8,
          bottom: responsive.miniPlayerHeight + 20,
        ),
        itemCount: _items.length + (_isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _items.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
            );
          }

          final item = _items[index];
          if (widget.type == SeeAllType.playlist && item is Playlist) {
            return _PlaylistListTile(playlist: item);
          } else if (widget.type == SeeAllType.album && item is Album) {
            return _AlbumListTile(album: item);
          } else if (widget.type == SeeAllType.track && item is Track) {
            return _TrackListTile(track: item, tracks: _items.cast<Track>(), index: index);
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
