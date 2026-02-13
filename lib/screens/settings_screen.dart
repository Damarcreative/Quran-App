import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/settings_service.dart';
import '../services/audio_service.dart';
import 'storage_management_screen.dart';
import 'about_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsService _settings = SettingsService();
  final AudioService _audioService = AudioService();

  Map<String, dynamic> _storageInfo = {};
  bool _isLoadingStorage = true;
  bool _isClearing = false;
  final String _appVersion = "3.0.0";

  @override
  void initState() {
    super.initState();
    _settings.addListener(_onSettingsChanged);
    _audioService.addListener(_onAudioChanged);
    _loadStorageInfo();
  }

  @override
  void dispose() {
    _settings.removeListener(_onSettingsChanged);
    _audioService.removeListener(_onAudioChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    if (mounted) setState(() {});
  }

  void _onAudioChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadStorageInfo() async {
    setState(() => _isLoadingStorage = true);
    final info = await _settings.getStorageInfo();
    if (mounted) {
      setState(() {
        _storageInfo = info;
        _isLoadingStorage = false;
      });
    }
  }

  Future<void> _launchUrl(String urlString) async {
    try {
      final Uri url = Uri.parse(urlString);
      if (!await launchUrl(url)) {
        debugPrint('Could not launch $url');
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
    }
  }

  String _getThemeModeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'System Default';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
    }
  }

  String _formatEditionName(String editionId) {
    final translations = _settings.getAvailableTranslations();
    final translation = translations.firstWhere(
      (t) => t['code'] == editionId,
      orElse: () => {'name': editionId},
    );
    return translation['name']!;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'SETTINGS',
                style: GoogleFonts.spaceGrotesk(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  color: colorScheme.onSurface,
                  letterSpacing: -1,
                ),
              ),
              TextSpan(
                text: '.',
                style: GoogleFonts.spaceGrotesk(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Section: General
          _buildSectionHeader('General'),

          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.zero,
              border: Border.all(color: colorScheme.outline),
            ),
            child: Column(
              children: [
                _buildSettingsTile(
                  title: 'Theme',
                  subtitle: _getThemeModeName(_settings.themeMode),
                  icon: Icons.dark_mode_outlined,
                  onTap: () => _showThemeDialog(context),
                ),
                Divider(height: 1, color: colorScheme.outline),
                _buildSettingsTile(
                  title: 'Default Translation',
                  subtitle: _formatEditionName(_settings.defaultTranslation),
                  icon: Icons.translate,
                  onTap: () => _showTranslationDialog(context),
                ),
                Divider(height: 1, color: colorScheme.outline),
                SwitchListTile(
                  title: Text(
                    'Arabic Numerals',
                    style: GoogleFonts.spaceGrotesk(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    'Use ١٢٣ instead of 123',
                    style: GoogleFonts.spaceGrotesk(
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                  ),
                  secondary: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.numbers,
                      color: colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  value: _settings.useArabicNumerals,
                  onChanged: (bool value) {
                    _settings.setUseArabicNumerals(value);
                  },
                  activeThumbColor: colorScheme.primary,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Section: Storage
          _buildSectionHeader('Storage'),

          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.zero,
              border: Border.all(color: colorScheme.outline),
            ),
            child: Column(
              children: [
                _buildStorageTile(
                  title: 'Clear Cache',
                  subtitle: 'Frees up space by removing temporary files',
                  value: _settings.formatBytes(_storageInfo['cacheSize'] ?? 0),
                  icon: Icons.cleaning_services_outlined,
                  onTap: () => _showClearCacheDialog(context),
                  isLoading: _isLoadingStorage,
                ),
                _buildStorageTile(
                  title: 'Manage Storage',
                  subtitle:
                      '${_settings.formatBytes(_storageInfo['totalSize'] ?? 0)} used',
                  value: '',
                  icon: Icons.storage,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const StorageManagementScreen(),
                      ),
                    ).then(
                      (_) => _loadStorageInfo(),
                    ); // Reload info when returning
                  },
                  isLoading: _isLoadingStorage,
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // About Section
          _buildSectionHeader('About'),

          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.zero,
              border: Border.all(color: colorScheme.outline),
            ),
            child: _buildSettingsTile(
              title: 'About Developer',
              subtitle: 'v$_appVersion',
              icon: Icons.info_outline,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AboutScreen()),
                );
              },
            ),
          ),

          const SizedBox(height: 48),

          Center(
            child: Column(
              children: [
                Text(
                  'Built with ❤️ for the Ummah',
                  style: GoogleFonts.spaceGrotesk(
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Read. Reflect. Act.',
                  style: GoogleFonts.spaceGrotesk(
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '© ${DateTime.now().year} DamarCreative. Open Source.',
                  style: GoogleFonts.spaceGrotesk(
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),

          if (_audioService.currentSurah != null) const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.spaceGrotesk(
          color: Theme.of(context).colorScheme.primary,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required String title,
    String? subtitle,
    required IconData icon,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: colorScheme.primary, size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.spaceGrotesk(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: GoogleFonts.spaceGrotesk(
                color: colorScheme.onSurface.withValues(alpha: 0.5),
                fontSize: 12,
              ),
            )
          : null,
      trailing:
          trailing ??
          Icon(
            Icons.chevron_right,
            color: colorScheme.onSurface.withValues(alpha: 0.5),
          ),
    );
  }

  Widget _buildStorageTile({
    required String title,
    required String subtitle,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
    bool isLoading = false,
    bool showArrow = true,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: colorScheme.primary, size: 20),
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.spaceGrotesk(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (isLoading)
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colorScheme.primary,
              ),
            )
          else
            Text(
              value,
              style: GoogleFonts.spaceGrotesk(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.spaceGrotesk(
          color: colorScheme.onSurface.withValues(alpha: 0.5),
          fontSize: 12,
        ),
      ),
      trailing: showArrow
          ? Icon(
              Icons.chevron_right,
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            )
          : null,
    );
  }

  void _showThemeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: colorScheme.outline),
          ),
          title: Text(
            'Select Theme',
            style: GoogleFonts.spaceGrotesk(color: colorScheme.onSurface),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildThemeOption(context, 'System Default', ThemeMode.system),
              _buildThemeOption(context, 'Light', ThemeMode.light),
              _buildThemeOption(context, 'Dark', ThemeMode.dark),
            ],
          ),
        );
      },
    );
  }

  Widget _buildThemeOption(BuildContext context, String title, ThemeMode mode) {
    final colorScheme = Theme.of(context).colorScheme;

    return RadioListTile<ThemeMode>(
      title: Text(
        title,
        style: GoogleFonts.spaceGrotesk(color: colorScheme.onSurface),
      ),
      value: mode,
      groupValue: _settings.themeMode,
      onChanged: (val) {
        if (val != null) {
          _settings.setThemeMode(val);
          Navigator.pop(context);
        }
      },
      activeColor: colorScheme.primary,
    );
  }

  void _showTranslationDialog(BuildContext context) {
    final translations = _settings.getAvailableTranslations();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor:
          Colors.transparent, // Transparent to show rounded corners of child
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: colorScheme.outline,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  // Title
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'Select Translation',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // List
                  Expanded(
                    child: ListView.separated(
                      controller: scrollController,
                      itemCount: translations.length,
                      separatorBuilder: (context, index) => Divider(
                        height: 1,
                        color: colorScheme.outline.withValues(alpha: 0.5),
                      ),
                      itemBuilder: (context, index) {
                        final t = translations[index];
                        return RadioListTile<String>(
                          value: t['code']!,
                          groupValue: _settings.defaultTranslation,
                          onChanged: (value) {
                            if (value != null) {
                              _settings.setDefaultTranslation(value);
                              Navigator.pop(context);
                            }
                          },
                          title: Text(
                            t['name']!,
                            style: GoogleFonts.spaceGrotesk(
                              color: colorScheme.onSurface,
                            ),
                          ),
                          activeColor: colorScheme.primary,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 24,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showClearCacheDialog(BuildContext context) async {
    final colorScheme = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colorScheme.outline),
        ),
        title: Text(
          'Clear All Cache?',
          style: GoogleFonts.spaceGrotesk(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'This will delete all downloaded data including Quran text, translations, prayer times, and audio files. You will need to re-download them.',
          style: GoogleFonts.spaceGrotesk(
            color: colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.spaceGrotesk(
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700]),
            child: Text(
              'Clear All',
              style: GoogleFonts.spaceGrotesk(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (!mounted) return;
      setState(() => _isClearing = true);
      await _settings.clearAllCache();
      await _loadStorageInfo();
      setState(() => _isClearing = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Cache cleared successfully',
              style: GoogleFonts.spaceGrotesk(),
            ),
            backgroundColor: colorScheme.primary,
          ),
        );
      }
    }
  }
}
