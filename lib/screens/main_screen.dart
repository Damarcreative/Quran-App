import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'surah_list_screen.dart';
import 'prayer_times_screen.dart';
import 'murotal_screen.dart';
import 'settings_screen.dart';
import '../services/audio_service.dart';
import '../widgets/mini_player.dart';
import '../widgets/full_player_view.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  bool _showFullPlayer = false;
  final AudioService _audioService = AudioService();

  final List<Widget> _screens = [
    const SurahListScreen(),
    const PrayerTimesScreen(),
    const MurotalScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _audioService.addListener(_onAudioUpdate);
  }

  @override
  void dispose() {
    _audioService.removeListener(_onAudioUpdate);
    super.dispose();
  }

  void _onAudioUpdate() {
    if (mounted) setState(() {});
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      // Collapse player on tab switch so user can see the new tab content
      _showFullPlayer = false;
    });
  }

  DateTime? _currentBackPressTime;

  Future<bool> _onWillPop() async {
    // 1. If Full Player is showing, close it
    if (_showFullPlayer) {
      setState(() {
        _showFullPlayer = false;
      });
      return false; // Do not exit app
    }

    // 2. Double click to exit to prevent accidental touches
    final now = DateTime.now();
    if (_currentBackPressTime == null || 
        now.difference(_currentBackPressTime!) > const Duration(seconds: 2)) {
      _currentBackPressTime = now;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Double-tap to exit',
            style: GoogleFonts.spaceGrotesk(color: Colors.white),
          ),
          backgroundColor: const Color(0xFF2A2A2A),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
      return false;
    }
    
    return true; // Allow exit
  }

  @override
  Widget build(BuildContext context) {
    final hasAudio = _audioService.currentSurah != null;
    final colorScheme = Theme.of(context).colorScheme;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Stack(
          children: [
            IndexedStack(
              index: _selectedIndex,
              children: _screens,
            ),
            
            // Mini Player
            if (!_showFullPlayer && hasAudio)
              Positioned(
                left: 0, 
                right: 0, 
                bottom: 0,
                child: MiniPlayer(
                  onTap: () => setState(() => _showFullPlayer = true),
                ),
              ),

            // Full Player Lyrics View
            if (_showFullPlayer && hasAudio)
              Positioned.fill(
                child: FullPlayerView(
                  onCollapse: () => setState(() => _showFullPlayer = false),
                ),
              ),
          ],
        ),
        bottomNavigationBar: _showFullPlayer ? null : Container(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: colorScheme.outline)),
          ),
          child: NavigationBarTheme(
            data: NavigationBarThemeData(
              indicatorColor: colorScheme.primary.withOpacity(0.2),
              labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
              height: 48,
              iconTheme: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return IconThemeData(size: 20, color: colorScheme.primary);
                }
                return IconThemeData(size: 20, color: colorScheme.onSurface.withOpacity(0.5));
              }),
            ),
            child: NavigationBar(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              selectedIndex: _selectedIndex,
              onDestinationSelected: _onItemTapped,
              height: 48,
              elevation: 0,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.auto_stories_outlined),
                  selectedIcon: Icon(Icons.auto_stories),
                  label: 'Quran',
                ),
                NavigationDestination(
                  icon: Icon(Icons.mosque_outlined),
                  selectedIcon: Icon(Icons.mosque),
                  label: 'Times',
                ),
                NavigationDestination(
                  icon: Icon(Icons.headphones_outlined),
                  selectedIcon: Icon(Icons.headphones),
                  label: 'Murotal',
                ),
                NavigationDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings),
                  label: 'Settings',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
