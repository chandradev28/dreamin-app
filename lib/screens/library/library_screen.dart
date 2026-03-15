import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../../providers/providers.dart';
import 'library_playlists_screen.dart';
import 'library_albums_screen.dart';
import 'library_tracks_screen.dart';
import 'library_artists_screen.dart';
import 'library_downloads_screen.dart';
import '../settings/settings_screen.dart';

/// Library Screen - TIDAL Collection Style
/// Clean list design with sections for Playlists, Albums, Tracks, Artists, etc.
class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final responsive = Responsive(context);
    final favoritesState = ref.watch(favoritesProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header - TIDAL Style
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  responsive.horizontalPadding,
                  responsive.horizontalPadding,
                  responsive.horizontalPadding,
                  16,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Library',
                      style: AppTheme.headlineLarge.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.settings_outlined),
                          iconSize: 24,
                          color: Colors.white,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const SettingsScreen()),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Library Categories - TIDAL Clean Style
            SliverToBoxAdapter(
              child: Column(
                children: [
                  // Playlists
                  _TidalLibraryTile(
                    icon: Icons.queue_music_outlined,
                    title: 'Playlists',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const LibraryPlaylistsScreen()),
                      );
                    },
                  ),

                  // Albums
                  _TidalLibraryTile(
                    icon: Icons.album_outlined,
                    title: 'Albums',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const LibraryAlbumsScreen()),
                      );
                    },
                  ),

                  // Tracks / Favorites
                  _TidalLibraryTile(
                    icon: Icons.music_note_outlined,
                    title: 'Tracks',
                    subtitle: '${favoritesState.favorites.length} liked songs',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const LibraryTracksScreen()),
                      );
                    },
                  ),

                  // Artists
                  _TidalLibraryTile(
                    icon: Icons.person_outline,
                    title: 'Artists',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const LibraryArtistsScreen()),
                      );
                    },
                  ),

                  // Downloads
                  _TidalLibraryTile(
                    icon: Icons.download_outlined,
                    title: 'Downloads',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const LibraryDownloadsScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Bottom spacing for mini player
            SliverToBoxAdapter(
              child: SizedBox(
                  height: responsive.miniPlayerHeight +
                      responsive.bottomNavHeight +
                      20),
            ),
          ],
        ),
      ),
    );
  }
}

/// TIDAL-style Library List Tile
/// Clean design with outline icons, no colored backgrounds
class _TidalLibraryTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _TidalLibraryTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: responsive.horizontalPadding,
          vertical: 14,
        ),
        child: Row(
          children: [
            // Icon
            Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 20),
            // Title and subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTheme.bodyLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        subtitle!,
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.secondaryColor,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
