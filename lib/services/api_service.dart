import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../models/surah.dart';
import '../models/ayah.dart';

class ApiService {
  static const String baseUrl = 'https://quran-api.damarcreative.my.id/api';

  Future<List<Surah>> fetchSurahs({bool forceRefresh = false}) async {
    const String cacheKey = 'cache_surah_list';
    final prefs = await SharedPreferences.getInstance();

    if (!forceRefresh && prefs.containsKey(cacheKey)) {
      final String? cachedData = prefs.getString(cacheKey);
      if (cachedData != null) {
        try {
          final List<dynamic> data = json.decode(cachedData); 
          if (data.isNotEmpty) {
             return data.map((json) => Surah.fromJson(json)).toList();
          }
        } catch (e) {
          print('Cache error: $e');
        }
      }
    }

    try {
      final response = await http.get(Uri.parse('$baseUrl/surah'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(response.body);
        final List<dynamic> data = body['data'];
        
        await prefs.setString(cacheKey, json.encode(data));
        
        return data.map((json) => Surah.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load surahs');
      }
    } catch (e) {
      // Fallback to offline asset
      try {
        final String jsonString = await rootBundle.loadString('assets/surah_list.json');
        final Map<String, dynamic> body = json.decode(jsonString);
        // The API response wrapper might be in the asset or just the list.
        // My curl command was: curl ... > assets/surah_list.json
        // If the API returns {data: [...]}, then we parse it similarly.
        final List<dynamic> data = body['data'];
        
        return data.map((json) => Surah.fromJson(json)).toList();
      } catch (_) {
         throw Exception('Failed to connect to API and load offline data: $e');
      }
    }
  }

  /// Fetch Arabic only (with robust cache fallback)
  Future<List<Ayah>> fetchArabicOnly(int surahNumber) async {
    final String arabicCacheKey = 'cache_surah_${surahNumber}_arabic_v4';
    final prefs = await SharedPreferences.getInstance();

    // 1. Check Arabic-specific cache
    if (prefs.containsKey(arabicCacheKey)) {
       final String? cachedData = prefs.getString(arabicCacheKey);
       if (cachedData != null) {
         try {
           final List<dynamic> data = json.decode(cachedData);
           return data.map((item) => Ayah(
             number: item['number'],
             arabic: item['arabic'],
             translation: '',
           )).toList();
         } catch (e) {
           debugPrint('Error parsing Arabic cache: $e');
         }
       }
    }

    // 2. Check ANY other edition cache for this surah (e.g. Indonesian) to extract Arabic
    // This allows offline usage if *any* translation was previously cached
    try {
      final keys = prefs.getKeys();
      final String prefix = 'cache_surah_${surahNumber}_';
      
      for (final key in keys) {
        if (key.startsWith(prefix) && key.endsWith('_v4') && key != arabicCacheKey) {
           final String? cachedData = prefs.getString(key);
           if (cachedData != null) {
             final List<dynamic> data = json.decode(cachedData);
             if (data.isNotEmpty) {
                // Found a cache! Extract Arabic from it.
                final ayahs = data.map((item) => Ayah(
                  number: item['number'],
                  arabic: item['arabic'],
                  translation: '',
                )).toList();
                
                // Cache this as separate Arabic cache for next time
                final String jsonString = json.encode(ayahs.map((e) => {
                  'number': e.number,
                  'arabic': e.arabic,
                }).toList());
                await prefs.setString(arabicCacheKey, jsonString);
                
                return ayahs;
             }
           }
        }
      }
    } catch (e) {
      debugPrint('Error checking fallback cache: $e');
    }

    // 3. Fetch from API
    try {
      final arabicResponse = await http.get(Uri.parse('$baseUrl/surah/$surahNumber/arabic'));

      if (arabicResponse.statusCode == 200) {
        final Map<String, dynamic> arabicBody = json.decode(arabicResponse.body);
        final List<dynamic> arabicList = arabicBody['data']['ayahs'];

        final List<Ayah> ayahs = [];
        int currentNumber = 1;

        for (int i = 0; i < arabicList.length; i++) {
          final arabicItem = arabicList[i];
          String arabicText = arabicItem['uthmani'] ?? '';

          if (arabicItem['number'] == 0) continue;
          if (arabicText.trim().isEmpty) continue;
          
          ayahs.add(Ayah(
            number: currentNumber++,
            arabic: arabicText,
            translation: '',
          ));
        }

        // Cache Arabic separately
        final String jsonString = json.encode(ayahs.map((e) => {
          'number': e.number,
          'arabic': e.arabic,
        }).toList());
        await prefs.setString(arabicCacheKey, jsonString);

        return ayahs;
      } else {
        throw Exception('Failed to load Arabic');
      }
    } catch (e) {
      throw Exception('Failed to connect to API: $e');
    }
  }

  /// Fetch translation and merge with existing ayahs
  Future<List<Ayah>> fetchTranslation(int surahNumber, List<Ayah> arabicAyahs, {String edition = 'id-indonesian'}) async {
    final String cacheKey = 'cache_surah_${surahNumber}_${edition}_v4';
    final prefs = await SharedPreferences.getInstance();

    // Check full cache first
    if (prefs.containsKey(cacheKey)) {
       final String? cachedData = prefs.getString(cacheKey);
       if (cachedData != null) {
         final List<dynamic> data = json.decode(cachedData);
         return data.map((item) => Ayah(
           number: item['number'],
           arabic: item['arabic'],
           translation: item['translation'] ?? '',
         )).toList();
       }
    }

    try {
      final translationResponse = await http.get(Uri.parse('$baseUrl/surah/$surahNumber/$edition'));

      if (translationResponse.statusCode == 200) {
        final Map<String, dynamic> transBody = json.decode(translationResponse.body);
        final List<dynamic> transList = transBody['data']['ayahs'];

        final List<Ayah> mergedAyahs = [];
        
        for (int i = 0; i < arabicAyahs.length; i++) {
          final trans = (i < transList.length) ? transList[i]['text'] ?? '' : '';
          mergedAyahs.add(Ayah(
            number: arabicAyahs[i].number,
            arabic: arabicAyahs[i].arabic,
            translation: trans,
          ));
        }

        // Cache full data
        final String jsonString = json.encode(mergedAyahs.map((e) => {
          'number': e.number,
          'arabic': e.arabic,
          'translation': e.translation,
        }).toList());
        await prefs.setString(cacheKey, jsonString);

        return mergedAyahs;
      } else {
        return arabicAyahs; // Return Arabic only if translation fails
      }
    } catch (e) {
      return arabicAyahs; // Return Arabic only on error
    }
  }

  Future<List<Ayah>> fetchSurahDetails(int surahNumber, {String edition = 'id-indonesian'}) async {
    try {
      final List<Ayah> arabicAyahs = await fetchArabicOnly(surahNumber);
      
      return await fetchTranslation(surahNumber, arabicAyahs, edition: edition);
      
    } catch (e) {
      debugPrint('fetchSurahDetails Error: $e');
      throw Exception('Failed to load data: $e');
    }
  }


  Future<List<Map<String, dynamic>>> fetchPrayerSchedule(String province, String city, {DateTime? date}) async {
    const String url = 'https://equran.id/api/v2/shalat';
    final DateTime targetDate = date ?? DateTime.now();
    final int month = targetDate.month; // Send as int
    final int year = targetDate.year;   // Send as int

    // Cache key for this specific location and month
    final String cacheKey = 'prayer_times_${province}_${city}_${year}_$month';
    final prefs = await SharedPreferences.getInstance();

    if (prefs.containsKey(cacheKey)) {
       final String? cachedData = prefs.getString(cacheKey);
       if (cachedData != null) {
         final List<dynamic> data = json.decode(cachedData);
         return data.cast<Map<String, dynamic>>();
       }
    }

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'provinsi': province,
          'kabkota': city,
          'bulan': month, // int
          'tahun': year,  // int
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(response.body);
        final List<dynamic> jadwal = body['data']['jadwal'];
        
        // Cache the result
        await prefs.setString(cacheKey, json.encode(jadwal));

        return jadwal.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to load prayer times');
      }
    } catch (e) {
      throw Exception('Failed to connect to API: $e');
    }
  }
}
