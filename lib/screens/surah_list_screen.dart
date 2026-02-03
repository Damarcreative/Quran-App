import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/surah.dart';
import '../services/api_service.dart';
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

  void _showDevInfo() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Developer Info',
                    style: GoogleFonts.spaceGrotesk(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildInfoItem('Developer', 'Damar Jati'),
              _buildInfoItem('Email', 'dev@damarcreative.my.id'),
              _buildInfoItem('Portfolio', 'https://damarcreative.my.id/'),
              _buildInfoItem('Website', 'https://quran.damarcreative.my.id/'),
              _buildInfoItem('Repository', 'https://github.com/Damarcreative/QuranAPI.git'),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                    onPressed: () {
                   },
                   icon: const Icon(Icons.bug_report_outlined, color: Color(0xFF0F172A)),
                   label: Text('Report Issue', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                   style: ElevatedButton.styleFrom(
                     backgroundColor: const Color(0xFF40B779),
                     padding: const EdgeInsets.symmetric(vertical: 16),
                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                   ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.spaceGrotesk(color: const Color(0xFF888888), fontSize: 12)),
          const SizedBox(height: 4),
          SelectableText(
            value,
            style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 16),
          ),
        ],
      ),
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
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: _showDevInfo,
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(80.0), // increased for search bar
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: TextField(
                  controller: _searchController,
                  onChanged: _filterSurahs,
                  style: GoogleFonts.spaceGrotesk(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search Surah...',
                    hintStyle: GoogleFonts.spaceGrotesk(color: const Color(0xFF888888)),
                    filled: true,
                    fillColor: Colors.transparent,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
                    enabledBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF2A2A2A), width: 2),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF40B779), width: 2),
                    ),
                    suffixIcon: const Icon(Icons.search, color: Color(0xFF40B779)),
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
