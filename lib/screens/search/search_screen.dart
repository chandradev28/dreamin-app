import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';

/// Search Screen - Responsive
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  Timer? _debounceTimer;

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      ref.read(searchProvider.notifier).search(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchProvider);
    final responsive = Responsive(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Search Header
            Padding(
              padding: EdgeInsets.all(responsive.horizontalPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Search',
                    style: responsive.value(
                      mobile: AppTheme.headlineMedium,
                      tablet: AppTheme.headlineLarge,
                    ),
                  ),
                  SizedBox(height: responsive.value(mobile: 16.0, tablet: 20.0)),
                  // Search Input
                  SizedBox(
                    height: responsive.value(mobile: 48.0, tablet: 56.0),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      style: AppTheme.bodyLarge,
                      decoration: InputDecoration(
                        hintText: 'Artists, tracks, albums...',
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
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Search Results
            Expanded(
              child: _buildSearchContent(searchState, responsive),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchContent(SearchState searchState, Responsive responsive) {
    if (searchState.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryColor),
      );
    }

    if (searchState.error != null) {
      return Center(
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
      );
    }

    if (searchState.query.isEmpty) {
      return _buildEmptyState(responsive);
    }

    if (searchState.result == null || searchState.result!.isEmpty) {
      return Center(
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
      );
    }

    return _buildSearchResults(searchState.result!, responsive);
  }

  Widget _buildEmptyState(Responsive responsive) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: responsive.value(mobile: 64.0, tablet: 80.0),
            color: AppTheme.secondaryColor.withOpacity(0.5),
          ),
          SizedBox(height: responsive.sectionSpacing),
          Text('Search for music', style: AppTheme.titleLarge),
          const SizedBox(height: AppTheme.spacingS),
          Text('Find artists, albums, and tracks', style: AppTheme.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildSearchResults(searchResult, Responsive responsive) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          // Tabs
          TabBar(
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: AppTheme.secondaryColor,
            indicatorColor: AppTheme.primaryColor,
            labelStyle: responsive.value(
              mobile: AppTheme.labelLarge,
              tablet: AppTheme.titleSmall,
            ),
            tabs: [
              Tab(text: 'Tracks (${searchResult.tracks.length})'),
              Tab(text: 'Albums (${searchResult.albums.length})'),
              Tab(text: 'Artists (${searchResult.artists.length})'),
            ],
          ),
          // Tab Content
          Expanded(
            child: TabBarView(
              children: [
                _buildTracksList(searchResult.tracks, responsive),
                _buildAlbumsGrid(searchResult.albums, responsive),
                _buildArtistsGrid(searchResult.artists, responsive),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTracksList(List tracks, Responsive responsive) {
    if (tracks.isEmpty) {
      return const Center(
        child: Text('No tracks found', style: TextStyle(color: AppTheme.secondaryColor)),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.only(bottom: responsive.miniPlayerHeight + responsive.bottomNavHeight + 20),
      itemCount: tracks.length,
      itemBuilder: (context, index) {
        final track = tracks[index];
        final playerState = ref.watch(playerProvider);
        final favState = ref.watch(favoritesProvider);
        
        return TrackListTile(
          track: track,
          isPlaying: playerState.currentTrack?.id == track.id,
          isFavorite: favState.favoriteIds.contains('${track.id}_${track.source.name}'),
          onTap: () {
            ref.read(playerProvider.notifier).playQueue(tracks.cast(), startIndex: index);
          },
          onFavoriteTap: () {
            ref.read(favoritesProvider.notifier).toggleFavorite(track);
          },
        );
      },
    );
  }

  Widget _buildAlbumsGrid(List albums, Responsive responsive) {
    if (albums.isEmpty) {
      return const Center(
        child: Text('No albums found', style: TextStyle(color: AppTheme.secondaryColor)),
      );
    }

    return GridView.builder(
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
          onTap: () {
            // Navigate to album detail
          },
        );
      },
    );
  }

  Widget _buildArtistsGrid(List artists, Responsive responsive) {
    if (artists.isEmpty) {
      return const Center(
        child: Text('No artists found', style: TextStyle(color: AppTheme.secondaryColor)),
      );
    }

    return GridView.builder(
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
          onTap: () {
            // Navigate to artist detail
          },
        );
      },
    );
  }
}
