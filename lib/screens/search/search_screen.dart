import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';
import '../../models/models.dart';
import '../album/album_detail_screen.dart';
import '../playlist/playlist_detail_screen.dart';
import '../artist/artist_detail_screen.dart';

/// Search Screen - Echo/Deezer Style with Browse Sections
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _debounceTimer;

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (query.trim().isNotEmpty) {
        ref.read(searchProvider.notifier).search(query);
      } else {
        ref.read(searchProvider.notifier).clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchProvider);
    final homeData = ref.watch(homeDataProvider);
    final responsive = Responsive(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Search Header with Search Bar
            Container(
              color: AppTheme.backgroundColor,
              padding: EdgeInsets.fromLTRB(
                responsive.horizontalPadding,
                responsive.value(mobile: 12.0, tablet: 16.0),
                responsive.horizontalPadding,
                responsive.value(mobile: 12.0, tablet: 16.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title removed - search bar is prominent
                  // Search Input - Echo Style (rounded, dark background)
                  Container(
                    height: responsive.value(mobile: 48.0, tablet: 56.0),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() {});
                        _onSearchChanged(value);
                      },
                      style: AppTheme.bodyLarge.copyWith(color: AppTheme.primaryColor),
                      decoration: InputDecoration(
                        hintText: 'Search',
                        hintStyle: AppTheme.bodyLarge.copyWith(
                          color: AppTheme.secondaryColor,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: AppTheme.secondaryColor,
                          size: responsive.value(mobile: 24.0, tablet: 28.0),
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(
                                  Icons.clear,
                                  color: AppTheme.secondaryColor,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  ref.read(searchProvider.notifier).clear();
                                  setState(() {});
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingM,
                          vertical: AppTheme.spacingM,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: Container(
                color: AppTheme.backgroundColor,
                child: _buildContent(searchState, homeData, responsive),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(SearchState searchState, HomeDataState homeData, Responsive responsive) {
    // Show loading
    if (searchState.isLoading) {
      return Container(
        color: AppTheme.backgroundColor,
        child: const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryColor),
        ),
      );
    }

    // Show error
    if (searchState.error != null) {
      return Container(
        color: AppTheme.backgroundColor,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: responsive.value(mobile: 48.0, tablet: 64.0),
                color: AppTheme.errorColor,
              ),
              SizedBox(height: responsive.sectionSpacing),
              Text('Search failed', style: AppTheme.titleLarge),
              const SizedBox(height: AppTheme.spacingS),
              Text(
                searchState.error!,
                style: AppTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // If no query, show BROWSE sections (Echo-style)
    if (searchState.query.isEmpty || _searchController.text.isEmpty) {
      return _buildBrowseSections(homeData, responsive);
    }

    // Show no results
    if (searchState.result == null || searchState.result!.isEmpty) {
      return Container(
        color: AppTheme.backgroundColor,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: responsive.value(mobile: 48.0, tablet: 64.0),
                color: AppTheme.secondaryColor,
              ),
              SizedBox(height: responsive.sectionSpacing),
              Text('No results found', style: AppTheme.titleLarge),
              const SizedBox(height: AppTheme.spacingS),
              Text('Try a different search term', style: AppTheme.bodyMedium),
            ],
          ),
        ),
      );
    }

    // Show results
    return _buildSearchResults(searchState.result!, responsive);
  }

  /// Echo-style Browse Sections (shown when not searching)
  Widget _buildBrowseSections(HomeDataState homeData, Responsive responsive) {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: EdgeInsets.only(
        bottom: responsive.miniPlayerHeight + responsive.bottomNavHeight + 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // SECTION 1: Highlights (Featured Playlists)
          if (homeData.playlistsForYou.isNotEmpty) ...[
            _SectionHeader(
              title: 'Highlights',
              onSeeAll: () {},
            ),
            SizedBox(
              height: responsive.value(mobile: 180.0, tablet: 220.0),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: responsive.horizontalPadding),
                itemCount: homeData.playlistsForYou.length,
                itemBuilder: (context, index) {
                  final playlist = homeData.playlistsForYou[index];
                  return _PlaylistBrowseCard(
                    playlist: playlist,
                    width: responsive.value(mobile: 140.0, tablet: 180.0),
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
                  );
                },
              ),
            ),
            SizedBox(height: responsive.sectionSpacing),
          ],

          // SECTION 2: Your 2026 Level Up (New Albums)
          if (homeData.newAlbums.isNotEmpty) ...[
            _SectionHeader(
              title: 'Your 2026 level up',
              onSeeAll: () {},
            ),
            SizedBox(
              height: responsive.value(mobile: 200.0, tablet: 240.0),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: responsive.horizontalPadding),
                itemCount: homeData.newAlbums.length,
                itemBuilder: (context, index) {
                  final album = homeData.newAlbums[index];
                  return _AlbumBrowseCard(
                    album: album,
                    width: responsive.value(mobile: 140.0, tablet: 180.0),
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
                  );
                },
              ),
            ),
            SizedBox(height: responsive.sectionSpacing),
          ],

          // SECTION 3: This week's freshest releases (Trending Tracks as Playlists)
          if (homeData.recommendations.isNotEmpty) ...[
            _SectionHeader(
              title: "This week's freshest releases",
              onSeeAll: () {},
            ),
            SizedBox(
              height: responsive.value(mobile: 180.0, tablet: 220.0),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: responsive.horizontalPadding),
                itemCount: (homeData.recommendations.length / 2).ceil().clamp(0, 6),
                itemBuilder: (context, index) {
                  final track = homeData.recommendations[index];
                  return _TrackBrowseCard(
                    track: track,
                    width: responsive.value(mobile: 140.0, tablet: 180.0),
                    onTap: () {
                      ref.read(playerProvider.notifier).playQueue(
                        homeData.recommendations,
                        startIndex: index,
                      );
                    },
                  );
                },
              ),
            ),
            SizedBox(height: responsive.sectionSpacing),
          ],

          // SECTION 4: Top Genres as Cards
          if (homeData.topGenres.isNotEmpty) ...[
            _SectionHeader(
              title: 'Browse by genre',
              onSeeAll: () {},
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: responsive.horizontalPadding),
              child: Wrap(
                spacing: AppTheme.spacingS,
                runSpacing: AppTheme.spacingS,
                children: homeData.topGenres.map((genre) {
                  return _GenreCard(
                    genre: genre,
                    onTap: () {
                      _searchController.text = genre;
                      _onSearchChanged(genre);
                    },
                  );
                }).toList(),
              ),
            ),
            SizedBox(height: responsive.sectionSpacing),
          ],

          // SECTION 5: Popular Artists
          if (homeData.recentlyPlayedArtists.isNotEmpty) ...[
            _SectionHeader(
              title: 'Popular artists',
              onSeeAll: () {},
            ),
            SizedBox(
              height: responsive.value(mobile: 140.0, tablet: 170.0),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: responsive.horizontalPadding),
                itemCount: homeData.recentlyPlayedArtists.length,
                itemBuilder: (context, index) {
                  final artist = homeData.recentlyPlayedArtists[index];
                  return _ArtistBrowseCard(
                    artist: artist,
                    onTap: () {
                      _searchController.text = artist.name;
                      _onSearchChanged(artist.name);
                    },
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Search results with tabs
  Widget _buildSearchResults(SearchResult result, Responsive responsive) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          // Tabs
          Container(
            color: AppTheme.backgroundColor,
            child: TabBar(
              labelColor: AppTheme.primaryColor,
              unselectedLabelColor: AppTheme.secondaryColor,
              indicatorColor: AppTheme.primaryColor,
              indicatorWeight: 3,
              labelStyle: responsive.value(
                mobile: AppTheme.labelLarge,
                tablet: AppTheme.titleSmall,
              ),
              tabs: [
                Tab(text: 'Tracks (${result.tracks.length})'),
                Tab(text: 'Albums (${result.albums.length})'),
                Tab(text: 'Artists (${result.artists.length})'),
              ],
            ),
          ),
          // Tab Content
          Expanded(
            child: Container(
              color: AppTheme.backgroundColor,
              child: TabBarView(
                children: [
                  _buildTracksList(result.tracks, responsive),
                  _buildAlbumsGrid(result.albums, responsive),
                  _buildArtistsGrid(result.artists, responsive),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTracksList(List<Track> tracks, Responsive responsive) {
    if (tracks.isEmpty) {
      return Container(
        color: AppTheme.backgroundColor,
        child: const Center(
          child: Text('No tracks found', style: TextStyle(color: AppTheme.secondaryColor)),
        ),
      );
    }

    return Container(
      color: AppTheme.backgroundColor,
      child: ListView.builder(
        padding: EdgeInsets.only(
          top: AppTheme.spacingS,
          bottom: responsive.miniPlayerHeight + responsive.bottomNavHeight + 20,
        ),
        itemCount: tracks.length,
        itemBuilder: (context, index) {
          final track = tracks[index];
          final playerState = ref.watch(playerProvider);
          final favState = ref.watch(favoritesProvider);

          return TrackListTile(
            track: track,
            isPlaying: playerState.currentTrack?.id == track.id,
            isFavorite: favState.isFavorite(track),
            onTap: () {
              ref.read(playerProvider.notifier).playQueue(tracks, startIndex: index);
            },
            onFavoriteTap: () {
              ref.read(favoritesProvider.notifier).toggleFavorite(track);
            },
          );
        },
      ),
    );
  }

  Widget _buildAlbumsGrid(List<Album> albums, Responsive responsive) {
    if (albums.isEmpty) {
      return Container(
        color: AppTheme.backgroundColor,
        child: const Center(
          child: Text('No albums found', style: TextStyle(color: AppTheme.secondaryColor)),
        ),
      );
    }

    return Container(
      color: AppTheme.backgroundColor,
      child: GridView.builder(
        padding: EdgeInsets.all(responsive.horizontalPadding).copyWith(
          bottom: responsive.miniPlayerHeight + responsive.bottomNavHeight + 20,
        ),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: responsive.gridColumns,
          mainAxisSpacing: responsive.cardSpacing,
          crossAxisSpacing: responsive.cardSpacing,
          childAspectRatio: 0.75,
        ),
        itemCount: albums.length,
        itemBuilder: (context, index) {
          return AlbumCard(
            album: albums[index],
            onTap: () {},
          );
        },
      ),
    );
  }

  Widget _buildArtistsGrid(List<Artist> artists, Responsive responsive) {
    if (artists.isEmpty) {
      return Container(
        color: AppTheme.backgroundColor,
        child: const Center(
          child: Text('No artists found', style: TextStyle(color: AppTheme.secondaryColor)),
        ),
      );
    }

    return Container(
      color: AppTheme.backgroundColor,
      child: GridView.builder(
        padding: EdgeInsets.all(responsive.horizontalPadding).copyWith(
          bottom: responsive.miniPlayerHeight + responsive.bottomNavHeight + 20,
        ),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: responsive.value(mobile: 3, tablet: 4, desktop: 6),
          mainAxisSpacing: responsive.cardSpacing,
          crossAxisSpacing: responsive.cardSpacing,
          childAspectRatio: 0.85,
        ),
        itemCount: artists.length,
        itemBuilder: (context, index) {
          return ArtistCard(
            artist: artists[index],
            onTap: () {},
          );
        },
      ),
    );
  }
}

// ============================================================================
// BROWSE CARDS - Echo/Deezer Style
// ============================================================================

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;

  const _SectionHeader({required this.title, this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spacingM,
        AppTheme.spacingM,
        AppTheme.spacingM,
        AppTheme.spacingS,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: AppTheme.titleLarge,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (onSeeAll != null)
            IconButton(
              icon: const Icon(Icons.arrow_forward, color: AppTheme.secondaryColor),
              onPressed: onSeeAll,
              iconSize: 20,
            ),
        ],
      ),
    );
  }
}

class _PlaylistBrowseCard extends StatelessWidget {
  final Playlist playlist;
  final double width;
  final VoidCallback onTap;

  const _PlaylistBrowseCard({
    required this.playlist,
    required this.width,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        margin: const EdgeInsets.only(right: AppTheme.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Container(
              width: width,
              height: width,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
                color: AppTheme.surfaceColor,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
                child: playlist.coverArtUrl != null
                    ? CachedNetworkImage(
                        imageUrl: playlist.coverArtUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => _ImagePlaceholder(text: playlist.title),
                        errorWidget: (_, __, ___) => _ImagePlaceholder(text: playlist.title),
                      )
                    : _ImagePlaceholder(text: playlist.title),
              ),
            ),
            const SizedBox(height: AppTheme.spacingS),
            // Name
            Text(
              playlist.title,
              style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            // Subtitle
            Text(
              '${playlist.trackCount} tracks',
              style: AppTheme.bodySmall.copyWith(color: AppTheme.secondaryColor),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _AlbumBrowseCard extends StatelessWidget {
  final Album album;
  final double width;
  final VoidCallback onTap;

  const _AlbumBrowseCard({
    required this.album,
    required this.width,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        margin: const EdgeInsets.only(right: AppTheme.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Container(
              width: width,
              height: width,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
                color: AppTheme.surfaceColor,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
                child: album.coverArtUrl != null
                    ? CachedNetworkImage(
                        imageUrl: album.coverArtUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => _ImagePlaceholder(text: album.title),
                        errorWidget: (_, __, ___) => _ImagePlaceholder(text: album.title),
                      )
                    : _ImagePlaceholder(text: album.title),
              ),
            ),
            const SizedBox(height: AppTheme.spacingS),
            // Title
            Text(
              album.title,
              style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            // Artist
            Text(
              album.artist,
              style: AppTheme.bodySmall.copyWith(color: AppTheme.secondaryColor),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _TrackBrowseCard extends StatelessWidget {
  final Track track;
  final double width;
  final VoidCallback onTap;

  const _TrackBrowseCard({
    required this.track,
    required this.width,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        margin: const EdgeInsets.only(right: AppTheme.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with play overlay
            Stack(
              children: [
                Container(
                  width: width,
                  height: width,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                    color: AppTheme.surfaceColor,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                    child: track.coverArtUrl != null
                        ? CachedNetworkImage(
                            imageUrl: track.coverArtUrl!,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => _ImagePlaceholder(text: track.title),
                            errorWidget: (_, __, ___) => _ImagePlaceholder(text: track.title),
                          )
                        : _ImagePlaceholder(text: track.title),
                  ),
                ),
                // Play button overlay
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.primaryColor,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.play_arrow, color: Colors.white, size: 22),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingS),
            // Title
            Text(
              track.title,
              style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            // Artist
            Text(
              track.artist,
              style: AppTheme.bodySmall.copyWith(color: AppTheme.secondaryColor),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _ArtistBrowseCard extends StatelessWidget {
  final Artist artist;
  final VoidCallback onTap;

  const _ArtistBrowseCard({
    required this.artist,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: AppTheme.spacingM),
        child: Column(
          children: [
            // Circular Image
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.surfaceColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipOval(
                child: artist.imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: artist.imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => _ArtistPlaceholder(name: artist.name),
                        errorWidget: (_, __, ___) => _ArtistPlaceholder(name: artist.name),
                      )
                    : _ArtistPlaceholder(name: artist.name),
              ),
            ),
            const SizedBox(height: AppTheme.spacingS),
            // Name
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
    );
  }
}

class _GenreCard extends StatelessWidget {
  final String genre;
  final VoidCallback onTap;

  const _GenreCard({
    required this.genre,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingL,
          vertical: AppTheme.spacingM,
        ),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
        ),
        child: Text(
          genre,
          style: AppTheme.bodyMedium.copyWith(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  final String text;

  const _ImagePlaceholder({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.surfaceLight,
      child: Center(
        child: Icon(
          Icons.music_note,
          color: AppTheme.secondaryColor.withOpacity(0.5),
          size: 32,
        ),
      ),
    );
  }
}

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
