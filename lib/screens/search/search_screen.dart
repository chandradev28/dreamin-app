import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import '../album/album_detail_screen.dart';
import '../playlist/playlist_detail_screen.dart';
import '../artist/artist_detail_screen.dart';
import 'search_all_results_screen.dart';

/// Search Screen - TIDAL Style
/// Browse: Genres, Moods, Decades
/// Search: Text suggestions + mixed results
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  bool _isSearching = false;

  static const List<String> genres = [
    'Hip-Hop', 'Pop', 'R&B / Soul', 'Rock', 'Electronic', 
    'Latin', 'Country', 'Jazz', 'Classical', 'Metal',
  ];

  static const List<String> moods = [
    'Chill', 'Workout', 'Party', 'Focus', 'Sleep',
    'Romance', 'Road Trip', 'Cooking', 'Meditation',
  ];

  static const List<String> decades = [
    '1950s', '1960s', '1970s', '1980s', '1990s', '2000s', '2010s', '2020s',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (query.trim().isNotEmpty) {
        ref.read(searchProvider.notifier).search(query.trim());
      }
    });
    setState(() {
      _isSearching = query.isNotEmpty;
    });
  }

  void _onCategoryTap(String category) {
    _searchController.text = category;
    _onSearchChanged(category);
    FocusScope.of(context).unfocus();
  }

  void _onSuggestionTap(String suggestion) {
    _searchController.text = suggestion;
    _onSearchChanged(suggestion);
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
            // Search Bar
            Padding(
              padding: EdgeInsets.all(responsive.horizontalPadding),
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  style: AppTheme.bodyLarge,
                  decoration: InputDecoration(
                    hintText: 'Search',
                    hintStyle: AppTheme.bodyLarge.copyWith(color: AppTheme.secondaryColor),
                    prefixIcon: const Icon(Icons.search, color: AppTheme.secondaryColor),
                    suffixIcon: _isSearching
                        ? IconButton(
                            icon: const Icon(Icons.close, color: AppTheme.secondaryColor),
                            onPressed: () {
                              _searchController.clear();
                              ref.read(searchProvider.notifier).clear();
                              setState(() => _isSearching = false);
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
            ),

            // Content
            Expanded(
              child: _isSearching
                  ? _buildSearchResults(searchState, responsive)
                  : _buildBrowseSection(responsive),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // BROWSE SECTION
  // ===========================================================================

  Widget _buildBrowseSection(Responsive responsive) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: responsive.miniPlayerHeight + responsive.bottomNavHeight + 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BrowseSectionHeader(title: 'Genres', onViewAll: () {}),
          _buildChipRow(genres, responsive),
          const SizedBox(height: 24),
          _BrowseSectionHeader(title: 'Moods & Activities', onViewAll: () {}),
          _buildChipRow(moods, responsive),
          const SizedBox(height: 24),
          _BrowseSectionHeader(title: 'Decades', onViewAll: () {}),
          _buildChipRow(decades, responsive),
          const SizedBox(height: 24),
          _buildNewReleasesSection(responsive),
        ],
      ),
    );
  }

  Widget _buildChipRow(List<String> items, Responsive responsive) {
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: responsive.horizontalPadding),
        itemCount: items.length,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: _CategoryChip(label: items[index], onTap: () => _onCategoryTap(items[index])),
        ),
      ),
    );
  }

  Widget _buildNewReleasesSection(Responsive responsive) {
    final homeData = ref.watch(homeDataProvider);
    if (homeData.newAlbums.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BrowseSectionHeader(title: 'New Releases', onViewAll: () {}),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: responsive.horizontalPadding),
            itemCount: homeData.newAlbums.length,
            itemBuilder: (context, index) {
              final album = homeData.newAlbums[index];
              return _AlbumCard(
                album: album,
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => AlbumDetailScreen(albumId: album.id, album: album),
                )),
              );
            },
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // SEARCH RESULTS WITH SUGGESTIONS
  // ===========================================================================

  Widget _buildSearchResults(SearchState searchState, Responsive responsive) {
    if (searchState.isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
    }

    if (searchState.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppTheme.errorColor),
            const SizedBox(height: 16),
            Text('Search failed', style: AppTheme.titleLarge),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(searchState.error!, style: AppTheme.bodyMedium.copyWith(color: AppTheme.secondaryColor), textAlign: TextAlign.center),
            ),
          ],
        ),
      );
    }

    final result = searchState.result;
    if (result == null) {
      return Center(child: Text('Start typing to search', style: AppTheme.bodyLarge.copyWith(color: AppTheme.secondaryColor)));
    }

    final hasResults = result.tracks.isNotEmpty || result.artists.isNotEmpty || result.albums.isNotEmpty;

    if (!hasResults) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: AppTheme.secondaryColor),
            const SizedBox(height: 16),
            Text('No results found', style: AppTheme.titleLarge),
          ],
        ),
      );
    }

    // Build suggestions from results
    final suggestions = _buildSuggestions(result);
    final query = _searchController.text;

    return ListView(
      padding: EdgeInsets.only(bottom: responsive.miniPlayerHeight + responsive.bottomNavHeight + 20),
      children: [
        // Text Suggestions (with search icon) - like TIDAL
        ...suggestions.take(4).map((s) => _SuggestionTile(
          suggestion: s,
          query: query,
          onTap: () => _onSuggestionTap(s),
        )),
        
        // ARTIST AT TOP (circular image) - tapping opens artist page
        if (result.artists.isNotEmpty) ...[
          _ArtistResultTile(
            artist: result.artists.first,
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => ArtistDetailScreen(artistId: result.artists.first.id, artist: result.artists.first),
            )),
          ),
        ],
        
        // ALBUMS SECTION (horizontal scroll)
        if (result.albums.isNotEmpty) ...[
          Padding(
            padding: EdgeInsets.fromLTRB(responsive.horizontalPadding, 20, responsive.horizontalPadding, 8),
            child: Text('Albums', style: AppTheme.titleMedium),
          ),
          SizedBox(
            height: responsive.value(mobile: 180.0, tablet: 220.0),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: responsive.horizontalPadding),
              itemCount: result.albums.take(6).length,
              itemBuilder: (context, index) {
                final album = result.albums[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: _AlbumCard(
                    album: album,
                    onTap: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => AlbumDetailScreen(albumId: album.id, album: album),
                    )),
                  ),
                );
              },
            ),
          ),
        ],
        
        // TRACKS SECTION
        if (result.tracks.isNotEmpty) ...[
          Padding(
            padding: EdgeInsets.fromLTRB(responsive.horizontalPadding, 20, responsive.horizontalPadding, 8),
            child: Text('Tracks', style: AppTheme.titleMedium),
          ),
          ...result.tracks.take(4).map((track) => _TrackResultTile(
            track: track,
            onTap: () => ref.read(playerProvider.notifier).playQueue(
              result.tracks, 
              startIndex: result.tracks.indexOf(track),
            ),
          )),
        ],
        
        // PLAYLISTS SECTION
        if (result.playlists.isNotEmpty) ...[
          Padding(
            padding: EdgeInsets.fromLTRB(responsive.horizontalPadding, 20, responsive.horizontalPadding, 8),
            child: Text('Playlists', style: AppTheme.titleMedium),
          ),
          ...result.playlists.take(4).map((playlist) => _PlaylistResultTile(
            playlist: playlist,
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => PlaylistDetailScreen(playlistId: playlist.id, playlist: playlist),
            )),
          )),
        ],
        
        // VIEW ALL RESULTS BUTTON
        Padding(
          padding: EdgeInsets.symmetric(horizontal: responsive.horizontalPadding, vertical: 24),
          child: GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SearchAllResultsScreen(
                  query: query,
                  result: result,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'View all results for ',
                  style: AppTheme.bodyMedium.copyWith(color: AppTheme.secondaryColor),
                ),
                Text(
                  query,
                  style: AppTheme.bodyMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 8),
                Icon(Icons.arrow_forward, color: AppTheme.secondaryColor, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<String> _buildSuggestions(SearchResult result) {
    final suggestions = <String>{};
    final query = _searchController.text.toLowerCase();
    
    for (final artist in result.artists.take(4)) {
      suggestions.add(artist.name.toLowerCase());
    }
    
    for (final track in result.tracks.take(4)) {
      if (track.title.toLowerCase().contains(query)) {
        suggestions.add('${track.artist.toLowerCase()} ${track.title.toLowerCase()}');
      }
    }
    
    return suggestions.toList();
  }
}

// =============================================================================
// WIDGETS
// =============================================================================

class _BrowseSectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onViewAll;

  const _BrowseSectionHeader({required this.title, required this.onViewAll});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: AppTheme.headlineSmall),
          TextButton(
            onPressed: onViewAll,
            child: Text('VIEW AS LIST', style: AppTheme.labelSmall.copyWith(color: AppTheme.secondaryColor)),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _CategoryChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: AppTheme.bodyMedium),
      ),
    );
  }
}

/// Search Suggestion Tile - shows search icon + highlighted text
class _SuggestionTile extends StatelessWidget {
  final String suggestion;
  final String query;
  final VoidCallback onTap;

  const _SuggestionTile({required this.suggestion, required this.query, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: const Icon(Icons.search, color: AppTheme.secondaryColor, size: 20),
      title: _buildHighlightedText(suggestion, query),
      dense: true,
    );
  }

  Widget _buildHighlightedText(String text, String query) {
    final queryLower = query.toLowerCase();
    final textLower = text.toLowerCase();
    final index = textLower.indexOf(queryLower);

    if (index == -1 || query.isEmpty) {
      return Text(text, style: AppTheme.bodyMedium);
    }

    return RichText(
      text: TextSpan(
        style: AppTheme.bodyMedium.copyWith(color: AppTheme.secondaryColor),
        children: [
          TextSpan(text: text.substring(0, index)),
          TextSpan(
            text: text.substring(index, index + query.length),
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
          ),
          TextSpan(text: text.substring(index + query.length)),
        ],
      ),
    );
  }
}

class _ArtistResultTile extends StatelessWidget {
  final Artist artist;
  final VoidCallback onTap;

  const _ArtistResultTile({required this.artist, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 50, height: 50,
        decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.surfaceColor),
        child: ClipOval(
          child: artist.imageUrl != null
              ? CachedNetworkImage(imageUrl: artist.imageUrl!, fit: BoxFit.cover)
              : Center(child: Text(artist.name.isNotEmpty ? artist.name[0].toUpperCase() : '?', style: AppTheme.titleLarge)),
        ),
      ),
      title: Text(artist.name, style: AppTheme.bodyLarge),
      trailing: const Icon(Icons.more_vert, color: AppTheme.secondaryColor),
    );
  }
}

class _TrackResultTile extends StatelessWidget {
  final Track track;
  final VoidCallback onTap;

  const _TrackResultTile({required this.track, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: track.coverArtUrl != null
            ? CachedNetworkImage(imageUrl: track.coverArtUrl!, width: 50, height: 50, fit: BoxFit.cover)
            : Container(width: 50, height: 50, color: AppTheme.surfaceColor, child: const Icon(Icons.music_note, color: AppTheme.secondaryColor)),
      ),
      title: Text(track.title, style: AppTheme.bodyLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text('Track by ${track.artist}', style: AppTheme.bodySmall.copyWith(color: AppTheme.secondaryColor), maxLines: 1),
      trailing: const Icon(Icons.more_vert, color: AppTheme.secondaryColor),
    );
  }
}

class _AlbumCard extends StatelessWidget {
  final Album album;
  final VoidCallback onTap;

  const _AlbumCard({required this.album, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: album.coverArtUrl != null
                  ? CachedNetworkImage(imageUrl: album.coverArtUrl!, width: 120, height: 120, fit: BoxFit.cover)
                  : Container(width: 120, height: 120, color: AppTheme.surfaceColor, child: const Icon(Icons.album, size: 40, color: AppTheme.secondaryColor)),
            ),
            const SizedBox(height: 8),
            Text(album.title, style: AppTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(album.artist, style: AppTheme.labelSmall.copyWith(color: AppTheme.secondaryColor), maxLines: 1),
          ],
        ),
      ),
    );
  }
}

class _PlaylistResultTile extends StatelessWidget {
  final Playlist playlist;
  final VoidCallback onTap;

  const _PlaylistResultTile({required this.playlist, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: playlist.coverArtUrl != null
            ? CachedNetworkImage(imageUrl: playlist.coverArtUrl!, width: 50, height: 50, fit: BoxFit.cover)
            : Container(width: 50, height: 50, color: AppTheme.surfaceColor, child: const Icon(Icons.playlist_play, color: AppTheme.secondaryColor)),
      ),
      title: Text(playlist.title, style: AppTheme.bodyLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('by ${playlist.creatorName ?? "TIDAL"}', style: AppTheme.bodySmall.copyWith(color: AppTheme.secondaryColor), maxLines: 1),
          Text('${playlist.trackCount} TRACKS', style: AppTheme.labelSmall.copyWith(color: AppTheme.tertiaryColor, letterSpacing: 0.5)),
        ],
      ),
      isThreeLine: true,
      trailing: const Icon(Icons.more_vert, color: AppTheme.secondaryColor),
    );
  }
}
