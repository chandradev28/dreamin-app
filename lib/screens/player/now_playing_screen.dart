import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../../providers/providers.dart';

/// Now Playing Screen - Responsive
class NowPlayingScreen extends ConsumerWidget {
  const NowPlayingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerProvider);
    final track = playerState.currentTrack;
    final responsive = Responsive(context);

    if (track == null) {
      return const Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: Center(
          child: Text('No track playing'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: responsive.isLandscape
            ? _buildLandscapeLayout(context, ref, playerState, responsive)
            : _buildPortraitLayout(context, ref, playerState, responsive),
      ),
    );
  }

  Widget _buildPortraitLayout(
    BuildContext context,
    WidgetRef ref,
    PlayerState playerState,
    Responsive responsive,
  ) {
    final track = playerState.currentTrack!;

    return Column(
      children: [
        // Header
        _buildHeader(context, responsive),

        // Main Content
        Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: responsive.horizontalPadding),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Waveform / Album Art
                Expanded(
                  flex: 3,
                  child: Center(
                    child: _WaveformVisualizer(
                      isPlaying: playerState.isPlaying,
                      size: responsive.nowPlayingCoverSize,
                    ),
                  ),
                ),

                // Track Info
                _buildTrackInfo(track, ref, responsive),

                // Progress Bar
                SizedBox(height: responsive.sectionSpacing),
                _ProgressBar(
                  position: playerState.position,
                  duration: playerState.duration,
                  onSeek: (position) {
                    ref.read(playerProvider.notifier).seek(position);
                  },
                ),

                // Playback Controls
                SizedBox(height: responsive.sectionSpacing),
                _PlaybackControls(
                  isPlaying: playerState.isPlaying,
                  isShuffleOn: playerState.isShuffleOn,
                  repeatMode: playerState.repeatMode,
                  responsive: responsive,
                  onPlayPause: () {
                    ref.read(playerProvider.notifier).togglePlayPause();
                  },
                  onPrevious: () {
                    ref.read(playerProvider.notifier).skipPrevious();
                  },
                  onNext: () {
                    ref.read(playerProvider.notifier).skipNext();
                  },
                  onShuffle: () {
                    ref.read(playerProvider.notifier).toggleShuffle();
                  },
                  onRepeat: () {
                    ref.read(playerProvider.notifier).toggleRepeat();
                  },
                ),

                // Volume Slider
                SizedBox(height: responsive.sectionSpacing),
                _VolumeSlider(
                  volume: playerState.volume,
                  isMuted: playerState.isMuted,
                  onVolumeChanged: (volume) {
                    ref.read(playerProvider.notifier).setVolume(volume);
                  },
                ),

                SizedBox(height: responsive.sectionSpacing),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLandscapeLayout(
    BuildContext context,
    WidgetRef ref,
    PlayerState playerState,
    Responsive responsive,
  ) {
    final track = playerState.currentTrack!;

    return Row(
      children: [
        // Left side - Waveform
        Expanded(
          flex: 1,
          child: Center(
            child: _WaveformVisualizer(
              isPlaying: playerState.isPlaying,
              size: responsive.screenHeight * 0.5,
            ),
          ),
        ),

        // Right side - Controls
        Expanded(
          flex: 1,
          child: Padding(
            padding: EdgeInsets.all(responsive.horizontalPadding),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Track Info
                _buildTrackInfo(track, ref, responsive),

                SizedBox(height: responsive.sectionSpacing),

                // Progress Bar
                _ProgressBar(
                  position: playerState.position,
                  duration: playerState.duration,
                  onSeek: (position) {
                    ref.read(playerProvider.notifier).seek(position);
                  },
                ),

                SizedBox(height: responsive.sectionSpacing),

                // Controls
                _PlaybackControls(
                  isPlaying: playerState.isPlaying,
                  isShuffleOn: playerState.isShuffleOn,
                  repeatMode: playerState.repeatMode,
                  responsive: responsive,
                  onPlayPause: () => ref.read(playerProvider.notifier).togglePlayPause(),
                  onPrevious: () => ref.read(playerProvider.notifier).skipPrevious(),
                  onNext: () => ref.read(playerProvider.notifier).skipNext(),
                  onShuffle: () => ref.read(playerProvider.notifier).toggleShuffle(),
                  onRepeat: () => ref.read(playerProvider.notifier).toggleRepeat(),
                ),

                SizedBox(height: responsive.sectionSpacing),

                // Volume
                _VolumeSlider(
                  volume: playerState.volume,
                  isMuted: playerState.isMuted,
                  onVolumeChanged: (volume) {
                    ref.read(playerProvider.notifier).setVolume(volume);
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, Responsive responsive) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.horizontalPadding,
        vertical: responsive.value(mobile: 12.0, tablet: 16.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(
              Icons.keyboard_arrow_down,
              size: responsive.value(mobile: 32.0, tablet: 40.0),
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Row(
            children: [
              _TabButton(
                label: 'Playing',
                isSelected: true,
                onTap: () {},
                responsive: responsive,
              ),
              SizedBox(width: responsive.sectionSpacing),
              _TabButton(
                label: 'Lyrics',
                isSelected: false,
                onTap: () {},
                responsive: responsive,
              ),
            ],
          ),
          IconButton(
            icon: Icon(
              Icons.speaker_group_outlined,
              size: responsive.value(mobile: 24.0, tablet: 28.0),
            ),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildTrackInfo(track, WidgetRef ref, Responsive responsive) {
    final favState = ref.watch(favoritesProvider);
    final isFavorite = favState.favoriteIds.contains('${track.id}_${track.source.name}');

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                track.title,
                style: responsive.value(
                  mobile: AppTheme.headlineSmall,
                  tablet: AppTheme.headlineMedium,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                track.artist,
                style: AppTheme.bodyMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        IconButton(
          icon: Icon(
            isFavorite ? Icons.favorite : Icons.favorite_border,
            size: responsive.value(mobile: 28.0, tablet: 32.0),
          ),
          color: isFavorite ? AppTheme.accentColor : AppTheme.primaryColor,
          onPressed: () {
            ref.read(favoritesProvider.notifier).toggleFavorite(track);
          },
        ),
      ],
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Responsive responsive;

  const _TabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.responsive,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        label,
        style: (isSelected
            ? responsive.value(mobile: AppTheme.titleSmall, tablet: AppTheme.titleMedium)
            : responsive.value(mobile: AppTheme.titleSmall, tablet: AppTheme.titleMedium)
                .copyWith(color: AppTheme.secondaryColor)),
      ),
    );
  }
}

class _WaveformVisualizer extends StatefulWidget {
  final bool isPlaying;
  final double size;

  const _WaveformVisualizer({
    required this.isPlaying,
    required this.size,
  });

  @override
  State<_WaveformVisualizer> createState() => _WaveformVisualizerState();
}

class _WaveformVisualizerState extends State<_WaveformVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    if (widget.isPlaying) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(_WaveformVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.isPlaying && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size * 0.5),
          painter: _WaveformPainter(
            progress: _controller.value,
            isPlaying: widget.isPlaying,
          ),
        );
      },
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final double progress;
  final bool isPlaying;

  _WaveformPainter({required this.progress, required this.isPlaying});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.primaryColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final width = size.width;
    final height = size.height;
    final centerY = height / 2;

    path.moveTo(0, centerY);

    for (double x = 0; x <= width; x += 3) {
      final normalizedX = x / width;
      final wave1 = math.sin((normalizedX * 4 * math.pi) + (progress * 2 * math.pi)) * 30;
      final wave2 = math.sin((normalizedX * 8 * math.pi) + (progress * 3 * math.pi)) * 15;
      final wave3 = math.sin((normalizedX * 2 * math.pi) + (progress * math.pi)) * 20;
      
      final amplitude = isPlaying ? (wave1 + wave2 + wave3) : (wave1 + wave2 + wave3) * 0.3;
      final y = centerY + amplitude;
      
      path.lineTo(x, y);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isPlaying != isPlaying;
  }
}

class _ProgressBar extends StatelessWidget {
  final Duration position;
  final Duration duration;
  final ValueChanged<Duration> onSeek;

  const _ProgressBar({
    required this.position,
    required this.duration,
    required this.onSeek,
  });

  @override
  Widget build(BuildContext context) {
    final progress = duration.inMilliseconds > 0
        ? position.inMilliseconds / duration.inMilliseconds
        : 0.0;
    final responsive = Responsive(context);

    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: responsive.value(mobile: 4.0, tablet: 6.0),
            thumbShape: RoundSliderThumbShape(
              enabledThumbRadius: responsive.value(mobile: 6.0, tablet: 8.0),
            ),
            overlayShape: RoundSliderOverlayShape(
              overlayRadius: responsive.value(mobile: 14.0, tablet: 18.0),
            ),
          ),
          child: Slider(
            value: progress.clamp(0.0, 1.0),
            onChanged: (value) {
              final newPosition = Duration(
                milliseconds: (value * duration.inMilliseconds).round(),
              );
              onSeek(newPosition);
            },
            activeColor: AppTheme.primaryColor,
            inactiveColor: AppTheme.surfaceLighter,
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: responsive.horizontalPadding),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_formatDuration(position), style: AppTheme.bodySmall),
              Text(_formatDuration(duration), style: AppTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

class _PlaybackControls extends StatelessWidget {
  final bool isPlaying;
  final bool isShuffleOn;
  final RepeatMode repeatMode;
  final Responsive responsive;
  final VoidCallback onPlayPause;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onShuffle;
  final VoidCallback onRepeat;

  const _PlaybackControls({
    required this.isPlaying,
    required this.isShuffleOn,
    required this.repeatMode,
    required this.responsive,
    required this.onPlayPause,
    required this.onPrevious,
    required this.onNext,
    required this.onShuffle,
    required this.onRepeat,
  });

  @override
  Widget build(BuildContext context) {
    final playButtonSize = responsive.value(mobile: 72.0, tablet: 88.0);
    final iconSize = responsive.value(mobile: 40.0, tablet: 48.0);
    final navIconSize = responsive.value(mobile: 36.0, tablet: 44.0);
    final smallIconSize = responsive.value(mobile: 24.0, tablet: 28.0);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          icon: Icon(Icons.shuffle, size: smallIconSize),
          color: isShuffleOn ? AppTheme.primaryColor : AppTheme.secondaryColor,
          onPressed: onShuffle,
        ),
        IconButton(
          icon: Icon(Icons.skip_previous, size: navIconSize),
          onPressed: onPrevious,
          color: AppTheme.primaryColor,
        ),
        Container(
          width: playButtonSize,
          height: playButtonSize,
          decoration: const BoxDecoration(
            color: AppTheme.primaryColor,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(
              isPlaying ? Icons.pause : Icons.play_arrow,
              size: iconSize,
              color: AppTheme.backgroundColor,
            ),
            onPressed: onPlayPause,
          ),
        ),
        IconButton(
          icon: Icon(Icons.skip_next, size: navIconSize),
          onPressed: onNext,
          color: AppTheme.primaryColor,
        ),
        IconButton(
          icon: Icon(
            repeatMode == RepeatMode.one ? Icons.repeat_one : Icons.repeat,
            size: smallIconSize,
          ),
          color: repeatMode != RepeatMode.off
              ? AppTheme.primaryColor
              : AppTheme.secondaryColor,
          onPressed: onRepeat,
        ),
      ],
    );
  }
}

class _VolumeSlider extends StatelessWidget {
  final double volume;
  final bool isMuted;
  final ValueChanged<double> onVolumeChanged;

  const _VolumeSlider({
    required this.volume,
    required this.isMuted,
    required this.onVolumeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);

    return Row(
      children: [
        Icon(
          isMuted || volume == 0
              ? Icons.volume_off
              : volume < 0.5
                  ? Icons.volume_down
                  : Icons.volume_up,
          color: AppTheme.secondaryColor,
          size: responsive.value(mobile: 20.0, tablet: 24.0),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: responsive.value(mobile: 3.0, tablet: 4.0),
              thumbShape: RoundSliderThumbShape(
                enabledThumbRadius: responsive.value(mobile: 5.0, tablet: 7.0),
              ),
              overlayShape: RoundSliderOverlayShape(
                overlayRadius: responsive.value(mobile: 12.0, tablet: 16.0),
              ),
            ),
            child: Slider(
              value: volume,
              onChanged: onVolumeChanged,
              activeColor: AppTheme.secondaryColor,
              inactiveColor: AppTheme.surfaceLighter,
            ),
          ),
        ),
      ],
    );
  }
}
