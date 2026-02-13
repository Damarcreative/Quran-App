import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../models/surah.dart';
import '../models/ayah.dart';
import '../services/api_service.dart';
import '../services/settings_service.dart';
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
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();
  final TextEditingController _ayahInputController = TextEditingController();
  final SettingsService _settings = SettingsService();

  // Settings State
  bool _showArabic = true;
  bool _showTranslation = true;
  late String _currentEdition;
  List<String> _availableEditions = [];

  @override
  void initState() {
    super.initState();
    _currentEdition = _settings.defaultTranslation;
    _fetchData();
    _loadEditions();
    _settings.addListener(_onSettingsChanged);
  }

  @override
  void dispose() {
    _settings.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    if (mounted) {
      if (_currentEdition != _settings.defaultTranslation) {
        setState(() {
          _currentEdition = _settings.defaultTranslation;
          _fetchData();
        });
      } else {
        setState(() {});
      }
    }
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
      setState(() {
        _availableEditions = ['id-indonesian', 'en-sahih'];
      });
    }
  }

  String _formatEditionName(String editionId) {
    if (editionId == 'id-indonesian') return 'Indonesian Translation';
    if (editionId == 'en-sahih') return 'English (Sahih International)';

    return editionId
        .split('-')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  void _fetchData() {
    _ayahsFuture = ApiService()
        .fetchSurahDetails(widget.surah.number, edition: _currentEdition)
        .then((ayahs) async {
          if (widget.surah.number != 1 && widget.surah.number != 9) {
            final int basmalahIndex = ayahs.indexWhere((a) => a.number == 0);
            const String basmalahArabic =
                'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ';
            // Fetch Basmalah from Surah 1 (Al-Fatihah) Ayah 1
            String basmalahTranslation;
            try {
              final fatihah = await ApiService().fetchSurahDetails(
                1,
                edition: _currentEdition,
              );
              if (fatihah.isNotEmpty) {
                basmalahTranslation = fatihah.first.translation;
              } else {
                basmalahTranslation =
                    'In the name of Allah, the Entirely Merciful, the Especially Merciful';
              }
            } catch (e) {
              basmalahTranslation =
                  'In the name of Allah, the Entirely Merciful, the Especially Merciful';
            }

            if (basmalahIndex != -1) {
              final existing = ayahs[basmalahIndex];
              ayahs[basmalahIndex] = Ayah(
                number: 0,
                arabic: basmalahArabic,
                translation: existing.translation.isNotEmpty
                    ? existing.translation
                    : basmalahTranslation,
              );
            } else {
              ayahs.insert(
                0,
                Ayah(
                  number: 0,
                  arabic: basmalahArabic,
                  translation: basmalahTranslation,
                ),
              );
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
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(0)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                24,
                24,
                MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colorScheme.outline,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Settings',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
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
                            style: GoogleFonts.spaceGrotesk(
                              color: colorScheme.onSurface,
                            ),
                            decoration: InputDecoration(
                              hintText:
                                  'Enter Ayah Number (${_settings.formatNumber(1)}-${_settings.formatNumber(widget.surah.totalAyahs)})',
                              hintStyle: GoogleFonts.spaceGrotesk(
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                              filled: true,
                              fillColor: Theme.of(context).cardColor,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(0),
                                borderSide: BorderSide(
                                  color: colorScheme.outline,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(0),
                                borderSide: BorderSide(
                                  color: colorScheme.outline,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(0),
                                borderSide: BorderSide(
                                  color: colorScheme.primary,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            onSubmitted: (val) => _jumpToAyah(val, context),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            border: Border.all(color: colorScheme.outline),
                            borderRadius: BorderRadius.circular(0),
                          ),
                          child: IconButton(
                            onPressed: () =>
                                _jumpToAyah(_ayahInputController.text, context),
                            icon: const Icon(
                              Icons.arrow_forward,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(0),
                        border: Border.all(color: colorScheme.outline),
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
                                  color: Theme.of(context).cardColor,
                                  border: Border.all(
                                    color: colorScheme.outline,
                                  ),
                                  borderRadius: BorderRadius.circular(0),
                                ),
                                child: Text(
                                  _settings.formatNumber(index + 1),
                                  style: GoogleFonts.spaceGrotesk(
                                    color: colorScheme.onSurface,
                                    fontWeight: FontWeight.bold,
                                  ),
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
                      border: Border.all(color: colorScheme.outline),
                      borderRadius: BorderRadius.circular(0),
                    ),
                    child: Column(
                      children: [
                        _buildSwitchTile('Arabic Text', _showArabic, (val) {
                          setState(() => _showArabic = val);
                          setModalState(() {});
                        }),
                        Divider(height: 1, color: colorScheme.outline),
                        _buildSwitchTile(
                          'Translation / Tafsir',
                          _showTranslation,
                          (val) {
                            setState(() => _showTranslation = val);
                            setModalState(() {});
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildSectionLabel('Edition'),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      border: Border.all(color: colorScheme.outline),
                      borderRadius: BorderRadius.circular(0),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _currentEdition,
                        dropdownColor: Theme.of(context).cardColor,
                        isExpanded: true,
                        icon: Icon(
                          Icons.expand_more,
                          color: colorScheme.primary,
                        ),
                        style: GoogleFonts.spaceGrotesk(
                          color: colorScheme.onSurface,
                        ),
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
          },
        );
      },
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.spaceGrotesk(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildSwitchTile(String title, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      title: Text(
        title,
        style: GoogleFonts.spaceGrotesk(
          color: Theme.of(context).colorScheme.onSurface,
          fontSize: 15,
        ),
      ),
      value: value,
      activeThumbColor: Theme.of(context).colorScheme.primary,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          widget.surah.name,
          style: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        scrolledUnderElevation: 0,
        elevation: 0,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _openSettings,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: colorScheme.outline, height: 1.0),
        ),
      ),
      body: FutureBuilder<List<Ayah>>(
        future: _ayahsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: colorScheme.primary),
            );
          } else if (snapshot.hasError) {
            return _buildErrorState();
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                'No Ayahs found',
                style: TextStyle(color: colorScheme.onSurface),
              ),
            );
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
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${widget.surah.nameAr} • ${widget.surah.type} • ${_settings.formatNumber(widget.surah.totalAyahs)} Verses',
                        style: GoogleFonts.spaceGrotesk(
                          color: colorScheme.onSurface.withValues(alpha: 0.5),
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
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off_outlined, size: 64, color: colorScheme.primary),
            const SizedBox(height: 24),
            Text(
              'Failed to Load Data',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Please check your internet connection.',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14,
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
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
                backgroundColor: colorScheme.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(0),
                ),
              ),
              child: Text(
                'Try Again',
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 48),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: colorScheme.outline),
                borderRadius: BorderRadius.circular(0),
                color: Theme.of(context).cardColor,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.offline_pin_outlined,
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Offline Access',
                          style: GoogleFonts.spaceGrotesk(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'To access this page without internet, please download the "Arabic" and "${_settings.formatEditionName(_settings.defaultTranslation)}" editions via the Download button on the main page.',
                    style: GoogleFonts.spaceGrotesk(
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                      fontSize: 13,
                      height: 1.5,
                    ),
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
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colorScheme.outline)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  border: Border.all(color: colorScheme.outline),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  _settings.formatNumber(ayah.number),
                  style: GoogleFonts.spaceGrotesk(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          if (_showArabic) ...[
            const SizedBox(height: 24),
            Text(
              ayah.arabic,
              textAlign: TextAlign.right,
              style: GoogleFonts.amiri(
                color: colorScheme.onSurface,
                fontSize: 32,
                height: 2.5,
              ),
            ),
          ],
          if (_showTranslation) ...[
            const SizedBox(height: 24),
            if (ayah.translation.trim().isNotEmpty)
              Text(
                ayah.translation,
                textAlign: TextAlign.left,
                style: GoogleFonts.spaceGrotesk(
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                  fontSize: 18,
                  height: 1.6,
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: colorScheme.error.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.wifi_off, size: 14, color: colorScheme.error),
                    const SizedBox(width: 8),
                    Text(
                      "Translation unavailable offline",
                      style: GoogleFonts.spaceGrotesk(
                        color: colorScheme.error,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}
