import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palette_generator/palette_generator.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../services/tidal_service.dart';
import '../../widgets/quality_badge.dart';
import '../../widgets/track_options_sheet.dart';
import '../album/album_detail_screen.dart';

enum _PlayerView { player, nextUp, suggested, lyrics, credits }

class NowPlayingScreen extends ConsumerStatefulWidget {
  const NowPlayingScreen({super.key});

  @override
  ConsumerState<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends ConsumerState<NowPlayingScreen> {
  Color _dominantColor = AppTheme.backgroundColor;
  Color _secondaryColor = AppTheme.surfaceColor;
  String? _lastCoverUrl;
  String? _lastPrefetchedTrackKey;
  _PlayerView _activeView = _PlayerView.player;
  final ScrollController _lyricsScrollController = ScrollController();
  int _lastLyricIndex = -1;

  @override
  void initState() {
    super.initState();
    _extractColors();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _extractColors();
  }

  @override
  void dispose() {
    _lyricsScrollController.dispose();
    super.dispose();
  }

  Future<void> _extractColors() async {
    final track = ref.read(playerProvider).currentTrack;
    if (track?.coverArtUrl == null || track!.coverArtUrl == _lastCoverUrl) {
      return;
    }

    _lastCoverUrl = track.coverArtUrl;
    _lastLyricIndex = -1;
    try {
      final palette = await PaletteGenerator.fromImageProvider(
        CachedNetworkImageProvider(track.coverArtUrl!),
        maximumColorCount: 8,
      );

      if (!mounted) return;
      setState(() {
        _dominantColor =
            palette.dominantColor?.color ?? AppTheme.backgroundColor;
        _secondaryColor = palette.darkMutedColor?.color ??
            palette.mutedColor?.color ??
            AppTheme.surfaceColor;
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(playerProvider);
    final track = playerState.currentTrack;
    final responsive = Responsive(context);

    if (track?.coverArtUrl != _lastCoverUrl) {
      _extractColors();
    }

    if (track == null) {
      return _buildEmptyState(context, responsive);
    }

    _prefetchTrackDetails(track);

    return GestureDetector(
      onVerticalDragEnd: (details) {
        if (details.velocity.pixelsPerSecond.dy > 350) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                _dominantColor.withOpacity(0.9),
                _secondaryColor.withOpacity(0.58),
                AppTheme.backgroundColor,
              ],
              stops: const [0.0, 0.42, 0.86],
            ),
          ),
          child: SafeArea(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: _activeView == _PlayerView.player
                  ? _buildPlayerView(
                      context,
                      responsive,
                      playerState,
                      track,
                    )
                  : _buildDetailView(
                      context,
                      responsive,
                      playerState,
                      track,
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, Responsive responsive) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(responsive.horizontalPadding),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.keyboard_arrow_down, size: 30),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.music_off_rounded,
                      size: 80,
                      color: Colors.white.withOpacity(0.32),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No track playing',
                      style: AppTheme.titleLarge.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Select a track to start',
                      style: AppTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerView(
    BuildContext context,
    Responsive responsive,
    PlayerState playerState,
    Track track,
  ) {
    return Column(
      key: const ValueKey('player'),
      children: [
        _buildPlayerHeader(context, playerState, responsive),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxHeight < 660;
              final maxCover = math.max(220.0, constraints.maxWidth - 6);
              final minCover = math.min(maxCover, compact ? 252.0 : 280.0);
              final coverSize =
                  (constraints.maxHeight * (compact ? 0.40 : 0.45))
                      .clamp(minCover, maxCover)
                      .toDouble();
              final infoGap = compact ? 12.0 : 18.0;
              final progressGap = compact ? 10.0 : 14.0;
              final actionsGap = compact ? 18.0 : 22.0;
              final bottomInset =
                  (constraints.maxHeight * 0.028).clamp(12.0, 24.0).toDouble();

              return Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: responsive.horizontalPadding),
                child: Column(
                  children: [
                    SizedBox(height: compact ? 2 : 6),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            children: [
                              Center(
                                child: _buildAlbumCover(
                                  track,
                                  responsive,
                                  sizeOverride: coverSize,
                                ),
                              ),
                              SizedBox(height: infoGap),
                              _buildTrackInfo(track, compact: compact),
                              SizedBox(height: progressGap),
                              _buildProgressBar(
                                playerState,
                                compact: compact,
                              ),
                            ],
                          ),
                          Padding(
                            padding: EdgeInsets.only(bottom: bottomInset),
                            child: Column(
                              children: [
                                _buildPlaybackControls(
                                  playerState,
                                  compact: compact,
                                ),
                                SizedBox(height: actionsGap),
                                _buildPanelActions(
                                  showLabels: false,
                                  compact: compact,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDetailView(
    BuildContext context,
    Responsive responsive,
    PlayerState playerState,
    Track track,
  ) {
    return Column(
      key: ValueKey(_activeView.name),
      children: [
        _buildDetailHeader(responsive),
        Padding(
          padding:
              EdgeInsets.symmetric(horizontal: responsive.horizontalPadding),
          child: _buildCompactTrackCard(track),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: Padding(
            padding:
                EdgeInsets.symmetric(horizontal: responsive.horizontalPadding),
            child: _buildDetailContent(context, track, playerState),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            responsive.horizontalPadding,
            8,
            responsive.horizontalPadding,
            20,
          ),
          child: _buildCompactTransport(playerState),
        ),
      ],
    );
  }

  Widget _buildPlayerHeader(
    BuildContext context,
    PlayerState playerState,
    Responsive responsive,
  ) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        responsive.horizontalPadding,
        4,
        responsive.horizontalPadding,
        8,
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 54,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.48),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PLAYING FROM',
                      style: AppTheme.labelSmall.copyWith(
                        color: Colors.white.withOpacity(0.66),
                        letterSpacing: 1.6,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _displayQueueSource(playerState.queueSource),
                      style: AppTheme.titleLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 17,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: IconButton(
                  icon: const Icon(Icons.cast_outlined, color: Colors.white),
                  onPressed: () {},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailHeader(Responsive responsive) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        responsive.horizontalPadding,
        8,
        responsive.horizontalPadding,
        10,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => setState(() => _activeView = _PlayerView.player),
          ),
        ],
      ),
    );
  }

  Widget _buildAlbumCover(
    Track track,
    Responsive responsive, {
    double? sizeOverride,
  }) {
    final size = (sizeOverride ??
            responsive.value(mobile: 300.0, tablet: 380.0) ??
            300.0)
        .toDouble();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.34),
            blurRadius: 34,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: track.coverArtUrl != null
            ? CachedNetworkImage(
                imageUrl: track.coverArtUrl!,
                fit: BoxFit.cover,
                placeholder: (_, __) => _buildPlaceholder(size),
                errorWidget: (_, __, ___) => _buildPlaceholder(size),
              )
            : _buildPlaceholder(size),
      ),
    );
  }

  Widget _buildPlaceholder(double size) {
    return Container(
      width: size,
      height: size,
      color: AppTheme.surfaceColor,
      child: const Icon(Icons.music_note, size: 80, color: Colors.white38),
    );
  }

  Widget _buildTrackInfo(Track track, {bool compact = false}) {
    final favorites = ref.watch(favoritesProvider);
    final isFavorite = favorites.isFavorite(track);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                track.title,
                style: AppTheme.headlineLarge.copyWith(
                  color: Colors.white,
                  fontSize: compact ? 20 : 24,
                  letterSpacing: -0.4,
                ),
                maxLines: compact ? 1 : 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                track.artist,
                style: AppTheme.headlineSmall.copyWith(
                  color: Colors.white.withOpacity(0.84),
                  fontWeight: FontWeight.w500,
                  fontSize: compact ? 15 : 18,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        IconButton(
          icon: Icon(
            isFavorite ? Icons.favorite : Icons.favorite_border,
            color: Colors.white,
          ),
          visualDensity: VisualDensity.compact,
          onPressed: () =>
              ref.read(favoritesProvider.notifier).toggleFavorite(track),
        ),
        IconButton(
          icon: const Icon(Icons.share_outlined, color: Colors.white),
          visualDensity: VisualDensity.compact,
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          visualDensity: VisualDensity.compact,
          onPressed: () => TrackOptionsSheet.show(context, track),
        ),
      ],
    );
  }

  Widget _buildProgressBar(PlayerState playerState, {bool compact = false}) {
    final duration = playerState.duration;
    final position = playerState.position;
    final progress = duration.inMilliseconds > 0
        ? position.inMilliseconds / duration.inMilliseconds
        : 0.0;

    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: compact ? 3 : 4,
            thumbShape: RoundSliderThumbShape(
              enabledThumbRadius: compact ? 6 : 7,
            ),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
            activeTrackColor: Colors.white,
            inactiveTrackColor: Colors.white.withOpacity(0.22),
            thumbColor: Colors.white,
            overlayColor: Colors.white.withOpacity(0.18),
          ),
          child: Slider(
            value: progress.clamp(0.0, 1.0),
            onChanged: (value) {
              final nextPosition = Duration(
                milliseconds: (duration.inMilliseconds * value).round(),
              );
              ref.read(playerProvider.notifier).seek(nextPosition);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(position),
                style: AppTheme.labelMedium.copyWith(
                  color: Colors.white.withOpacity(0.78),
                ),
              ),
              QualityBadge(
                qualityCode: playerState.currentQuality,
                source: playerState.currentTrack?.source,
                bitDepth: playerState.currentBitDepth,
                sampleRate: playerState.currentSampleRate,
                codec: playerState.currentCodec,
                fontSize: compact ? 9 : 10,
              ),
              Text(
                _formatDuration(duration),
                style: AppTheme.labelMedium.copyWith(
                  color: Colors.white.withOpacity(0.78),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlaybackControls(PlayerState playerState,
      {bool compact = false}) {
    final notifier = ref.read(playerProvider.notifier);
    final sideIconSize = compact ? 34.0 : 40.0;
    final centerSize = compact ? 76.0 : 88.0;
    final centerIconSize = compact ? 38.0 : 44.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: Icon(
            Icons.shuffle,
            color: playerState.shuffleEnabled
                ? Colors.white
                : Colors.white.withOpacity(0.72),
            size: compact ? 24 : 28,
          ),
          onPressed: () => notifier.toggleShuffle(),
        ),
        IconButton(
          icon: Icon(Icons.skip_previous,
              size: sideIconSize, color: Colors.white),
          onPressed: () => notifier.previous(),
        ),
        Container(
          width: centerSize,
          height: centerSize,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
          child: IconButton(
            icon: Icon(
              playerState.isPlaying ? Icons.pause : Icons.play_arrow,
              size: centerIconSize,
              color: Colors.black,
            ),
            onPressed: () => notifier.togglePlayPause(),
          ),
        ),
        IconButton(
          icon: Icon(Icons.skip_next, size: sideIconSize, color: Colors.white),
          onPressed: () => notifier.next(),
        ),
        IconButton(
          icon: Icon(
            playerState.repeatMode == RepeatMode.one
                ? Icons.repeat_one
                : Icons.repeat,
            color: playerState.repeatMode == RepeatMode.off
                ? Colors.white.withOpacity(0.72)
                : Colors.white,
            size: compact ? 24 : 28,
          ),
          onPressed: () => notifier.cycleRepeatMode(),
        ),
      ],
    );
  }

  Widget _buildPanelActions({bool showLabels = true, bool compact = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildPanelActionButton(
          icon: Icons.reorder_rounded,
          label: 'Next up',
          iconSize: compact ? 25 : 28,
          showLabel: showLabels,
          onTap: () => setState(() => _activeView = _PlayerView.nextUp),
        ),
        _buildPanelActionButton(
          icon: Icons.music_note_outlined,
          label: 'Suggested',
          iconSize: compact ? 25 : 28,
          showLabel: showLabels,
          onTap: () => setState(() => _activeView = _PlayerView.suggested),
        ),
        _buildPanelActionButton(
          icon: Icons.lyrics_outlined,
          label: 'Lyrics',
          iconSize: compact ? 25 : 28,
          showLabel: showLabels,
          onTap: () => setState(() => _activeView = _PlayerView.lyrics),
        ),
        _buildPanelActionButton(
          icon: Icons.info_outline_rounded,
          label: 'Credits',
          iconSize: compact ? 25 : 28,
          showLabel: showLabels,
          onTap: () => setState(() => _activeView = _PlayerView.credits),
        ),
      ],
    );
  }

  Widget _buildPanelActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool enabled = true,
    bool showLabel = true,
    double iconSize = 28,
  }) {
    final color = enabled ? Colors.white : Colors.white38;

    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        child: Column(
          children: [
            Icon(icon, color: color, size: iconSize),
            if (showLabel) ...[
              const SizedBox(height: 8),
              Text(
                label,
                style: AppTheme.labelMedium.copyWith(color: color),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCompactTrackCard(Track track) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: AppTheme.surfaceLight,
            ),
            clipBehavior: Clip.antiAlias,
            child: track.coverArtUrl != null
                ? CachedNetworkImage(
                    imageUrl: track.coverArtUrl!,
                    fit: BoxFit.cover,
                  )
                : const Icon(Icons.music_note, color: Colors.white38),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  track.title,
                  style: AppTheme.titleLarge.copyWith(color: Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  track.artist,
                  style: AppTheme.bodyLarge.copyWith(
                    color: Colors.white.withOpacity(0.72),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () => TrackOptionsSheet.show(context, track),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailContent(
    BuildContext context,
    Track track,
    PlayerState playerState,
  ) {
    switch (_activeView) {
      case _PlayerView.nextUp:
        final nextUpAsync = ref.watch(playerNextUpProvider(track));
        return nextUpAsync.when(
          data: (items) {
            if (items.isEmpty) {
              return _buildPanelEmptyState(
                'Next Up from ${track.artist}',
                'No same-artist tracks were found for this song yet.',
              );
            }
            return _buildTrackPanel(
              title: 'Next Up from ${track.artist}',
              tracks: items,
              trailingIcon: Icons.drag_handle_rounded,
            );
          },
          loading: () => _buildPanelLoading('Next Up from ${track.artist}'),
          error: (_, __) => _buildPanelEmptyState(
            'Next Up from ${track.artist}',
            'This section is not available right now.',
          ),
        );
      case _PlayerView.suggested:
        final suggestedAsync = ref.watch(playerSuggestedTracksProvider(track));
        return suggestedAsync.when(
          data: (items) {
            if (items.isEmpty) {
              return _buildPanelEmptyState(
                'Suggested tracks',
                'Recommendations are still warming up from your listening history.',
              );
            }
            return _buildTrackPanel(
              title: 'Suggested tracks',
              tracks: items,
              trailingIcon: Icons.playlist_add_rounded,
            );
          },
          loading: () => _buildPanelLoading('Suggested tracks'),
          error: (_, __) => _buildPanelEmptyState(
            'Suggested tracks',
            'This section is not available right now.',
          ),
        );
      case _PlayerView.lyrics:
        final lyricsAsync = ref.watch(playerLyricsProvider(track));
        return lyricsAsync.when(
          data: (lyrics) => _buildLyricsPanel(playerState, lyrics),
          loading: () => _buildPanelLoading('Lyrics'),
          error: (_, __) => _buildPanelEmptyState(
            'Lyrics',
            'Lyrics are not available for this track.',
          ),
        );
      case _PlayerView.credits:
        final trackInfoAsync = ref.watch(playerTrackInfoProvider(track));
        return trackInfoAsync.when(
          data: (info) => _buildCreditsPanel(context, track, info),
          loading: () => _buildPanelLoading('Song credits'),
          error: (_, __) => _buildPanelEmptyState(
            'Song credits',
            'Detailed metadata is not available for this track.',
          ),
        );
      case _PlayerView.player:
        return const SizedBox.shrink();
    }
  }

  Widget _buildTrackPanel({
    required String title,
    required List<Track> tracks,
    required IconData trailingIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTheme.headlineMedium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 18),
        Expanded(
          child: ListView.separated(
            itemCount: tracks.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final item = tracks[index];
              return _buildTrackRow(
                item,
                trailingIcon: trailingIcon,
                onTrailingTap: () {
                  ref.read(playerProvider.notifier).addToQueueNext(item);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Added "${item.title}" to play next'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                onTap: () => ref.read(playerProvider.notifier).play(item),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTrackRow(
    Track track, {
    required IconData trailingIcon,
    required VoidCallback onTrailingTap,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              color: AppTheme.surfaceLight,
            ),
            clipBehavior: Clip.antiAlias,
            child: track.coverArtUrl != null
                ? CachedNetworkImage(
                    imageUrl: track.coverArtUrl!,
                    fit: BoxFit.cover,
                  )
                : const Icon(Icons.music_note, color: Colors.white38),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  track.title,
                  style: AppTheme.titleLarge.copyWith(color: Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  track.artist,
                  style: AppTheme.bodyLarge.copyWith(
                    color: Colors.white.withOpacity(0.72),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(trailingIcon, color: Colors.white70),
            onPressed: onTrailingTap,
          ),
        ],
      ),
    );
  }

  Widget _buildLyricsPanel(PlayerState playerState, Lyrics? lyrics) {
    if (lyrics == null ||
        (lyrics.lyrics.trim().isEmpty && lyrics.syncedLyrics.isEmpty)) {
      return _buildPanelEmptyState(
        'Lyrics',
        'Lyrics are not available for this track.',
      );
    }

    if (lyrics.isSynced && lyrics.syncedLyrics.isNotEmpty) {
      final activeIndex = _findActiveLyricIndex(
        lyrics.syncedLyrics,
        playerState.position.inMilliseconds,
      );
      _syncLyricScroll(activeIndex);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lyrics',
            style: AppTheme.headlineMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: ListView.builder(
              controller: _lyricsScrollController,
              itemCount: lyrics.syncedLyrics.length,
              itemBuilder: (context, index) {
                final line = lyrics.syncedLyrics[index];
                final isActive = index == activeIndex;
                final opacity = isActive
                    ? 1.0
                    : index < activeIndex
                        ? 0.38
                        : 0.56;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 22),
                  child: Text(
                    line.text.isEmpty ? '...' : line.text,
                    style: AppTheme.headlineLarge.copyWith(
                      color: Colors.white.withOpacity(opacity),
                      fontSize: 26,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                      height: 1.24,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      );
    }

    final lines = lyrics.lyrics
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Lyrics',
          style: AppTheme.headlineMedium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 18),
        Expanded(
          child: ListView.separated(
            itemCount: lines.length,
            separatorBuilder: (_, __) => const SizedBox(height: 18),
            itemBuilder: (context, index) {
              return Text(
                lines[index],
                style: AppTheme.headlineSmall.copyWith(
                  color: Colors.white.withOpacity(0.82),
                  fontSize: 24,
                  height: 1.28,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCreditsPanel(
    BuildContext context,
    Track track,
    TrackInfo? info,
  ) {
    final metadata = <MapEntry<String, String>>[];

    void addField(String label, String? value) {
      if (value == null || value.trim().isEmpty) return;
      metadata.add(MapEntry(label, value.trim()));
    }

    addField('Primary artist', info?.artist ?? track.artist);
    addField('Album', info?.album ?? track.album);
    addField('Release date', info?.releaseDate);
    addField('Copyright', info?.copyright);
    addField('ISRC', info?.isrc);
    addField('BPM', info?.bpm?.toString());
    addField('Musical key', info?.musicalKey);
    addField('Audio quality', info?.qualityLabel ?? info?.audioQuality);
    addField(
      'Audio tags',
      info == null || info.tags.isEmpty ? null : info.tags.join(' • '),
    );

    if (metadata.isEmpty) {
      return _buildPanelEmptyState(
        'Song credits',
        'Detailed metadata is not available for this track.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Song credits',
          style: AppTheme.headlineMedium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: ListView.separated(
            itemCount: metadata.length,
            separatorBuilder: (_, __) => const SizedBox(height: 24),
            itemBuilder: (context, index) {
              final entry = metadata[index];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.key.toUpperCase(),
                    style: AppTheme.labelMedium.copyWith(
                      color: Colors.white.withOpacity(0.56),
                      letterSpacing: 1.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    entry.value,
                    style: AppTheme.headlineSmall.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        if (track.albumId.isNotEmpty)
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.16),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AlbumDetailScreen(albumId: track.albumId),
                  ),
                );
              },
              child: const Text('See Full Album Credits'),
            ),
          ),
      ],
    );
  }

  Widget _buildCompactTransport(PlayerState playerState) {
    final notifier = ref.read(playerProvider.notifier);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: Icon(
            Icons.shuffle,
            color: playerState.shuffleEnabled
                ? Colors.white
                : Colors.white.withOpacity(0.72),
          ),
          onPressed: () => notifier.toggleShuffle(),
        ),
        IconButton(
          icon: const Icon(Icons.skip_previous, size: 38, color: Colors.white),
          onPressed: () => notifier.previous(),
        ),
        Container(
          width: 72,
          height: 72,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
          child: IconButton(
            icon: Icon(
              playerState.isPlaying ? Icons.pause : Icons.play_arrow,
              size: 38,
              color: Colors.black,
            ),
            onPressed: () => notifier.togglePlayPause(),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.skip_next, size: 38, color: Colors.white),
          onPressed: () => notifier.next(),
        ),
        IconButton(
          icon: Icon(
            playerState.repeatMode == RepeatMode.one
                ? Icons.repeat_one
                : Icons.repeat,
            color: playerState.repeatMode == RepeatMode.off
                ? Colors.white.withOpacity(0.72)
                : Colors.white,
          ),
          onPressed: () => notifier.cycleRepeatMode(),
        ),
      ],
    );
  }

  Widget _buildPanelEmptyState(String title, String message) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTheme.headlineMedium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          message,
          style: AppTheme.bodyLarge.copyWith(
            color: Colors.white.withOpacity(0.68),
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildPanelLoading(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTheme.headlineMedium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 24),
        const Expanded(
          child: Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ),
      ],
    );
  }

  void _prefetchTrackDetails(Track track) {
    final trackKey = '${track.id}_${track.source.name}';
    if (_lastPrefetchedTrackKey == trackKey) {
      return;
    }

    _lastPrefetchedTrackKey = trackKey;
    ref.read(playerTrackInfoProvider(track).future);
    ref.read(playerLyricsProvider(track).future);
    ref.read(playerNextUpProvider(track).future);
    ref.read(playerSuggestedTracksProvider(track).future);
  }

  int _findActiveLyricIndex(List<LyricLine> lines, int positionMs) {
    if (lines.isEmpty) return -1;
    for (var index = 0; index < lines.length; index++) {
      final current = lines[index].startTimeMs;
      final next =
          index + 1 < lines.length ? lines[index + 1].startTimeMs : 1 << 31;
      if (positionMs >= current && positionMs < next) {
        return index;
      }
    }
    return lines.length - 1;
  }

  void _syncLyricScroll(int activeIndex) {
    if (activeIndex < 0 || activeIndex == _lastLyricIndex) return;
    _lastLyricIndex = activeIndex;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_lyricsScrollController.hasClients) return;
      final offset = (activeIndex * 76.0) - 120.0;
      _lyricsScrollController.animateTo(
        offset < 0 ? 0 : offset,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
      );
    });
  }

  String _displayQueueSource(String? source) {
    final value = source?.trim();
    if (value == null || value.isEmpty) {
      return 'Your Library';
    }

    const prefixes = [
      'Playlist: ',
      'Artist: ',
      'Album: ',
      'Mix: ',
      'Search: ',
    ];

    for (final prefix in prefixes) {
      if (value.startsWith(prefix)) {
        return value.substring(prefix.length).trim();
      }
    }

    return value;
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
