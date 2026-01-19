import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/providers.dart';
import '../artist/artist_detail_screen.dart';

/// Library Artists Screen - TIDAL Style (Followed Artists)
class LibraryArtistsScreen extends ConsumerStatefulWidget {
  const LibraryArtistsScreen({super.key});

  @override
  ConsumerState<LibraryArtistsScreen> createState() => _LibraryArtistsScreenState();
}

class _LibraryArtistsScreenState extends ConsumerState<LibraryArtistsScreen> {
  List<dynamic> _artists = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadArtists();
  }

  Future<void> _loadArtists() async {
    final database = ref.read(databaseProvider);
    // Get top artists from listening history
    final artistData = await database.getTopArtistData(limit: 50);
    if (mounted) {
      setState(() {
        _artists = artistData;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.sort, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : _artists.isEmpty
              ? _buildEmptyState()
              : _buildArtistsList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Person icon
            Icon(
              Icons.person_outline,
              size: 64,
              color: Colors.white.withOpacity(0.4),
            ),
            const SizedBox(height: 32),
            Text(
              "You haven't followed any artists yet. Tap the heart icon on any artist to follow them.",
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

  Widget _buildArtistsList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _artists.length,
      itemBuilder: (context, index) {
        final artist = _artists[index];
        return ListTile(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ArtistDetailScreen(artistId: artist.artistId as String),
              ),
            );
          },
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: CircleAvatar(
            radius: 28,
            backgroundColor: AppTheme.surfaceLight,
            child: Icon(
              Icons.person,
              color: AppTheme.secondaryColor,
              size: 28,
            ),
          ),
          title: Text(
            artist.artistName as String,
            style: AppTheme.bodyLarge.copyWith(
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            '${artist.playCount} plays',
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.secondaryColor,
            ),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.more_horiz, color: AppTheme.secondaryColor),
            onPressed: () {},
          ),
        );
      },
    );
  }
}
