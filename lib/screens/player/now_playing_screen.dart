import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:palette_generator/palette_generator.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';

/// Now Playing Screen - TIDAL Style
/// Features:
/// - "Playing From" header showing source playlist/album
/// - Large album cover
/// - Dynamic background color from cover art
/// - Track info with action buttons
/// - Progress bar with quality badge
/// - Playback controls
class NowPlayingScreen extends ConsumerStatefulWidget {
  const NowPlayingScreen({super.key});

  @override
  ConsumerState<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends ConsumerState<NowPlayingScreen> {
  Color _dominantColor = AppTheme.backgroundColor;
  Color _secondaryColor = AppTheme.surfaceColor;
  String? _lastCoverUrl;

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

  Future<void> _extractColors() async {
    final playerState = ref.read(playerProvider);
    final track = playerState.currentTrack;
    
    if (track?.coverArtUrl == null || track!.coverArtUrl == _lastCoverUrl) return;
    _lastCoverUrl = track.coverArtUrl;

    try {
      final paletteGenerator = await PaletteGenerator.fromImageProvider(
        CachedNetworkImageProvider(track.coverArtUrl!),
        maximumColorCount: 5,
      );
      
      if (mounted) {
        setState(() {
          _dominantColor = paletteGenerator.dominantColor?.color ?? AppTheme.backgroundColor;
          _secondaryColor = paletteGenerator.darkMutedColor?.color ?? 
                           paletteGenerator.mutedColor?.color ?? 
                           AppTheme.surfaceColor;
        });
      }
    } catch (e) {
      // Use default colors if extraction fails
    }
  }

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(playerProvider);
    final track = playerState.currentTrack;
    final responsive = Responsive(context);

    // Extract colors when track changes
    if (track?.coverArtUrl != _lastCoverUrl) {
      _extractColors();
    }

    if (track == null) {
      return _buildEmptyState(context, responsive);
    }

    return GestureDetector(
      onVerticalDragEnd: (details) {
        // If user swipes down fast enough, close the screen
        if (details.velocity.pixelsPerSecond.dy > 300) {
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
                _dominantColor.withOpacity(0.8),
                _secondaryColor.withOpacity(0.6),
                AppTheme.backgroundColor,
              ],
              stops: const [0.0, 0.4, 0.8],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Header with drag handle and "Playing From"
                _buildHeader(context, playerState, responsive),
                
                // Main content
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: responsive.horizontalPadding),
                    child: Column(
                      children: [
                        // Album Cover
                        _buildAlbumCover(track, responsive),
                        
                        const SizedBox(height: 24),
                        
                        // Track Info with Actions
                        _buildTrackInfo(track, responsive),
                        
                        const SizedBox(height: 24),
                        
                        // Progress Bar
                        _buildProgressBar(playerState, responsive),
                        
                        const SizedBox(height: 16),
                        
                        // Playback Controls
                        _buildPlaybackControls(playerState, responsive),
                        
                        const SizedBox(height: 24),
                        
                        // Bottom Actions (queue, quality, info)
                        _buildBottomActions(responsive),
                        
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
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
                    icon: const Icon(Icons.keyboard_arrow_down, size: 32),
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
                    Icon(Icons.music_off_rounded, size: 80, color: AppTheme.secondaryColor),
                    const SizedBox(height: 16),
                    Text('No track playing', style: AppTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text('Select a track to start', style: AppTheme.bodyMedium.copyWith(color: AppTheme.secondaryColor)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, PlayerState playerState, Responsive responsive) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: responsive.horizontalPadding, vertical: 12),
      child: Column(
        children: [
          // Drag handle - tap to close
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 60,
              height: 24,
              alignment: Alignment.center,
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Playing From row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PLAYING FROM',
                      style: AppTheme.labelSmall.copyWith(
                        color: Colors.white.withOpacity(0.6),
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      playerState.queueSource ?? 'Your Library',
                      style: AppTheme.bodyMedium.copyWith(color: Colors.white),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.cast_outlined, color: Colors.white70),
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAlbumCover(Track track, Responsive responsive) {
    final coverSize = responsive.value(mobile: 280.0, tablet: 380.0);
    
    return Container(
      width: coverSize,
      height: coverSize,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: track.coverArtUrl != null
            ? CachedNetworkImage(
                imageUrl: track.coverArtUrl!,
                fit: BoxFit.cover,
                placeholder: (_, __) => _buildPlaceholder(coverSize),
                errorWidget: (_, __, ___) => _buildPlaceholder(coverSize),
              )
            : _buildPlaceholder(coverSize),
      ),
    );
  }

  Widget _buildPlaceholder(double size) {
    return Container(
      width: size,
      height: size,
      color: AppTheme.surfaceColor,
      child: const Icon(Icons.music_note, size: 80, color: AppTheme.secondaryColor),
    );
  }

  Widget _buildTrackInfo(Track track, Responsive responsive) {
    final favState = ref.watch(favoritesProvider);
    final isFavorite = favState.isFavorite(track);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                track.title,
                style: AppTheme.headlineSmall.copyWith(color: Colors.white),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                track.artist,
                style: AppTheme.bodyLarge.copyWith(color: Colors.white70),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        // Favorite
        IconButton(
          icon: Icon(
            isFavorite ? Icons.favorite : Icons.favorite_border,
            color: isFavorite ? AppTheme.accentColor : Colors.white70,
          ),
          onPressed: () => ref.read(favoritesProvider.notifier).toggleFavorite(track),
        ),
        // Share
        IconButton(
          icon: const Icon(Icons.share_outlined, color: Colors.white70),
          onPressed: () {},
        ),
        // More
        IconButton(
          icon: const Icon(Icons.more_vert, color: Colors.white70),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildProgressBar(PlayerState playerState, Responsive responsive) {
    final position = playerState.position;
    final duration = playerState.duration;
    final progress = duration.inMilliseconds > 0 
        ? position.inMilliseconds / duration.inMilliseconds 
        : 0.0;

    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            activeTrackColor: Colors.white,
            inactiveTrackColor: Colors.white.withOpacity(0.3),
            thumbColor: Colors.white,
            overlayColor: Colors.white.withOpacity(0.2),
          ),
          child: Slider(
            value: progress.clamp(0.0, 1.0),
            onChanged: (value) {
              final newPosition = Duration(milliseconds: (duration.inMilliseconds * value).round());
              ref.read(playerProvider.notifier).seek(newPosition);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_formatDuration(position), style: AppTheme.labelSmall.copyWith(color: Colors.white70)),
              // Quality badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(playerState.qualityLabel, style: AppTheme.labelSmall.copyWith(color: Colors.white, fontSize: 10)),
              ),
              Text(_formatDuration(duration), style: AppTheme.labelSmall.copyWith(color: Colors.white70)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlaybackControls(PlayerState playerState, Responsive responsive) {
    final notifier = ref.read(playerProvider.notifier);
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Shuffle
        IconButton(
          icon: Icon(
            Icons.shuffle,
            color: playerState.shuffleEnabled ? AppTheme.primaryColor : Colors.white70,
          ),
          onPressed: () => notifier.toggleShuffle(),
        ),
        const SizedBox(width: 16),
        // Previous
        IconButton(
          icon: const Icon(Icons.skip_previous, size: 36, color: Colors.white),
          onPressed: () => notifier.previous(),
        ),
        const SizedBox(width: 16),
        // Play/Pause
        Container(
          width: 64,
          height: 64,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
          child: IconButton(
            icon: Icon(
              playerState.isPlaying ? Icons.pause : Icons.play_arrow,
              size: 36,
              color: Colors.black,
            ),
            onPressed: () => notifier.togglePlayPause(),
          ),
        ),
        const SizedBox(width: 16),
        // Next
        IconButton(
          icon: const Icon(Icons.skip_next, size: 36, color: Colors.white),
          onPressed: () => notifier.next(),
        ),
        const SizedBox(width: 16),
        // Repeat
        IconButton(
          icon: Icon(
            playerState.repeatMode == RepeatMode.one 
                ? Icons.repeat_one 
                : Icons.repeat,
            color: playerState.repeatMode != RepeatMode.off ? AppTheme.primaryColor : Colors.white70,
          ),
          onPressed: () => notifier.cycleRepeatMode(),
        ),
      ],
    );
  }

  Widget _buildBottomActions(Responsive responsive) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Queue
        IconButton(
          icon: const Icon(Icons.queue_music_outlined, color: Colors.white70),
          onPressed: () {},
          tooltip: 'Queue',
        ),
        const SizedBox(width: 32),
        // Audio quality/Dolby
        IconButton(
          icon: const Icon(Icons.graphic_eq, color: Colors.white70),
          onPressed: () {},
          tooltip: 'Audio Quality',
        ),
        const SizedBox(width: 32),
        // Info
        IconButton(
          icon: const Icon(Icons.info_outline, color: Colors.white70),
          onPressed: () {},
          tooltip: 'Track Info',
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
