import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';

/// Home Screen - Responsive with Recommendations
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeData = ref.watch(homeDataProvider);
    final responsive = Responsive(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: RefreshIndicator(
        onRefresh: () => ref.read(homeDataProvider.notifier).refresh(),
        color: AppTheme.primaryColor,
        backgroundColor: AppTheme.surfaceColor,
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              floating: true,
              backgroundColor: AppTheme.backgroundColor,
              toolbarHeight: responsive.value(mobile: 56.0, tablet: 64.0),
              title: Text(
                'Dreamin',
                style: responsive.value(
                  mobile: AppTheme.headlineMedium,
                  tablet: AppTheme.headlineLarge,
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: () {},
                ),
                SizedBox(width: responsive.value(mobile: 8.0, tablet: 16.0)),
              ],
            ),

            // Content
            if (homeData.isLoading)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.primaryColor,
                  ),
                ),
              )
            else if (homeData.error != null)
              SliverFillRemaining(
                child: _ErrorWidget(
                  message: homeData.error!,
                  onRetry: () => ref.read(homeDataProvider.notifier).refresh(),
                ),
              )
            else ...[
              // For You - Recommendations
              if (homeData.recommendations.isNotEmpty)
                SliverToBoxAdapter(
                  child: ForYouSection(
                    tracks: homeData.recommendations,
                    onTrackTap: (track, index) {
                      ref.read(playerProvider.notifier).playQueue(
                        homeData.recommendations,
                        startIndex: index,
                      );
                    },
                  ),
                ),

              // Suggested New Albums
              if (homeData.newAlbums.isNotEmpty) ...[
                const SliverToBoxAdapter(
                  child: SectionHeader(
                    title: 'Suggested New Albums',
                  ),
                ),
                SliverToBoxAdapter(
                  child: HorizontalScrollList(
                    items: homeData.newAlbums,
                    itemWidth: responsive.albumCardWidth,
                    itemBuilder: (album, width) => AlbumCard(
                      album: album,
                      width: width,
                      onTap: () {
                        // Navigate to album detail
                      },
                    ),
                  ),
                ),
              ],

              // Popular Playlists
              if (homeData.popularPlaylists.isNotEmpty) ...[
                const SliverToBoxAdapter(
                  child: SectionHeader(
                    title: 'Popular Playlists',
                  ),
                ),
                SliverToBoxAdapter(
                  child: HorizontalScrollList(
                    items: homeData.popularPlaylists,
                    itemWidth: responsive.playlistCardWidth,
                    itemBuilder: (playlist, width) => PlaylistCard(
                      playlist: playlist,
                      width: width,
                      onTap: () {
                        // Navigate to playlist detail
                      },
                    ),
                  ),
                ),
              ],

              // Featured Playlists
              if (homeData.featuredPlaylists.isNotEmpty) ...[
                const SliverToBoxAdapter(
                  child: SectionHeader(
                    title: 'Featured Playlists',
                  ),
                ),
                SliverToBoxAdapter(
                  child: HorizontalScrollList(
                    items: homeData.featuredPlaylists,
                    itemWidth: responsive.playlistCardWidth,
                    itemBuilder: (playlist, width) => PlaylistCard(
                      playlist: playlist,
                      width: width,
                      onTap: () {
                        // Navigate to playlist detail
                      },
                    ),
                  ),
                ),
              ],

              // Bottom spacing for mini player
              SliverToBoxAdapter(
                child: SizedBox(height: responsive.miniPlayerHeight + responsive.bottomNavHeight + 20),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorWidget({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);
    
    return Center(
      child: Padding(
        padding: EdgeInsets.all(responsive.horizontalPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: responsive.value(mobile: 64.0, tablet: 80.0),
              color: AppTheme.errorColor,
            ),
            SizedBox(height: responsive.sectionSpacing),
            Text(
              'Something went wrong',
              style: AppTheme.titleLarge,
            ),
            const SizedBox(height: AppTheme.spacingS),
            Text(
              message,
              style: AppTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: responsive.sectionSpacing),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
