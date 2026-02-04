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
      backgroundColor: const Color(0xFF0A0A0A), // Black, consistent with Surah List modal
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(0)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
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
                   Text(
                    'Settings',
                    style: GoogleFonts.spaceGrotesk(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 24),
                  
                  _buildSectionLabel('Jump to Ayah'),
                  const SizedBox(height: 12),
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
                              fillColor: const Color(0xFF0A0A0A), // Match black background
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(0), // Sharp
                                borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(0), // Sharp
                                borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(0), // Sharp
                                borderSide: const BorderSide(color: Color(0xFF40B779)),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            onSubmitted: (val) => _jumpToAyah(val, context),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          decoration: BoxDecoration(
                              color: const Color(0xFF40B779), 
                              border: Border.all(color: const Color(0xFF2A2A2A)),
                              borderRadius: BorderRadius.circular(0) // Sharp
                          ),
                          child: IconButton(
                            onPressed: () => _jumpToAyah(_ayahInputController.text, context),
                            icon: const Icon(Icons.arrow_forward, color: Color(0xFF0A0A0A)), // Black icon for contrast
                          ),
                        ),
                      ],
                    )
                  else
                    Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color: Colors.transparent, // Transparent for 'box'
                            borderRadius: BorderRadius.circular(0), // Sharp
                            border: Border.all(color: const Color(0xFF2A2A2A)),
                        ),
                      height: 70,
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
                                width: 46,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0A0A0A),
                                  border: Border.all(color: const Color(0xFF2A2A2A)),
                                  borderRadius: BorderRadius.circular(0), // Sharp
                                ),
                                child: Text(
                                  '${index + 1}',
                                  style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 24),
                  _buildSectionLabel('Visibility'),
                  const SizedBox(height: 12),
                  Container(
                     decoration: BoxDecoration(
                      color: Colors.transparent,
                      border: Border.all(color: const Color(0xFF2A2A2A)),
                      borderRadius: BorderRadius.circular(0), // Sharp
                    ),
                    child: Column(
                        children: [
                             _buildSwitchTile('Arabic Text', _showArabic, (val) {
                                  setState(() => _showArabic = val);
                                  setModalState(() {});
                             }),
                             const Divider(height: 1, color: Color(0xFF2A2A2A)),
                             _buildSwitchTile('Translation / Tafsir', _showTranslation, (val) {
                                  setState(() => _showTranslation = val);
                                  setModalState(() {});
                             }),
                        ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildSectionLabel('Edition'),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                       color: Colors.transparent,
                      border: Border.all(color: const Color(0xFF2A2A2A)),
                      borderRadius: BorderRadius.circular(0), // Sharp
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _currentEdition,
                        dropdownColor: const Color(0xFF0A0A0A),
                        isExpanded: true,
                        icon: const Icon(Icons.expand_more, color: Color(0xFF40B779)),
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

  Widget _buildSectionLabel(String label) {
    return Text(label, style: GoogleFonts.spaceGrotesk(color: const Color(0xFF888888), fontSize: 13, fontWeight: FontWeight.w600));
  }
  
  Widget _buildSwitchTile(String title, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      title: Text(title, style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 15)),
      value: value,
      activeColor: const Color(0xFF40B779),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      onChanged: onChanged,
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
            return _buildErrorState();
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

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off_outlined, size: 64, color: const Color(0xFF40B779)),
            const SizedBox(height: 24),
            Text(
              'Failed to Load Data',
              style: GoogleFonts.spaceGrotesk(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Please check your internet connection.',
              style: GoogleFonts.spaceGrotesk(fontSize: 14, color: const Color(0xFF888888)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _fetchData();
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF40B779),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
              ),
              child: Text('Try Again', style: GoogleFonts.spaceGrotesk(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 48),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF2A2A2A)),
                borderRadius: BorderRadius.circular(0),
                color: const Color(0xFF111111),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.offline_pin_outlined, color: const Color(0xFF888888), size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Offline Access',
                          style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'To access this page without internet, please download the "Arabic" and "Indonesian" editions via the Download button on the main page.',
                    style: GoogleFonts.spaceGrotesk(color: const Color(0xFF888888), fontSize: 13, height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ),
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
