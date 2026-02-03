import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
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
          // Cache might be corrupt, proceed to fetch
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
      throw Exception('Failed to connect to API: $e');
    }
  }

  Future<List<Ayah>> fetchSurahDetails(int surahNumber, {String edition = 'id-indonesian'}) async {
    final String cacheKey = 'cache_surah_${surahNumber}_$edition';
    final String arabicCacheKey = 'cache_surah_${surahNumber}_arabic';
    final prefs = await SharedPreferences.getInstance();

    if (prefs.containsKey(cacheKey)) {
       final String? cachedData = prefs.getString(cacheKey);
       if (cachedData != null) {
         final List<dynamic> data = json.decode(cachedData);
         return data.map((item) => Ayah(
           number: item['number'],
           arabic: item['arabic'],
           translation: item['translation'],
         )).toList();
       }
    }

    try {
      final arabicResponse = await http.get(Uri.parse('$baseUrl/surah/$surahNumber/arabic'));
      final translationResponse = await http.get(Uri.parse('$baseUrl/surah/$surahNumber/$edition'));

      if (arabicResponse.statusCode == 200 && translationResponse.statusCode == 200) {
        final Map<String, dynamic> arabicBody = json.decode(arabicResponse.body);
        final Map<String, dynamic> transBody = json.decode(translationResponse.body);

        final List<dynamic> arabicList = arabicBody['data']['ayahs'];
        final List<dynamic> transList = transBody['data']['ayahs'];

        final List<Ayah> ayahs = List.generate(arabicList.length, (index) {
          final arabicItem = arabicList[index];
          final transItem = (index < transList.length) ? transList[index] : null;

          return Ayah(
            number: arabicItem['number'] is int ? arabicItem['number'] : index + 1,
            arabic: arabicItem['uthmani'] ?? '',
            translation: transItem != null ? transItem['text'] ?? '' : '',
          );
        });

        final String jsonString = json.encode(ayahs.map((e) => {
          'number': e.number,
          'arabic': e.arabic,
          'translation': e.translation,
        }).toList());
        
        await prefs.setString(cacheKey, jsonString);

        return ayahs;
      } else {
        throw Exception('Failed to load surah details');
      }
    } catch (e) {
      throw Exception('Failed to connect to API: $e');
    }
  }
}
