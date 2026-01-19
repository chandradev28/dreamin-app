import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/providers.dart';

/// Library Playlists Screen - TIDAL Style
class LibraryPlaylistsScreen extends ConsumerStatefulWidget {
  const LibraryPlaylistsScreen({super.key});

  @override
  ConsumerState<LibraryPlaylistsScreen> createState() => _LibraryPlaylistsScreenState();
}

class _LibraryPlaylistsScreenState extends ConsumerState<LibraryPlaylistsScreen> {
  List<dynamic> _playlists = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPlaylists();
  }

  Future<void> _loadPlaylists() async {
    final database = ref.read(databaseProvider);
    final playlists = await database.getAllPlaylists();
    if (mounted) {
      setState(() {
        _playlists = playlists;
        _isLoading = false;
      });
    }
  }

  Future<void> _createNewPlaylist() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: Text('Create new playlist', style: AppTheme.titleLarge),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: AppTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: 'Playlist name',
            hintStyle: AppTheme.bodyLarge.copyWith(color: AppTheme.secondaryColor),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppTheme.secondaryColor),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppTheme.primaryColor),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: AppTheme.secondaryColor)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text('Create', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      final database = ref.read(databaseProvider);
      await database.createPlaylist(result);
      _loadPlaylists();
    }
  }

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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : _playlists.isEmpty
              ? _buildEmptyState()
              : _buildPlaylistsList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Playlist icon (music note with lines)
            Icon(
              Icons.queue_music_outlined,
              size: 64,
              color: Colors.white.withOpacity(0.4),
            ),
            const SizedBox(height: 32),
            Text(
              "You haven't added any playlists yet. Tap the heart icon on any playlist to add it to your collection.",
              style: AppTheme.bodyMedium.copyWith(
                color: Colors.white.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            // Create new playlist button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _createNewPlaylist,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white, width: 1),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: Text(
                  'Create new playlist',
                  style: AppTheme.bodyLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaylistsList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _playlists.length,
      itemBuilder: (context, index) {
        final playlist = _playlists[index];
        return ListTile(
          onTap: () {
            // Navigate to local playlist detail
          },
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: _placeholderIcon(),
          ),
          title: Text(
            playlist.name as String,
            style: AppTheme.bodyLarge.copyWith(
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            'Playlist',
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.secondaryColor,
            ),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.more_horiz, color: AppTheme.secondaryColor),
            onPressed: () {},
          ),
        );
      },
    );
  }

  Widget _placeholderIcon() {
    return Container(
      width: 56,
      height: 56,
      color: AppTheme.surfaceLight,
      child: const Icon(Icons.queue_music, color: AppTheme.secondaryColor, size: 28),
    );
  }
}
