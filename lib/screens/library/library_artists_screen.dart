import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_theme.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/artist_options_sheet.dart';
import '../artist/artist_detail_screen.dart';

/// Library Artists Screen - saved/followed artists
class LibraryArtistsScreen extends ConsumerStatefulWidget {
  const LibraryArtistsScreen({super.key});

  @override
  ConsumerState<LibraryArtistsScreen> createState() =>
      _LibraryArtistsScreenState();
}

enum _ArtistSortMode { recent, nameAsc, nameDesc, albumCountDesc }

class _LibraryArtistsScreenState extends ConsumerState<LibraryArtistsScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _showSearch = false;
  String _searchQuery = '';
  _ArtistSortMode _sortMode = _ArtistSortMode.recent;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final savedArtistsState = ref.watch(savedArtistsProvider);
    final artists = _sortedArtists(_filteredArtists(savedArtistsState.artists));

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Artists',
          style: AppTheme.titleLarge.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {
              setState(() {
                _showSearch = !_showSearch;
                if (!_showSearch) {
                  _searchController.clear();
                  _searchQuery = '';
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.sort, color: Colors.white),
            onPressed: _showSortSheet,
          ),
        ],
      ),
      body: savedArtistsState.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            )
          : Column(
              children: [
                if (_showSearch)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        style: AppTheme.bodyLarge.copyWith(color: Colors.white),
                        onChanged: (value) =>
                            setState(() => _searchQuery = value.trim()),
                        decoration: InputDecoration(
                          hintText: 'Search artists',
                          hintStyle: AppTheme.bodyLarge.copyWith(
                            color: Colors.white.withOpacity(0.46),
                          ),
                          prefixIcon:
                              const Icon(Icons.search, color: Colors.white70),
                          suffixIcon: _searchQuery.isEmpty
                              ? null
                              : IconButton(
                                  icon: const Icon(
                                    Icons.close,
                                    color: Colors.white70,
                                  ),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 15,
                          ),
                        ),
                      ),
                    ),
                  ),
                Expanded(
                  child: artists.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: artists.length,
                          itemBuilder: (context, index) {
                            final artist = artists[index];
                            return ListTile(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ArtistDetailScreen(
                                      artistId: artist.id,
                                      artist: artist,
                                    ),
                                  ),
                                );
                              },
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              leading: CircleAvatar(
                                radius: 28,
                                backgroundColor: AppTheme.surfaceLight,
                                backgroundImage: artist.imageUrl != null
                                    ? CachedNetworkImageProvider(
                                        artist.imageUrl!,
                                      )
                                    : null,
                                child: artist.imageUrl == null
                                    ? const Icon(
                                        Icons.person,
                                        color: AppTheme.secondaryColor,
                                        size: 28,
                                      )
                                    : null,
                              ),
                              title: Text(
                                artist.name,
                                style: AppTheme.bodyLarge.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                artist.albumCount != null
                                    ? '${artist.albumCount} albums'
                                    : 'Saved artist',
                                style: AppTheme.bodySmall.copyWith(
                                  color: AppTheme.secondaryColor,
                                ),
                              ),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.more_horiz,
                                  color: AppTheme.secondaryColor,
                                ),
                                onPressed: () => ArtistOptionsSheet.show(
                                  context,
                                  artist,
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildEmptyState() {
    final hasSearch = _searchQuery.isNotEmpty;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_outline,
              size: 64,
              color: Colors.white.withOpacity(0.4),
            ),
            const SizedBox(height: 32),
            Text(
              hasSearch
                  ? 'No artists match your search.'
                  : "You haven't followed any artists yet. Use the artist menu to add them to your collection.",
              style: AppTheme.bodyMedium.copyWith(
                color: Colors.white.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  List<Artist> _filteredArtists(List<Artist> artists) {
    if (_searchQuery.isEmpty) {
      return List<Artist>.from(artists);
    }
    final query = _searchQuery.toLowerCase();
    return artists
        .where(
          (artist) =>
              artist.name.toLowerCase().contains(query) ||
              (artist.albumCount?.toString().contains(query) ?? false),
        )
        .toList();
  }

  List<Artist> _sortedArtists(List<Artist> artists) {
    final sorted = List<Artist>.from(artists);
    switch (_sortMode) {
      case _ArtistSortMode.recent:
        break;
      case _ArtistSortMode.nameAsc:
        sorted.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
        break;
      case _ArtistSortMode.nameDesc:
        sorted.sort(
          (a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()),
        );
        break;
      case _ArtistSortMode.albumCountDesc:
        sorted.sort((a, b) => (b.albumCount ?? 0).compareTo(a.albumCount ?? 0));
        break;
    }
    return sorted;
  }

  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      builder: (context) => SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            _buildSortTile('Recently added', _ArtistSortMode.recent),
            _buildSortTile('Name A-Z', _ArtistSortMode.nameAsc),
            _buildSortTile('Name Z-A', _ArtistSortMode.nameDesc),
            _buildSortTile('Most albums', _ArtistSortMode.albumCountDesc),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 12),
          ],
        ),
      ),
    );
  }

  Widget _buildSortTile(String label, _ArtistSortMode mode) {
    final selected = _sortMode == mode;
    return ListTile(
      leading: Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_off,
        color: selected ? AppTheme.primaryColor : Colors.white70,
      ),
      title: Text(
        label,
        style: AppTheme.bodyLarge.copyWith(color: Colors.white),
      ),
      onTap: () {
        setState(() => _sortMode = mode);
        Navigator.pop(context);
      },
    );
  }
}
