import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/theme/app_theme.dart';
import '../models/music_source.dart';
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

class QobuzProfile {
  final String id;
  final String name;
  final String userToken;
  final String userId;
  final String appId;
  final String appSecret;
  final QobuzAccountInfo? accountInfo;
  final String? error;

  const QobuzProfile({
    required this.id,
    required this.name,
    this.userToken = '',
    this.userId = '',
    this.appId = '',
    this.appSecret = '',
    this.accountInfo,
    this.error,
  });

  bool get hasToken => userToken.trim().isNotEmpty;
  bool get hasOfficialCredentials =>
      userToken.trim().isNotEmpty &&
      userId.trim().isNotEmpty &&
      appId.trim().isNotEmpty &&
      appSecret.trim().isNotEmpty;
  bool get isConnected => accountInfo != null && error == null;

  String get displayName {
    if (name.trim().isNotEmpty) {
      return name.trim();
    }
    if (accountInfo?.displayName.isNotEmpty == true) {
      return accountInfo!.displayName;
    }
    if (accountInfo?.login.isNotEmpty == true) {
      return accountInfo!.login;
    }
    return 'Qobuz Profile';
  }

  QobuzAuthConfig? get authConfig => hasOfficialCredentials
      ? QobuzAuthConfig(
          userToken: userToken.trim(),
          userId: userId.trim(),
          appId: appId.trim(),
          appSecret: appSecret.trim(),
        )
      : null;

  QobuzProfile copyWith({
    String? id,
    String? name,
    String? userToken,
    String? userId,
    String? appId,
    String? appSecret,
    QobuzAccountInfo? accountInfo,
    String? error,
    bool clearAccountInfo = false,
    bool clearError = false,
  }) {
    return QobuzProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      userToken: userToken ?? this.userToken,
      userId: userId ?? this.userId,
      appId: appId ?? this.appId,
      appSecret: appSecret ?? this.appSecret,
      accountInfo: clearAccountInfo ? null : (accountInfo ?? this.accountInfo),
      error: clearError ? null : (error ?? this.error),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'userToken': userToken,
      'userId': userId,
      'appId': appId,
      'appSecret': appSecret,
      'accountInfo': accountInfo == null
          ? null
          : {
              'userId': accountInfo!.userId,
              'displayName': accountInfo!.displayName,
              'login': accountInfo!.login,
              'email': accountInfo!.email,
              'countryCode': accountInfo!.countryCode,
              'subscriptionLabel': accountInfo!.subscriptionLabel,
              'startDate': accountInfo!.startDate,
              'endDate': accountInfo!.endDate,
              'losslessStreaming': accountInfo!.losslessStreaming,
              'hiResStreaming': accountInfo!.hiResStreaming,
            },
      'error': error,
    };
  }

  factory QobuzProfile.fromJson(Map<String, dynamic> json) {
    final infoJson = json['accountInfo'] as Map<String, dynamic>?;
    return QobuzProfile(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      userToken: (json['userToken'] ?? '').toString(),
      userId: (json['userId'] ?? '').toString(),
      appId: (json['appId'] ?? '').toString(),
      appSecret: (json['appSecret'] ?? '').toString(),
      accountInfo: infoJson == null
          ? null
          : QobuzAccountInfo(
              userId: (infoJson['userId'] ?? '').toString(),
              displayName: (infoJson['displayName'] ?? '').toString(),
              login: (infoJson['login'] ?? '').toString(),
              email: (infoJson['email'] ?? '').toString(),
              countryCode: (infoJson['countryCode'] ?? '').toString(),
              subscriptionLabel:
                  (infoJson['subscriptionLabel'] ?? '').toString(),
              startDate: (infoJson['startDate'] ?? '').toString(),
              endDate: (infoJson['endDate'] ?? '').toString(),
              losslessStreaming: infoJson['losslessStreaming'] == true,
              hiResStreaming: infoJson['hiResStreaming'] == true,
            ),
      error: json['error']?.toString(),
    );
  }
}

class QobuzAuthState {
  final List<QobuzProfile> profiles;
  final String? activeProfileId;
  final QobuzStreamQuality preferredQuality;
  final bool isLoading;
  final bool isInitialized;
  final String? error;

  const QobuzAuthState({
    this.profiles = const [],
    this.activeProfileId,
    this.preferredQuality = QobuzStreamQuality.maxHiRes,
    this.isLoading = false,
    this.isInitialized = false,
    this.error,
  });

  QobuzProfile? get activeProfile {
    if (profiles.isEmpty) {
      return null;
    }
    final profileId = activeProfileId;
    if (profileId == null) {
      return profiles.first;
    }
    return profiles.firstWhere(
      (profile) => profile.id == profileId,
      orElse: () => profiles.first,
    );
  }

  bool get hasProfiles => profiles.isNotEmpty;
  bool get hasCredentials => activeProfile?.hasOfficialCredentials == true;
  bool get isConnected => activeProfile?.isConnected == true;
  QobuzAuthConfig? get authConfig => activeProfile?.authConfig;

  QobuzAuthState copyWith({
    List<QobuzProfile>? profiles,
    String? activeProfileId,
    QobuzStreamQuality? preferredQuality,
    bool? isLoading,
    bool? isInitialized,
    String? error,
    bool clearActiveProfile = false,
    bool clearError = false,
  }) {
    return QobuzAuthState(
      profiles: profiles ?? this.profiles,
      activeProfileId:
          clearActiveProfile ? null : (activeProfileId ?? this.activeProfileId),
      preferredQuality: preferredQuality ?? this.preferredQuality,
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

  static const _profilesKey = 'qobuz_profiles_v2';
  static const _activeProfileKey = 'qobuz_active_profile_id';
  static const _preferredQualityKey = 'qobuz_preferred_quality';
  static const _legacyTokenKey = 'qobuz_user_token';
  static const _legacyUserIdKey = 'qobuz_user_id';
  static const _legacyAppIdKey = 'qobuz_app_id';
  static const _legacyAppSecretKey = 'qobuz_app_secret';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final profilesJson = prefs.getString(_profilesKey);
    final qualityName = prefs.getString(_preferredQualityKey);
    final preferredQuality = QobuzStreamQuality.values.firstWhere(
      (value) => value.name == qualityName,
      orElse: () => QobuzStreamQuality.maxHiRes,
    );

    List<QobuzProfile> profiles = [];
    if (profilesJson != null && profilesJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(profilesJson) as List<dynamic>;
        profiles = decoded
            .map((item) => QobuzProfile.fromJson(item as Map<String, dynamic>))
            .where((profile) => profile.id.isNotEmpty)
            .toList();
      } catch (_) {}
    } else {
      final legacyProfile = _loadLegacyProfile(prefs);
      if (legacyProfile != null) {
        profiles = [legacyProfile];
        await _persistProfiles(profiles, legacyProfile.id);
      }
    }

    final activeProfileId = prefs.getString(_activeProfileKey);
    state = state.copyWith(
      profiles: profiles,
      activeProfileId: profiles.any((profile) => profile.id == activeProfileId)
          ? activeProfileId
          : (profiles.isNotEmpty ? profiles.first.id : null),
      preferredQuality: preferredQuality,
      isInitialized: true,
      clearError: true,
    );

    final activeProfile = state.activeProfile;
    if (activeProfile?.hasOfficialCredentials == true) {
      await refreshActiveProfile();
    }
  }

  QobuzProfile? _loadLegacyProfile(SharedPreferences prefs) {
    final token = prefs.getString(_legacyTokenKey) ?? '';
    if (token.trim().isEmpty) {
      return null;
    }

    return QobuzProfile(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: 'Primary',
      userToken: token,
      userId: prefs.getString(_legacyUserIdKey) ?? '',
      appId: prefs.getString(_legacyAppIdKey) ?? '',
      appSecret: prefs.getString(_legacyAppSecretKey) ?? '',
    );
  }

  Future<void> _persistProfiles(
    List<QobuzProfile> profiles,
    String? activeProfileId,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _profilesKey,
      jsonEncode(profiles.map((profile) => profile.toJson()).toList()),
    );
    if (activeProfileId == null) {
      await prefs.remove(_activeProfileKey);
    } else {
      await prefs.setString(_activeProfileKey, activeProfileId);
    }
  }

  Future<void> saveProfile({
    String? profileId,
    required String name,
    required String userToken,
    String userId = '',
    String appId = '',
    String appSecret = '',
    bool makeActive = true,
  }) async {
    final cleanedToken = userToken.trim();
    if (cleanedToken.isEmpty) {
      state = state.copyWith(error: 'Qobuz token is required');
      return;
    }

    final cleanedProfile = QobuzProfile(
      id: profileId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: name.trim(),
      userToken: cleanedToken,
      userId: userId.trim(),
      appId: appId.trim(),
      appSecret: appSecret.trim(),
    );

    final nextProfiles = [...state.profiles];
    final existingIndex =
        nextProfiles.indexWhere((profile) => profile.id == cleanedProfile.id);
    if (existingIndex == -1) {
      nextProfiles.add(cleanedProfile);
    } else {
      nextProfiles[existingIndex] = cleanedProfile;
    }

    final nextActiveId = makeActive
        ? cleanedProfile.id
        : (state.activeProfileId ?? cleanedProfile.id);

    state = state.copyWith(
      profiles: nextProfiles,
      activeProfileId: nextActiveId,
      isInitialized: true,
      clearError: true,
    );
    await _persistProfiles(nextProfiles, nextActiveId);

    if (cleanedProfile.hasOfficialCredentials) {
      await refreshActiveProfile();
    }
  }

  Future<void> setActiveProfile(String profileId) async {
    if (!state.profiles.any((profile) => profile.id == profileId)) {
      return;
    }

    state = state.copyWith(
      activeProfileId: profileId,
      clearError: true,
    );
    await _persistProfiles(state.profiles, profileId);

    if (state.activeProfile?.hasOfficialCredentials == true) {
      await refreshActiveProfile();
    }
  }

  Future<void> refreshActiveProfile() async {
    final profile = state.activeProfile;
    if (profile == null) {
      state = state.copyWith(
        isInitialized: true,
        error: 'Add a Qobuz profile first',
      );
      return;
    }

    if (!profile.hasOfficialCredentials) {
      state = state.copyWith(
        isInitialized: true,
        clearError: true,
      );
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final info = await QobuzServiceImpl(authConfig: profile.authConfig)
          .getAccountInfo();
      final updatedProfiles = state.profiles
          .map(
            (entry) => entry.id == profile.id
                ? entry.copyWith(
                    accountInfo: info,
                    clearError: true,
                  )
                : entry,
          )
          .toList();
      state = state.copyWith(
        profiles: updatedProfiles,
        isLoading: false,
        isInitialized: true,
        clearError: true,
      );
      await _persistProfiles(updatedProfiles, state.activeProfileId);
    } catch (e) {
      final updatedProfiles = state.profiles
          .map(
            (entry) => entry.id == profile.id
                ? entry.copyWith(
                    error: e.toString(),
                    clearAccountInfo: true,
                  )
                : entry,
          )
          .toList();
      state = state.copyWith(
        profiles: updatedProfiles,
        isLoading: false,
        isInitialized: true,
        error: e.toString(),
      );
      await _persistProfiles(updatedProfiles, state.activeProfileId);
    }
  }

  Future<void> removeProfile(String profileId) async {
    final updatedProfiles =
        state.profiles.where((profile) => profile.id != profileId).toList();
    final nextActiveId = updatedProfiles.isEmpty
        ? null
        : (state.activeProfileId == profileId
            ? updatedProfiles.first.id
            : state.activeProfileId);

    state = state.copyWith(
      profiles: updatedProfiles,
      activeProfileId: nextActiveId,
      isInitialized: true,
      clearError: true,
      clearActiveProfile: updatedProfiles.isEmpty,
    );

    await _persistProfiles(updatedProfiles, nextActiveId);

    if (updatedProfiles.isEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_legacyTokenKey);
      await prefs.remove(_legacyUserIdKey);
      await prefs.remove(_legacyAppIdKey);
      await prefs.remove(_legacyAppSecretKey);
    } else if (state.activeProfile?.hasOfficialCredentials == true) {
      await refreshActiveProfile();
    }
  }

  Future<void> clearCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_profilesKey);
    await prefs.remove(_activeProfileKey);
    await prefs.remove(_legacyTokenKey);
    await prefs.remove(_legacyUserIdKey);
    await prefs.remove(_legacyAppIdKey);
    await prefs.remove(_legacyAppSecretKey);
    state = state.copyWith(
      profiles: const [],
      clearActiveProfile: true,
      isInitialized: true,
      clearError: true,
    );
  }

  Future<void> setPreferredQuality(QobuzStreamQuality quality) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_preferredQualityKey, quality.name);
    state = state.copyWith(preferredQuality: quality);
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

final qobuzPreferredQualityProvider = Provider<QobuzStreamQuality>((ref) {
  return ref.watch(qobuzAuthProvider).preferredQuality;
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
