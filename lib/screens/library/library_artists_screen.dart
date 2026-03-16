import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/providers.dart';
import '../../widgets/artist_options_sheet.dart';
import '../artist/artist_detail_screen.dart';

/// Library Artists Screen - saved/followed artists
class LibraryArtistsScreen extends ConsumerWidget {
  const LibraryArtistsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedArtistsState = ref.watch(savedArtistsProvider);
    final artists = savedArtistsState.artists;

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
      ),
      body: savedArtistsState.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            )
          : artists.isEmpty
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
                            ? CachedNetworkImageProvider(artist.imageUrl!)
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
    );
  }

  Widget _buildEmptyState() {
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
              "You haven't followed any artists yet. Use the artist menu to add them to your collection.",
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
}
