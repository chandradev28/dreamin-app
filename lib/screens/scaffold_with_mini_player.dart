import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../providers/providers.dart';
import '../widgets/widgets.dart';
import 'player/now_playing_screen.dart';

/// Scaffold wrapper that includes mini player at bottom
/// Use this for screens that need to show mini player (detail screens, etc.)
class ScaffoldWithMiniPlayer extends ConsumerStatefulWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Color? backgroundColor;
  final bool extendBody;
  final bool extendBodyBehindAppBar;

  const ScaffoldWithMiniPlayer({
    super.key,
    required this.body,
    this.appBar,
    this.backgroundColor,
    this.extendBody = false,
    this.extendBodyBehindAppBar = false,
  });

  @override
  ConsumerState<ScaffoldWithMiniPlayer> createState() =>
      _ScaffoldWithMiniPlayerState();
}

class _ScaffoldWithMiniPlayerState
    extends ConsumerState<ScaffoldWithMiniPlayer> {
  String? _lastError;

  void _openNowPlaying(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return const NowPlayingScreen();
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeOutCubic;

          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(playerProvider);
    final hasTrack = playerState.hasTrack;

    // Show snackbar when error changes
    if (playerState.error != null && playerState.error != _lastError) {
      _lastError = playerState.error;
      // Show snackbar after build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(playerState.error!),
              backgroundColor: AppTheme.errorColor,
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.only(
                bottom: hasTrack ? 80 : 16,
                left: 16,
                right: 16,
              ),
            ),
          );
        }
      });
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: widget.extendBody,
      extendBodyBehindAppBar: widget.extendBodyBehindAppBar,
      appBar: widget.appBar,
      body: PosterGradientBackground(
        fallbackGradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            (widget.backgroundColor ?? AppTheme.backgroundColor)
                .withOpacity(0.92),
            AppTheme.backgroundColor,
          ],
        ),
        child: Stack(
          children: [
            Positioned.fill(
              bottom: hasTrack ? 64.0 : 0,
              child: widget.body,
            ),
            if (hasTrack)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: MiniPlayer(onTap: () => _openNowPlaying(context)),
              ),
          ],
        ),
      ),
    );
  }
}
