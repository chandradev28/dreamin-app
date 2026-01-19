import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import '../../widgets/track_options_sheet.dart';
import '../../widgets/album_options_sheet.dart';
import '../album/album_detail_screen.dart';
import '../playlist/playlist_detail_screen.dart';
import '../artist/artist_detail_screen.dart';
import 'search_all_results_screen.dart';

/// Search Screen - Clean TIDAL Style Layout
/// Fixed: No repeated sections, proper artist images, clean mixed results
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
  // SEARCH RESULTS - Clean TIDAL Style (like the reference image)
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

    final query = _searchController.text;

    // Build a SINGLE, clean mixed results list (like Tidal app)
    return ListView(
      padding: EdgeInsets.only(bottom: responsive.miniPlayerHeight + responsive.bottomNavHeight + 20),
      children: [
        // Search suggestions at top
        ..._buildSearchSuggestions(result, query),
        
        // Mixed results: Artist card, then albums, then tracks, then playlists
        ..._buildMixedResults(result, responsive, query),
      ],
    );
  }

  /// Build search suggestions (like Tidal's "acdc thunderstruck", "accept", etc.)
  List<Widget> _buildSearchSuggestions(SearchResult result, String query) {
    final suggestions = <String>{};
    
    // Add artist names as suggestions
    for (final artist in result.artists.take(2)) {
      suggestions.add(artist.name.toLowerCase());
    }
    
    // Add "artist + track" combinations
    for (final track in result.tracks.take(2)) {
      final suggestion = '${track.artist.toLowerCase()} ${track.title.toLowerCase()}';
      if (suggestion.contains(query.toLowerCase())) {
        suggestions.add(suggestion);
      }
    }

    return suggestions.take(4).map((s) => ListTile(
      dense: true,
      leading: const Icon(Icons.search, color: AppTheme.secondaryColor, size: 20),
      title: _buildHighlightedText(s, query),
      onTap: () {
        _searchController.text = s;
        _onSearchChanged(s);
      },
    )).toList();
  }

  /// Build mixed results in proper order: Artist -> Albums -> Tracks -> Playlists
  List<Widget> _buildMixedResults(SearchResult result, Responsive responsive, String query) {
    final widgets = <Widget>[];

    // 1. ARTIST at top (large card with circular image)
    if (result.artists.isNotEmpty) {
      final artist = result.artists.first;
      widgets.add(_buildArtistCard(artist));
    }

    // 2. ALBUMS (horizontal scroll)
    if (result.albums.isNotEmpty) {
      // Deduplicate albums by ID
      final uniqueAlbums = <String, Album>{};
      for (final album in result.albums) {
        uniqueAlbums[album.id] = album;
      }
      final albums = uniqueAlbums.values.take(6).toList();
      
      widgets.add(Padding(
        padding: EdgeInsets.fromLTRB(responsive.horizontalPadding, 20, responsive.horizontalPadding, 8),
        child: Text('Albums', style: AppTheme.titleMedium),
      ));
      widgets.add(SizedBox(
        height: responsive.value(mobile: 180.0, tablet: 220.0),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: responsive.horizontalPadding),
          itemCount: albums.length,
          itemBuilder: (context, index) {
            final album = albums[index];
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
      ));
    }

    // 3. TRACKS (list)
    if (result.tracks.isNotEmpty) {
      // Deduplicate tracks by ID
      final uniqueTracks = <String, Track>{};
      for (final track in result.tracks) {
        uniqueTracks[track.id] = track;
      }
      final tracks = uniqueTracks.values.take(6).toList();
      
      widgets.add(Padding(
        padding: EdgeInsets.fromLTRB(responsive.horizontalPadding, 20, responsive.horizontalPadding, 8),
        child: Text('Tracks', style: AppTheme.titleMedium),
      ));
      widgets.addAll(tracks.map((track) => _buildTrackTile(track, result.tracks)));
    }

    // 4. PLAYLISTS (list) - only once!
    if (result.playlists.isNotEmpty) {
      // Deduplicate playlists by ID
      final uniquePlaylists = <String, Playlist>{};
      for (final playlist in result.playlists) {
        uniquePlaylists[playlist.id] = playlist;
      }
      final playlists = uniquePlaylists.values.take(4).toList();
      
      widgets.add(Padding(
        padding: EdgeInsets.fromLTRB(responsive.horizontalPadding, 20, responsive.horizontalPadding, 8),
        child: Text('Playlists', style: AppTheme.titleMedium),
      ));
      widgets.addAll(playlists.map((playlist) => _buildPlaylistTile(playlist)));
    }

    // 5. VIEW ALL button (only once at the end)
    widgets.add(Padding(
      padding: EdgeInsets.symmetric(horizontal: responsive.horizontalPadding, vertical: 24),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SearchAllResultsScreen(query: query, result: result),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('View all results for ', style: AppTheme.bodyMedium.copyWith(color: AppTheme.secondaryColor)),
            Text(query, style: AppTheme.bodyMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward, color: AppTheme.secondaryColor, size: 18),
          ],
        ),
      ),
    ));

    return widgets;
  }

  Widget _buildArtistCard(Artist artist) {
    return ListTile(
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => ArtistDetailScreen(artistId: artist.id, artist: artist),
      )),
      leading: Container(
        width: 56, height: 56,
        decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.surfaceColor),
        child: ClipOval(
          child: artist.imageUrl != null && artist.imageUrl!.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: artist.imageUrl!,
                  fit: BoxFit.cover,
                  width: 56,
                  height: 56,
                  placeholder: (_, __) => _buildArtistInitial(artist.name),
                  errorWidget: (_, __, ___) => _buildArtistInitial(artist.name),
                )
              : _buildArtistInitial(artist.name),
        ),
      ),
      title: Text(artist.name, style: AppTheme.titleMedium),
      trailing: const Icon(Icons.more_vert, color: AppTheme.secondaryColor),
    );
  }

  Widget _buildArtistInitial(String name) {
    return Container(
      width: 56, height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor.withOpacity(0.7), AppTheme.surfaceColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: AppTheme.headlineSmall.copyWith(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildTrackTile(Track track, List<Track> allTracks) {
    return ListTile(
      onTap: () => ref.read(playerProvider.notifier).playQueue(allTracks, startIndex: allTracks.indexOf(track)),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: track.coverArtUrl != null
            ? CachedNetworkImage(imageUrl: track.coverArtUrl!, width: 50, height: 50, fit: BoxFit.cover)
            : Container(width: 50, height: 50, color: AppTheme.surfaceColor, child: const Icon(Icons.music_note, color: AppTheme.secondaryColor)),
      ),
      title: Text(track.title, style: AppTheme.bodyLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text('Track by ${track.artist}', style: AppTheme.bodySmall.copyWith(color: AppTheme.secondaryColor), maxLines: 1),
      trailing: GestureDetector(
        onTap: () => TrackOptionsSheet.show(context, track),
        child: const Icon(Icons.more_vert, color: AppTheme.secondaryColor),
      ),
    );
  }

  Widget _buildPlaylistTile(Playlist playlist) {
    return ListTile(
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => PlaylistDetailScreen(playlistId: playlist.id, playlist: playlist),
      )),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: playlist.coverArtUrl != null
            ? CachedNetworkImage(imageUrl: playlist.coverArtUrl!, width: 50, height: 50, fit: BoxFit.cover)
            : Container(width: 50, height: 50, color: AppTheme.surfaceColor, child: const Icon(Icons.playlist_play, color: AppTheme.secondaryColor)),
      ),
      title: Text(playlist.title, style: AppTheme.bodyLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text('by ${playlist.creatorName ?? "TIDAL"} • ${playlist.trackCount} tracks', 
        style: AppTheme.bodySmall.copyWith(color: AppTheme.secondaryColor), maxLines: 1),
      trailing: const Icon(Icons.more_vert, color: AppTheme.secondaryColor),
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
            style: AppTheme.bodyMedium.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          TextSpan(text: text.substring(index + query.length)),
        ],
      ),
    );
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
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: album.coverArtUrl != null
                      ? CachedNetworkImage(imageUrl: album.coverArtUrl!, width: 120, height: 120, fit: BoxFit.cover)
                      : Container(width: 120, height: 120, color: AppTheme.surfaceColor, child: const Icon(Icons.album, size: 40, color: AppTheme.secondaryColor)),
                ),
                // 3-dot menu overlay
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () => AlbumOptionsSheet.show(context, album),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.more_vert, color: Colors.white, size: 16),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(album.title, style: AppTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
            Text('Album by ${album.artist}', style: AppTheme.labelSmall.copyWith(color: AppTheme.secondaryColor), maxLines: 1),
          ],
        ),
      ),
    );
  }
}
