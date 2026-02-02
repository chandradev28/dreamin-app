import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/api_constants.dart';
import '../services/subsonic_service.dart';

/// Pre-configured HiFi Server credentials
class _HiFiCredentials {
  static const serverUrl = 'http://135.235.163.138:8080';
  static const username = 'hifi';
  static const password = 'local';
}

/// Subsonic/HiFi Server Configuration State
class SubsonicConfigState {
  final String serverUrl;
  final String username;
  final String password;
  final bool isEnabled;
  final bool isConnected;

  const SubsonicConfigState({
    this.serverUrl = _HiFiCredentials.serverUrl,
    this.username = _HiFiCredentials.username,
    this.password = _HiFiCredentials.password,
    this.isEnabled = true,
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

/// Subsonic Configuration Notifier - Pre-configured with HiFi server
class SubsonicConfigNotifier extends StateNotifier<SubsonicConfigState> {
  SubsonicServiceImpl? _service;

  SubsonicConfigNotifier() : super(const SubsonicConfigState()) {
    // Initialize immediately with pre-set credentials
    _initService();
  }

  SubsonicServiceImpl? get service => _service;

  void _initService() {
    _service = SubsonicServiceImpl(state.toSubsonicConfig());
    state = state.copyWith(isConnected: true);
  }

  /// Test connection to server
  Future<bool> testConnection() async {
    if (!state.hasConfig) return false;
    
    _initService();
    final success = await _service?.ping() ?? false;
    
    state = state.copyWith(isConnected: success);
    return success;
  }
}

/// Provider for Subsonic configuration (pre-configured)
final subsonicConfigProvider = StateNotifierProvider<SubsonicConfigNotifier, SubsonicConfigState>((ref) {
  return SubsonicConfigNotifier();
});

/// Provider for Subsonic service (always available with pre-set config)
final subsonicServiceProvider = Provider<SubsonicServiceImpl?>((ref) {
  final notifier = ref.watch(subsonicConfigProvider.notifier);
  return notifier.service;
});
