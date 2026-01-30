import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import '../../data/database.dart';
import '../../widgets/playlist_options_sheet.dart';
import '../playlist/playlist_detail_screen.dart';

/// Library Playlists Screen - Shows saved playlists (TIDAL-style list layout)
class LibraryPlaylistsScreen extends ConsumerStatefulWidget {
  const LibraryPlaylistsScreen({super.key});

  @override
  ConsumerState<LibraryPlaylistsScreen> createState() => _LibraryPlaylistsScreenState();
}

class _LibraryPlaylistsScreenState extends ConsumerState<LibraryPlaylistsScreen> {
  List<LocalPlaylist> _userPlaylists = [];
  Map<int, int> _userPlaylistTrackCounts = {};

  @override
  void initState() {
    super.initState();
    _loadUserPlaylists();
  }

  Future<void> _loadUserPlaylists() async {
    final database = ref.read(databaseProvider);
    final playlists = await database.getAllPlaylists();
    
    // Get track count for each playlist
    final trackCounts = <int, int>{};
    for (final playlist in playlists) {
      final tracks = await database.getPlaylistTracks(playlist.id);
      trackCounts[playlist.id] = tracks.length;
    }
    
    if (mounted) {
      setState(() {
        _userPlaylists = playlists;
        _userPlaylistTrackCounts = trackCounts;
      });
    }
  }

  void _showCreatePlaylistDialog() {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text('Create Playlist', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: AppTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: 'Playlist name',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppTheme.primaryColor),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.white.withOpacity(0.7))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                final database = ref.read(databaseProvider);
                await database.createPlaylist(controller.text);
                if (context.mounted) {
                  Navigator.pop(context);
                  _loadUserPlaylists();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Playlist created'),
                      backgroundColor: AppTheme.surfaceLight,
                    ),
                  );
                }
              }
            },
            child: const Text('Create', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final savedPlaylistsState = ref.watch(savedPlaylistsProvider);
    final tidalPlaylists = savedPlaylistsState.playlists;

    final hasAnyPlaylists = _userPlaylists.isNotEmpty || tidalPlaylists.isNotEmpty;

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
            icon: const Icon(Icons.sort, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // Create button - always at top
          _buildCreateButton(),
          
          const SizedBox(height: 16),
          
          if (!hasAnyPlaylists)
            _buildEmptyState()
          else ...[
            // User playlists first
            ..._userPlaylists.map((playlist) => _UserPlaylistItem(
              playlist: playlist,
              trackCount: _userPlaylistTrackCounts[playlist.id] ?? 0,
              onRefresh: _loadUserPlaylists,
            )),
            
            // TIDAL playlists second
            ...tidalPlaylists.map((playlist) => _TidalPlaylistItem(playlist: playlist)),
          ],
          
          // Bottom padding
          SizedBox(height: MediaQuery.of(context).padding.bottom + 80),
        ],
      ),
    );
  }

  Widget _buildCreateButton() {
    return InkWell(
      onTap: _showCreatePlaylistDialog,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, color: Colors.white.withOpacity(0.9), size: 20),
            const SizedBox(width: 8),
            Text(
              'Create...',
              style: AppTheme.bodyLarge.copyWith(
                color: Colors.white.withOpacity(0.9),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 80),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.queue_music_outlined,
            size: 64,
            color: Colors.white.withOpacity(0.4),
          ),
          const SizedBox(height: 24),
          Text(
            "No playlists yet",
            style: AppTheme.titleMedium.copyWith(
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              "Create your own playlist or save playlists you find",
              style: AppTheme.bodyMedium.copyWith(
                color: Colors.white.withOpacity(0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

/// User-created playlist item
class _UserPlaylistItem extends ConsumerWidget {
  final LocalPlaylist playlist;
  final int trackCount;
  final VoidCallback onRefresh;

  const _UserPlaylistItem({
    required this.playlist,
    required this.trackCount,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () async {
        // Load tracks and navigate to local playlist detail
        final database = ref.read(databaseProvider);
        final playlistTracks = await database.getPlaylistTracks(playlist.id);
        
        // Convert to Track objects
        final tracks = <Track>[];
        for (final pt in playlistTracks) {
          try {
            final json = jsonDecode(pt.trackJson) as Map<String, dynamic>;
            tracks.add(Track.fromTidalJson(json));
          } catch (_) {}
        }
        
        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => _LocalPlaylistDetailScreen(
                playlist: playlist,
                tracks: tracks,
                onRefresh: onRefresh,
              ),
            ),
          );
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            // Playlist icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(4),
              ),
              child: playlist.coverUrl != null
                  ? CachedNetworkImage(
                      imageUrl: playlist.coverUrl!,
                      fit: BoxFit.cover,
                    )
                  : const Icon(
                      Icons.queue_music,
                      color: AppTheme.secondaryColor,
                      size: 28,
                    ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    playlist.name,
                    style: AppTheme.bodyLarge.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'by you',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.secondaryColor,
                    ),
                  ),
                  Text(
                    trackCount == 0 ? 'NO ITEMS' : '$trackCount ${trackCount == 1 ? 'TRACK' : 'TRACKS'}',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.secondaryColor,
                      fontSize: 11,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            // 3-dot menu
            IconButton(
              icon: const Icon(Icons.more_horiz, color: AppTheme.secondaryColor),
              onPressed: () => _showUserPlaylistOptions(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  void _showUserPlaylistOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      builder: (context) => Column(
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
          ListTile(
            leading: const Icon(Icons.edit_outlined, color: Colors.white),
            title: const Text('Rename playlist', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              _showRenameDialog(context, ref);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            title: const Text('Delete playlist', style: TextStyle(color: Colors.red)),
            onTap: () async {
              Navigator.pop(context);
              final database = ref.read(databaseProvider);
              await database.deletePlaylist(playlist.id);
              onRefresh();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Playlist deleted')),
                );
              }
            },
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }

  void _showRenameDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController(text: playlist.name);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text('Rename Playlist', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: AppTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: 'Playlist name',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              // TODO: Add rename functionality to database
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

/// TIDAL playlist item
class _TidalPlaylistItem extends StatelessWidget {
  final Playlist playlist;

  const _TidalPlaylistItem({required this.playlist});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PlaylistDetailScreen(
              playlistId: playlist.id,
              playlist: playlist,
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            // Playlist cover
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(4),
              ),
              clipBehavior: Clip.antiAlias,
              child: playlist.coverArtUrl != null
                  ? CachedNetworkImage(
                      imageUrl: playlist.coverArtUrl!,
                      fit: BoxFit.cover,
                    )
                  : const Icon(
                      Icons.queue_music,
                      color: AppTheme.secondaryColor,
                      size: 28,
                    ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    playlist.title,
                    style: AppTheme.bodyLarge.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'by ${playlist.creatorName ?? 'TIDAL'}',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.secondaryColor,
                    ),
                  ),
                  Text(
                    playlist.trackCount == 0 
                        ? 'NO ITEMS' 
                        : '${playlist.trackCount} ${playlist.trackCount == 1 ? 'TRACK' : 'TRACKS'}',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.secondaryColor,
                      fontSize: 11,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            // 3-dot menu
            IconButton(
              icon: const Icon(Icons.more_horiz, color: AppTheme.secondaryColor),
              onPressed: () => PlaylistOptionsSheet.show(context, playlist),
            ),
          ],
        ),
      ),
    );
  }
}

/// Local playlist detail screen
class _LocalPlaylistDetailScreen extends StatelessWidget {
  final LocalPlaylist playlist;
  final List<Track> tracks;
  final VoidCallback onRefresh;

  const _LocalPlaylistDetailScreen({
    required this.playlist,
    required this.tracks,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
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
          playlist.name,
          style: AppTheme.titleLarge.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      body: tracks.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.queue_music_outlined,
                    size: 64,
                    color: Colors.white.withOpacity(0.4),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No tracks yet',
                    style: AppTheme.titleMedium.copyWith(
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add tracks from the track options menu',
                    style: AppTheme.bodyMedium.copyWith(
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: tracks.length,
              itemBuilder: (context, index) {
                final track = tracks[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: track.coverArtUrl != null
                        ? CachedNetworkImage(
                            imageUrl: track.coverArtUrl!,
                            fit: BoxFit.cover,
                          )
                        : const Icon(Icons.music_note, color: AppTheme.secondaryColor),
                  ),
                  title: Text(
                    track.title,
                    style: AppTheme.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    track.artist,
                    style: AppTheme.bodySmall.copyWith(color: AppTheme.secondaryColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              },
            ),
    );
  }
}
