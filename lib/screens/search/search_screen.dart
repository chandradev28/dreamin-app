import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import '../../widgets/album_options_sheet.dart';
import '../../widgets/widgets.dart';
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

  static const List<_BrowseTileData> genres = [
    _BrowseTileData(label: 'Hip-Hop'),
    _BrowseTileData(label: 'Pop'),
    _BrowseTileData(label: 'R&B / Soul'),
    _BrowseTileData(label: 'Rock'),
    _BrowseTileData(label: 'Electronic'),
    _BrowseTileData(label: 'Latin'),
    _BrowseTileData(label: 'Country'),
    _BrowseTileData(label: 'Jazz'),
    _BrowseTileData(label: 'Classical'),
    _BrowseTileData(label: 'Metal'),
  ];

  static const List<_BrowseTileData> moods = [
    _BrowseTileData(label: 'Chill'),
    _BrowseTileData(label: 'Workout'),
    _BrowseTileData(label: 'Party'),
    _BrowseTileData(label: 'Focus'),
    _BrowseTileData(label: 'Sleep'),
    _BrowseTileData(label: 'Romance'),
    _BrowseTileData(label: 'Road Trip'),
    _BrowseTileData(label: 'Meditation'),
  ];

  static const List<_BrowseTileData> decades = [
    _BrowseTileData(label: '1950s'),
    _BrowseTileData(label: '1960s'),
    _BrowseTileData(label: '1970s'),
    _BrowseTileData(label: '1980s'),
    _BrowseTileData(label: '1990s'),
    _BrowseTileData(label: '2000s'),
    _BrowseTileData(label: '2010s'),
    _BrowseTileData(label: '2020s'),
  ];

  static const List<_BrowseShortcutData> shortcuts = [
    _BrowseShortcutData(
      label: 'HiRes',
      icon: Icons.graphic_eq_rounded,
      iconColor: AppTheme.hifiBadge,
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _commitSearch(String query) async {
    await ref.read(searchHistoryProvider.notifier).add(query);
  }

  void _runSearch(String query, {bool saveToHistory = false}) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      ref.read(searchProvider.notifier).clear();
      setState(() => _isSearching = false);
      return;
    }

    if (saveToHistory) {
      unawaited(_commitSearch(trimmed));
    }

    ref.read(searchProvider.notifier).search(trimmed);
    setState(() => _isSearching = true);
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      ref.read(searchProvider.notifier).clear();
      setState(() => _isSearching = false);
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 400), () {
      _runSearch(trimmed, saveToHistory: true);
    });
    setState(() => _isSearching = true);
  }

  void _onCategoryTap(String category) {
    _searchController.text = category;
    _runSearch(category, saveToHistory: true);
    FocusScope.of(context).unfocus();
  }

  void _onHistoryTap(String query) {
    _searchController.text = query;
    _searchController.selection =
        TextSelection.collapsed(offset: _searchController.text.length);
    _runSearch(query, saveToHistory: true);
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchProvider);
    final searchHistory = ref.watch(searchHistoryProvider);
    final responsive = Responsive(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: PosterGradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.all(responsive.horizontalPadding),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor.withOpacity(0.86),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    onSubmitted: (value) =>
                        _runSearch(value, saveToHistory: true),
                    onTapOutside: (_) =>
                        FocusManager.instance.primaryFocus?.unfocus(),
                    style: AppTheme.titleMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search',
                      hintStyle: AppTheme.titleMedium.copyWith(
                        color: Colors.white.withOpacity(0.46),
                        fontWeight: FontWeight.w500,
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: AppTheme.secondaryColor,
                      ),
                      suffixIcon: _isSearching
                          ? IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: AppTheme.secondaryColor,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                ref.read(searchProvider.notifier).clear();
                                setState(() => _isSearching = false);
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _isSearching
                    ? _buildSearchResults(searchState, responsive)
                    : _buildBrowseSection(searchHistory, responsive),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // BROWSE SECTION
  // ===========================================================================

  Widget _buildBrowseSection(
      List<String> searchHistory, Responsive responsive) {
    final horizontal = responsive.horizontalPadding;

    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.fromLTRB(
        0,
        8,
        0,
        responsive.miniPlayerHeight + responsive.bottomNavHeight + 24,
      ),
      children: [
        if (searchHistory.isNotEmpty) ...[
          Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontal),
            child: _SearchHistoryHeader(
              onClearAll: () {
                ref.read(searchHistoryProvider.notifier).clear();
              },
            ),
          ),
          const SizedBox(height: 10),
          ...searchHistory.map(
            (entry) => _SearchHistoryTile(
              query: entry,
              horizontalPadding: horizontal,
              onTap: () => _onHistoryTap(entry),
              onRemove: () {
                ref.read(searchHistoryProvider.notifier).remove(entry);
              },
            ),
          ),
          const SizedBox(height: 26),
        ],
        Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontal),
          child: _BrowseSectionHeader(title: 'Genres', onViewAll: () {}),
        ),
        const SizedBox(height: 14),
        _buildSlidingBentoRow(
          items: genres,
          horizontalPadding: horizontal,
          onTap: (item) => _onCategoryTap(item.label),
        ),
        const SizedBox(height: 34),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontal),
          child: _BrowseSectionHeader(
            title: 'Moods & Activities',
            onViewAll: () {},
          ),
        ),
        const SizedBox(height: 14),
        _buildSlidingBentoRow(
          items: moods,
          horizontalPadding: horizontal,
          onTap: (item) => _onCategoryTap(item.label),
        ),
        const SizedBox(height: 34),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontal),
          child: _BrowseSectionHeader(title: 'Decades', onViewAll: () {}),
        ),
        const SizedBox(height: 14),
        _buildSlidingBentoRow(
          items: decades,
          horizontalPadding: horizontal,
          onTap: (item) => _onCategoryTap(item.label),
        ),
        const SizedBox(height: 34),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontal),
          child: _buildShortcutList(shortcuts),
        ),
      ],
    );
  }

  Widget _buildSlidingBentoRow({
    required List<_BrowseTileData> items,
    required double horizontalPadding,
    required ValueChanged<_BrowseTileData> onTap,
  }) {
    return SizedBox(
      height: 58,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final item = items[index];
          return _BrowseBentoTile(
            width: _tileWidthFor(item),
            height: 58,
            label: item.label,
            onTap: () => onTap(item),
          );
        },
      ),
    );
  }

  double _tileWidthFor(_BrowseTileData item) {
    final painter = TextPainter(
      text: TextSpan(
        text: item.label,
        style: AppTheme.titleMedium.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 15,
          letterSpacing: -0.2,
        ),
      ),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();

    return (painter.width + 42).clamp(98.0, 170.0);
  }

  Widget _buildShortcutList(List<_BrowseShortcutData> items) {
    return Column(
      children: items
          .map(
            (item) => _BrowseShortcutTile(
              label: item.label,
              icon: item.icon,
              iconColor: item.iconColor,
              onTap: () => _onCategoryTap(item.label),
            ),
          )
          .toList(),
    );
  }

  // ===========================================================================
  // SEARCH RESULTS - Clean TIDAL Style (like the reference image)
  // ===========================================================================

  Widget _buildSearchResults(SearchState searchState, Responsive responsive) {
    if (searchState.isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryColor));
    }

    if (searchState.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline,
                size: 64, color: AppTheme.errorColor),
            const SizedBox(height: 16),
            Text('Search failed', style: AppTheme.titleLarge),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(searchState.error!,
                  style: AppTheme.bodyMedium
                      .copyWith(color: AppTheme.secondaryColor),
                  textAlign: TextAlign.center),
            ),
          ],
        ),
      );
    }

    final result = searchState.result;
    if (result == null) {
      return Center(
          child: Text('Start typing to search',
              style:
                  AppTheme.bodyLarge.copyWith(color: AppTheme.secondaryColor)));
    }

    final hasResults = result.tracks.isNotEmpty ||
        result.artists.isNotEmpty ||
        result.albums.isNotEmpty;

    if (!hasResults) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off,
                size: 64, color: AppTheme.secondaryColor),
            const SizedBox(height: 16),
            Text('No results found', style: AppTheme.titleLarge),
          ],
        ),
      );
    }

    final query = _searchController.text;

    // Build a SINGLE, clean mixed results list (like Tidal app)
    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.only(
          bottom:
              responsive.miniPlayerHeight + responsive.bottomNavHeight + 20),
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
      final suggestion =
          '${track.artist.toLowerCase()} ${track.title.toLowerCase()}';
      if (suggestion.contains(query.toLowerCase())) {
        suggestions.add(suggestion);
      }
    }

    return suggestions
        .take(4)
        .map((s) => ListTile(
              dense: true,
              leading: const Icon(Icons.search,
                  color: AppTheme.secondaryColor, size: 20),
              title: _buildHighlightedText(s, query),
              onTap: () {
                _searchController.text = s;
                _runSearch(s, saveToHistory: true);
              },
            ))
        .toList();
  }

  /// Build mixed results in proper order: Artist -> Albums -> Tracks -> Playlists
  List<Widget> _buildMixedResults(
      SearchResult result, Responsive responsive, String query) {
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
        padding: EdgeInsets.fromLTRB(
            responsive.horizontalPadding, 20, responsive.horizontalPadding, 8),
        child: Text('Albums', style: AppTheme.titleMedium),
      ));
      widgets.add(SizedBox(
        height: responsive.value(mobile: 180.0, tablet: 220.0),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding:
              EdgeInsets.symmetric(horizontal: responsive.horizontalPadding),
          itemCount: albums.length,
          itemBuilder: (context, index) {
            final album = albums[index];
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _AlbumCard(
                album: album,
                onTap: () {
                  final trimmedQuery = query.trim();
                  if (trimmedQuery.isNotEmpty) {
                    unawaited(_commitSearch(trimmedQuery));
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          AlbumDetailScreen(albumId: album.id, album: album),
                    ),
                  );
                },
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
        padding: EdgeInsets.fromLTRB(
            responsive.horizontalPadding, 20, responsive.horizontalPadding, 8),
        child: Text('Tracks', style: AppTheme.titleMedium),
      ));
      widgets
          .addAll(tracks.map((track) => _buildTrackTile(track, result.tracks)));
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
        padding: EdgeInsets.fromLTRB(
            responsive.horizontalPadding, 20, responsive.horizontalPadding, 8),
        child: Text('Playlists', style: AppTheme.titleMedium),
      ));
      widgets.addAll(playlists.map((playlist) => _buildPlaylistTile(playlist)));
    }

    // 5. VIEW ALL button (only once at the end)
    widgets.add(Padding(
      padding: EdgeInsets.symmetric(
          horizontal: responsive.horizontalPadding, vertical: 24),
      child: GestureDetector(
        onTap: () {
          final trimmedQuery = query.trim();
          if (trimmedQuery.isNotEmpty) {
            unawaited(_commitSearch(trimmedQuery));
          }
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  SearchAllResultsScreen(query: query, result: result),
            ),
          );
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('View all results for ',
                style: AppTheme.bodyMedium
                    .copyWith(color: AppTheme.secondaryColor)),
            Text(query,
                style: AppTheme.bodyMedium.copyWith(
                    color: Colors.white, fontWeight: FontWeight.w600)),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward,
                color: AppTheme.secondaryColor, size: 18),
          ],
        ),
      ),
    ));

    return widgets;
  }

  Widget _buildArtistCard(Artist artist) {
    return ListTile(
      onTap: () {
        final trimmedQuery = _searchController.text.trim();
        if (trimmedQuery.isNotEmpty) {
          unawaited(_commitSearch(trimmedQuery));
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                ArtistDetailScreen(artistId: artist.id, artist: artist),
          ),
        );
      },
      leading: Container(
        width: 56,
        height: 56,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppTheme.surfaceColor,
        ),
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
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withOpacity(0.7),
            AppTheme.surfaceColor
          ],
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
      onTap: () {
        final trimmedQuery = _searchController.text.trim();
        if (trimmedQuery.isNotEmpty) {
          unawaited(_commitSearch(trimmedQuery));
        }
        ref
            .read(playerProvider.notifier)
            .playQueue(allTracks, startIndex: allTracks.indexOf(track));
      },
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: track.coverArtUrl != null
            ? CachedNetworkImage(
                imageUrl: track.coverArtUrl!,
                width: 50,
                height: 50,
                fit: BoxFit.cover)
            : Container(
                width: 50,
                height: 50,
                color: AppTheme.surfaceColor,
                child: const Icon(Icons.music_note,
                    color: AppTheme.secondaryColor)),
      ),
      title: Text(track.title,
          style: AppTheme.bodyLarge,
          maxLines: 1,
          overflow: TextOverflow.ellipsis),
      subtitle: Text('Track by ${track.artist}',
          style: AppTheme.bodySmall.copyWith(color: AppTheme.secondaryColor),
          maxLines: 1),
      trailing: GestureDetector(
        onTap: () => TrackOptionsSheet.show(context, track),
        child: const Icon(Icons.more_vert, color: AppTheme.secondaryColor),
      ),
    );
  }

  Widget _buildPlaylistTile(Playlist playlist) {
    return ListTile(
      onTap: () {
        final trimmedQuery = _searchController.text.trim();
        if (trimmedQuery.isNotEmpty) {
          unawaited(_commitSearch(trimmedQuery));
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PlaylistDetailScreen(
                playlistId: playlist.id, playlist: playlist),
          ),
        );
      },
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: playlist.coverArtUrl != null
            ? CachedNetworkImage(
                imageUrl: playlist.coverArtUrl!,
                width: 50,
                height: 50,
                fit: BoxFit.cover)
            : Container(
                width: 50,
                height: 50,
                color: AppTheme.surfaceColor,
                child: const Icon(Icons.playlist_play,
                    color: AppTheme.secondaryColor)),
      ),
      title: Text(playlist.title,
          style: AppTheme.bodyLarge,
          maxLines: 1,
          overflow: TextOverflow.ellipsis),
      subtitle: Text(
          'by ${playlist.creatorName ?? "TIDAL"} • ${playlist.trackCount} tracks',
          style: AppTheme.bodySmall.copyWith(color: AppTheme.secondaryColor),
          maxLines: 1),
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
            style: AppTheme.bodyMedium
                .copyWith(color: Colors.white, fontWeight: FontWeight.bold),
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

class _SearchHistoryHeader extends StatelessWidget {
  final VoidCallback onClearAll;

  const _SearchHistoryHeader({required this.onClearAll});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Search History',
          style: AppTheme.headlineMedium.copyWith(
            fontSize: 21,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          ),
        ),
        TextButton(
          onPressed: onClearAll,
          style: TextButton.styleFrom(
            foregroundColor: Colors.white.withOpacity(0.72),
            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'Clear all',
            style: AppTheme.bodyMedium.copyWith(
              color: Colors.white.withOpacity(0.72),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _SearchHistoryTile extends StatelessWidget {
  final String query;
  final double horizontalPadding;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _SearchHistoryTile({
    required this.query,
    required this.horizontalPadding,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              children: [
                const SizedBox(
                  width: 36,
                  child: Icon(
                    Icons.history_rounded,
                    color: AppTheme.secondaryColor,
                    size: 20,
                  ),
                ),
                Expanded(
                  child: Text(
                    query,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.titleMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onRemove,
                  splashRadius: 18,
                  icon: const Icon(
                    Icons.close,
                    color: AppTheme.secondaryColor,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BrowseSectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onViewAll;

  const _BrowseSectionHeader({required this.title, required this.onViewAll});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: AppTheme.headlineMedium.copyWith(
            fontSize: 21,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          ),
        ),
        InkWell(
          onTap: onViewAll,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF25252B),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.06),
              ),
            ),
            child: Text(
              'VIEW AS LIST',
              style: AppTheme.labelMedium.copyWith(
                color: Colors.white.withOpacity(0.82),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BrowseBentoTile extends StatelessWidget {
  final double width;
  final double height;
  final String label;
  final VoidCallback onTap;

  const _BrowseBentoTile({
    required this.width,
    this.height = 68,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A31),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.white.withOpacity(0.06),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              label,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.titleMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 15,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BrowseShortcutTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  const _BrowseShortcutTile({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            SizedBox(
              width: 34,
              child: Icon(icon, color: iconColor, size: 23),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: AppTheme.headlineSmall.copyWith(
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrowseTileData {
  final String label;

  const _BrowseTileData({
    required this.label,
  });
}

class _BrowseShortcutData {
  final String label;
  final IconData icon;
  final Color iconColor;

  const _BrowseShortcutData({
    required this.label,
    required this.icon,
    required this.iconColor,
  });
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
                      ? CachedNetworkImage(
                          imageUrl: album.coverArtUrl!,
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover)
                      : Container(
                          width: 120,
                          height: 120,
                          color: AppTheme.surfaceColor,
                          child: const Icon(Icons.album,
                              size: 40, color: AppTheme.secondaryColor)),
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
                      child: const Icon(Icons.more_vert,
                          color: Colors.white, size: 16),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(album.title,
                style: AppTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            Text('Album by ${album.artist}',
                style: AppTheme.labelSmall
                    .copyWith(color: AppTheme.secondaryColor),
                maxLines: 1),
          ],
        ),
      ),
    );
  }
}
