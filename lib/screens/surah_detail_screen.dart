import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../models/surah.dart';
import '../models/ayah.dart';
import '../models/ayah.dart';
import '../services/api_service.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class SurahDetailScreen extends StatefulWidget {
  final Surah surah;

  const SurahDetailScreen({super.key, required this.surah});

  @override
  State<SurahDetailScreen> createState() => _SurahDetailScreenState();
}

class _SurahDetailScreenState extends State<SurahDetailScreen> {
  late Future<List<Ayah>> _ayahsFuture;
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener = ItemPositionsListener.create();
  final TextEditingController _ayahInputController = TextEditingController();

  // Settings State
  bool _showArabic = true;
  bool _showTranslation = true;
  String _currentEdition = 'id-indonesian';
  List<String> _availableEditions = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
    _loadEditions();
  }

  Future<void> _loadEditions() async {
    try {
      final jsonString = await rootBundle.loadString('assets/editions.json');
      final Map<String, dynamic> data = json.decode(jsonString);
      final List<dynamic> editionsRaw = data['editions'];
      List<String> allEditions = editionsRaw.cast<String>();

      allEditions.removeWhere((element) => element == 'arabic');

      List<String> pinned = ['id-indonesian', 'en-sahih'];
      
      allEditions.removeWhere((element) => pinned.contains(element));
      
      setState(() {
        _availableEditions = [...pinned, ...allEditions];
      });
      
    } catch (e) {
      debugPrint('Error loading editions: $e');
      // Fallback
      setState(() {
        _availableEditions = ['id-indonesian', 'en-sahih'];
      });
    }
  }

  String _formatEditionName(String editionId) {
    if (editionId == 'id-indonesian') return 'Indonesian Translation';
    if (editionId == 'en-sahih') return 'English (Sahih International)';
    
    return editionId.split('-').map((word) => word[0].toUpperCase() + word.substring(1)).join(' ');
  }

  void _fetchData() {
    _ayahsFuture = ApiService().fetchSurahDetails(widget.surah.number, edition: _currentEdition).then((ayahs) {
      if (widget.surah.number != 1 && widget.surah.number != 9) {
        final int basmalahIndex = ayahs.indexWhere((a) => a.number == 0);
        const String basmalahArabic = 'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ';
        const String basmalahTranslation = 'Dengan menyebut nama Allah Yang Maha Pengasih lagi Maha Penyayang';

        if (basmalahIndex != -1) {
          final existing = ayahs[basmalahIndex];
          ayahs[basmalahIndex] = Ayah(
            number: 0,
            arabic: basmalahArabic, // Force the Arabic text
            translation: existing.translation.isNotEmpty ? existing.translation : basmalahTranslation,
          );
        } else {
          ayahs.insert(0, Ayah(
            number: 0,
            arabic: basmalahArabic,
            translation: basmalahTranslation,
          ));
        }
      }
      return ayahs;
    });
  }

  void _jumpToAyah(String value, BuildContext modalContext) {
    if (value.isEmpty) return;
    final int? ayahNum = int.tryParse(value);
    if (ayahNum != null && ayahNum > 0 && ayahNum <= widget.surah.totalAyahs) {
        _itemScrollController.jumpTo(index: ayahNum); 
        Navigator.pop(context);
    }
  }

  void _openSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F172A), // Dark slate
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(
                    'Settings',
                    style: GoogleFonts.spaceGrotesk(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 24),
                  const SizedBox(height: 24),
                  Text('Jump to Ayah', style: GoogleFonts.spaceGrotesk(color: const Color(0xFF888888), fontSize: 12)),
                  const SizedBox(height: 8),
                  if (widget.surah.totalAyahs > 20)
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _ayahInputController,
                            keyboardType: TextInputType.number,
                            style: GoogleFonts.spaceGrotesk(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Enter Ayah Number (1-${widget.surah.totalAyahs})',
                              hintStyle: GoogleFonts.spaceGrotesk(color: const Color(0xFF555555)),
                              filled: true,
                              fillColor: const Color(0xFF0F172A),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFF40B779)),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            onSubmitted: (val) => _jumpToAyah(val, context),
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          onPressed: () => _jumpToAyah(_ayahInputController.text, context),
                          icon: const Icon(Icons.arrow_forward, color: Color(0xFF40B779)),
                          style: IconButton.styleFrom(
                             backgroundColor: const Color(0xFF1E293B),
                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ],
                    )
                  else
                    SizedBox(
                      height: 50,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: widget.surah.totalAyahs,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: InkWell(
                              onTap: () {
                                _itemScrollController.jumpTo(index: index + 1); 
                                Navigator.pop(context);
                              },
                              child: Container(
                                alignment: Alignment.center,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                decoration: BoxDecoration(
                                  border: Border.all(color: const Color(0xFF2A2A2A)),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${index + 1}',
                                  style: GoogleFonts.spaceGrotesk(color: Colors.white),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 24),
                  Text('Visibility', style: GoogleFonts.spaceGrotesk(color: const Color(0xFF888888), fontSize: 12)),
                  SwitchListTile(
                    title: Text('Arabic Text', style: GoogleFonts.spaceGrotesk(color: Colors.white)),
                    value: _showArabic,
                    activeColor: const Color(0xFF40B779),
                    onChanged: (val) {
                      setState(() => _showArabic = val);
                      setModalState(() {});
                    },
                  ),
                  SwitchListTile(
                    title: Text('Translation / Tafsir', style: GoogleFonts.spaceGrotesk(color: Colors.white)),
                    value: _showTranslation,
                    activeColor: const Color(0xFF40B779),
                    onChanged: (val) {
                      setState(() => _showTranslation = val);
                      setModalState(() {});
                    },
                  ),
                  const SizedBox(height: 24),
                  Text('Edition', style: GoogleFonts.spaceGrotesk(color: const Color(0xFF888888), fontSize: 12)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFF2A2A2A)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _currentEdition,
                        dropdownColor: const Color(0xFF0F172A),
                        isExpanded: true,
                        style: GoogleFonts.spaceGrotesk(color: Colors.white),
                        items: _availableEditions.map((editionKey) {
                          return DropdownMenuItem(
                            value: editionKey,
                            child: Text(
                              _formatEditionName(editionKey),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                               _currentEdition = val;
                               _fetchData();
                            });
                            Navigator.pop(context);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            );
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
        title: Text(
          widget.surah.name,
          style: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF0A0A0A),
        scrolledUnderElevation: 0,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _openSettings,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: const Color(0xFF2A2A2A),
            height: 1.0,
          ),
        ),
      ),
      body: FutureBuilder<List<Ayah>>(
        future: _ayahsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF40B779)));
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
             return const Center(child: Text('No Ayahs found', style: TextStyle(color: Colors.white)));
          }

          final ayahs = snapshot.data!;
          return ScrollablePositionedList.builder(
            itemScrollController: _itemScrollController,
            itemPositionsListener: _itemPositionsListener,
            padding: const EdgeInsets.symmetric(vertical: 24),
            itemCount: ayahs.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 48, top: 24),
                  child: Column(
                    children: [
                      Text(
                        widget.surah.name,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 32,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                         '${widget.surah.nameAr} • ${widget.surah.type} • ${widget.surah.totalAyahs} Verses',
                         style: GoogleFonts.spaceGrotesk(
                           color: const Color(0xFF888888),
                           fontSize: 16,
                         ),
                      ),
                    ],
                  ),
                );
              }

              final ayah = ayahs[index - 1];
              return _buildAyahItem(ayah);
            },
          );
        },
      ),
    );
  }

  Widget _buildAyahItem(Ayah ayah) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFF2A2A2A)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A0A0A),
                  border: Border.all(color: const Color(0xFF2A2A2A)),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '${ayah.number}',
                  style: GoogleFonts.spaceGrotesk(
                    color: const Color(0xFF40B779),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              // Optionals (Share, Audio)
            ],
          ),
          if (_showArabic) ...[
            const SizedBox(height: 24),
            Text(
              ayah.arabic,
              textAlign: TextAlign.right,
              style: GoogleFonts.amiri(
                color: Colors.white,
                fontSize: 32,
                height: 2.5,
              ),
            ),
          ],
          if (_showTranslation) ...[
            const SizedBox(height: 24),
            Text(
              ayah.translation,
              textAlign: TextAlign.left,
              style: GoogleFonts.spaceGrotesk(
                color: const Color(0xFFBBBBBB),
                fontSize: 18,
                height: 1.6,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
