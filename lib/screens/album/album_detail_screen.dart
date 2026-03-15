import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
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

    final tidalService = ref.read(tidalServiceProvider);
    final lastFmService = ref.read(lastFmServiceProvider);

    try {
      // 1. Load more albums by this artist from Tidal
      List<Album> moreAlbums = [];
      try {
        final artist = await tidalService.getArtist(albumDetail.artistId);
        moreAlbums =
            artist.albums.where((a) => a.id != albumDetail.id).take(6).toList();
      } catch (_) {}

      // 2. Get related artists from Last.fm (genuine related artists!)
      List<Artist> relatedArtists = [];

      try {
        final lastFmSimilar = await lastFmService
            .getSimilarArtists(albumDetail.artist, limit: 10);

        // For each related artist: get their Tidal profile AND their top album
        for (final lfmArtist in lastFmSimilar.take(8)) {
          try {
            // Search Tidal for this artist to get proper ID and image
            final tidalArtists =
                await tidalService.searchArtists(lfmArtist.name, limit: 1);
            if (tidalArtists.isNotEmpty) {
              final artist = tidalArtists.first;
              relatedArtists.add(artist);
            }
          } catch (_) {}
        }
      } catch (_) {}

      // 3. Fallback to Tidal search if Last.fm failed
      if (relatedArtists.isEmpty) {
        try {
          final searchedArtists =
              await tidalService.searchArtists(albumDetail.artist, limit: 10);
          relatedArtists = searchedArtists
              .where((a) => a.id != albumDetail.artistId)
              .take(8)
              .toList();
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _moreAlbumsByArtist = moreAlbums;
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

  Widget _buildAppBar(BuildContext context) {
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
            onPressed: () {},
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
            child: SafeArea(bottom: false, child: _buildAppBar(context))),

        // Album Header (Cover + Info)
        SliverToBoxAdapter(
          child: _AlbumHeader(
            albumDetail: albumDetail,
            onArtistTap: () => _navigateToArtist(context, albumDetail),
            onPlay: () => _playAlbum(ref, albumDetail, shuffle: false),
            onShuffle: () => _playAlbum(ref, albumDetail, shuffle: true),
            isAlbumSaved: ref.watch(isAlbumSavedProvider(albumDetail.id)),
            onToggleSave: () {
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
            },
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

        // Related Artists
        if (_relatedArtists.isNotEmpty) ...[
          _SectionHeader(
            title: 'Related Artists',
            onViewAll: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ViewAllScreen(
                  title: 'Related Artists',
                  artists: _relatedArtists,
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

  void _navigateToAlbum(BuildContext context, Album album) {
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (_) => AlbumDetailScreen(albumId: album.id, album: album)),
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
  final bool isAlbumSaved;
  final VoidCallback onToggleSave;

  const _AlbumHeader({
    required this.albumDetail,
    required this.onArtistTap,
    required this.onPlay,
    required this.onShuffle,
    required this.isAlbumSaved,
    required this.onToggleSave,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);
    final coverSize = responsive.value(mobile: 224.0, tablet: 288.0);
    final qualityCode = _qualityCode();
    final bitDepth = _bitDepth();
    final sampleRate = _sampleRate();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: responsive.horizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: coverSize,
              height: coverSize,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.32),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
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
          ),
          const SizedBox(height: 24),
          Text(
            albumDetail.title,
            style: AppTheme.headlineMedium.copyWith(
              fontSize: 31,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.8,
              height: 1.02,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: onArtistTap,
            child: Text(
              'Album by ${albumDetail.artist}',
              style: AppTheme.bodyLarge.copyWith(
                color: Colors.white.withOpacity(0.68),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (albumDetail.year != null)
                Text(
                  '${albumDetail.year}',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.secondaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              if (albumDetail.tracks.isNotEmpty)
                Text(
                  '${albumDetail.tracks.length} tracks',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.secondaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              if (albumDetail.duration != null)
                Text(
                  '${albumDetail.duration!.inMinutes} min',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.secondaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              if (qualityCode != null)
                QualityBadge(
                  qualityCode: qualityCode,
                  source: albumDetail.source,
                  bitDepth: bitDepth,
                  sampleRate: sampleRate,
                  codec: 'FLAC',
                  fontSize: 9,
                ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onPlay,
                  icon: const Icon(Icons.play_arrow_rounded, size: 20),
                  label: const Text('Play'),
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: AppTheme.bodyLarge.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onShuffle,
                  icon: const Icon(Icons.shuffle_rounded, size: 18),
                  label: const Text('Shuffle'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withOpacity(0.18)),
                    backgroundColor: Colors.white.withOpacity(0.04),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: AppTheme.bodyLarge.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _ActionIcon(
                  icon: Icons.download_outlined,
                  label: 'Download',
                  onTap: () {}),
              _ActionIcon(
                icon: isAlbumSaved ? Icons.check : Icons.add,
                label: isAlbumSaved ? 'Added' : 'Add',
                onTap: onToggleSave,
                isActive: isAlbumSaved,
              ),
              _ActionIcon(
                  icon: Icons.share_outlined, label: 'Share', onTap: () {}),
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
    return bitDepth >= 24 ? 'HI_RES_LOSSLESS' : 'LOSSLESS';
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

  int? _sampleRate() {
    int? maxSampleRate = albumDetail.quality?.sampleRate;
    for (final track in albumDetail.tracks) {
      final sampleRate = track.quality?.sampleRate;
      if (sampleRate != null &&
          (maxSampleRate == null || sampleRate > maxSampleRate)) {
        maxSampleRate = sampleRate;
      }
    }
    return maxSampleRate;
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
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            label,
            style: AppTheme.labelSmall.copyWith(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
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
      fontSize: 15.5,
      fontWeight: FontWeight.w500,
      color: isPlaying ? AppTheme.accentColor : Colors.white,
    );
    final subtitleStyle = GoogleFonts.inter(
      fontSize: 13,
      fontWeight: FontWeight.w400,
      color: AppTheme.secondaryColor,
    );
    final numberStyle = GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: AppTheme.tertiaryColor,
    );

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 2),
      minVerticalPadding: 6,
      leading: SizedBox(
        width: 24,
        child: Center(
          child: isPlaying
              ? Icon(Icons.equalizer, color: AppTheme.accentColor, size: 18)
              : Text('$index', style: numberStyle),
        ),
      ),
      title: Row(
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
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
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
      subtitle: Text(
        track.artist,
        style: subtitleStyle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.more_vert,
              size: 20, color: AppTheme.secondaryColor),
          onPressed: () => TrackOptionsSheet.show(context, track),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
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
        padding: const EdgeInsets.fromLTRB(18, 34, 18, 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: AppTheme.titleLarge.copyWith(
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
                    fontSize: 11,
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

  const _HorizontalAlbumList({required this.albums, required this.onAlbumTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 198,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        itemCount: albums.length,
        itemBuilder: (context, index) {
          final album = albums[index];
          return GestureDetector(
            onTap: () => onAlbumTap(album),
            child: Container(
              width: 128,
              margin: const EdgeInsets.only(right: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: album.coverArtUrl != null
                        ? CachedNetworkImage(
                            imageUrl: album.coverArtUrl!,
                            width: 128,
                            height: 128,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              width: 128,
                              height: 128,
                              color: AppTheme.surfaceColor,
                            ),
                          )
                        : Container(
                            width: 128,
                            height: 128,
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    album.year?.toString() ?? '',
                    style: AppTheme.labelSmall
                        .copyWith(color: AppTheme.secondaryColor),
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

  const _HorizontalArtistList(
      {required this.artists, required this.onArtistTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 130,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: artists.length,
        itemBuilder: (context, index) {
          final artist = artists[index];
          return GestureDetector(
            onTap: () => onArtistTap(artist),
            child: Container(
              width: 90,
              margin: const EdgeInsets.only(right: 16),
              child: Column(
                children: [
                  // Circular Artist Image
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.surfaceColor,
                    ),
                    child: ClipOval(
                      child: artist.imageUrl != null
                          ? CachedNetworkImage(
                              imageUrl: artist.imageUrl!,
                              width: 80,
                              height: 80,
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
      width: 80,
      height: 80,
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
