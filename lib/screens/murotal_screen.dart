import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/surah.dart';
import '../services/api_service.dart';
import '../services/audio_service.dart';
import '../services/murotal_download_service.dart';
import '../services/settings_service.dart';
import 'murotal_download_screen.dart';

class MurotalScreen extends StatefulWidget {
  const MurotalScreen({super.key});

  @override
  State<MurotalScreen> createState() => _MurotalScreenState();
}

class _MurotalScreenState extends State<MurotalScreen> {
  final AudioService _audioService = AudioService();
  final MurotalDownloadService _downloadService = MurotalDownloadService();
  final SettingsService _settings = SettingsService();

  late Future<List<Surah>> _surahListFuture;
  List<Surah> _allSurahs = [];
  List<Surah> _filteredSurahs = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _settings.addListener(_onSettingsUpdate);
    _audioService.addListener(_onAudioUpdate);
    _downloadService.addListener(_onDownloadUpdate);
    _downloadService.init();
    _downloadService.scanDownloadedFiles();
    _surahListFuture = ApiService().fetchSurahs().then((surahs) {
      if (mounted) {
        setState(() {
          _allSurahs = surahs;
          _filteredSurahs = surahs;
        });
      }
      return surahs;
    });
  }

  @override
  void dispose() {
    _settings.removeListener(_onSettingsUpdate);
    _audioService.removeListener(_onAudioUpdate);
    _downloadService.removeListener(_onDownloadUpdate);
    _searchController.dispose();
    super.dispose();
  }

  void _onSettingsUpdate() {
    if (mounted) setState(() {});
  }

  void _onAudioUpdate() {
    if (mounted) setState(() {});
  }

  void _onDownloadUpdate() {
    if (mounted) setState(() {});
  }

  void _filterSurahs(String query) {
    setState(() {
      final normalizedQuery = query.trim().toLowerCase();

      if (normalizedQuery == 'offline') {
        // Offline Mode: Show only downloaded surahs
        _filteredSurahs = _allSurahs.where((surah) {
          return _downloadService.isSurahDownloaded(surah.number);
        }).toList();

        // Set custom sequence for playback
        final sequence = _filteredSurahs.map((s) => s.number).toList();
        _audioService.setCustomSurahSequence(sequence);
      } else {
        // Normal Mode
        _audioService.clearCustomSurahSequence();

        if (query.isEmpty) {
          _filteredSurahs = _allSurahs;
        } else {
          _filteredSurahs = _allSurahs.where((surah) {
            return surah.name.toLowerCase().contains(normalizedQuery) ||
                surah.number.toString().contains(query);
          }).toList();
        }
      }
    });
  }

  void _showHelpDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Murotal Guide',
                    style: GoogleFonts.spaceGrotesk(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    _buildHelpSection(
                      icon: Icons.cloud_download,
                      title: 'Download & Offline',
                      description:
                          'Tap the download icon to download. Surahs with a checkmark (✓) are available offline.',
                    ),
                    const SizedBox(height: 16),
                    _buildHelpSection(
                      icon: Icons.search,
                      title: 'Offline Search Mode',
                      description:
                          'Type "offline" in the search bar to filter ONLY downloaded Surahs. The playlist will automatically cycle through this list only.',
                    ),
                    const SizedBox(height: 16),
                    _buildHelpSection(
                      icon: Icons.playlist_play,
                      title: 'Player Navigation',
                      description:
                          'The Next/Previous buttons follow the list currently displayed on the screen. If in "offline" search mode, only offline Surahs will be played sequentially.',
                    ),
                    const SizedBox(height: 64),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Got it',
                          style: GoogleFonts.spaceGrotesk(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHelpSection({
    required IconData icon,
    required String title,
    required String description,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: colorScheme.primary, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.spaceGrotesk(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(description, style: GoogleFonts.spaceGrotesk(fontSize: 12)),
            ],
          ),
        ),
      ],
    );
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
                text: 'MUROTAL',
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
        centerTitle: false,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        scrolledUnderElevation: 0,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showHelpDialog,
            tooltip: 'Guide',
            color: colorScheme.primary,
          ),
          IconButton(
            icon: Icon(Icons.download_outlined, color: colorScheme.primary),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => DraggableScrollableSheet(
                  initialChildSize: 0.7,
                  minChildSize: 0.5,
                  maxChildSize: 0.9,
                  builder: (context, scrollController) =>
                      MurotalDownloadScreen(scrollController: scrollController),
                ),
              );
            },
            tooltip: 'Download Manager',
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
            child: TextField(
              controller: _searchController,
              onChanged: _filterSurahs,
              style: GoogleFonts.spaceGrotesk(
                color: colorScheme.onSurface,
                height: 1.5,
              ),
              decoration: InputDecoration(
                hintText: 'Search Surah to listen...',
                hintStyle: GoogleFonts.spaceGrotesk(
                  color: colorScheme.onSurface.withOpacity(0.5),
                ),
                isDense: true,
                filled: true,
                fillColor: Colors.transparent,
                contentPadding: const EdgeInsets.only(bottom: 4, top: 12),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: colorScheme.outline, width: 2),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: colorScheme.primary, width: 2),
                ),
                suffixIcon: Icon(
                  Icons.search,
                  color: colorScheme.primary,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<List<Surah>>(
              future: _surahListFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    _allSurahs.isEmpty) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: colorScheme.primary,
                    ),
                  );
                } else if (_filteredSurahs.isEmpty) {
                  return Center(
                    child: Text(
                      "No Surahs found",
                      style: TextStyle(
                        color: colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    24,
                    16,
                    24,
                    100,
                  ), // Keep padding for global player
                  itemCount: _filteredSurahs.length,
                  itemBuilder: (context, index) {
                    return _buildSurahItem(_filteredSurahs[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSurahItem(Surah surah) {
    final colorScheme = Theme.of(context).colorScheme;
    final isPlayingThisSurah =
        _audioService.currentSurah?.number == surah.number;
    final isDownloaded = _downloadService.isSurahDownloaded(surah.number);

    // Format numerals
    final formattedNumber = _settings.formatNumber(surah.number);
    final formattedAyahCount = _settings.formatNumber(surah.totalAyahs);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(
          color: isPlayingThisSurah ? colorScheme.primary : colorScheme.outline,
        ),
        color: isPlayingThisSurah
            ? colorScheme.primary.withOpacity(0.05)
            : Colors.transparent,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isPlayingThisSurah
                ? colorScheme.primary
                : Theme.of(context).cardColor,
            shape: BoxShape.circle,
            border: Border.all(color: colorScheme.outline),
          ),
          child: Text(
            formattedNumber,
            style: GoogleFonts.spaceGrotesk(
              color: isPlayingThisSurah ? Colors.black : colorScheme.primary,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                surah.name,
                style: GoogleFonts.spaceGrotesk(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isDownloaded) ...[
              const SizedBox(width: 8),
              Icon(Icons.check_circle, size: 16, color: colorScheme.primary),
            ],
          ],
        ),
        subtitle: Text(
          '$formattedAyahCount Ayahs${isDownloaded ? ' • Offline' : ''}',
          style: GoogleFonts.spaceGrotesk(
            color: colorScheme.onSurface.withOpacity(0.5),
            fontSize: 12,
          ),
        ),
        trailing: IconButton(
          icon: Icon(
            isPlayingThisSurah && _audioService.isPlaying
                ? Icons.pause_circle_filled
                : Icons.play_circle_fill,
            color: colorScheme.primary,
            size: 32,
          ),
          onPressed: () {
            if (isPlayingThisSurah) {
              if (_audioService.isPlaying) {
                _audioService.pause();
              } else {
                _audioService.resume();
              }
            } else {
              _audioService.playAyah(surah, 1);
            }
          },
        ),
        onTap: () {
          // Open Detail to select Ayah
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            useRootNavigator: true,
            backgroundColor: Theme.of(context).cardColor,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            builder: (context) => _buildAyahSelector(surah),
          );
        },
      ),
    );
  }

  Widget _buildAyahSelector(Surah surah) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Select Ayah - ${surah.name}',
                style: GoogleFonts.spaceGrotesk(
                  color: colorScheme.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(
                  Icons.close,
                  color: colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: surah.totalAyahs,
              itemBuilder: (context, index) {
                final ayahNum = index + 1;
                final isCurrent =
                    _audioService.currentSurah?.number == surah.number &&
                    _audioService.currentAyah == ayahNum;
                return InkWell(
                  onTap: () {
                    _audioService.playAyah(surah, ayahNum);
                    Navigator.pop(context);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? colorScheme.primary
                          : Theme.of(context).cardColor,
                      border: Border.all(color: colorScheme.outline),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _settings.formatNumber(ayahNum),
                      style: GoogleFonts.spaceGrotesk(
                        color: isCurrent ? Colors.black : colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
