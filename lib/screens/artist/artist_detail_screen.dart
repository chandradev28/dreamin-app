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

final artistFallbackByNameProvider =
    FutureProvider.family<ArtistDetail?, String>((ref, artistName) async {
  final musicService = ref.watch(musicServiceProvider);
  final cleaned = artistName.trim();
  if (cleaned.isEmpty) {
    return null;
  }

  try {
    final results = await musicService.searchArtists(cleaned, limit: 8);
    if (results.isEmpty) {
      return null;
    }

    String normalize(String value) =>
        value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();

    final target = normalize(cleaned);
    final bestMatch = results.firstWhere(
      (artist) => normalize(artist.name) == target,
      orElse: () => results.first,
    );

    return await musicService.getArtist(bestMatch.id);
  } catch (_) {
    return null;
  }
});

class _ArtistDiscographyGroups {
  final List<Album> albums;
  final List<Album> epsSingles;
  final List<Album> liveAlbums;
  final List<Album> compilations;
  final List<Album> others;
  final List<Album> otherVersions;

  const _ArtistDiscographyGroups({
    this.albums = const [],
    this.epsSingles = const [],
    this.liveAlbums = const [],
    this.compilations = const [],
    this.others = const [],
    this.otherVersions = const [],
  });
}

final artistPageExtrasProvider =
    FutureProvider.family<_ArtistPageExtras, _ArtistExtrasArgs>((
  ref,
  args,
) async {
  final musicService = ref.watch(musicServiceProvider);
  final lastFmService = ref.watch(lastFmServiceProvider);

  final results = await Future.wait<dynamic>([
    lastFmService.getArtistInfo(args.artistName),
    musicService.searchPlaylists(args.artistName, limit: 12),
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
  final seenArtistIds = <String>{};
  for (final item in (results[2] as List).take(8)) {
    try {
      final lastFmArtist = item;
      final searchResults = await musicService
          .searchArtists(lastFmArtist.name as String, limit: 3);
      if (searchResults.isNotEmpty) {
        final bestMatch = searchResults.first;
        if (seenArtistIds.add(bestMatch.id)) {
          similar.add(bestMatch);
        }
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
    final fallbackArtistDetail = artist != null
        ? ref.watch(artistFallbackByNameProvider(artist!.name))
        : const AsyncValue<ArtistDetail?>.data(null);

    return ScaffoldWithMiniPlayer(
      body: artistDetail.when(
        loading: () => _buildLoadingState(context, responsive),
        error: (error, _) =>
            _buildErrorState(context, error.toString(), responsive),
        data: (data) {
          if (data == null) {
            return fallbackArtistDetail.when(
              loading: () => _buildLoadingState(context, responsive),
              error: (_, __) =>
                  _buildErrorState(context, 'Artist not found', responsive),
              data: (fallback) {
                if (fallback == null) {
                  return _buildErrorState(
                      context, 'Artist not found', responsive);
                }
                return _buildContent(context, ref, fallback, responsive);
              },
            );
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
    final discography = _buildDiscographyGroups(artistDetail.albums);
    final topTracks = artistDetail.topTracks.take(30).toList();
    final bioText = _cleanBio(
      artistDetail.bio?.isNotEmpty == true
          ? artistDetail.bio
          : extrasAsync.valueOrNull?.bioSummary,
    );
    final playlists = _mergePlaylists(
      artistDetail.playlists,
      extrasAsync.valueOrNull?.playlists ?? const [],
    );
    final relatedArtists = _mergeArtists(
      artistDetail.relatedArtists,
      extrasAsync.valueOrNull?.similarArtists ?? const [],
      currentArtistId: artistDetail.id,
      currentArtistName: artistDetail.name,
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
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
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
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
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
          ..._buildAlbumRailSection(
            context,
            title: 'Albums',
            viewAllTitle: 'Albums by ${artistDetail.name}',
            albums: discography.albums,
          ),
          ..._buildAlbumRailSection(
            context,
            title: 'EP & Singles',
            viewAllTitle: 'EPs & Singles by ${artistDetail.name}',
            albums: discography.epsSingles,
          ),
          ..._buildAlbumRailSection(
            context,
            title: 'Live Albums',
            viewAllTitle: 'Live Albums by ${artistDetail.name}',
            albums: discography.liveAlbums,
          ),
          ..._buildAlbumRailSection(
            context,
            title: 'Compilations',
            viewAllTitle: 'Compilations by ${artistDetail.name}',
            albums: discography.compilations,
            railHeight: 218,
          ),
          ..._buildAlbumRailSection(
            context,
            title: 'Others',
            viewAllTitle: 'Other Releases by ${artistDetail.name}',
            albums: discography.others,
          ),
          ..._buildAlbumRailSection(
            context,
            title: 'Other Versions',
            viewAllTitle: 'Other Versions by ${artistDetail.name}',
            albums: discography.otherVersions,
          ),
          ..._buildPlaylistRailSection(
            context,
            title: 'Playlists',
            viewAllTitle: 'Playlists for ${artistDetail.name}',
            playlists: playlists,
          ),
          ..._buildArtistRailSection(
            context,
            title: 'Related Artists',
            viewAllTitle: 'Related Artists',
            artists: relatedArtists,
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
                child: const Row(
                  children: [
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

  List<Widget> _buildAlbumRailSection(
    BuildContext context, {
    required String title,
    required String viewAllTitle,
    required List<Album> albums,
    double railHeight = 224,
  }) {
    if (albums.isEmpty) {
      return const [];
    }

    return [
      _buildSectionHeader(
        context,
        title,
        onSeeAll: albums.length > 4
            ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ViewAllScreen(
                      title: viewAllTitle,
                      albums: albums,
                    ),
                  ),
                );
              }
            : null,
      ),
      SliverToBoxAdapter(
        child: SizedBox(
          height: railHeight,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: albums.length.clamp(0, 10),
            itemBuilder: (context, index) {
              final album = albums[index];
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: _AlbumCard(
                  album: album,
                  subtitle: album.year?.toString(),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AlbumDetailScreen(albumId: album.id),
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
    ];
  }

  List<Widget> _buildPlaylistRailSection(
    BuildContext context, {
    required String title,
    required String viewAllTitle,
    required List<Playlist> playlists,
  }) {
    if (playlists.isEmpty) {
      return const [];
    }

    return [
      _buildSectionHeader(
        context,
        title,
        onSeeAll: playlists.length > 4
            ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ViewAllScreen(
                      title: viewAllTitle,
                      playlists: playlists,
                    ),
                  ),
                );
              }
            : null,
      ),
      SliverToBoxAdapter(
        child: SizedBox(
          height: 236,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: playlists.length.clamp(0, 10),
            itemBuilder: (context, index) {
              final playlist = playlists[index];
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
    ];
  }

  List<Widget> _buildArtistRailSection(
    BuildContext context, {
    required String title,
    required String viewAllTitle,
    required List<Artist> artists,
  }) {
    if (artists.isEmpty) {
      return const [];
    }

    return [
      _buildSectionHeader(
        context,
        title,
        onSeeAll: artists.length > 4
            ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ViewAllScreen(
                      title: viewAllTitle,
                      artists: artists,
                    ),
                  ),
                );
              }
            : null,
      ),
      SliverToBoxAdapter(
        child: SizedBox(
          height: 214,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: artists.length.clamp(0, 10),
            itemBuilder: (context, index) {
              final relatedArtist = artists[index];
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: _ArtistCard(
                  artist: relatedArtist,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ArtistDetailScreen(
                          artistId: relatedArtist.id,
                          artist: relatedArtist,
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
    ];
  }

  _ArtistDiscographyGroups _buildDiscographyGroups(List<Album> albums) {
    final uniqueAlbums = <Album>[];
    final seenKeys = <String>{};
    for (final album in albums) {
      final key = album.id.isNotEmpty
          ? album.id
          : '${album.title}|${album.artist}|${album.year}|${album.albumType.name}';
      if (seenKeys.add(key)) {
        uniqueAlbums.add(album);
      }
    }

    final albumReleases = <Album>[];
    final epsSingles = <Album>[];
    final liveAlbums = <Album>[];
    final compilations = <Album>[];
    final others = <Album>[];
    final versionFamilies = <String, List<Album>>{};

    for (final album in uniqueAlbums) {
      switch (album.albumType) {
        case AlbumType.ep:
        case AlbumType.single:
          epsSingles.add(album);
          break;
        case AlbumType.live:
          liveAlbums.add(album);
          break;
        case AlbumType.compilation:
          compilations.add(album);
          break;
        case AlbumType.other:
          others.add(album);
          break;
        case AlbumType.album:
          albumReleases.add(album);
          break;
      }

      if (album.albumType != AlbumType.live) {
        final normalizedTitle = _normalizedAlbumTitle(album.title);
        if (normalizedTitle.isNotEmpty) {
          versionFamilies.putIfAbsent(normalizedTitle, () => []).add(album);
        }
      }
    }

    final otherVersions = <Album>[];
    final seenVersionIds = <String>{};
    for (final family in versionFamilies.values) {
      if (family.length < 2) {
        continue;
      }

      final sortedFamily = List<Album>.from(family)
        ..sort((a, b) {
          final priorityCompare =
              _albumVersionPriority(a).compareTo(_albumVersionPriority(b));
          if (priorityCompare != 0) {
            return priorityCompare;
          }

          final yearA = a.year ?? 9999;
          final yearB = b.year ?? 9999;
          if (yearA != yearB) {
            return yearA.compareTo(yearB);
          }

          return a.title.toLowerCase().compareTo(b.title.toLowerCase());
        });

      for (final version in sortedFamily.skip(1)) {
        if (seenVersionIds.add(version.id)) {
          otherVersions.add(version);
        }
      }
    }

    return _ArtistDiscographyGroups(
      albums: albumReleases,
      epsSingles: epsSingles,
      liveAlbums: liveAlbums,
      compilations: compilations,
      others: others,
      otherVersions: otherVersions,
    );
  }

  List<Playlist> _mergePlaylists(
    List<Playlist> primary,
    List<Playlist> secondary,
  ) {
    final merged = <Playlist>[];
    final seenIds = <String>{};
    for (final playlist in [...primary, ...secondary]) {
      if (playlist.id.isEmpty) {
        continue;
      }
      if (seenIds.add(playlist.id)) {
        merged.add(playlist);
      }
    }
    return merged;
  }

  List<Artist> _mergeArtists(
    List<Artist> primary,
    List<Artist> secondary, {
    required String currentArtistId,
    required String currentArtistName,
  }) {
    final merged = <Artist>[];
    final seenIds = <String>{currentArtistId};
    final seenNames = <String>{_normalizedArtistName(currentArtistName)};

    for (final artist in [...primary, ...secondary]) {
      final normalizedName = _normalizedArtistName(artist.name);
      if (artist.id.isNotEmpty && !seenIds.add(artist.id)) {
        continue;
      }
      if (normalizedName.isNotEmpty && !seenNames.add(normalizedName)) {
        continue;
      }
      merged.add(artist);
    }

    return merged;
  }

  String _normalizedAlbumTitle(String title) {
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

  int _albumVersionPriority(Album album) {
    final title = album.title.toLowerCase();
    if (RegExp(
      r'\b(deluxe|expanded|anniversary|collector|super deluxe|box set)\b',
    ).hasMatch(title)) {
      return 2;
    }
    if (RegExp(
      r'\b(remaster(ed)?|edition|version|mono|stereo|mix)\b',
    ).hasMatch(title)) {
      return 1;
    }
    if (title.contains('(') || title.contains('[')) {
      return 1;
    }
    return 0;
  }

  String _normalizedArtistName(String name) {
    return name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
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
  static const double _cardWidth = 156;
  static const double _coverSize = 156;

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
        width: _cardWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Album Cover
            Container(
              width: _coverSize,
              height: _coverSize,
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
    final fallbackCreator = switch (playlist.source) {
      MusicSource.qobuz => 'by Qobuz',
      MusicSource.subsonic => 'Playlist',
      MusicSource.tidal => 'by TIDAL',
    };

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
                  ? fallbackCreator
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
  static const double _cardWidth = 132;
  static const double _imageSize = 132;

  const _ArtistCard({
    required this.artist,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: _cardWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: _imageSize,
              height: _imageSize,
              decoration: const BoxDecoration(
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
