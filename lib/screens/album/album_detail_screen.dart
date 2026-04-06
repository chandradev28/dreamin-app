import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import '../../widgets/album_options_sheet.dart';
import '../../widgets/widgets.dart';
import '../artist/artist_detail_screen.dart';
import '../scaffold_with_mini_player.dart';
import 'view_all_screen.dart';

/// Album Detail Screen - TIDAL Style
/// Shows: Album header, Play/Shuffle, Track list, More Albums by Artist, Related Albums, Related Artists
class AlbumDetailScreen extends ConsumerStatefulWidget {
  final String albumId;
  final Album? album;

  const AlbumDetailScreen({
    super.key,
    required this.albumId,
    this.album,
  });

  @override
  ConsumerState<AlbumDetailScreen> createState() => _AlbumDetailScreenState();
}

class _AlbumDetailScreenState extends ConsumerState<AlbumDetailScreen> {
  List<Album> _moreAlbumsByArtist = [];
  List<Album> _liveAlbums = [];
  List<Album> _otherVersions = [];
  List<Album> _relatedAlbums = [];
  List<Artist> _relatedArtists = [];
  bool _isLoadingExtras = false;
  bool _hasLoadedExtras = false; // Prevent duplicate loads

  @override
  void initState() {
    super.initState();
  }

  Future<void> _loadExtraContent(AlbumDetail albumDetail) async {
    if (_isLoadingExtras || _hasLoadedExtras) return;
    setState(() => _isLoadingExtras = true);

    final musicService = ref.read(musicServiceProvider);
    final lastFmService = ref.read(lastFmServiceProvider);

    try {
      final sameArtistAlbums = <Album>[];
      ArtistDetail? sourceArtistDetail;
      try {
        sourceArtistDetail = await musicService.getArtist(albumDetail.artistId);
        if (sourceArtistDetail != null) {
          sameArtistAlbums.addAll(
            sourceArtistDetail.albums.where(
              (album) => _belongsToArtist(
                album,
                albumDetail.artistId,
                albumDetail.artist,
              ),
            ),
          );
        }
      } catch (_) {}

      if (sameArtistAlbums.length < 12) {
        try {
          final searchedAlbums = await musicService.searchAlbums(
            albumDetail.artist,
            limit: 50,
          );
          sameArtistAlbums.addAll(
            searchedAlbums.where(
              (album) => _belongsToArtist(
                album,
                albumDetail.artistId,
                albumDetail.artist,
              ),
            ),
          );
        } catch (_) {}
      }

      final sameArtistBuckets =
          _buildAlbumVariantBuckets(albumDetail, sameArtistAlbums);
      final moreAlbums = sameArtistBuckets.moreAlbums;
      final liveAlbums = sameArtistBuckets.liveAlbums;
      final otherVersions = sameArtistBuckets.otherVersions;

      final relatedArtists = <Artist>[];
      final relatedAlbums = <Album>[];
      final seenArtistIds = <String>{albumDetail.artistId};
      final seenRelatedAlbumIds = <String>{albumDetail.id};

      void addRelatedArtist(Artist artist) {
        if (artist.id.isEmpty ||
            seenArtistIds.contains(artist.id) ||
            _normalizeArtistName(artist.name) ==
                _normalizeArtistName(albumDetail.artist)) {
          return;
        }
        seenArtistIds.add(artist.id);
        relatedArtists.add(artist);
      }

      if (sourceArtistDetail != null) {
        for (final artist in sourceArtistDetail.relatedArtists) {
          addRelatedArtist(artist);
          if (relatedArtists.length >= 10) {
            break;
          }
        }
      }

      if (relatedArtists.isEmpty && musicService.source == MusicSource.tidal) {
        try {
          final lastFmSimilar = await lastFmService.getSimilarArtists(
            albumDetail.artist,
            limit: 12,
          );

          for (final lfmArtist in lastFmSimilar) {
            try {
              final sourceArtists =
                  await musicService.searchArtists(lfmArtist.name, limit: 5);
              final matchedArtist =
                  _pickBestArtistMatch(sourceArtists, lfmArtist.name);
              if (matchedArtist == null) {
                continue;
              }
              addRelatedArtist(matchedArtist);
              if (relatedArtists.length >= 10) {
                break;
              }
            } catch (_) {}
          }
        } catch (_) {}
      }

      for (final relatedArtist in relatedArtists) {
        if (relatedAlbums.length >= 12) {
          break;
        }
        try {
          final detail = await musicService.getArtist(relatedArtist.id);
          if (detail == null) {
            continue;
          }
          final firstAlbum = detail.albums.firstWhere(
            (album) =>
                !_belongsToArtist(
                  album,
                  albumDetail.artistId,
                  albumDetail.artist,
                ) &&
                !seenRelatedAlbumIds.contains(album.id),
            orElse: () => Album(
              id: '',
              title: '',
              artist: '',
              artistId: '',
              trackCount: 0,
              source: musicService.source,
            ),
          );
          if (firstAlbum.id.isNotEmpty) {
            seenRelatedAlbumIds.add(firstAlbum.id);
            relatedAlbums.add(firstAlbum);
          }
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _moreAlbumsByArtist = moreAlbums;
          _liveAlbums = liveAlbums;
          _otherVersions = otherVersions;
          _relatedAlbums = relatedAlbums;
          _relatedArtists = relatedArtists;
          _isLoadingExtras = false;
          _hasLoadedExtras = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingExtras = false;
          _hasLoadedExtras = true;
        });
      }
    }
  }

  _AlbumVariantBuckets _buildAlbumVariantBuckets(
    AlbumDetail currentAlbum,
    List<Album> albums,
  ) {
    final currentKey = _normalizedAlbumTitle(currentAlbum.title);
    final seenIds = <String>{currentAlbum.id};
    final liveAlbums = <Album>[];
    final otherVersions = <Album>[];
    final moreAlbums = <Album>[];

    for (final album in albums) {
      if (album.id.isEmpty || seenIds.contains(album.id)) {
        continue;
      }
      seenIds.add(album.id);

      final normalizedTitle = _normalizedAlbumTitle(album.title);
      final isLive = album.albumType == AlbumType.live ||
          album.title.toLowerCase().contains('live');
      final isVersionMatch =
          normalizedTitle.isNotEmpty && normalizedTitle == currentKey;

      if (isLive) {
        liveAlbums.add(album);
      } else if (isVersionMatch) {
        otherVersions.add(album);
      } else {
        moreAlbums.add(album);
      }
    }

    return _AlbumVariantBuckets(
      liveAlbums: liveAlbums,
      otherVersions: otherVersions,
      moreAlbums: moreAlbums,
    );
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

  String _normalizeArtistName(String name) {
    return name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
  }

  bool _belongsToArtist(Album album, String artistId, String artistName) {
    if (album.id.isEmpty) {
      return false;
    }
    if (album.artistId.isNotEmpty && album.artistId == artistId) {
      return true;
    }
    return _normalizeArtistName(album.artist) ==
        _normalizeArtistName(artistName);
  }

  Artist? _pickBestArtistMatch(List<Artist> artists, String expectedName) {
    if (artists.isEmpty) {
      return null;
    }
    final normalizedExpected = _normalizeArtistName(expectedName);
    for (final artist in artists) {
      if (_normalizeArtistName(artist.name) == normalizedExpected) {
        return artist;
      }
    }
    for (final artist in artists) {
      final normalized = _normalizeArtistName(artist.name);
      if (normalized.contains(normalizedExpected) ||
          normalizedExpected.contains(normalized)) {
        return artist;
      }
    }
    return artists.first;
  }

  Future<Album> _resolveAlbumForNavigation(Album album) async {
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
    final normalizedTitle = _normalizedAlbumTitle(title);

    for (final album in albums) {
      if (_normalizeArtistName(album.artist) == normalizedArtist &&
          _normalizedAlbumTitle(album.title) == normalizedTitle) {
        return album;
      }
    }

    for (final album in albums) {
      if (_normalizeArtistName(album.artist) == normalizedArtist) {
        final candidateTitle = _normalizedAlbumTitle(album.title);
        if (candidateTitle.contains(normalizedTitle) ||
            normalizedTitle.contains(candidateTitle)) {
          return album;
        }
      }
    }

    return null;
  }

  void _showAlbumCredits(BuildContext context, AlbumDetail albumDetail) {
    final qualityLabel = _albumQualityLabel(albumDetail);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      builder: (context) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Album credits',
                style: AppTheme.titleLarge.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 18),
              _CreditRow(label: 'Artist', value: albumDetail.artist),
              if (albumDetail.year != null)
                _CreditRow(
                  label: 'Release year',
                  value: albumDetail.year.toString(),
                ),
              _CreditRow(
                label: 'Tracks',
                value: '${albumDetail.tracks.length}',
              ),
              if (albumDetail.duration != null)
                _CreditRow(
                  label: 'Duration',
                  value: '${albumDetail.duration!.inMinutes} min',
                ),
              if (qualityLabel != null)
                _CreditRow(label: 'Quality', value: qualityLabel),
              if (albumDetail.copyright != null &&
                  albumDetail.copyright!.trim().isNotEmpty)
                _CreditRow(
                  label: 'Copyright',
                  value: albumDetail.copyright!,
                ),
            ],
          ),
        ),
      ),
    );
  }

  String? _albumQualityLabel(AlbumDetail albumDetail) {
    int? maxBitDepth = albumDetail.quality?.bitDepth;
    for (final track in albumDetail.tracks) {
      final bitDepth = track.quality?.bitDepth;
      if (bitDepth != null && (maxBitDepth == null || bitDepth > maxBitDepth)) {
        maxBitDepth = bitDepth;
      }
    }
    if (maxBitDepth == null) {
      return null;
    }
    return maxBitDepth >= 24 ? 'MAX' : 'HIGH';
  }

  Future<void> _shareAlbum(
      BuildContext context, AlbumDetail albumDetail) async {
    final shareUrl = albumDetail.source == MusicSource.tidal
        ? 'https://listen.tidal.com/album/${albumDetail.id}'
        : '${albumDetail.title} - ${albumDetail.artist}';
    final shareText =
        '${albumDetail.title} by ${albumDetail.artist}\n$shareUrl';
    await Clipboard.setData(ClipboardData(text: shareText));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Album link copied to clipboard'),
        backgroundColor: AppTheme.surfaceLight,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final albumDetailAsync = ref.watch(albumDetailProvider(widget.albumId));
    final responsive = Responsive(context);

    return ScaffoldWithMiniPlayer(
      backgroundColor: AppTheme.backgroundColor,
      body: albumDetailAsync.when(
        loading: () => _buildLoadingState(context, responsive),
        error: (error, stack) =>
            _buildErrorState(context, error.toString(), responsive),
        data: (albumDetail) {
          if (albumDetail == null) {
            return _buildErrorState(context, 'Album not found', responsive);
          }
          // Load extra content when album loads (only once)
          if (!_hasLoadedExtras && !_isLoadingExtras) {
            WidgetsBinding.instance
                .addPostFrameCallback((_) => _loadExtraContent(albumDetail));
          }
          return _buildContent(context, ref, albumDetail, responsive);
        },
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context, Responsive responsive) {
    return SafeArea(
      child: Column(
        children: [
          _buildAppBar(context),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.album != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: widget.album!.coverArtUrl != null
                          ? CachedNetworkImage(
                              imageUrl: widget.album!.coverArtUrl!,
                              width: 150,
                              height: 150,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              width: 150,
                              height: 150,
                              color: AppTheme.surfaceColor,
                              child: const Icon(Icons.album, size: 60),
                            ),
                    ),
                    const SizedBox(height: 16),
                    Text(widget.album!.title, style: AppTheme.titleLarge),
                    const SizedBox(height: 8),
                  ],
                  const CircularProgressIndicator(color: AppTheme.primaryColor),
                  const SizedBox(height: 16),
                  Text('Loading album...', style: AppTheme.bodyMedium),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(
      BuildContext context, String error, Responsive responsive) {
    return SafeArea(
      child: Column(
        children: [
          _buildAppBar(context),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline,
                      size: 64, color: AppTheme.errorColor),
                  const SizedBox(height: 16),
                  Text('Failed to load album', style: AppTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(error,
                      style: AppTheme.bodyMedium, textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, {VoidCallback? onMore}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: onMore,
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    AlbumDetail albumDetail,
    Responsive responsive,
  ) {
    final playerState = ref.watch(playerProvider);

    return CustomScrollView(
      slivers: [
        // App Bar
        SliverToBoxAdapter(
          child: SafeArea(
            bottom: false,
            child: _buildAppBar(
              context,
              onMore: () => AlbumOptionsSheet.show(
                context,
                Album(
                  id: albumDetail.id,
                  title: albumDetail.title,
                  artist: albumDetail.artist,
                  artistId: albumDetail.artistId,
                  coverArtUrl: albumDetail.coverArtUrl,
                  year: albumDetail.year,
                  trackCount: albumDetail.trackCount,
                  source: albumDetail.source,
                  quality: albumDetail.quality,
                  duration: albumDetail.duration,
                  isExplicit: albumDetail.isExplicit,
                  albumType: albumDetail.albumType,
                ),
              ),
            ),
          ),
        ),

        // Album Header (Cover + Info)
        SliverToBoxAdapter(
          child: _AlbumHeader(
            albumDetail: albumDetail,
            onArtistTap: () => _navigateToArtist(context, albumDetail),
            onPlay: () => _playAlbum(ref, albumDetail, shuffle: false),
            onShuffle: () => _playAlbum(ref, albumDetail, shuffle: true),
            onDownload: () {
              ref.read(downloadProvider.notifier).addAllToQueue(
                    albumDetail.tracks,
                  );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Queued ${albumDetail.tracks.length} tracks for download',
                  ),
                ),
              );
            },
            isAlbumSaved: ref.watch(isAlbumSavedProvider(albumDetail.id)),
            onToggleSave: () {
              final wasSaved = ref.read(isAlbumSavedProvider(albumDetail.id));
              // Create Album from AlbumDetail for saving
              final album = Album(
                id: albumDetail.id,
                title: albumDetail.title,
                artist: albumDetail.artist,
                artistId: albumDetail.artistId,
                coverArtUrl: albumDetail.coverArtUrl,
                year: albumDetail.year,
                trackCount: albumDetail.trackCount,
                source: albumDetail.source,
                quality: albumDetail.quality,
                duration: albumDetail.duration,
                isExplicit: albumDetail.isExplicit,
                albumType: albumDetail.albumType,
              );
              ref.read(savedAlbumsProvider.notifier).toggleAlbum(album);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    wasSaved
                        ? 'Removed from collection'
                        : 'Added to collection',
                  ),
                  backgroundColor: AppTheme.surfaceLight,
                ),
              );
            },
            onCredits: () => _showAlbumCredits(context, albumDetail),
            onShare: () => _shareAlbum(context, albumDetail),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 20)),

        // Track List
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final track = albumDetail.tracks[index];
              final isPlaying = playerState.currentTrack?.id == track.id;

              return _TrackListItem(
                track: track,
                index: index + 1,
                isPlaying: isPlaying,
                onTap: () {
                  ref
                      .read(playerProvider.notifier)
                      .playQueue(albumDetail.tracks, startIndex: index);
                },
              );
            },
            childCount: albumDetail.tracks.length,
          ),
        ),

        // Copyright / Release Info
        if (albumDetail.copyright != null || albumDetail.year != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(responsive.horizontalPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (albumDetail.year != null)
                    Text('Released: ${albumDetail.year}',
                        style: AppTheme.bodySmall
                            .copyWith(color: AppTheme.secondaryColor)),
                  if (albumDetail.copyright != null)
                    Text(albumDetail.copyright!,
                        style: AppTheme.labelSmall
                            .copyWith(color: AppTheme.tertiaryColor)),
                ],
              ),
            ),
          ),

        // More Albums by Artist
        if (_moreAlbumsByArtist.isNotEmpty) ...[
          _SectionHeader(
            title: 'More Albums by ${albumDetail.artist}',
            onViewAll: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ViewAllScreen(
                  title: 'More Albums by ${albumDetail.artist}',
                  albums: _moreAlbumsByArtist,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _HorizontalAlbumList(
              albums: _moreAlbumsByArtist,
              onAlbumTap: (album) => _navigateToAlbum(context, album),
            ),
          ),
        ],

        if (_otherVersions.isNotEmpty) ...[
          _SectionHeader(
            title: 'Other Versions',
            onViewAll: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ViewAllScreen(
                  title: 'Other Versions',
                  albums: _otherVersions,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _HorizontalAlbumList(
              albums: _otherVersions,
              onAlbumTap: (album) => _navigateToAlbum(context, album),
            ),
          ),
        ],

        if (_liveAlbums.isNotEmpty) ...[
          _SectionHeader(
            title: 'Live Albums',
            onViewAll: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ViewAllScreen(
                  title: 'Live Albums',
                  albums: _liveAlbums,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _HorizontalAlbumList(
              albums: _liveAlbums,
              onAlbumTap: (album) => _navigateToAlbum(context, album),
            ),
          ),
        ],

        if (_relatedAlbums.isNotEmpty) ...[
          _SectionHeader(
            title: 'Related Albums',
            onViewAll: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ViewAllScreen(
                  title: 'Related Albums',
                  albums: _relatedAlbums,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _HorizontalAlbumList(
              albums: _relatedAlbums,
              onAlbumTap: (album) => _navigateToAlbum(context, album),
            ),
          ),
        ],

        // Related Artists
        if (_relatedArtists.isNotEmpty) ...[
          _SectionHeader(
            title: 'Related Artists',
            onViewAll: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ViewAllScreen(
                  title: 'Related Artists',
                  artists: _relatedArtists.take(10).toList(),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _HorizontalArtistList(
              artists: _relatedArtists,
              onArtistTap: (artist) => _navigateToArtistById(context, artist),
            ),
          ),
        ],

        // Loading indicator for extras
        if (_isLoadingExtras)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                  child:
                      CircularProgressIndicator(color: AppTheme.primaryColor)),
            ),
          ),

        // Bottom spacing
        SliverToBoxAdapter(
          child: SizedBox(
              height: responsive.miniPlayerHeight +
                  responsive.bottomNavHeight +
                  40),
        ),
      ],
    );
  }

  void _playAlbum(WidgetRef ref, AlbumDetail albumDetail,
      {required bool shuffle}) {
    if (albumDetail.tracks.isEmpty) return;
    final tracks = shuffle
        ? (List<Track>.from(albumDetail.tracks)..shuffle())
        : albumDetail.tracks;
    ref.read(playerProvider.notifier).playQueue(tracks, startIndex: 0);
  }

  void _navigateToArtist(BuildContext context, AlbumDetail albumDetail) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ArtistDetailScreen(
          artistId: albumDetail.artistId,
          artist: Artist(
              id: albumDetail.artistId,
              name: albumDetail.artist,
              source: MusicSource.tidal),
        ),
      ),
    );
  }

  void _navigateToArtistById(BuildContext context, Artist artist) {
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (_) =>
              ArtistDetailScreen(artistId: artist.id, artist: artist)),
    );
  }

  Future<void> _navigateToAlbum(BuildContext context, Album album) async {
    final resolvedAlbum = await _resolveAlbumForNavigation(album);
    if (!context.mounted) {
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AlbumDetailScreen(
          albumId: resolvedAlbum.id,
          album: resolvedAlbum,
        ),
      ),
    );
  }
}

// ============================================================================
// ALBUM HEADER WIDGET
// ============================================================================

class _AlbumHeader extends StatelessWidget {
  final AlbumDetail albumDetail;
  final VoidCallback onArtistTap;
  final VoidCallback onPlay;
  final VoidCallback onShuffle;
  final VoidCallback onDownload;
  final VoidCallback onCredits;
  final VoidCallback onShare;
  final bool isAlbumSaved;
  final VoidCallback onToggleSave;

  const _AlbumHeader({
    required this.albumDetail,
    required this.onArtistTap,
    required this.onPlay,
    required this.onShuffle,
    required this.onDownload,
    required this.onCredits,
    required this.onShare,
    required this.isAlbumSaved,
    required this.onToggleSave,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);
    final coverSize = responsive.value(mobile: 236.0, tablet: 300.0);
    final qualityCode = _qualityCode();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: responsive.horizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            height: coverSize + 84,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: albumDetail.coverArtUrl != null
                        ? Stack(
                            fit: StackFit.expand,
                            children: [
                              CachedNetworkImage(
                                imageUrl: albumDetail.coverArtUrl!,
                                fit: BoxFit.cover,
                              ),
                              BackdropFilter(
                                filter:
                                    ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                                child: Container(
                                  color: Colors.black.withOpacity(0.4),
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.black.withOpacity(0.16),
                                      Colors.black.withOpacity(0.55),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Container(color: AppTheme.surfaceColor),
                  ),
                ),
                Container(
                  width: coverSize,
                  height: coverSize,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.34),
                        blurRadius: 26,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: albumDetail.source == MusicSource.tidal
                        ? TidalCover(
                            coverUrl: albumDetail.coverArtUrl,
                            size: 640,
                            borderRadius: 0,
                            fit: BoxFit.cover,
                            enableVideoCover: false,
                          )
                        : albumDetail.coverArtUrl != null
                            ? CachedNetworkImage(
                                imageUrl: albumDetail.coverArtUrl!,
                                fit: BoxFit.cover,
                                placeholder: (_, __) =>
                                    Container(color: AppTheme.surfaceColor),
                              )
                            : Container(
                                color: AppTheme.surfaceColor,
                                child: const Icon(
                                  Icons.album,
                                  size: 80,
                                  color: AppTheme.secondaryColor,
                                ),
                              ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            albumDetail.title,
            textAlign: TextAlign.center,
            style: AppTheme.headlineMedium.copyWith(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.9,
              height: 1.02,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: onArtistTap,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      'Album by ${albumDetail.artist}',
                      textAlign: TextAlign.center,
                      style: AppTheme.bodyLarge.copyWith(
                        color: Colors.white.withOpacity(0.72),
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: Colors.white.withOpacity(0.72),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (albumDetail.year != null)
                Text(
                  '${albumDetail.year}',
                  style: AppTheme.bodySmall.copyWith(
                    color: Colors.white.withOpacity(0.8),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.1,
                  ),
                ),
              if (qualityCode != null) _AlbumQualityBadge(label: qualityCode),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onPlay,
                  icon: const Icon(Icons.play_arrow_rounded, size: 19),
                  label: const Text('Play'),
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: AppTheme.bodyLarge.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onShuffle,
                  icon: const Icon(Icons.shuffle_rounded, size: 18),
                  label: const Text('Shuffle'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.12),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: AppTheme.bodyLarge.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ActionIcon(
                icon: isAlbumSaved
                    ? Icons.favorite_outline
                    : Icons.favorite_border,
                label: 'Add',
                onTap: onToggleSave,
                isActive: isAlbumSaved,
              ),
              _ActionIcon(
                icon: Icons.info_outline,
                label: 'Credits',
                onTap: onCredits,
              ),
              _ActionIcon(
                icon: Icons.download_outlined,
                label: 'Download',
                onTap: onDownload,
              ),
              _ActionIcon(
                icon: Icons.share_outlined,
                label: 'Share',
                onTap: onShare,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String? _qualityCode() {
    final bitDepth = _bitDepth();
    if (bitDepth == null) {
      return null;
    }
    return bitDepth >= 24 ? 'MAX' : 'HIGH';
  }

  int? _bitDepth() {
    int? maxBitDepth = albumDetail.quality?.bitDepth;
    for (final track in albumDetail.tracks) {
      final bitDepth = track.quality?.bitDepth;
      if (bitDepth != null && (maxBitDepth == null || bitDepth > maxBitDepth)) {
        maxBitDepth = bitDepth;
      }
    }
    return maxBitDepth;
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isActive;

  const _ActionIcon({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppTheme.primaryColor : AppTheme.secondaryColor;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 5),
          Text(
            label,
            style: AppTheme.labelSmall.copyWith(
              color: color,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _AlbumQualityBadge extends StatelessWidget {
  final String label;

  const _AlbumQualityBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    final isMax = label == 'MAX';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isMax
            ? const Color(0xFF8F6E1D).withOpacity(0.92)
            : const Color(0xFF004E47).withOpacity(0.95),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.9,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _CreditRow extends StatelessWidget {
  final String label;
  final String value;

  const _CreditRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: AppTheme.labelSmall.copyWith(
              color: AppTheme.tertiaryColor,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTheme.bodyLarge.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// TRACK LIST ITEM
// ============================================================================

class _TrackListItem extends StatelessWidget {
  final Track track;
  final int index;
  final bool isPlaying;
  final VoidCallback onTap;

  const _TrackListItem({
    required this.track,
    required this.index,
    required this.isPlaying,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final titleStyle = GoogleFonts.inter(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      color: isPlaying ? AppTheme.accentColor : Colors.white,
    );
    final subtitleStyle = GoogleFonts.inter(
      fontSize: 12.5,
      fontWeight: FontWeight.w400,
      color: AppTheme.secondaryColor,
    );
    final numberStyle = GoogleFonts.inter(
      fontSize: 13.5,
      fontWeight: FontWeight.w400,
      color: AppTheme.tertiaryColor,
    );

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 22,
              child: Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Center(
                  child: isPlaying
                      ? Icon(
                          Icons.equalizer,
                          color: AppTheme.accentColor,
                          size: 17,
                        )
                      : Text('$index', style: numberStyle),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          track.title,
                          style: titleStyle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (track.isExplicit) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.14),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: Text(
                            'E',
                            style: AppTheme.labelSmall.copyWith(
                              fontSize: 9,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    track.artist,
                    style: subtitleStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(
                  Icons.more_vert,
                  size: 18,
                  color: AppTheme.secondaryColor,
                ),
                onPressed: () => TrackOptionsSheet.show(
                  context,
                  track,
                  showGoToAlbum: false,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// SECTION HEADER WITH VIEW ALL
// ============================================================================

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onViewAll;

  const _SectionHeader({required this.title, this.onViewAll});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 30, 18, 10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: AppTheme.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (onViewAll != null)
              TextButton(
                onPressed: onViewAll,
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.06),
                  foregroundColor: Colors.white.withOpacity(0.82),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'VIEW ALL',
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.65,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// HORIZONTAL ALBUM LIST
// ============================================================================

class _HorizontalAlbumList extends StatelessWidget {
  final List<Album> albums;
  final Function(Album) onAlbumTap;
  static const double _tidalCardWidth = 156;
  static const double _tidalCoverSize = 156;
  static const double _tidalRailHeight = 224;

  const _HorizontalAlbumList({required this.albums, required this.onAlbumTap});

  @override
  Widget build(BuildContext context) {
    const cardWidth = _tidalCardWidth;
    const coverSize = _tidalCoverSize;
    const railHeight = _tidalRailHeight;

    return SizedBox(
      height: railHeight,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        itemCount: albums.length,
        itemBuilder: (context, index) {
          final album = albums[index];
          return GestureDetector(
            onTap: () => onAlbumTap(album),
            child: Container(
              width: cardWidth,
              margin: const EdgeInsets.only(right: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: album.coverArtUrl != null
                        ? CachedNetworkImage(
                            imageUrl: album.coverArtUrl!,
                            width: coverSize,
                            height: coverSize,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              width: coverSize,
                              height: coverSize,
                              color: AppTheme.surfaceColor,
                            ),
                          )
                        : Container(
                            width: coverSize,
                            height: coverSize,
                            color: AppTheme.surfaceColor,
                            child: const Icon(
                              Icons.album,
                              size: 40,
                              color: AppTheme.secondaryColor,
                            ),
                          ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    album.title,
                    style: AppTheme.bodySmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    album.artist,
                    style: AppTheme.labelSmall
                        .copyWith(color: AppTheme.secondaryColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ============================================================================
// HORIZONTAL ARTIST LIST
// ============================================================================

class _HorizontalArtistList extends StatelessWidget {
  final List<Artist> artists;
  final Function(Artist) onArtistTap;
  static const double _imageSize = 156;
  static const double _cardWidth = 156;
  static const double _railHeight = 236;

  const _HorizontalArtistList(
      {required this.artists, required this.onArtistTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _railHeight,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: artists.length,
        itemBuilder: (context, index) {
          final artist = artists[index];
          return GestureDetector(
            onTap: () => onArtistTap(artist),
            child: Container(
              width: _cardWidth,
              margin: const EdgeInsets.only(right: 16),
              child: Column(
                children: [
                  // Circular Artist Image
                  Container(
                    width: _imageSize,
                    height: _imageSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.surfaceColor,
                    ),
                    child: ClipOval(
                      child: artist.imageUrl != null
                          ? CachedNetworkImage(
                              imageUrl: artist.imageUrl!,
                              width: _imageSize,
                              height: _imageSize,
                              fit: BoxFit.cover,
                              placeholder: (_, __) =>
                                  _buildArtistPlaceholder(artist),
                              errorWidget: (_, __, ___) =>
                                  _buildArtistPlaceholder(artist),
                            )
                          : _buildArtistPlaceholder(artist),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Name
                  Text(
                    artist.name,
                    style: AppTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildArtistPlaceholder(Artist artist) {
    return Container(
      width: _imageSize,
      height: _imageSize,
      color: AppTheme.surfaceLight,
      child: Center(
        child: Text(
          artist.name.isNotEmpty ? artist.name[0].toUpperCase() : '?',
          style:
              AppTheme.headlineMedium.copyWith(color: AppTheme.secondaryColor),
        ),
      ),
    );
  }
}

class _AlbumVariantBuckets {
  final List<Album> liveAlbums;
  final List<Album> otherVersions;
  final List<Album> moreAlbums;

  const _AlbumVariantBuckets({
    required this.liveAlbums,
    required this.otherVersions,
    required this.moreAlbums,
  });
}
