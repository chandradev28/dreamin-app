import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import '../../widgets/artist_options_sheet.dart';
import '../../widgets/track_options_sheet.dart';
import '../album/album_detail_screen.dart';
import '../album/view_all_screen.dart';
import '../playlist/playlist_detail_screen.dart';
import '../scaffold_with_mini_player.dart';
import 'top_tracks_view_all_screen.dart';

class _ArtistExtrasArgs {
  final String artistId;
  final String artistName;

  const _ArtistExtrasArgs({
    required this.artistId,
    required this.artistName,
  });

  @override
  bool operator ==(Object other) {
    return other is _ArtistExtrasArgs &&
        other.artistId == artistId &&
        other.artistName == artistName;
  }

  @override
  int get hashCode => Object.hash(artistId, artistName);
}

class _ArtistPageExtras {
  final String? bioSummary;
  final List<Playlist> playlists;
  final List<Artist> similarArtists;

  const _ArtistPageExtras({
    this.bioSummary,
    this.playlists = const [],
    this.similarArtists = const [],
  });
}

final artistPageExtrasProvider =
    FutureProvider.family<_ArtistPageExtras, _ArtistExtrasArgs>((
  ref,
  args,
) async {
  final tidalService = ref.watch(tidalServiceProvider);
  final lastFmService = ref.watch(lastFmServiceProvider);

  final results = await Future.wait<dynamic>([
    lastFmService.getArtistInfo(args.artistName),
    tidalService.searchPlaylists(args.artistName, limit: 12),
    lastFmService.getSimilarArtists(args.artistName, limit: 10),
  ]);

  final artistInfo = results[0];
  final playlists = (results[1] as List<Playlist>)
      .where((playlist) {
        final name = args.artistName.toLowerCase();
        return playlist.title.toLowerCase().contains(name) ||
            (playlist.creatorName?.toLowerCase().contains(name) ?? false) ||
            (playlist.description?.toLowerCase().contains(name) ?? false);
      })
      .take(10)
      .toList();

  final similar = <Artist>[];
  for (final item in (results[2] as List).take(8)) {
    try {
      final lastFmArtist = item;
      final searchResults = await tidalService
          .searchArtists(lastFmArtist.name as String, limit: 3);
      if (searchResults.isNotEmpty) {
        similar.add(searchResults.first);
      }
    } catch (_) {}
  }

  return _ArtistPageExtras(
    bioSummary: artistInfo?.bioSummary as String?,
    playlists: playlists,
    similarArtists: similar,
  );
});

/// Artist Detail Screen - TIDAL Style Design
/// Sections: Header, Top Tracks (30), Albums, EP & Singles, Live Albums, Playlists
class ArtistDetailScreen extends ConsumerWidget {
  final String artistId;
  final Artist? artist;

  const ArtistDetailScreen({
    super.key,
    required this.artistId,
    this.artist,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final responsive = Responsive(context);
    final artistDetail = ref.watch(artistDetailProvider(artistId));

    return ScaffoldWithMiniPlayer(
      body: artistDetail.when(
        loading: () => _buildLoadingState(context, responsive),
        error: (error, _) =>
            _buildErrorState(context, error.toString(), responsive),
        data: (data) {
          if (data == null) {
            return _buildErrorState(context, 'Artist not found', responsive);
          }
          return _buildContent(context, ref, data, responsive);
        },
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context, Responsive responsive) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryColor),
      ),
    );
  }

  Widget _buildErrorState(
      BuildContext context, String error, Responsive responsive) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline,
                color: AppTheme.secondaryColor, size: 48),
            const SizedBox(height: 16),
            Text('Failed to load artist',
                style: AppTheme.titleMedium.copyWith(color: Colors.white)),
            const SizedBox(height: 8),
            Text(error,
                style:
                    AppTheme.bodySmall.copyWith(color: AppTheme.secondaryColor),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    ArtistDetail artistDetail,
    Responsive responsive,
  ) {
    final playerState = ref.watch(playerProvider);
    final extrasAsync = ref.watch(
      artistPageExtrasProvider(
        _ArtistExtrasArgs(
          artistId: artistDetail.id,
          artistName: artistDetail.name,
        ),
      ),
    );
    final albums = artistDetail.albums
        .where((a) => a.albumType == AlbumType.album)
        .toList();
    final epsSingles = artistDetail.albums
        .where(
          (a) => a.albumType == AlbumType.ep || a.albumType == AlbumType.single,
        )
        .toList();
    final compilations = artistDetail.albums
        .where((a) => a.albumType == AlbumType.compilation)
        .toList();
    final liveAlbums = artistDetail.albums
        .where((a) => a.albumType == AlbumType.live)
        .toList();
    final topTracks = artistDetail.topTracks.take(30).toList();
    final bioText = _cleanBio(
      artistDetail.bio?.isNotEmpty == true
          ? artistDetail.bio
          : extrasAsync.valueOrNull?.bioSummary,
    );
    final artistSummary = Artist(
      id: artistDetail.id,
      name: artistDetail.name,
      imageUrl: artistDetail.imageUrl,
      albumCount: artistDetail.albumCount,
      source: artistDetail.source,
      bio: artistDetail.bio,
    );
    final isSavedArtist = ref.watch(isArtistSavedProvider(artistDetail.id));

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: CustomScrollView(
        slivers: [
          _buildHeroHeader(context, artistDetail, bioText, artistSummary),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                responsive.horizontalPadding,
                18,
                responsive.horizontalPadding,
                0,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: topTracks.isNotEmpty
                              ? () {
                                  ref.read(playerProvider.notifier).playQueue(
                                        topTracks,
                                        startIndex: 0,
                                        source: 'Artist: ${artistDetail.name}',
                                      );
                                }
                              : null,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(
                                color: Colors.white, width: 1.1),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.play_arrow, size: 22),
                              SizedBox(width: 6),
                              Text('Play',
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: topTracks.isNotEmpty
                              ? () {
                                  final shuffled = List<Track>.from(topTracks)
                                    ..shuffle();
                                  ref.read(playerProvider.notifier).playQueue(
                                        shuffled,
                                        startIndex: 0,
                                        source:
                                            'Artist: ${artistDetail.name} (Shuffled)',
                                      );
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.shuffle, size: 20),
                              SizedBox(width: 6),
                              Text('Shuffle',
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _ActionIconButton(
                        icon: Icons.radio,
                        label: 'Radio',
                        onTap: () {},
                      ),
                      const SizedBox(width: 36),
                      _ActionIconButton(
                        icon: Icons.add,
                        label: isSavedArtist ? 'Following' : 'Follow',
                        isActive: isSavedArtist,
                        onTap: () {
                          ref
                              .read(savedArtistsProvider.notifier)
                              .toggleArtist(artistSummary);
                        },
                      ),
                      const SizedBox(width: 36),
                      _ActionIconButton(
                        icon: Icons.share_outlined,
                        label: 'Share',
                        onTap: () {},
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 28)),
          if (topTracks.isNotEmpty) ...[
            _buildSectionHeader(
              context,
              'Top Tracks',
              onSeeAll: topTracks.length > 5
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TopTracksViewAllScreen(
                            title: 'Top Tracks',
                            artistName: artistDetail.name,
                            tracks: topTracks,
                          ),
                        ),
                      );
                    }
                  : null,
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final track = topTracks[index];
                  final isPlaying = playerState.currentTrack?.id == track.id;

                  return _TrackTile(
                    track: track,
                    index: index + 1,
                    isPlaying: isPlaying,
                    onTap: () {
                      ref.read(playerProvider.notifier).playQueue(
                            topTracks,
                            startIndex: index,
                            source: 'Artist: ${artistDetail.name}',
                          );
                    },
                    onMoreTap: () {
                      TrackOptionsSheet.show(context, track);
                    },
                  );
                },
                childCount: topTracks.length
                    .clamp(0, 5), // Show only 5, See All for more
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
          if (albums.isNotEmpty) ...[
            _buildSectionHeader(
              context,
              'Albums',
              onSeeAll: albums.length > 4
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ViewAllScreen(
                            title: 'Albums by ${artistDetail.name}',
                            albums: albums,
                          ),
                        ),
                      );
                    }
                  : null,
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: albums.length.clamp(0, 10),
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: _AlbumCard(
                        album: albums[index],
                        subtitle: albums[index].year?.toString(),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  AlbumDetailScreen(albumId: albums[index].id),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
          if (epsSingles.isNotEmpty) ...[
            _buildSectionHeader(
              context,
              'EP & Singles',
              onSeeAll: epsSingles.length > 4
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ViewAllScreen(
                            title: 'EPs & Singles by ${artistDetail.name}',
                            albums: epsSingles,
                          ),
                        ),
                      );
                    }
                  : null,
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: epsSingles.length.clamp(0, 10),
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: _AlbumCard(
                        album: epsSingles[index],
                        subtitle: epsSingles[index].year?.toString(),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AlbumDetailScreen(
                                  albumId: epsSingles[index].id),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
          if (compilations.isNotEmpty) ...[
            _buildSectionHeader(
              context,
              'Compilations',
              onSeeAll: compilations.length > 4
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ViewAllScreen(
                            title: 'Compilations by ${artistDetail.name}',
                            albums: compilations,
                          ),
                        ),
                      );
                    }
                  : null,
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 218,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: compilations.length.clamp(0, 10),
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: _AlbumCard(
                        album: compilations[index],
                        subtitle: compilations[index].year?.toString(),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AlbumDetailScreen(
                                albumId: compilations[index].id,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
          if (liveAlbums.isNotEmpty) ...[
            _buildSectionHeader(
              context,
              'Live Albums',
              onSeeAll: liveAlbums.length > 4
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ViewAllScreen(
                            title: 'Live Albums by ${artistDetail.name}',
                            albums: liveAlbums,
                          ),
                        ),
                      );
                    }
                  : null,
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: liveAlbums.length.clamp(0, 10),
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: _AlbumCard(
                        album: liveAlbums[index],
                        subtitle: liveAlbums[index].year?.toString(),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AlbumDetailScreen(
                                  albumId: liveAlbums[index].id),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
          extrasAsync.when(
            data: (extras) {
              if (extras.playlists.isEmpty) {
                return const SliverToBoxAdapter(child: SizedBox.shrink());
              }

              return SliverMainAxisGroup(
                slivers: [
                  _buildSectionHeader(
                    context,
                    'Playlists',
                    onSeeAll: extras.playlists.length > 4
                        ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ViewAllScreen(
                                  title: 'Playlists for ${artistDetail.name}',
                                  playlists: extras.playlists,
                                ),
                              ),
                            );
                          }
                        : null,
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 218,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: extras.playlists.length.clamp(0, 10),
                        itemBuilder: (context, index) {
                          final playlist = extras.playlists[index];
                          return Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: _PlaylistCard(
                              playlist: playlist,
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
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              );
            },
            loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
            error: (_, __) =>
                const SliverToBoxAdapter(child: SizedBox.shrink()),
          ),
          extrasAsync.when(
            data: (extras) {
              if (extras.similarArtists.isEmpty) {
                return const SliverToBoxAdapter(child: SizedBox.shrink());
              }

              return SliverMainAxisGroup(
                slivers: [
                  _buildSectionHeader(
                    context,
                    'Fans Also Like',
                    onSeeAll: extras.similarArtists.length > 4
                        ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ViewAllScreen(
                                  title: 'Fans Also Like',
                                  artists: extras.similarArtists,
                                ),
                              ),
                            );
                          }
                        : null,
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 190,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: extras.similarArtists.length.clamp(0, 10),
                        itemBuilder: (context, index) {
                          final similarArtist = extras.similarArtists[index];
                          return Padding(
                            padding: const EdgeInsets.only(right: 16),
                            child: _ArtistCard(
                              artist: similarArtist,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ArtistDetailScreen(
                                      artistId: similarArtist.id,
                                      artist: similarArtist,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              );
            },
            loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
            error: (_, __) =>
                const SliverToBoxAdapter(child: SizedBox.shrink()),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height:
                  responsive.miniPlayerHeight + responsive.bottomNavHeight + 28,
            ),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildHeroHeader(
    BuildContext context,
    ArtistDetail artistDetail,
    String? bioText,
    Artist artistSummary,
  ) {
    return SliverAppBar(
      backgroundColor: AppTheme.backgroundColor,
      elevation: 0,
      pinned: true,
      expandedHeight: 360,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search, color: Colors.white),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onPressed: () => ArtistOptionsSheet.show(context, artistSummary),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        title: Text(
          artistDetail.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            artistDetail.imageUrl != null
                ? CachedNetworkImage(
                    imageUrl: artistDetail.imageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (_, __) =>
                        _buildAvatarPlaceholder(artistDetail.name),
                    errorWidget: (_, __, ___) =>
                        _buildAvatarPlaceholder(artistDetail.name),
                  )
                : _buildAvatarPlaceholder(artistDetail.name),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.08),
                    Colors.black.withOpacity(0.28),
                    Colors.black.withOpacity(0.88),
                    AppTheme.backgroundColor,
                  ],
                  stops: const [0.0, 0.35, 0.72, 1.0],
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 58,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    artistDetail.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${artistDetail.albumCount ?? artistDetail.albums.length} albums',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (bioText != null && bioText.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      bioText,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarPlaceholder(String name) {
    return Container(
      color: AppTheme.surfaceLight,
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(
            color: AppTheme.primaryColor,
            fontSize: 60,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  String? _cleanBio(String? text) {
    if (text == null || text.trim().isEmpty) {
      return null;
    }

    final withoutHtml = text.replaceAll(RegExp(r'<[^>]*>'), ' ');
    final normalized = withoutHtml.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.isEmpty) {
      return null;
    }
    return normalized;
  }

  SliverToBoxAdapter _buildSectionHeader(
    BuildContext context,
    String title, {
    VoidCallback? onSeeAll,
  }) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (onSeeAll != null)
              GestureDetector(
                onTap: onSeeAll,
                child: Row(
                  children: const [
                    Icon(Icons.chevron_right,
                        color: AppTheme.secondaryColor, size: 24),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// WIDGETS
// ============================================================================

/// Action Icon Button (Radio, Follow, Share)
class _ActionIconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isActive;

  const _ActionIconButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppTheme.primaryColor : Colors.white;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

/// Track Tile for Top Tracks list
class _TrackTile extends StatelessWidget {
  final Track track;
  final int index;
  final bool isPlaying;
  final VoidCallback onTap;
  final VoidCallback onMoreTap;

  const _TrackTile({
    required this.track,
    required this.index,
    required this.isPlaying,
    required this.onTap,
    required this.onMoreTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: SizedBox(
          width: 48,
          height: 48,
          child: track.coverArtUrl != null
              ? CachedNetworkImage(
                  imageUrl: track.coverArtUrl!,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    color: AppTheme.surfaceColor,
                    child: const Icon(Icons.music_note,
                        color: AppTheme.secondaryColor, size: 20),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    color: AppTheme.surfaceColor,
                    child: const Icon(Icons.music_note,
                        color: AppTheme.secondaryColor, size: 20),
                  ),
                )
              : Container(
                  color: AppTheme.surfaceColor,
                  child: const Icon(Icons.music_note,
                      color: AppTheme.secondaryColor, size: 20),
                ),
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              track.title,
              style: TextStyle(
                color: isPlaying ? AppTheme.primaryColor : Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (track.isExplicit)
            Container(
              margin: const EdgeInsets.only(left: 6),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.grey.shade700,
                borderRadius: BorderRadius.circular(2),
              ),
              child: const Text(
                'E',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      subtitle: Text(
        track.artist,
        style: const TextStyle(color: AppTheme.secondaryColor, fontSize: 13),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: GestureDetector(
        onTap: onMoreTap,
        child: const Padding(
          padding: EdgeInsets.all(8),
          child:
              Icon(Icons.more_vert, color: AppTheme.secondaryColor, size: 22),
        ),
      ),
    );
  }
}

/// Album Card for horizontal scroll
class _AlbumCard extends StatelessWidget {
  final Album album;
  final String? subtitle;
  final VoidCallback onTap;

  const _AlbumCard({
    required this.album,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 140,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Album Cover
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: AppTheme.surfaceColor,
              ),
              clipBehavior: Clip.antiAlias,
              child: album.coverArtUrl != null
                  ? CachedNetworkImage(
                      imageUrl: album.coverArtUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => const Center(
                        child: Icon(Icons.album,
                            color: AppTheme.secondaryColor, size: 40),
                      ),
                      errorWidget: (_, __, ___) => const Center(
                        child: Icon(Icons.album,
                            color: AppTheme.secondaryColor, size: 40),
                      ),
                    )
                  : const Center(
                      child: Icon(Icons.album,
                          color: AppTheme.secondaryColor, size: 40),
                    ),
            ),

            const SizedBox(height: 8),

            // Album Title
            Text(
              album.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 2),

            Text(
              subtitle ?? album.artist,
              style: const TextStyle(
                color: AppTheme.secondaryColor,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaylistCard extends StatelessWidget {
  final Playlist playlist;
  final VoidCallback onTap;

  const _PlaylistCard({
    required this.playlist,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 140,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: AppTheme.surfaceColor,
              ),
              clipBehavior: Clip.antiAlias,
              child: playlist.coverArtUrl != null
                  ? CachedNetworkImage(
                      imageUrl: playlist.coverArtUrl!,
                      fit: BoxFit.cover,
                    )
                  : const Center(
                      child: Icon(
                        Icons.queue_music,
                        color: AppTheme.secondaryColor,
                        size: 36,
                      ),
                    ),
            ),
            const SizedBox(height: 8),
            Text(
              playlist.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              playlist.creatorName == null || playlist.creatorName!.isEmpty
                  ? 'by TIDAL'
                  : 'by ${playlist.creatorName}',
              style: const TextStyle(
                color: AppTheme.secondaryColor,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _ArtistCard extends StatelessWidget {
  final Artist artist;
  final VoidCallback onTap;

  const _ArtistCard({
    required this.artist,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 120,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.surfaceColor,
              ),
              clipBehavior: Clip.antiAlias,
              child: artist.imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: artist.imageUrl!,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color: AppTheme.surfaceLight,
                      child: Center(
                        child: Text(
                          artist.name.isNotEmpty
                              ? artist.name[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 10),
            Text(
              artist.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
