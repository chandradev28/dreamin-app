import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/music_service.dart';
import '../services/tidal_service.dart';
import '../services/subsonic_service.dart';
import '../services/qobuz_service.dart';
import 'subsonic_provider.dart';

/// Active music source enum
enum ActiveSource { tidal, subsonic, qobuz }

extension ActiveSourceExtension on ActiveSource {
  String get displayName {
    switch (this) {
      case ActiveSource.tidal:
        return 'TIDAL';
      case ActiveSource.subsonic:
        return 'HiFi Server';
      case ActiveSource.qobuz:
        return 'Qobuz';
    }
  }

  String get description {
    switch (this) {
      case ActiveSource.tidal:
        return 'HiFi quality streaming with recommendations';
      case ActiveSource.subsonic:
        return 'Your personal Subsonic/HiFi server';
      case ActiveSource.qobuz:
        return '24-bit Hi-Res FLAC streaming';
    }
  }
}

/// Source selection state
class SourceSelectionState {
  final ActiveSource activeSource;
  final bool isInitialized;

  const SourceSelectionState({
    this.activeSource = ActiveSource.tidal,
    this.isInitialized = false,
  });

  SourceSelectionState copyWith({
    ActiveSource? activeSource,
    bool? isInitialized,
  }) {
    return SourceSelectionState(
      activeSource: activeSource ?? this.activeSource,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}

/// Source selection notifier
class SourceSelectionNotifier extends StateNotifier<SourceSelectionState> {
  SourceSelectionNotifier() : super(const SourceSelectionState()) {
    _loadSourceSelection();
  }

  Future<void> _loadSourceSelection() async {
    final prefs = await SharedPreferences.getInstance();
    final savedSource = prefs.getString('active_source') ?? 'tidal';
    
    ActiveSource source;
    switch (savedSource) {
      case 'subsonic':
        source = ActiveSource.subsonic;
        break;
      case 'qobuz':
        source = ActiveSource.qobuz;
        break;
      default:
        source = ActiveSource.tidal;
    }
    
    state = state.copyWith(activeSource: source, isInitialized: true);
  }

  Future<void> setActiveSource(ActiveSource source) async {
    state = state.copyWith(activeSource: source);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('active_source', source.name);
  }
}

/// Provider for source selection state
final sourceSelectionProvider = StateNotifierProvider<SourceSelectionNotifier, SourceSelectionState>((ref) {
  return SourceSelectionNotifier();
});

/// Provider for the active music service
/// Returns the appropriate service based on user's source selection
final musicServiceProvider = Provider<MusicService>((ref) {
  final sourceState = ref.watch(sourceSelectionProvider);
  final subsonicConfig = ref.watch(subsonicConfigProvider);
  
  switch (sourceState.activeSource) {
    case ActiveSource.subsonic:
      if (subsonicConfig.hasConfig && subsonicConfig.isEnabled) {
        return SubsonicServiceImpl(subsonicConfig.toSubsonicConfig());
      }
      // Fallback to TIDAL if Subsonic not configured
      return TidalServiceImpl();
      
    case ActiveSource.qobuz:
      return QobuzServiceImpl();
      
    case ActiveSource.tidal:
    default:
      return TidalServiceImpl();
  }
});

/// Provider to check if current source supports a feature
final sourceSupportsPlaylistsProvider = Provider<bool>((ref) {
  final source = ref.watch(sourceSelectionProvider).activeSource;
  return source != ActiveSource.subsonic;
});

final sourceSupportsArtistDetailsProvider = Provider<bool>((ref) {
  final source = ref.watch(sourceSelectionProvider).activeSource;
  return source != ActiveSource.qobuz;
});

final sourceSupportsDiscoveryProvider = Provider<bool>((ref) {
  final source = ref.watch(sourceSelectionProvider).activeSource;
  return source == ActiveSource.tidal;
});
