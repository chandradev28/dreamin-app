import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';
import '../../models/models.dart';
import '../album/album_detail_screen.dart';
import '../playlist/playlist_detail_screen.dart';
import '../artist/artist_detail_screen.dart';

/// Home Screen - Echo-style with multiple sections
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
              // 1. FOR YOU - Recommendations (Main featured section)
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

              // 2. CONTINUE STREAMING - Recently Played Artists (circular avatars)
              if (homeData.recentlyPlayedArtists.isNotEmpty) ...[
                const SliverToBoxAdapter(
                  child: SectionHeader(
                    title: 'Continue streaming',
                  ),
                ),
                SliverToBoxAdapter(
                  child: _ArtistCircleList(
                    artists: homeData.recentlyPlayedArtists,
                    onArtistTap: (artist) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ArtistDetailScreen(
                            artistId: artist.id,
                            artist: artist,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],

              // 3. MIXES INSPIRED BY - Tracks based on listening history
              if (homeData.mixesTracks.isNotEmpty) ...[
                const SliverToBoxAdapter(
                  child: SectionHeader(
                    title: 'Mixes inspired by...',
                  ),
                ),
                SliverToBoxAdapter(
                  child: HorizontalScrollList(
                    items: homeData.mixesTracks,
                    itemWidth: responsive.albumCardWidth,
                    itemBuilder: (track, width) => TrackCard(
                      track: track,
                      width: width,
                      onTap: () {
                        ref.read(playerProvider.notifier).playQueue(
                          homeData.mixesTracks,
                          startIndex: homeData.mixesTracks.indexOf(track),
                        );
                      },
                    ),
                  ),
                ),
              ],

              // 4. NEW RELEASES FOR YOU
              if (homeData.newAlbums.isNotEmpty) ...[
                const SliverToBoxAdapter(
                  child: SectionHeader(
                    title: 'New releases for you',
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
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => AlbumDetailScreen(
                              albumId: album.id,
                              album: album,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],

              // 5. SINCE YOU LIKE [ARTIST] - Similar artists
              if (homeData.similarArtists.isNotEmpty && 
                  homeData.similarToArtistName != null) ...[
                SliverToBoxAdapter(
                  child: SectionHeader(
                    title: 'Since you like ${homeData.similarToArtistName}',
                  ),
                ),
                SliverToBoxAdapter(
                  child: _ArtistCircleList(
                    artists: homeData.similarArtists,
                    onArtistTap: (artist) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ArtistDetailScreen(
                            artistId: artist.id,
                            artist: artist,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],

              // 6. RECENTLY YOU'VE BEEN LOVING - Favorites
              if (homeData.lovedTracks.isNotEmpty) ...[
                const SliverToBoxAdapter(
                  child: SectionHeader(
                    title: "Recently you've been loving...",
                  ),
                ),
                SliverToBoxAdapter(
                  child: HorizontalScrollList(
                    items: homeData.lovedTracks,
                    itemWidth: responsive.albumCardWidth,
                    itemBuilder: (track, width) => TrackCard(
                      track: track,
                      width: width,
                      onTap: () {
                        ref.read(playerProvider.notifier).playQueue(
                          homeData.lovedTracks,
                          startIndex: homeData.lovedTracks.indexOf(track),
                        );
                      },
                    ),
                  ),
                ),
              ],

              // 7. PLAYLISTS YOU'LL LOVE
              if (homeData.playlistsForYou.isNotEmpty) ...[
                const SliverToBoxAdapter(
                  child: SectionHeader(
                    title: "Playlists you'll love",
                  ),
                ),
                SliverToBoxAdapter(
                  child: HorizontalScrollList(
                    items: homeData.playlistsForYou,
                    itemWidth: responsive.playlistCardWidth,
                    itemBuilder: (playlist, width) => PlaylistCard(
                      playlist: playlist,
                      width: width,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => PlaylistDetailScreen(
                              playlistId: playlist.id,
                              playlist: playlist,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],

              // 8. YOUR TOP GENRES
              if (homeData.topGenres.isNotEmpty) ...[
                const SliverToBoxAdapter(
                  child: SectionHeader(
                    title: 'Your top genres',
                  ),
                ),
                SliverToBoxAdapter(
                  child: _GenreChipsGrid(
                    genres: homeData.topGenres,
                    onGenreTap: (genre) {
                      // Navigate to genre search
                    },
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

/// Circular artist avatars (Echo-style)
class _ArtistCircleList extends StatelessWidget {
  final List<Artist> artists;
  final Function(Artist) onArtistTap;

  const _ArtistCircleList({
    required this.artists,
    required this.onArtistTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 130,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingM),
        itemCount: artists.length,
        itemBuilder: (context, index) {
          final artist = artists[index];
          return Padding(
            padding: const EdgeInsets.only(right: AppTheme.spacingM),
            child: GestureDetector(
              onTap: () => onArtistTap(artist),
              child: SizedBox(
                width: 90,
                child: Column(
                  children: [
                    // Circular avatar
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.surfaceColor,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: artist.imageUrl != null
                            ? Image.network(
                                artist.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _ArtistPlaceholder(name: artist.name),
                              )
                            : _ArtistPlaceholder(name: artist.name),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingS),
                    // Artist name
                    Text(
                      artist.name,
                      style: AppTheme.bodySmall,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Artist placeholder avatar
class _ArtistPlaceholder extends StatelessWidget {
  final String name;

  const _ArtistPlaceholder({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.primaryColor.withOpacity(0.2),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: AppTheme.headlineMedium.copyWith(
            color: AppTheme.primaryColor,
          ),
        ),
      ),
    );
  }
}

/// Genre chips grid (Echo-style)
class _GenreChipsGrid extends StatelessWidget {
  final List<String> genres;
  final Function(String) onGenreTap;

  const _GenreChipsGrid({
    required this.genres,
    required this.onGenreTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingM),
      child: Wrap(
        spacing: AppTheme.spacingS,
        runSpacing: AppTheme.spacingS,
        children: genres.map((genre) {
          return GestureDetector(
            onTap: () => onGenreTap(genre),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingM,
                vertical: AppTheme.spacingS,
              ),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
                border: Border.all(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                ),
              ),
              child: Text(
                genre,
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
          );
        }).toList(),
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
