import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/surah.dart';
import '../services/api_service.dart';
import '../services/download_service.dart';
import 'surah_detail_screen.dart';

class SurahListScreen extends StatefulWidget {
  const SurahListScreen({super.key});

  @override
  State<SurahListScreen> createState() => _SurahListScreenState();
}

class _SurahListScreenState extends State<SurahListScreen> {
  late Future<List<Surah>> _surahListFuture;
  List<Surah> _allSurahs = [];
  List<Surah> _filteredSurahs = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize Download Service
    DownloadService().init();
    
    _surahListFuture = ApiService().fetchSurahs().then((surahs) {
      setState(() {
        _allSurahs = surahs;
        _filteredSurahs = surahs;
      });
      return surahs;
    });
  }

  void _filterSurahs(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredSurahs = _allSurahs;
      } else {
        _filteredSurahs = _allSurahs.where((surah) {
          return surah.name.toLowerCase().contains(query.toLowerCase()) ||
              surah.number.toString().contains(query);
        }).toList();
      }
    });
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

  void _showDevInfo() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0A0A0A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(0)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Developer Info',
                    style: GoogleFonts.spaceGrotesk(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildInfoItem('Developer', 'Damar Jati', Icons.person_outline),
              _buildInfoItem('App Version', '1.0.0', Icons.info_outline),
              _buildInfoItem('Email', 'dev@damarcreative.my.id', Icons.email_outlined, isLink: true, linkPrefix: 'mailto:'),
              _buildInfoItem('Portfolio', 'https://damarcreative.my.id/', Icons.language, isLink: true),
              _buildInfoItem('Website', 'https://quran.damarcreative.my.id/', Icons.public, isLink: true),
              _buildInfoItem('Repository', 'https://github.com/Damarcreative/QuranAPI.git', Icons.code, isLink: true),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                    onPressed: () {
                      _launchUrl('mailto:dev@damarcreative.my.id?subject=Quran App Issue Report');
                   },
                   icon: const Icon(Icons.bug_report_outlined, color: Color(0xFF0A0A0A)),
                   label: Text('Report Issue', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, color: const Color(0xFF0A0A0A))),
                   style: ElevatedButton.styleFrom(
                     backgroundColor: const Color(0xFF40B779),
                     padding: const EdgeInsets.symmetric(vertical: 16),
                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)), // Sharp button
                   ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon, {bool isLink = false, String linkPrefix = ''}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.transparent, 
        border: Border.all(color: const Color(0xFF2A2A2A)),
        borderRadius: BorderRadius.circular(0),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLink ? () => _launchUrl(linkPrefix + value) : null,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A0A0A),
                    borderRadius: BorderRadius.circular(0),
                    border: Border.all(color: const Color(0xFF2A2A2A)),
                  ),
                  child: Icon(icon, color: isLink ? const Color(0xFF40B779) : Colors.white, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: GoogleFonts.spaceGrotesk(color: const Color(0xFF888888), fontSize: 12)),
                      const SizedBox(height: 2),
                      Text(
                        value,
                        style: GoogleFonts.spaceGrotesk(
                          color: isLink ? const Color(0xFF40B779) : Colors.white, 
                          fontSize: 14, 
                          fontWeight: FontWeight.w500,
                          decoration: isLink ? TextDecoration.underline : TextDecoration.none,
                          decorationColor: const Color(0xFF40B779),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                 if (isLink)
                  const Icon(Icons.arrow_outward, color: Color(0xFF40B779), size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }



  void _showDownloadManager() async {
    // Load editions
    List<String> availableEditions = [];
    try {
      final String jsonString = await DefaultAssetBundle.of(context).loadString('assets/editions.json');
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      availableEditions = List<String>.from(jsonMap['editions']);
    } catch (e) {
      debugPrint('Error loading editions: $e');
      availableEditions = ['id-indonesian', 'en-sahih', 'ar-jalalayn']; // Fallback
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0A0A0A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(0)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            // State local to modal
            List<String> downloadQueue = ['arabic', 'id-indonesian', 'en-sahih']; // Defaults
            // Note: we need to handle state preservation if we want it to persist across re-opens, 
            // but for now per-session queue is fine or we'd need to lift state up.
            // Let's use a local variable for the initial build, but we need it to be persistent *during* the modal life.
            // Actually, StatefulBuilder restarts state if rebuilt? No, it maintains state for the builder.
            // We need to initialize the queue outside the builder if we want it to persist? 
            // Wait, StatefulBuilder doesn't hold state itself, it allows calling setState.
            // The list needs to be defined *outside* the builder but inside the function scope?
            // No, if it's inside _showDownloadManager, it resets every time content opens. That's expected.
            // BUT inside StatefulBuilder, we can't initialize it effectively.
            // Let's create a separate Widget for the content to handle state cleanly.
            return _DownloadManagerContent(availableEditions: availableEditions);
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
             RichText(
               text: TextSpan(
                 children: [
                   TextSpan(
                     text: 'QURAN',
                     style: GoogleFonts.spaceGrotesk(
                       fontWeight: FontWeight.bold,
                       fontSize: 24,
                       color: Colors.white,
                       letterSpacing: -1,
                     ),
                   ),
                   TextSpan(
                     text: '.',
                     style: GoogleFonts.spaceGrotesk(
                       fontWeight: FontWeight.bold,
                       fontSize: 24,
                       color: const Color(0xFF40B779),
                     ),
                   ),
                 ],
               ),
             ),
          ],
        ),
        centerTitle: false,
        backgroundColor: const Color(0xFF0A0A0A),
        scrolledUnderElevation: 0,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.download_outlined, color: Colors.white),
            onPressed: _showDownloadManager,
          ),
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: _showDevInfo,
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70.0), // Reduced height
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: TextField(
                  controller: _searchController,
                  onChanged: _filterSurahs,
                  style: GoogleFonts.spaceGrotesk(color: Colors.white, height: 1.5), // Added height for better alignment
                  decoration: InputDecoration(
                    hintText: 'Search Surah...',
                    hintStyle: GoogleFonts.spaceGrotesk(color: const Color(0xFF888888)),
                    isDense: true, // Make it compact
                    filled: true,
                    fillColor: Colors.transparent,
                    contentPadding: const EdgeInsets.only(bottom: 4, top: 12), // Push text to bottom
                    enabledBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF2A2A2A), width: 2),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF40B779), width: 2),
                    ),
                    suffixIcon: const Icon(Icons.search, color: Color(0xFF40B779), size: 20),
                    suffixIconConstraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                  ),
                ),
              ),
              Container(
                color: const Color(0xFF2A2A2A), // --border-color
                height: 1.0,
              ),
            ],
          ),
        ),
      ),
      body: FutureBuilder<List<Surah>>(
        future: _surahListFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && _allSurahs.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF40B779)));
          } else if (snapshot.hasError) {
            return Center(child: Text('Failed to load data', style: TextStyle(color: Colors.red)));
          } else if (_filteredSurahs.isEmpty && _allSurahs.isNotEmpty) {
             return Center(child: Text("No Surahs found matching '${_searchController.text}'", style: TextStyle(color: Colors.white70)));
          } else if (_allSurahs.isEmpty) {
             // Still loading or empty
             if (snapshot.connectionState == ConnectionState.done) {
               return const Center(child: Text("No Surahs found"));
             }
             return const SizedBox.shrink(); // Loading handled above
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              int crossAxisCount = 1;
              if (constraints.maxWidth > 1024) {
                 crossAxisCount = 3;
              } else if (constraints.maxWidth > 768) {
                 crossAxisCount = 2;
              }

              return RefreshIndicator(
                color: const Color(0xFF40B779),
                backgroundColor: const Color(0xFF1E293B),
                onRefresh: () async {
                  try {
                    final surahs = await ApiService().fetchSurahs(forceRefresh: true);
                    setState(() {
                      _allSurahs = surahs;
                      _filteredSurahs = surahs;
                      _searchController.clear();
                    });
                  } catch (e) {
                     ScaffoldMessenger.of(context).showSnackBar(
                       SnackBar(content: Text('Failed to refresh: $e')),
                     );
                  }
                },
                child: _filteredSurahs.isEmpty 
                  ? SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: SizedBox(
                        height: constraints.maxHeight,
                        child: const Center(child: Text("No Surahs found. Pull to refresh.", style: TextStyle(color: Colors.white70))),
                      ),
                    )
                  : crossAxisCount == 1 
                      ? ListView.builder(
                          padding: const EdgeInsets.all(24),
                          itemCount: _filteredSurahs.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _buildSurahCard(_filteredSurahs[index]),
                            );
                          },
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(24),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 24,
                            mainAxisSpacing: 24,
                            childAspectRatio: 2.2, // Shorter cards for grid
                          ),
                          itemCount: _filteredSurahs.length,
                          itemBuilder: (context, index) {
                            return _buildSurahCard(_filteredSurahs[index]);
                          },
                        ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSurahCard(Surah surah) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(color: const Color(0xFF2A2A2A)),
        borderRadius: BorderRadius.circular(0),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          hoverColor: Colors.transparent,
          highlightColor: const Color(0xFF40B779).withOpacity(0.05),
          splashColor: const Color(0xFF40B779).withOpacity(0.1),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SurahDetailScreen(surah: surah),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${surah.number}',
                          style: GoogleFonts.spaceGrotesk(
                            color: const Color(0xFF40B779),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${surah.totalAyahs} Ayahs',
                          style: GoogleFonts.spaceGrotesk(
                            color: const Color(0xFF888888),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(color: const Color(0xFF2A2A2A)),
                      ),
                      child: Text(
                        surah.type,
                        style: GoogleFonts.spaceGrotesk(
                          color: const Color(0xFF888888),
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text(
                        surah.name,
                        style: GoogleFonts.spaceGrotesk(
                          color: Colors.white,
                          fontSize: 18, // Slightly smaller to fit single line better
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      surah.nameAr,
                      style: GoogleFonts.amiri(
                        color: const Color(0xFF888888),
                        fontSize: 20, // Slightly larger for Arabic legibility
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DownloadManagerContent extends StatefulWidget {
  final List<String> availableEditions;

  const _DownloadManagerContent({required this.availableEditions});

  @override
  State<_DownloadManagerContent> createState() => _DownloadManagerContentState();
}

class _DownloadManagerContentState extends State<_DownloadManagerContent> {
  final _service = DownloadService();
  String? selectedEditionToAdd;

  @override
  void initState() {
    super.initState();
    // Ensure service is listening to updates
    _service.addListener(_onServiceUpdate);
    
    // Check Notification Permission
    Permission.notification.request();
  }

  @override
  void dispose() {
    _service.removeListener(_onServiceUpdate);
    super.dispose();
  }

  void _onServiceUpdate() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Download Manager',
                  style: GoogleFonts.spaceGrotesk(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                if (_service.status != DownloadStatus.idle)
                   Container(
                     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                     decoration: BoxDecoration(
                       color: const Color(0xFF40B779).withOpacity(0.2),
                       borderRadius: BorderRadius.circular(0), // Sharp
                       border: Border.all(color: const Color(0xFF40B779)),
                     ),
                     child: Text(
                       _service.status == DownloadStatus.paused ? 'PAUSED' : 'DOWNLOADING',
                       style: GoogleFonts.spaceGrotesk(color: const Color(0xFF40B779), fontSize: 10, fontWeight: FontWeight.bold),
                     ),
                   ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Managing resources for offline access.',
              style: GoogleFonts.spaceGrotesk(color: const Color(0xFF888888), fontSize: 14),
            ),
            const SizedBox(height: 24),

            // Add Edition Dropdown
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF2A2A2A)),
                borderRadius: BorderRadius.circular(0),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedEditionToAdd,
                  hint: Text('Select edition to add', style: GoogleFonts.spaceGrotesk(color: const Color(0xFF555555))),
                  dropdownColor: const Color(0xFF0A0A0A),
                  isExpanded: true,
                  items: widget.availableEditions
                      .where((e) => !_service.queue.contains(e) && !_service.downloadedEditions.contains(e))
                      .map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value, style: GoogleFonts.spaceGrotesk(color: Colors.white)),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    if (newValue != null) {
                      setState(() {
                        _service.addToQueue(newValue);
                        selectedEditionToAdd = null; 
                      });
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Controls & Progress
            if (_service.status != DownloadStatus.idle || _service.queue.isNotEmpty) ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _service.status == DownloadStatus.downloading 
                          ? _service.pauseDownload 
                          : _service.startDownload,
                      icon: Icon(
                        _service.status == DownloadStatus.downloading ? Icons.pause : Icons.play_arrow, 
                        color: Colors.black
                      ),
                      label: Text(
                        _service.status == DownloadStatus.downloading ? 'Pause' : 'Resume', 
                        style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, color: Colors.black)
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF40B779),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (_service.status != DownloadStatus.idle)
                    IconButton(
                      onPressed: _service.stopDownload,
                      icon: const Icon(Icons.stop, color: Colors.redAccent),
                      style: IconButton.styleFrom(
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                        side: const BorderSide(color: Color(0xFF2A2A2A)),
                      ),
                    ),
                ],
              ),
              if (_service.status != DownloadStatus.idle) ...[
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: _service.progress,
                  backgroundColor: const Color(0xFF2A2A2A),
                  color: const Color(0xFF40B779),
                ),
                const SizedBox(height: 8),
                Text(
                  'Downloading ${_service.currentEdition}: Surah ${_service.currentSurah} of 114',
                  style: GoogleFonts.spaceGrotesk(color: const Color(0xFF888888), fontSize: 12),
                ),
              ],
              const SizedBox(height: 24),
            ],

            // Queue List (Flexible for scrolling if many items)
            if (_service.queue.isNotEmpty) ...[
               Text('Queue:', style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.bold)),
               const SizedBox(height: 12),
               ConstrainedBox(
                 constraints: const BoxConstraints(maxHeight: 200),
                 child: ListView.builder(
                   shrinkWrap: true,
                   physics: const NeverScrollableScrollPhysics(),
                   itemCount: _service.queue.length,
                   itemBuilder: (context, index) {
                     final edition = _service.queue[index];
                     return Container(
                       margin: const EdgeInsets.only(bottom: 8),
                       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                       width: double.infinity,
                       decoration: BoxDecoration(
                         border: Border.all(color: const Color(0xFF2A2A2A)),
                         borderRadius: BorderRadius.circular(0),
                       ),
                       child: Row(
                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                         children: [
                           Text(edition, style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 14)),
                           IconButton(
                             icon: const Icon(Icons.close, size: 18, color: Color(0xFF888888)),
                             padding: EdgeInsets.zero,
                             constraints: const BoxConstraints(),
                             onPressed: () => _service.removeFromQueue(edition),
                           ),
                         ],
                       ),
                     );
                   },
                 ),
               ),
               const SizedBox(height: 24),
            ],
            
            if (_service.downloadedEditions.isNotEmpty) ...[
               Container(height: 1, color: const Color(0xFF2A2A2A)),
               const SizedBox(height: 24),
               Text('Downloaded:', style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.bold)),
               const SizedBox(height: 12),
               ConstrainedBox(
                 constraints: const BoxConstraints(maxHeight: 200),
                 child: ListView.builder(
                   shrinkWrap: true,
                   physics: const NeverScrollableScrollPhysics(),
                   itemCount: _service.downloadedEditions.length,
                   itemBuilder: (context, index) {
                     final edition = _service.downloadedEditions[index];
                     return Container(
                       margin: const EdgeInsets.only(bottom: 8),
                       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                       width: double.infinity,
                       decoration: BoxDecoration(
                         color: const Color(0xFF111111),
                         border: Border.all(color: const Color(0xFF2A2A2A)),
                         borderRadius: BorderRadius.circular(0),
                       ),
                       child: Row(
                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                         children: [
                           Text(edition, style: GoogleFonts.spaceGrotesk(color: const Color(0xFF888888), fontSize: 14)),
                           const Icon(Icons.check_circle_outline, color: Color(0xFF40B779), size: 18),
                         ],
                       ),
                     );
                   },
                 ),
               ),
            ],
          ],
        ),
      )
    );
  }
}
