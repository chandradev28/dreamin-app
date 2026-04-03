import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/music_provider.dart';
import '../../providers/source_provider.dart';

// ============================================================================
// SETTINGS STATE & PROVIDER
// ============================================================================

class SettingsState {
  // Playback
  final bool normalizeVolume;
  final bool autoplay;

  // Look and Feel
  final bool darkMode;

  const SettingsState({
    this.normalizeVolume = false,
    this.autoplay = true,
    this.darkMode = true,
  });

  SettingsState copyWith({
    bool? normalizeVolume,
    bool? autoplay,
    bool? darkMode,
  }) {
    return SettingsState(
      normalizeVolume: normalizeVolume ?? this.normalizeVolume,
      autoplay: autoplay ?? this.autoplay,
      darkMode: darkMode ?? this.darkMode,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(const SettingsState()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    state = SettingsState(
      normalizeVolume: prefs.getBool('normalizeVolume') ?? false,
      autoplay: prefs.getBool('autoplay') ?? true,
      darkMode: prefs.getBool('darkMode') ?? true,
    );
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('normalizeVolume', state.normalizeVolume);
    await prefs.setBool('autoplay', state.autoplay);
    await prefs.setBool('darkMode', state.darkMode);
  }

  void setNormalizeVolume(bool value) {
    state = state.copyWith(normalizeVolume: value);
    _saveSettings();
  }

  void setAutoplay(bool value) {
    state = state.copyWith(autoplay: value);
    _saveSettings();
  }

  void setDarkMode(bool value) {
    state = state.copyWith(darkMode: value);
    _saveSettings();
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});

// ============================================================================
// MAIN SETTINGS SCREEN - Category Navigation
// ============================================================================

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
          'Settings',
          style: AppTheme.titleLarge.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // Playback Section
          _SettingsCategoryTile(
            icon: Icons.play_circle_outline,
            title: 'Playback',
            subtitle: 'Volume normalization, autoplay',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const PlaybackSettingsScreen()),
              );
            },
          ),

          const SizedBox(height: 8),

          // Look and Feel Section
          _SettingsCategoryTile(
            icon: Icons.palette_outlined,
            title: 'Look and Feel',
            subtitle: 'Theme and display preferences',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const LookAndFeelSettingsScreen()),
              );
            },
          ),

          const SizedBox(height: 8),

          // Music Source Section (NEW)
          _SettingsCategoryTile(
            icon: Icons.library_music_outlined,
            title: 'Music Source',
            subtitle: 'TIDAL, Qobuz, or HiFi Server',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const MusicSourceSettingsScreen()),
              );
            },
          ),

          const SizedBox(height: 8),

          // App Info Section
          const Divider(color: AppTheme.surfaceLight),
          const SizedBox(height: 16),

          Center(
            child: Column(
              children: [
                Text(
                  'Dreamin',
                  style: AppTheme.titleMedium.copyWith(
                    color: AppTheme.secondaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Version 1.0.0',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.secondaryColor.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// PLAYBACK SETTINGS SCREEN
// ============================================================================

class PlaybackSettingsScreen extends ConsumerWidget {
  const PlaybackSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);

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
          'Playback',
          style: AppTheme.titleLarge.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          const SizedBox(height: 16),
          _SettingsTile(
            title: 'Normalize volume',
            subtitle: 'Set the same volume level for all tracks.',
            value: settings.normalizeVolume,
            onChanged: settingsNotifier.setNormalizeVolume,
          ),
          const Divider(color: AppTheme.surfaceLight, height: 1),
          _SettingsTile(
            title: 'Autoplay',
            subtitle:
                'Play similar songs after the last track in your queue ends.',
            value: settings.autoplay,
            onChanged: settingsNotifier.setAutoplay,
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }
}

// ============================================================================
// LOOK AND FEEL SETTINGS SCREEN
// ============================================================================

class LookAndFeelSettingsScreen extends ConsumerWidget {
  const LookAndFeelSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);

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
          'Look and Feel',
          style: AppTheme.titleLarge.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          const SizedBox(height: 16),
          _SettingsTile(
            title: 'Dark mode',
            subtitle: 'Use dark theme throughout the app.',
            value: settings.darkMode,
            onChanged: settingsNotifier.setDarkMode,
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }
}

// HiFiServerSettingsScreen removed - HiFi server is pre-configured

// ============================================================================
// WIDGETS
// ============================================================================

class _SettingsCategoryTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsCategoryTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surfaceColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTheme.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.secondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppTheme.secondaryColor),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.bodyLarge.copyWith(
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTheme.bodySmall.copyWith(
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.primaryColor,
            activeTrackColor: AppTheme.primaryColor.withOpacity(0.5),
            inactiveThumbColor: Colors.white.withOpacity(0.7),
            inactiveTrackColor: Colors.white.withOpacity(0.3),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// MUSIC SOURCE SETTINGS SCREEN
// ============================================================================

class MusicSourceSettingsScreen extends ConsumerStatefulWidget {
  const MusicSourceSettingsScreen({super.key});

  @override
  ConsumerState<MusicSourceSettingsScreen> createState() =>
      _MusicSourceSettingsScreenState();
}

class _MusicSourceSettingsScreenState
    extends ConsumerState<MusicSourceSettingsScreen> {
  Future<void> _activateSource(ActiveSource source) async {
    await ref.read(sourceSelectionProvider.notifier).setActiveSource(source);
    ref.invalidate(homeDataProvider);
  }

  Future<void> _showQobuzCredentialsDialog() async {
    final qobuzState = ref.read(qobuzAuthProvider);
    final tokenController = TextEditingController(text: qobuzState.userToken);
    final userIdController = TextEditingController(text: qobuzState.userId);
    final appIdController = TextEditingController(text: qobuzState.appId);
    final appSecretController =
        TextEditingController(text: qobuzState.appSecret);

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceColor,
          title: Text(
            'Connect Qobuz',
            style: AppTheme.titleLarge.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTokenField(
                  controller: tokenController,
                  label: 'User token',
                  obscureText: true,
                ),
                const SizedBox(height: 12),
                _buildTokenField(
                  controller: userIdController,
                  label: 'User ID',
                ),
                const SizedBox(height: 12),
                _buildTokenField(
                  controller: appIdController,
                  label: 'App ID',
                ),
                const SizedBox(height: 12),
                _buildTokenField(
                  controller: appSecretController,
                  label: 'App secret',
                  obscureText: true,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(this.context);
                await ref.read(qobuzAuthProvider.notifier).saveCredentials(
                      userToken: tokenController.text,
                      userId: userIdController.text,
                      appId: appIdController.text,
                      appSecret: appSecretController.text,
                    );
                final nextState = ref.read(qobuzAuthProvider);
                if (!mounted) {
                  return;
                }
                Navigator.of(this.context).pop();

                if (nextState.isConnected) {
                  await _activateSource(ActiveSource.qobuz);
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Qobuz account connected'),
                    ),
                  );
                } else {
                  messenger.showSnackBar(
                    SnackBar(
                      content:
                          Text(nextState.error ?? 'Qobuz validation failed'),
                    ),
                  );
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.black,
              ),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    tokenController.dispose();
    userIdController.dispose();
    appIdController.dispose();
    appSecretController.dispose();
  }

  Widget _buildTokenField({
    required TextEditingController controller,
    required String label,
    bool obscureText = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: AppTheme.bodyMedium.copyWith(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTheme.bodySmall.copyWith(
          color: Colors.white.withOpacity(0.7),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.06),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppTheme.primaryColor.withOpacity(0.7)),
        ),
      ),
    );
  }

  Widget _buildQobuzAccountCard(QobuzAuthState qobuzState) {
    final info = qobuzState.accountInfo;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: qobuzState.isConnected
              ? AppTheme.primaryColor.withOpacity(0.25)
              : Colors.white.withOpacity(0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_user_outlined, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Qobuz Account',
                  style: AppTheme.bodyLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (qobuzState.isLoading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (info != null) ...[
            Text(
              info.displayName.isNotEmpty ? info.displayName : info.login,
              style: AppTheme.titleMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              info.email.isNotEmpty ? info.email : info.login,
              style: AppTheme.bodySmall.copyWith(
                color: Colors.white.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 14),
            _detailLine('Country', info.countryCode),
            _detailLine('Plan', info.subscriptionLabel),
            _detailLine('Start Date', info.startDate),
            _detailLine('End Date', info.endDate),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _capabilityChip(
                  label: 'Lossless Streaming',
                  enabled: info.losslessStreaming,
                ),
                _capabilityChip(
                  label: 'Hi-Res Streaming',
                  enabled: info.hiResStreaming,
                ),
              ],
            ),
          ] else ...[
            Text(
              qobuzState.error ??
                  'Add your Qobuz token, user ID, app ID, and app secret to use your personal Qobuz account across the app.',
              style: AppTheme.bodySmall.copyWith(
                color: Colors.white.withOpacity(0.72),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _showQobuzCredentialsDialog,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.white.withOpacity(0.18)),
                    foregroundColor: Colors.white,
                  ),
                  child: Text(info == null ? 'Add Token' : 'Update Token'),
                ),
              ),
              if (qobuzState.hasCredentials) ...[
                const SizedBox(width: 10),
                IconButton(
                  onPressed: () =>
                      ref.read(qobuzAuthProvider.notifier).refreshAccountInfo(),
                  icon: const Icon(Icons.refresh, color: Colors.white),
                ),
                IconButton(
                  onPressed: () async {
                    await ref
                        .read(qobuzAuthProvider.notifier)
                        .clearCredentials();
                    if (ref.read(sourceSelectionProvider).activeSource ==
                        ActiveSource.qobuz) {
                      await _activateSource(ActiveSource.tidal);
                    }
                  },
                  icon: const Icon(Icons.logout, color: Colors.white70),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _detailLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: AppTheme.bodySmall.copyWith(
                color: Colors.white.withOpacity(0.55),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              style: AppTheme.bodyMedium.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _capabilityChip({
    required String label,
    required bool enabled,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: enabled
            ? AppTheme.primaryColor.withOpacity(0.15)
            : Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: enabled
              ? AppTheme.primaryColor.withOpacity(0.45)
              : Colors.white.withOpacity(0.08),
        ),
      ),
      child: Text(
        '$label ${enabled ? "✓" : "—"}',
        style: AppTheme.bodySmall.copyWith(
          color: enabled ? AppTheme.primaryColor : Colors.white70,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sourceState = ref.watch(sourceSelectionProvider);
    final qobuzState = ref.watch(qobuzAuthProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Music Source',
          style: AppTheme.headlineSmall.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline,
                    color: AppTheme.primaryColor, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Select your preferred music source. The entire app will use your selection for search, playback, and library.',
                    style: AppTheme.bodySmall.copyWith(
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _SourceOptionTile(
            icon: Icons.waves,
            iconColor: Colors.cyan,
            title: 'TIDAL',
            subtitle: 'HiFi streaming with recommendations',
            isSelected: sourceState.activeSource == ActiveSource.tidal,
            onTap: () => _activateSource(ActiveSource.tidal),
          ),
          const SizedBox(height: 12),
          _SourceOptionTile(
            icon: Icons.high_quality,
            iconColor: Colors.blue,
            title: 'Qobuz',
            subtitle: qobuzState.isConnected
                ? 'Connected Qobuz account with official playback'
                : '24-bit Hi-Res FLAC streaming',
            isSelected: sourceState.activeSource == ActiveSource.qobuz,
            onTap: () => _activateSource(ActiveSource.qobuz),
            trailingIcon: qobuzState.isConnected ? Icons.verified : null,
          ),
          const SizedBox(height: 16),
          _buildQobuzAccountCard(qobuzState),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle,
                    color: AppTheme.primaryColor, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Active Source',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      Text(
                        sourceState.activeSource.displayName,
                        style: AppTheme.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SourceOptionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? trailingIcon;

  const _SourceOptionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
    this.trailingIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected
          ? AppTheme.primaryColor.withOpacity(0.15)
          : AppTheme.surfaceColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppTheme.primaryColor : Colors.transparent,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTheme.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: AppTheme.bodySmall.copyWith(
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              if (trailingIcon != null)
                Icon(trailingIcon, color: Colors.white.withOpacity(0.5))
              else if (isSelected)
                Icon(Icons.radio_button_checked, color: AppTheme.primaryColor)
              else
                Icon(Icons.radio_button_off,
                    color: Colors.white.withOpacity(0.3)),
            ],
          ),
        ),
      ),
    );
  }
}
