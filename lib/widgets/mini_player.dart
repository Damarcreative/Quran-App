import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';

class MiniPlayer extends StatefulWidget {
  final VoidCallback onTap;

  const MiniPlayer({super.key, required this.onTap});

  @override
  State<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<MiniPlayer> {
  final AudioService _audioService = AudioService();
  final SettingsService _settings = SettingsService();

  @override
  void initState() {
    super.initState();
    _audioService.addListener(_update);
    _settings.addListener(_update);
  }

  @override
  void dispose() {
    _audioService.removeListener(_update);
    _settings.removeListener(_update);
    super.dispose();
  }

  void _update() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_audioService.currentSurah == null) return const SizedBox.shrink();

    final surah = _audioService.currentSurah!;
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        color: Theme.of(context).cardColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        surah.name,
                        style: GoogleFonts.spaceGrotesk(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Ayah ${_settings.formatNumber(_audioService.currentAyah)}',
                        style: GoogleFonts.spaceGrotesk(
                          color: colorScheme.primary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.skip_previous,
                        color: colorScheme.onSurface,
                      ),
                      onPressed: _audioService.hasPrevSurah()
                          ? _audioService.playPrevSurah
                          : null,
                    ),
                    IconButton(
                      icon: Icon(
                        _audioService.isPlaying
                            ? Icons.pause_circle_filled
                            : Icons.play_circle_fill,
                        size: 40,
                        color: colorScheme.primary,
                      ),
                      onPressed: () {
                        if (_audioService.isPlaying) {
                          _audioService.pause();
                        } else {
                          _audioService.resume();
                        }
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.skip_next, color: colorScheme.onSurface),
                      onPressed: _audioService.hasNextSurah()
                          ? _audioService.playNextSurah
                          : null,
                    ),
                  ],
                ),
              ],
            ),
            if (_audioService.isBuffering)
              LinearProgressIndicator(
                color: colorScheme.primary,
                backgroundColor: colorScheme.surfaceContainerHighest,
                minHeight: 2,
              ),
          ],
        ),
      ),
    );
  }
}
