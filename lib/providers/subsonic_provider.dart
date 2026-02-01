import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/api_constants.dart';
import '../services/subsonic_service.dart';

/// Subsonic/HiFi Server Configuration State
class SubsonicConfigState {
  final String serverUrl;
  final String username;
  final String password;
  final bool isEnabled;
  final bool isConnected;

  const SubsonicConfigState({
    this.serverUrl = '',
    this.username = '',
    this.password = '',
    this.isEnabled = false,
    this.isConnected = false,
  });

  SubsonicConfigState copyWith({
    String? serverUrl,
    String? username,
    String? password,
    bool? isEnabled,
    bool? isConnected,
  }) {
    return SubsonicConfigState(
      serverUrl: serverUrl ?? this.serverUrl,
      username: username ?? this.username,
      password: password ?? this.password,
      isEnabled: isEnabled ?? this.isEnabled,
      isConnected: isConnected ?? this.isConnected,
    );
  }

  bool get hasConfig => serverUrl.isNotEmpty && username.isNotEmpty && password.isNotEmpty;

  SubsonicConfig toSubsonicConfig() {
    return SubsonicConfig(
      serverUrl: serverUrl,
      username: username,
      password: password,
    );
  }
}

/// Subsonic Configuration Notifier
class SubsonicConfigNotifier extends StateNotifier<SubsonicConfigState> {
  SubsonicServiceImpl? _service;

  SubsonicConfigNotifier() : super(const SubsonicConfigState()) {
    _loadConfig();
  }

  SubsonicServiceImpl? get service => _service;

  Future<void> _loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    state = SubsonicConfigState(
      serverUrl: prefs.getString('subsonic_serverUrl') ?? '',
      username: prefs.getString('subsonic_username') ?? '',
      password: prefs.getString('subsonic_password') ?? '',
      isEnabled: prefs.getBool('subsonic_enabled') ?? false,
    );
    
    if (state.hasConfig && state.isEnabled) {
      _initService();
    }
  }

  Future<void> _saveConfig() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('subsonic_serverUrl', state.serverUrl);
    await prefs.setString('subsonic_username', state.username);
    await prefs.setString('subsonic_password', state.password);
    await prefs.setBool('subsonic_enabled', state.isEnabled);
  }

  void _initService() {
    if (state.hasConfig) {
      _service = SubsonicServiceImpl(state.toSubsonicConfig());
    }
  }

  /// Update server configuration
  Future<void> updateConfig({
    required String serverUrl,
    required String username,
    required String password,
  }) async {
    state = state.copyWith(
      serverUrl: serverUrl.trim(),
      username: username.trim(),
      password: password,
      isConnected: false,
    );
    await _saveConfig();
    _initService();
  }

  /// Test connection to server
  Future<bool> testConnection() async {
    if (!state.hasConfig) return false;
    
    _initService();
    final success = await _service?.ping() ?? false;
    
    state = state.copyWith(isConnected: success);
    return success;
  }

  /// Enable/disable HiFi source
  Future<void> setEnabled(bool enabled) async {
    state = state.copyWith(isEnabled: enabled);
    await _saveConfig();
    
    if (enabled && state.hasConfig) {
      _initService();
    } else {
      _service = null;
    }
  }
}

/// Provider for Subsonic configuration
final subsonicConfigProvider = StateNotifierProvider<SubsonicConfigNotifier, SubsonicConfigState>((ref) {
  return SubsonicConfigNotifier();
});

/// Provider for Subsonic service (null if not configured/enabled)
final subsonicServiceProvider = Provider<SubsonicServiceImpl?>((ref) {
  final config = ref.watch(subsonicConfigProvider);
  if (!config.isEnabled || !config.hasConfig) return null;
  return ref.watch(subsonicConfigProvider.notifier).service;
});
