import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/tidal_service.dart';

/// Cache for video cover availability checks
/// Prevents repeated network requests for covers that don't have video versions
final _videoCoverCache = <String, bool>{};

/// Tidal Cover Widget - Shows video cover if available, falls back to static image
/// 
/// Usage with UUID:
/// ```dart
/// TidalCover(
///   coverUuid: album.cover,
///   size: 640,
///   borderRadius: 12,
/// )
/// ```
/// 
/// Usage with full URL:
/// ```dart
/// TidalCover(
///   coverUrl: album.coverArtUrl,
///   size: 640,
///   borderRadius: 12,
/// )
/// ```
class TidalCover extends StatefulWidget {
  /// The cover UUID from Tidal album/track data (e.g., "a1b2c3d4-e5f6-7890-abcd-ef1234567890")
  final String? coverUuid;
  
  /// Full cover URL (e.g., "https://resources.tidal.com/images/a1b2/c3d4/.../640x640.jpg")
  /// If provided and coverUuid is null, UUID will be extracted from this URL
  final String? coverUrl;
  
  /// Size of the cover (default 640, options: 160, 320, 480, 640, 750, 1280)
  final int size;
  
  /// Border radius for the cover
  final double borderRadius;
  
  /// Whether to attempt loading video cover (set false to always use static image)
  final bool enableVideoCover;
  
  /// Placeholder widget while loading
  final Widget? placeholder;
  
  /// Error widget when image fails to load
  final Widget? errorWidget;
  
  /// BoxFit for the image/video
  final BoxFit fit;

  const TidalCover({
    super.key,
    this.coverUuid,
    this.coverUrl,
    this.size = 640,
    this.borderRadius = 8,
    this.enableVideoCover = true,
    this.placeholder,
    this.errorWidget,
    this.fit = BoxFit.cover,
  });
  
  /// Extract UUID from a full Tidal image URL
  /// e.g., "https://resources.tidal.com/images/a1b2/c3d4/e5f6/7890/640x640.jpg" 
  /// returns "a1b2c3d4-e5f6-7890" (with dashes)
  static String? extractUuidFromUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    
    // Pattern: https://resources.tidal.com/images/{uuid_parts}/size.jpg
    final regex = RegExp(r'resources\.tidal\.com/images/([a-f0-9/]+)/\d+x\d+');
    final match = regex.firstMatch(url);
    if (match != null) {
      final uuidParts = match.group(1);
      if (uuidParts != null) {
        // Convert slashes back to dashes: a1b2/c3d4/e5f6/7890 -> a1b2c3d4-e5f6-7890
        // Note: Tidal UUIDs are typically like dbbf4ed8-5e71-48f2-a50a-3f1c8b3f4d82
        return uuidParts.replaceAll('/', '-');
      }
    }
    return null;
  }

  @override
  State<TidalCover> createState() => _TidalCoverState();
}

class _TidalCoverState extends State<TidalCover> {
  VideoPlayerController? _videoController;
  bool _hasVideo = false;
  bool _videoInitialized = false;
  String? _resolvedUuid;
  
  final TidalService _tidalService = TidalService();

  @override
  void initState() {
    super.initState();
    _resolveUuidAndInit();
  }

  @override
  void didUpdateWidget(TidalCover oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.coverUuid != widget.coverUuid || oldWidget.coverUrl != widget.coverUrl) {
      _disposeVideo();
      _resolveUuidAndInit();
    }
  }
  
  /// Resolve UUID from either coverUuid or by extracting from coverUrl
  void _resolveUuidAndInit() {
    _resolvedUuid = widget.coverUuid;
    if (_resolvedUuid == null && widget.coverUrl != null) {
      _resolvedUuid = TidalCover.extractUuidFromUrl(widget.coverUrl);
    }
    _initCover();
  }

  Future<void> _initCover() async {
    if (_resolvedUuid == null || _resolvedUuid!.isEmpty) {
      return;
    }

    // Check cache first
    final cacheKey = '${_resolvedUuid}_${widget.size}';
    if (_videoCoverCache.containsKey(cacheKey)) {
      if (_videoCoverCache[cacheKey] == true && widget.enableVideoCover) {
        await _initializeVideo();
      }
      return;
    }

    // Try video if enabled
    if (widget.enableVideoCover) {
      await _tryLoadVideo(cacheKey);
    }
  }

  Future<void> _tryLoadVideo(String cacheKey) async {
    final videoUrl = _tidalService.getVideoCoverUrl(_resolvedUuid, size: widget.size);
    if (videoUrl == null) {
      _videoCoverCache[cacheKey] = false;
      return;
    }

    try {
      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(videoUrl),
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );
      
      await _videoController!.initialize();
      
      // Check if video is valid (has duration and dimensions)
      if (_videoController!.value.duration.inMilliseconds > 0 &&
          _videoController!.value.size.width > 0) {
        _videoController!.setLooping(true);
        _videoController!.setVolume(0); // Muted - it's just visual
        _videoController!.play();
        
        _videoCoverCache[cacheKey] = true;
        if (mounted) {
          setState(() {
            _hasVideo = true;
            _videoInitialized = true;
          });
        }
      } else {
        throw Exception('Invalid video');
      }
    } catch (_) {
      // Video doesn't exist or failed to load - cache and fall back to static
      _videoCoverCache[cacheKey] = false;
      _disposeVideo();
      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _initializeVideo() async {
    final videoUrl = _tidalService.getVideoCoverUrl(_resolvedUuid, size: widget.size);
    if (videoUrl == null) return;

    try {
      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(videoUrl),
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );
      await _videoController!.initialize();
      _videoController!.setLooping(true);
      _videoController!.setVolume(0);
      _videoController!.play();
      
      if (mounted) {
        setState(() {
          _hasVideo = true;
          _videoInitialized = true;
        });
      }
    } catch (_) {
      // Video failed to load - static image will be shown
    }
  }

  void _disposeVideo() {
    _videoController?.dispose();
    _videoController = null;
    _hasVideo = false;
    _videoInitialized = false;
  }

  @override
  void dispose() {
    _disposeVideo();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: AspectRatio(
        aspectRatio: 1,
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    // Show video if available and initialized
    if (_hasVideo && _videoInitialized && _videoController != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          // Static image as background (prevents flash on video load)
          _buildStaticImage(),
          // Video on top
          FittedBox(
            fit: widget.fit,
            child: SizedBox(
              width: _videoController!.value.size.width,
              height: _videoController!.value.size.height,
              child: VideoPlayer(_videoController!),
            ),
          ),
        ],
      );
    }

    // Fall back to static image
    return _buildStaticImage();
  }

  Widget _buildStaticImage() {
    final imageUrl = _tidalService.getStaticCoverUrl(_resolvedUuid, size: widget.size);
    
    if (imageUrl == null || imageUrl.isEmpty) {
      return widget.errorWidget ?? _buildDefaultError();
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: widget.fit,
      placeholder: (_, __) => widget.placeholder ?? _buildDefaultPlaceholder(),
      errorWidget: (_, __, ___) => widget.errorWidget ?? _buildDefaultError(),
    );
  }

  Widget _buildDefaultPlaceholder() {
    return Container(
      color: Colors.grey[900],
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white24),
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultError() {
    return Container(
      color: Colors.grey[900],
      child: Icon(
        Icons.album,
        color: Colors.grey[700],
        size: 48,
      ),
    );
  }
}

/// Convenience method to clear the video cover cache
/// Call this when you want to force re-checking video availability
void clearTidalVideoCoverCache() {
  _videoCoverCache.clear();
}
