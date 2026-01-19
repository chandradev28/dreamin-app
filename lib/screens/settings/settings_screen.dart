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

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
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
                MaterialPageRoute(builder: (_) => const PlaybackSettingsScreen()),
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
                MaterialPageRoute(builder: (_) => const LookAndFeelSettingsScreen()),
              );
            },
          ),
          
          const SizedBox(height: 32),
          
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
            subtitle: 'Play similar songs after the last track in your queue ends.',
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
