import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:convert';
import '../../core/theme/app_theme.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import '../../widgets/track_options_sheet.dart';

/// Library Tracks Screen - TIDAL Style (Liked Songs)
class LibraryTracksScreen extends ConsumerWidget {
  const LibraryTracksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesState = ref.watch(favoritesProvider);
    final favorites = favoritesState.favorites;
    
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
          'Tracks',
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
      body: favorites.isEmpty
          ? _buildEmptyState()
          : _buildTracksList(favorites, ref, context),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Music note icon
            Icon(
              Icons.music_note_outlined,
              size: 64,
              color: Colors.white.withOpacity(0.4),
            ),
            const SizedBox(height: 32),
            Text(
              "You haven't added any tracks yet. Tap the heart icon on any track to add it to your collection.",
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

  Widget _buildTracksList(List<dynamic> favorites, WidgetRef ref, BuildContext context) {
    // Parse all tracks first
    final tracks = <Track>[];
    for (final fav in favorites) {
      try {
        final trackData = jsonDecode(fav.trackJson as String);
        tracks.add(Track.fromJson(trackData));
      } catch (e) {
        // Skip invalid entries
      }
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: tracks.length,
      itemBuilder: (context, index) {
        final track = tracks[index];
        
        return ListTile(
          onTap: () {
            ref.read(playerProvider.notifier).playQueue(tracks, startIndex: index);
          },
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: track.coverArtUrl != null
                ? CachedNetworkImage(
                    imageUrl: track.coverArtUrl!,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => _placeholderIcon(),
                    errorWidget: (_, __, ___) => _placeholderIcon(),
                  )
                : _placeholderIcon(),
          ),
          title: Text(
            track.title,
            style: AppTheme.bodyLarge.copyWith(
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            track.artist,
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.secondaryColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: IconButton(
            icon: const Icon(Icons.more_horiz, color: AppTheme.secondaryColor),
            onPressed: () => TrackOptionsSheet.show(context, track),
          ),
        );
      },
    );
  }

  Widget _placeholderIcon() {
    return Container(
      width: 48,
      height: 48,
      color: AppTheme.surfaceLight,
      child: const Icon(Icons.music_note, color: AppTheme.secondaryColor, size: 24),
    );
  }
}
