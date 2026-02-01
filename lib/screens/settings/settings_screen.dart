import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/subsonic_provider.dart';
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
          
          const SizedBox(height: 8),
          
          // Music Source Section (NEW)
          _SettingsCategoryTile(
            icon: Icons.library_music_outlined,
            title: 'Music Source',
            subtitle: 'TIDAL, Qobuz, or HiFi Server',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MusicSourceSettingsScreen()),
              );
            },
          ),
          
          const SizedBox(height: 8),
          
          // HiFi Server Section
          _SettingsCategoryTile(
            icon: Icons.dns_outlined,
            title: 'HiFi Server',
            subtitle: 'Connect your personal music server',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HiFiServerSettingsScreen()),
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
// HIFI SERVER SETTINGS SCREEN
// ============================================================================

class HiFiServerSettingsScreen extends ConsumerStatefulWidget {
  const HiFiServerSettingsScreen({super.key});

  @override
  ConsumerState<HiFiServerSettingsScreen> createState() => _HiFiServerSettingsScreenState();
}

class _HiFiServerSettingsScreenState extends ConsumerState<HiFiServerSettingsScreen> {
  late TextEditingController _urlController;
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  bool _isTesting = false;
  String? _testResult;

  @override
  void initState() {
    super.initState();
    final config = ref.read(subsonicConfigProvider);
    _urlController = TextEditingController(text: config.serverUrl);
    _usernameController = TextEditingController(text: config.username);
    _passwordController = TextEditingController(text: config.password);
  }

  @override
  void dispose() {
    _urlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _saveAndTest() async {
    setState(() {
      _isTesting = true;
      _testResult = null;
    });

    final notifier = ref.read(subsonicConfigProvider.notifier);
    await notifier.updateConfig(
      serverUrl: _urlController.text,
      username: _usernameController.text,
      password: _passwordController.text,
    );

    final success = await notifier.testConnection();
    
    setState(() {
      _isTesting = false;
      _testResult = success ? 'Connected successfully!' : 'Connection failed. Check your settings.';
    });

    if (success) {
      await notifier.setEnabled(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(subsonicConfigProvider);

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
          'HiFi Server',
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
          
          // Status indicator
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: config.isEnabled && config.isConnected 
                  ? Colors.green.withOpacity(0.2)
                  : AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  config.isEnabled && config.isConnected 
                      ? Icons.check_circle 
                      : Icons.info_outline,
                  color: config.isEnabled && config.isConnected 
                      ? Colors.green 
                      : AppTheme.secondaryColor,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  config.isEnabled && config.isConnected 
                      ? 'Connected to HiFi server'
                      : 'Connect to your Subsonic/HiFi server',
                  style: AppTheme.bodyMedium.copyWith(
                    color: config.isEnabled && config.isConnected 
                        ? Colors.green 
                        : AppTheme.secondaryColor,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Server URL
          _buildTextField(
            label: 'Server URL',
            hint: 'http://192.168.1.100:8080',
            controller: _urlController,
            keyboardType: TextInputType.url,
          ),
          
          const SizedBox(height: 16),
          
          // Username
          _buildTextField(
            label: 'Username',
            hint: 'hifi',
            controller: _usernameController,
          ),
          
          const SizedBox(height: 16),
          
          // Password
          _buildTextField(
            label: 'Password',
            hint: '••••••',
            controller: _passwordController,
            obscureText: true,
          ),
          
          const SizedBox(height: 24),
          
          // Test result
          if (_testResult != null)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: _testResult!.contains('success') 
                    ? Colors.green.withOpacity(0.2)
                    : Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _testResult!,
                style: AppTheme.bodyMedium.copyWith(
                  color: _testResult!.contains('success') 
                      ? Colors.green 
                      : Colors.red,
                ),
              ),
            ),
          
          // Save & Test button
          ElevatedButton(
            onPressed: _isTesting ? null : _saveAndTest,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isTesting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Save & Test Connection'),
          ),
          
          const SizedBox(height: 16),
          
          // Enable/disable toggle
          if (config.hasConfig)
            _SettingsTile(
              title: 'Enable HiFi source',
              subtitle: 'Include HiFi server in search results',
              value: config.isEnabled,
              onChanged: (value) {
                ref.read(subsonicConfigProvider.notifier).setEnabled(value);
              },
            ),
          
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    TextInputType? keyboardType,
    bool obscureText = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.bodyMedium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          style: AppTheme.bodyMedium.copyWith(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTheme.bodyMedium.copyWith(
              color: AppTheme.secondaryColor.withOpacity(0.5),
            ),
            filled: true,
            fillColor: AppTheme.surfaceColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
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

// ============================================================================
// MUSIC SOURCE SETTINGS SCREEN
// ============================================================================

class MusicSourceSettingsScreen extends ConsumerWidget {
  const MusicSourceSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sourceState = ref.watch(sourceSelectionProvider);
    final subsonicConfig = ref.watch(subsonicConfigProvider);

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
          // Info card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: AppTheme.primaryColor, size: 24),
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
          
          // TIDAL Option
          _SourceOptionTile(
            icon: Icons.waves,
            iconColor: Colors.cyan,
            title: 'TIDAL',
            subtitle: 'HiFi streaming with recommendations',
            isSelected: sourceState.activeSource == ActiveSource.tidal,
            onTap: () => ref.read(sourceSelectionProvider.notifier).setActiveSource(ActiveSource.tidal),
          ),
          
          const SizedBox(height: 12),
          
          // Qobuz Option
          _SourceOptionTile(
            icon: Icons.high_quality,
            iconColor: Colors.blue,
            title: 'Qobuz',
            subtitle: '24-bit Hi-Res FLAC streaming',
            isSelected: sourceState.activeSource == ActiveSource.qobuz,
            onTap: () => ref.read(sourceSelectionProvider.notifier).setActiveSource(ActiveSource.qobuz),
          ),
          
          const SizedBox(height: 12),
          
          // HiFi Server Option
          _SourceOptionTile(
            icon: Icons.dns_outlined,
            iconColor: Colors.green,
            title: 'HiFi Server',
            subtitle: subsonicConfig.hasConfig 
                ? 'Connected to ${subsonicConfig.serverUrl}'  
                : 'Not configured - tap to set up',
            isSelected: sourceState.activeSource == ActiveSource.subsonic,
            onTap: () {
              if (subsonicConfig.hasConfig) {
                ref.read(sourceSelectionProvider.notifier).setActiveSource(ActiveSource.subsonic);
              } else {
                // Navigate to HiFi settings if not configured
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HiFiServerSettingsScreen()),
                );
              }
            },
            trailingIcon: !subsonicConfig.hasConfig ? Icons.chevron_right : null,
          ),
          
          const SizedBox(height: 32),
          
          // Current source indicator
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: AppTheme.primaryColor, size: 24),
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
      color: isSelected ? AppTheme.primaryColor.withOpacity(0.15) : AppTheme.surfaceColor,
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
                Icon(Icons.radio_button_off, color: Colors.white.withOpacity(0.3)),
            ],
          ),
        ),
      ),
    );
  }
}
