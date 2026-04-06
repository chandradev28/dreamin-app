import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import '../../widgets/track_options_sheet.dart';
import '../../widgets/album_options_sheet.dart';
import '../album/album_detail_screen.dart';
import '../playlist/playlist_detail_screen.dart';
import '../artist/artist_detail_screen.dart';
import '../scaffold_with_mini_player.dart';

/// Search All Results Screen - TIDAL Style
/// Tabs: Top Results, Albums, Tracks, Playlists
class SearchAllResultsScreen extends ConsumerStatefulWidget {
  final String query;
  final SearchResult result;

  const SearchAllResultsScreen({
    super.key,
    required this.query,
    required this.result,
  });

  @override
  ConsumerState<SearchAllResultsScreen> createState() =>
      _SearchAllResultsScreenState();
}

class _SearchAllResultsScreenState extends ConsumerState<SearchAllResultsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.search,
                  color: AppTheme.secondaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                widget.query,
                style: AppTheme.bodyLarge,
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.close,
                    color: AppTheme.secondaryColor, size: 18),
              ),
            ],
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          padding: EdgeInsets.zero,
          labelColor: Colors.white,
          unselectedLabelColor: AppTheme.secondaryColor,
          indicatorColor: Colors.white,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          unselectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          labelPadding: const EdgeInsets.symmetric(horizontal: 16),
          tabs: const [
            Tab(text: 'Top results'),
            Tab(text: 'Albums'),
            Tab(text: 'Tracks'),
            Tab(text: 'Playlists'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTopResultsTab(responsive),
          _buildAlbumsTab(responsive),
          _buildTracksTab(responsive),
          _buildPlaylistsTab(responsive),
        ],
      ),
    );
  }

  // TOP RESULTS TAB - Mixed: Artist + Albums + Tracks
  Widget _buildTopResultsTab(Responsive responsive) {
    return ListView(
      padding: EdgeInsets.only(
        top: 8,
        bottom: responsive.miniPlayerHeight + responsive.bottomNavHeight + 20,
      ),
      children: [
        // Artist at top
        if (widget.result.artists.isNotEmpty) ...[
          _ArtistCard(
            artist: widget.result.artists.first,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ArtistDetailScreen(
                  artistId: widget.result.artists.first.id,
                  artist: widget.result.artists.first,
                ),
              ),
            ),
          ),
        ],

        // Albums section
        if (widget.result.albums.isNotEmpty) ...[
          _buildSectionHeader('Albums'),
          ...widget.result.albums.take(3).map((album) => _AlbumTile(
                album: album,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        AlbumDetailScreen(albumId: album.id, album: album),
                  ),
                ),
              )),
        ],

        // Tracks section
        if (widget.result.tracks.isNotEmpty) ...[
          _buildSectionHeader('Tracks'),
          ...widget.result.tracks.take(4).map((track) => _TrackTile(
                track: track,
                onTap: () => ref.read(playerProvider.notifier).playQueue(
                      widget.result.tracks,
                      startIndex: widget.result.tracks.indexOf(track),
                    ),
              )),
        ],
      ],
    );
  }

  // ALBUMS TAB - All albums in grid
  Widget _buildAlbumsTab(Responsive responsive) {
    if (widget.result.albums.isEmpty) {
      return const Center(
          child: Text('No albums found',
              style: TextStyle(color: AppTheme.secondaryColor)));
    }

    return GridView.builder(
      padding: EdgeInsets.all(responsive.horizontalPadding),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: widget.result.albums.length,
      itemBuilder: (context, index) {
        final album = widget.result.albums[index];
        return _AlbumGridCard(
          album: album,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  AlbumDetailScreen(albumId: album.id, album: album),
            ),
          ),
        );
      },
    );
  }

  // TRACKS TAB - Top 50 tracks max
  Widget _buildTracksTab(Responsive responsive) {
    if (widget.result.tracks.isEmpty) {
      return const Center(
          child: Text('No tracks found',
              style: TextStyle(color: AppTheme.secondaryColor)));
    }

    final tracks = widget.result.tracks.take(50).toList();

    return ListView.builder(
      padding: EdgeInsets.only(
        top: 8,
        bottom: responsive.miniPlayerHeight + responsive.bottomNavHeight + 20,
      ),
      itemCount: tracks.length,
      itemBuilder: (context, index) {
        final track = tracks[index];
        return _TrackTile(
          track: track,
          onTap: () => ref.read(playerProvider.notifier).playQueue(
                tracks,
                startIndex: index,
              ),
        );
      },
    );
  }

  // PLAYLISTS TAB - All playlists
  Widget _buildPlaylistsTab(Responsive responsive) {
    if (widget.result.playlists.isEmpty) {
      return const Center(
          child: Text('No playlists found',
              style: TextStyle(color: AppTheme.secondaryColor)));
    }

    return ListView.builder(
      padding: EdgeInsets.only(
        top: 8,
        bottom: responsive.miniPlayerHeight + responsive.bottomNavHeight + 20,
      ),
      itemCount: widget.result.playlists.length,
      itemBuilder: (context, index) {
        final playlist = widget.result.playlists[index];
        return _PlaylistTile(
          playlist: playlist,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PlaylistDetailScreen(
                  playlistId: playlist.id, playlist: playlist),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(title, style: AppTheme.titleMedium),
    );
  }
}

// =============================================================================
// WIDGET COMPONENTS
// =============================================================================

class _ArtistCard extends StatelessWidget {
  final Artist artist;
  final VoidCallback onTap;

  const _ArtistCard({required this.artist, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppTheme.surfaceColor,
        ),
        child: ClipOval(
          child: artist.imageUrl != null
              ? CachedNetworkImage(
                  imageUrl: artist.imageUrl!, fit: BoxFit.cover)
              : Center(
                  child: Text(
                    artist.name.isNotEmpty ? artist.name[0].toUpperCase() : '?',
                    style: AppTheme.titleLarge,
                  ),
                ),
        ),
      ),
      title: Text(artist.name, style: AppTheme.titleMedium),
      trailing: const Icon(Icons.more_vert, color: AppTheme.secondaryColor),
    );
  }
}

class _AlbumTile extends StatelessWidget {
  final Album album;
  final VoidCallback onTap;

  const _AlbumTile({required this.album, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: album.coverArtUrl != null
            ? CachedNetworkImage(
                imageUrl: album.coverArtUrl!,
                width: 56,
                height: 56,
                fit: BoxFit.cover)
            : Container(
                width: 56,
                height: 56,
                color: AppTheme.surfaceColor,
                child: const Icon(Icons.album, color: AppTheme.secondaryColor)),
      ),
      title: Text(album.title,
          style: AppTheme.bodyLarge,
          maxLines: 1,
          overflow: TextOverflow.ellipsis),
      subtitle: Text(
        'Album by ${album.artist}${album.year != null ? ' • ${album.year}' : ''}',
        style: AppTheme.bodySmall.copyWith(color: AppTheme.secondaryColor),
        maxLines: 1,
      ),
      trailing: GestureDetector(
        onTap: () => AlbumOptionsSheet.show(context, album),
        child: const Icon(Icons.more_vert, color: AppTheme.secondaryColor),
      ),
    );
  }
}

class _AlbumGridCard extends StatelessWidget {
  final Album album;
  final VoidCallback onTap;

  const _AlbumGridCard({required this.album, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: album.coverArtUrl != null
                  ? CachedNetworkImage(
                      imageUrl: album.coverArtUrl!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    )
                  : Container(
                      color: AppTheme.surfaceColor,
                      child: const Icon(Icons.album,
                          size: 48, color: AppTheme.secondaryColor),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Text(album.title,
              style: AppTheme.bodyMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          Text(
            'Album by ${album.artist}${album.year != null ? ' • ${album.year}' : ''}',
            style: AppTheme.bodySmall.copyWith(color: AppTheme.secondaryColor),
            maxLines: 1,
          ),
        ],
      ),
    );
  }
}

class _TrackTile extends StatelessWidget {
  final Track track;
  final VoidCallback onTap;

  const _TrackTile({required this.track, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: track.coverArtUrl != null
            ? CachedNetworkImage(
                imageUrl: track.coverArtUrl!,
                width: 56,
                height: 56,
                fit: BoxFit.cover)
            : Container(
                width: 56,
                height: 56,
                color: AppTheme.surfaceColor,
                child: const Icon(Icons.music_note,
                    color: AppTheme.secondaryColor)),
      ),
      title: Text(track.title,
          style: AppTheme.bodyLarge,
          maxLines: 1,
          overflow: TextOverflow.ellipsis),
      subtitle: Text('Track by ${track.artist}',
          style: AppTheme.bodySmall.copyWith(color: AppTheme.secondaryColor),
          maxLines: 1),
      trailing: GestureDetector(
        onTap: () => TrackOptionsSheet.show(context, track),
        child: const Icon(Icons.more_vert, color: AppTheme.secondaryColor),
      ),
    );
  }
}

class _PlaylistTile extends StatelessWidget {
  final Playlist playlist;
  final VoidCallback onTap;

  const _PlaylistTile({required this.playlist, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: playlist.coverArtUrl != null
            ? CachedNetworkImage(
                imageUrl: playlist.coverArtUrl!,
                width: 56,
                height: 56,
                fit: BoxFit.cover)
            : Container(
                width: 56,
                height: 56,
                color: AppTheme.surfaceColor,
                child: const Icon(Icons.playlist_play,
                    color: AppTheme.secondaryColor)),
      ),
      title: Text(playlist.title,
          style: AppTheme.bodyLarge,
          maxLines: 1,
          overflow: TextOverflow.ellipsis),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('by ${playlist.creatorName ?? "TIDAL"}',
              style:
                  AppTheme.bodySmall.copyWith(color: AppTheme.secondaryColor),
              maxLines: 1),
          Text('${playlist.trackCount} TRACKS',
              style: AppTheme.labelSmall
                  .copyWith(color: AppTheme.tertiaryColor, letterSpacing: 0.5)),
        ],
      ),
      isThreeLine: true,
      trailing: const Icon(Icons.more_vert, color: AppTheme.secondaryColor),
    );
  }
}
