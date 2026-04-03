import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/theme/app_theme.dart';
import '../services/music_service.dart';
import '../services/qobuz_service.dart';
import '../services/subsonic_service.dart';
import '../services/tidal_service.dart';
import 'subsonic_provider.dart';

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

class QobuzAuthState {
  final String userToken;
  final String userId;
  final String appId;
  final String appSecret;
  final QobuzAccountInfo? accountInfo;
  final bool isLoading;
  final bool isInitialized;
  final String? error;

  const QobuzAuthState({
    this.userToken = '',
    this.userId = '',
    this.appId = '',
    this.appSecret = '',
    this.accountInfo,
    this.isLoading = false,
    this.isInitialized = false,
    this.error,
  });

  bool get hasCredentials =>
      userToken.trim().isNotEmpty &&
      userId.trim().isNotEmpty &&
      appId.trim().isNotEmpty &&
      appSecret.trim().isNotEmpty;

  bool get isConnected => accountInfo != null && error == null;

  QobuzAuthConfig? get authConfig => hasCredentials
      ? QobuzAuthConfig(
          userToken: userToken.trim(),
          userId: userId.trim(),
          appId: appId.trim(),
          appSecret: appSecret.trim(),
        )
      : null;

  QobuzAuthState copyWith({
    String? userToken,
    String? userId,
    String? appId,
    String? appSecret,
    QobuzAccountInfo? accountInfo,
    bool? isLoading,
    bool? isInitialized,
    String? error,
    bool clearAccountInfo = false,
    bool clearError = false,
  }) {
    return QobuzAuthState(
      userToken: userToken ?? this.userToken,
      userId: userId ?? this.userId,
      appId: appId ?? this.appId,
      appSecret: appSecret ?? this.appSecret,
      accountInfo: clearAccountInfo ? null : (accountInfo ?? this.accountInfo),
      isLoading: isLoading ?? this.isLoading,
      isInitialized: isInitialized ?? this.isInitialized,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class QobuzAuthNotifier extends StateNotifier<QobuzAuthState> {
  QobuzAuthNotifier() : super(const QobuzAuthState()) {
    _load();
  }

  static const _tokenKey = 'qobuz_user_token';
  static const _userIdKey = 'qobuz_user_id';
  static const _appIdKey = 'qobuz_app_id';
  static const _appSecretKey = 'qobuz_app_secret';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = state.copyWith(
      userToken: prefs.getString(_tokenKey) ?? '',
      userId: prefs.getString(_userIdKey) ?? '',
      appId: prefs.getString(_appIdKey) ?? '',
      appSecret: prefs.getString(_appSecretKey) ?? '',
      isInitialized: true,
      clearError: true,
      clearAccountInfo: true,
    );

    if (state.hasCredentials) {
      await refreshAccountInfo();
    }
  }

  Future<void> saveCredentials({
    required String userToken,
    required String userId,
    required String appId,
    required String appSecret,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, userToken.trim());
    await prefs.setString(_userIdKey, userId.trim());
    await prefs.setString(_appIdKey, appId.trim());
    await prefs.setString(_appSecretKey, appSecret.trim());

    state = state.copyWith(
      userToken: userToken.trim(),
      userId: userId.trim(),
      appId: appId.trim(),
      appSecret: appSecret.trim(),
      isInitialized: true,
      clearError: true,
      clearAccountInfo: true,
    );

    await refreshAccountInfo();
  }

  Future<void> refreshAccountInfo() async {
    final config = state.authConfig;
    if (config == null) {
      state = state.copyWith(
        error: 'Add your Qobuz token and app credentials first',
        isInitialized: true,
        clearAccountInfo: true,
      );
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final info = await QobuzServiceImpl(authConfig: config).getAccountInfo();
      state = state.copyWith(
        accountInfo: info,
        isLoading: false,
        isInitialized: true,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isInitialized: true,
        clearAccountInfo: true,
        error: e.toString(),
      );
    }
  }

  Future<void> clearCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_appIdKey);
    await prefs.remove(_appSecretKey);
    state = const QobuzAuthState(isInitialized: true);
  }
}

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

final qobuzAuthProvider =
    StateNotifierProvider<QobuzAuthNotifier, QobuzAuthState>((ref) {
  return QobuzAuthNotifier();
});

final sourceSelectionProvider =
    StateNotifierProvider<SourceSelectionNotifier, SourceSelectionState>((ref) {
  return SourceSelectionNotifier();
});

final qobuzServiceProvider = Provider<QobuzServiceImpl>((ref) {
  final qobuzAuth = ref.watch(qobuzAuthProvider);
  return QobuzServiceImpl(authConfig: qobuzAuth.authConfig);
});

final musicServiceProvider = Provider<MusicService>((ref) {
  final sourceState = ref.watch(sourceSelectionProvider);
  final subsonicConfig = ref.watch(subsonicConfigProvider);
  final qobuzService = ref.watch(qobuzServiceProvider);

  switch (sourceState.activeSource) {
    case ActiveSource.subsonic:
      if (subsonicConfig.hasConfig && subsonicConfig.isEnabled) {
        return SubsonicServiceImpl(subsonicConfig.toSubsonicConfig());
      }
      return TidalServiceImpl();
    case ActiveSource.qobuz:
      return qobuzService;
    case ActiveSource.tidal:
    default:
      return TidalServiceImpl();
  }
});

final sourceSupportsPlaylistsProvider = Provider<bool>((ref) {
  final source = ref.watch(sourceSelectionProvider).activeSource;
  return source != ActiveSource.subsonic;
});

final sourceSupportsArtistDetailsProvider = Provider<bool>((ref) {
  final source = ref.watch(sourceSelectionProvider).activeSource;
  return source != ActiveSource.subsonic;
});

final sourceSupportsDiscoveryProvider = Provider<bool>((ref) {
  final source = ref.watch(sourceSelectionProvider).activeSource;
  return source == ActiveSource.tidal || source == ActiveSource.qobuz;
});

final sourceThemeProvider = Provider<SourceThemeColors>((ref) {
  final source = ref.watch(sourceSelectionProvider).activeSource;

  switch (source) {
    case ActiveSource.qobuz:
      return SourceThemeColors.qobuz;
    case ActiveSource.subsonic:
      return SourceThemeColors.subsonic;
    case ActiveSource.tidal:
    default:
      return SourceThemeColors.tidal;
  }
});
