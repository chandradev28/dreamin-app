import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_theme.dart';

// ============================================================================
// SETTINGS STATE & PROVIDER
// ============================================================================

class SettingsState {
  // Playback
  final bool normalizeVolume;
  final bool autoplay;
  
  // Look and Feel
  final bool darkMode;
  final bool showExplicitContent;
  
  // Integration
  final bool lastFmScrobbling;
  final bool discordRichPresence;

  const SettingsState({
    this.normalizeVolume = false,
    this.autoplay = true,
    this.darkMode = true,
    this.showExplicitContent = true,
    this.lastFmScrobbling = false,
    this.discordRichPresence = false,
  });

  SettingsState copyWith({
    bool? normalizeVolume,
    bool? autoplay,
    bool? darkMode,
    bool? showExplicitContent,
    bool? lastFmScrobbling,
    bool? discordRichPresence,
  }) {
    return SettingsState(
      normalizeVolume: normalizeVolume ?? this.normalizeVolume,
      autoplay: autoplay ?? this.autoplay,
      darkMode: darkMode ?? this.darkMode,
      showExplicitContent: showExplicitContent ?? this.showExplicitContent,
      lastFmScrobbling: lastFmScrobbling ?? this.lastFmScrobbling,
      discordRichPresence: discordRichPresence ?? this.discordRichPresence,
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
      showExplicitContent: prefs.getBool('showExplicitContent') ?? true,
      lastFmScrobbling: prefs.getBool('lastFmScrobbling') ?? false,
      discordRichPresence: prefs.getBool('discordRichPresence') ?? false,
    );
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('normalizeVolume', state.normalizeVolume);
    await prefs.setBool('autoplay', state.autoplay);
    await prefs.setBool('darkMode', state.darkMode);
    await prefs.setBool('showExplicitContent', state.showExplicitContent);
    await prefs.setBool('lastFmScrobbling', state.lastFmScrobbling);
    await prefs.setBool('discordRichPresence', state.discordRichPresence);
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

  void setShowExplicitContent(bool value) {
    state = state.copyWith(showExplicitContent: value);
    _saveSettings();
  }

  void setLastFmScrobbling(bool value) {
    state = state.copyWith(lastFmScrobbling: value);
    _saveSettings();
  }

  void setDiscordRichPresence(bool value) {
    state = state.copyWith(discordRichPresence: value);
    _saveSettings();
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});

// ============================================================================
// SETTINGS SCREEN
// ============================================================================

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

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
          'Settings',
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
          
          // ==================== PLAYBACK SECTION ====================
          _SectionHeader(title: 'Playback'),
          const SizedBox(height: 8),
          
          _SettingsTile(
            title: 'Normalize volume',
            subtitle: 'Set the same volume level for all tracks.',
            value: settings.normalizeVolume,
            onChanged: settingsNotifier.setNormalizeVolume,
          ),
          
          _SettingsTile(
            title: 'Autoplay',
            subtitle: 'Play similar songs after the last track in your queue ends.',
            value: settings.autoplay,
            onChanged: settingsNotifier.setAutoplay,
          ),
          
          const SizedBox(height: 24),
          
          // ==================== LOOK AND FEEL SECTION ====================
          _SectionHeader(title: 'Look and Feel'),
          const SizedBox(height: 8),
          
          _SettingsTile(
            title: 'Dark mode',
            subtitle: 'Use dark theme throughout the app.',
            value: settings.darkMode,
            onChanged: settingsNotifier.setDarkMode,
          ),
          
          _SettingsTile(
            title: 'Show explicit content',
            subtitle: 'Allow content labeled with the E tag.',
            value: settings.showExplicitContent,
            onChanged: settingsNotifier.setShowExplicitContent,
          ),
          
          const SizedBox(height: 24),
          
          // ==================== INTEGRATION SECTION ====================
          _SectionHeader(title: 'Integration'),
          const SizedBox(height: 8),
          
          _SettingsTile(
            title: 'Last.fm scrobbling',
            subtitle: 'Share your listening activity with Last.fm.',
            value: settings.lastFmScrobbling,
            onChanged: settingsNotifier.setLastFmScrobbling,
          ),
          
          _SettingsTile(
            title: 'Discord Rich Presence',
            subtitle: 'Show currently playing track on Discord.',
            value: settings.discordRichPresence,
            onChanged: settingsNotifier.setDiscordRichPresence,
          ),
          
          const SizedBox(height: 48),
        ],
      ),
    );
  }
}

// ============================================================================
// WIDGETS
// ============================================================================

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Text(
        title,
        style: AppTheme.headlineSmall.copyWith(
          fontWeight: FontWeight.bold,
          color: Colors.white,
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
      padding: const EdgeInsets.symmetric(vertical: 12),
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
