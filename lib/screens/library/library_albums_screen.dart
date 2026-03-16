import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/album_options_sheet.dart';
import '../album/album_detail_screen.dart';

/// Library Albums Screen - saved albums with working search and sort
class LibraryAlbumsScreen extends ConsumerStatefulWidget {
  const LibraryAlbumsScreen({super.key});

  @override
  ConsumerState<LibraryAlbumsScreen> createState() =>
      _LibraryAlbumsScreenState();
}

enum _AlbumSortMode { recent, titleAsc, titleDesc, artistAsc, yearDesc }

class _LibraryAlbumsScreenState extends ConsumerState<LibraryAlbumsScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _showSearch = false;
  String _searchQuery = '';
  _AlbumSortMode _sortMode = _AlbumSortMode.recent;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final savedAlbumsState = ref.watch(savedAlbumsProvider);
    final albums = _sortedAlbums(_filteredAlbums(savedAlbumsState.albums));

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
          'Albums',
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
      body: savedAlbumsState.isLoading
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
                          hintText: 'Search albums',
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
                  child: albums.isEmpty
                      ? _buildEmptyState()
                      : GridView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.7,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 18,
                          ),
                          itemCount: albums.length,
                          itemBuilder: (context, index) {
                            final album = albums[index];
                            return _AlbumGridItem(album: album);
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
              Icons.album_outlined,
              size: 64,
              color: Colors.white.withOpacity(0.4),
            ),
            const SizedBox(height: 32),
            Text(
              hasSearch
                  ? 'No albums match your search.'
                  : "You haven't added any albums yet. Tap the + icon on any album to add it to your collection.",
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

  List<Album> _filteredAlbums(List<Album> albums) {
    if (_searchQuery.isEmpty) {
      return List<Album>.from(albums);
    }
    final query = _searchQuery.toLowerCase();
    return albums
        .where(
          (album) =>
              album.title.toLowerCase().contains(query) ||
              album.artist.toLowerCase().contains(query) ||
              (album.year?.toString().contains(query) ?? false),
        )
        .toList();
  }

  List<Album> _sortedAlbums(List<Album> albums) {
    final sorted = List<Album>.from(albums);
    switch (_sortMode) {
      case _AlbumSortMode.recent:
        break;
      case _AlbumSortMode.titleAsc:
        sorted.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
        break;
      case _AlbumSortMode.titleDesc:
        sorted.sort(
          (a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()),
        );
        break;
      case _AlbumSortMode.artistAsc:
        sorted.sort(
          (a, b) => a.artist.toLowerCase().compareTo(b.artist.toLowerCase()),
        );
        break;
      case _AlbumSortMode.yearDesc:
        sorted.sort((a, b) => (b.year ?? 0).compareTo(a.year ?? 0));
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
            _buildSortTile('Recently added', _AlbumSortMode.recent),
            _buildSortTile('Title A-Z', _AlbumSortMode.titleAsc),
            _buildSortTile('Title Z-A', _AlbumSortMode.titleDesc),
            _buildSortTile('Artist A-Z', _AlbumSortMode.artistAsc),
            _buildSortTile('Year newest first', _AlbumSortMode.yearDesc),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 12),
          ],
        ),
      ),
    );
  }

  Widget _buildSortTile(String label, _AlbumSortMode mode) {
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

class _AlbumGridItem extends StatelessWidget {
  final Album album;

  const _AlbumGridItem({required this.album});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AlbumDetailScreen(albumId: album.id, album: album),
          ),
        );
      },
      borderRadius: BorderRadius.circular(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: album.coverArtUrl != null
                      ? CachedNetworkImage(
                          imageUrl: album.coverArtUrl!,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          color: AppTheme.surfaceLight,
                          child: const Icon(
                            Icons.album,
                            color: AppTheme.secondaryColor,
                            size: 36,
                          ),
                        ),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: Material(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => AlbumOptionsSheet.show(context, album),
                      child: const Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(
                          Icons.more_vert,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            album.title,
            style: AppTheme.bodyLarge.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            'Album by ${album.artist}',
            style: AppTheme.bodySmall.copyWith(color: AppTheme.secondaryColor),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
