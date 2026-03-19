import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palette_generator/palette_generator.dart';

import '../core/theme/app_theme.dart';
import '../providers/providers.dart';

class PosterGradientBackground extends ConsumerStatefulWidget {
  final Widget child;
  final Gradient? fallbackGradient;

  const PosterGradientBackground({
    super.key,
    required this.child,
    this.fallbackGradient,
  });

  @override
  ConsumerState<PosterGradientBackground> createState() =>
      _PosterGradientBackgroundState();
}

class _PosterGradientBackgroundState
    extends ConsumerState<PosterGradientBackground> {
  String? _coverUrl;
  Color _dominantColor = AppTheme.backgroundColor;

  @override
  Widget build(BuildContext context) {
    final track =
        ref.watch(playerProvider.select((state) => state.currentTrack));
    final coverUrl = track?.coverArtUrl;

    if (coverUrl != _coverUrl) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updatePalette(coverUrl);
      });
    }

    final hasArtwork = coverUrl != null && coverUrl.isNotEmpty;

    return Stack(
      fit: StackFit.expand,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          decoration: BoxDecoration(
            gradient: hasArtwork
                ? LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      _dominantColor.withOpacity(0.95),
                      _dominantColor.withOpacity(0.55),
                      AppTheme.backgroundColor.withOpacity(0.96),
                      AppTheme.backgroundColor,
                    ],
                    stops: const [0.0, 0.28, 0.68, 1.0],
                  )
                : widget.fallbackGradient ??
                    const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF0D1B18),
                        AppTheme.backgroundColor,
                      ],
                    ),
          ),
        ),
        if (hasArtwork)
          Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.26,
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                  child: CachedNetworkImage(
                    imageUrl: coverUrl,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(hasArtwork ? 0.18 : 0.0),
                  Colors.black.withOpacity(0.35),
                  Colors.black.withOpacity(0.72),
                  Colors.black.withOpacity(0.92),
                ],
                stops: const [0.0, 0.22, 0.62, 1.0],
              ),
            ),
          ),
        ),
        Positioned.fill(child: widget.child),
      ],
    );
  }

  Future<void> _updatePalette(String? coverUrl) async {
    _coverUrl = coverUrl;

    if (coverUrl == null || coverUrl.isEmpty) {
      if (mounted) {
        setState(() {
          _dominantColor = AppTheme.backgroundColor;
        });
      }
      return;
    }

    try {
      final palette = await PaletteGenerator.fromImageProvider(
        CachedNetworkImageProvider(coverUrl),
        size: const Size(120, 120),
        maximumColorCount: 12,
      );

      if (!mounted || _coverUrl != coverUrl) {
        return;
      }

      setState(() {
        _dominantColor = palette.darkVibrantColor?.color ??
            palette.dominantColor?.color ??
            palette.vibrantColor?.color ??
            AppTheme.backgroundColor;
      });
    } catch (_) {
      if (!mounted || _coverUrl != coverUrl) {
        return;
      }

      setState(() {
        _dominantColor = AppTheme.backgroundColor;
      });
    }
  }
}
