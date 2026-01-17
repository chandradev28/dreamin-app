import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../providers/providers.dart';
import '../widgets/widgets.dart';
import 'player/now_playing_screen.dart';

/// Scaffold wrapper that includes mini player at bottom
/// Use this for screens that need to show mini player (detail screens, etc.)
class ScaffoldWithMiniPlayer extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerProvider);
    final hasTrack = playerState.hasTrack;

    return Scaffold(
      backgroundColor: backgroundColor ?? AppTheme.backgroundColor,
      extendBody: extendBody,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      appBar: appBar,
      body: Stack(
        children: [
          // Main content - add bottom padding if mini player is showing
          Positioned.fill(
            bottom: hasTrack ? 64.0 : 0,
            child: body,
          ),

          // Mini player at bottom
          if (hasTrack)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: MiniPlayer(onTap: () => _openNowPlaying(context)),
            ),
        ],
      ),
    );
  }
}
