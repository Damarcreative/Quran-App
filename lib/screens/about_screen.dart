import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/audio_service.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  final AudioService _audioService = AudioService();
  final String _appVersion = "3.0.0"; // Hardcoded version

  @override
  void initState() {
    super.initState();
    _audioService.addListener(_onAudioChanged);
  }

  @override
  void dispose() {
    _audioService.removeListener(_onAudioChanged);
    super.dispose();
  }

  void _onAudioChanged() {
    if (mounted) setState(() {});
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
                text: 'ABOUT',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.transparent, // Hidden line since it's a full screen now
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'About Developer',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 24),
            _buildAboutInfoItem(context, 'Developer', 'Damar Jati', Icons.person_outline),
            _buildAboutInfoItem(context, 'App Version', 'v$_appVersion', Icons.info_outline),
            _buildAboutInfoItem(context, 'Email', 'dev@damarcreative.my.id', Icons.email_outlined,
                isLink: true, linkPrefix: 'mailto:'),
            _buildAboutInfoItem(context, 'Portfolio', 'https://damarcreative.my.id/', Icons.language, isLink: true),
            _buildAboutInfoItem(context, 'Website', 'https://quran.damarcreative.my.id/', Icons.public, isLink: true),
            _buildAboutInfoItem(context, 'Repository', 'https://github.com/Damarcreative/QuranAPI.git', Icons.code, isLink: true),

            const SizedBox(height: 24),
            Text(
              'Attribution',
              style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
            ),
            const SizedBox(height: 12),
            _buildAboutInfoItem(context, 'Prayer Times Source', 'Equran.id', Icons.api,
                isLink: true, linkPrefix: 'https://', valueOverride: 'https://equran.id/'),

            const SizedBox(height: 24),
            Text(
              'Support',
              style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _launchUrl('https://damarcreative.my.id/found.html'),
                icon: const Icon(Icons.favorite, color: Colors.black),
                label: Text('Donate to Developer',
                    style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, color: Colors.black)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _launchUrl('mailto:dev@damarcreative.my.id?subject=Quran App Issue Report'),
                icon: Icon(Icons.bug_report_outlined, color: colorScheme.onSurface),
                label: Text('Report Issue',
                    style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: colorScheme.outline),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Miniplayer Padding
            if (_audioService.currentSurah != null)
              const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutInfoItem(BuildContext context, String label, String value, IconData icon,
      {bool isLink = false, String linkPrefix = '', String? valueOverride}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: isLink ? () => _launchUrl(valueOverride ?? (linkPrefix + value)) : null,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: isLink ? colorScheme.primary : colorScheme.onSurface, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: GoogleFonts.spaceGrotesk(color: colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 12)),
                      const SizedBox(height: 2),
                      Text(
                        value,
                        style: GoogleFonts.spaceGrotesk(
                          color: isLink ? colorScheme.primary : colorScheme.onSurface,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          decoration: isLink ? TextDecoration.underline : TextDecoration.none,
                          decorationColor: colorScheme.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (isLink)
                  Icon(Icons.arrow_outward, color: colorScheme.primary, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
