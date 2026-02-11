import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import '../models/surah.dart';
import 'api_service.dart';

enum MurotalDownloadStatus { idle, downloading, paused }

class MurotalDownloadService extends ChangeNotifier {
  static final MurotalDownloadService _instance = MurotalDownloadService._internal();
  factory MurotalDownloadService() => _instance;
  MurotalDownloadService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  final ApiService _api = ApiService();
  final Dio _dio = Dio();
  String? _localPath;

  // State
  List<int> queue = [];
  List<int> downloadedSurahs = [];
  MurotalDownloadStatus status = MurotalDownloadStatus.idle;
  double progress = 0.0;
  int currentSurah = 0;
  int currentAyah = 0;
  int totalAyahs = 0;
  
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    // Initialize local path
    final dir = await getApplicationDocumentsDirectory();
    _localPath = '${dir.path}/audio';
    await Directory(_localPath!).create(recursive: true);

    final prefs = await SharedPreferences.getInstance();
    
    // Load persisted data
    final downloadedList = prefs.getStringList('murotal_downloaded_surahs') ?? [];
    downloadedSurahs = downloadedList.map((e) => int.parse(e)).toList();
    
    final queueList = prefs.getStringList('murotal_download_queue') ?? [];
    queue = queueList.map((e) => int.parse(e)).toList();
    
    currentSurah = prefs.getInt('murotal_current_download_surah') ?? 0;
    currentAyah = prefs.getInt('murotal_last_downloaded_ayah') ?? 0;
    
    debugPrint('MurotalDownloadService Init: Queue=${queue.length}, Downloaded=${downloadedSurahs.length}');
    debugPrint('Resume State: Surah=$currentSurah, LastAyah=$currentAyah');

    // Init Notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );
    
    await flutterLocalNotificationsPlugin.initialize(settings: initializationSettings);
    
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> _saveDownloadedList() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('murotal_downloaded_surahs', downloadedSurahs.map((e) => e.toString()).toList());
    debugPrint('Saved Downloaded Surahs: ${downloadedSurahs.length} items');
  }

  Future<void> _saveQueue() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('murotal_download_queue', queue.map((e) => e.toString()).toList());
    debugPrint('Saved Queue: ${queue.length} items');
  }

  void addToQueue(int surahNumber) {
    if (!queue.contains(surahNumber) && !downloadedSurahs.contains(surahNumber)) {
      queue.add(surahNumber);
      _saveQueue();
      notifyListeners();
    }
  }

  void removeFromQueue(int surahNumber) {
    queue.remove(surahNumber);
    _saveQueue();
    notifyListeners();
  }

  Future<void> startDownload() async {
    if (queue.isEmpty) return;
    if (status == MurotalDownloadStatus.downloading) return;

    status = MurotalDownloadStatus.downloading;
    notifyListeners();

    // Get surah list for total ayahs info
    final surahs = await _api.fetchSurahs();

    // Process queue
    while (queue.isNotEmpty && status == MurotalDownloadStatus.downloading) {
      currentSurah = queue.first;
      
      // Find surah info
      final surahInfo = surahs.firstWhere(
        (s) => s.number == currentSurah,
        orElse: () => Surah(number: currentSurah, name: 'Surah $currentSurah', nameAr: '', type: '', totalAyahs: 7),
      );
      totalAyahs = surahInfo.totalAyahs;
      
      // Resume Logic
      int startFrom = 1;
      final prefs = await SharedPreferences.getInstance();
      int? savedSurah = prefs.getInt('murotal_current_download_surah');
      int? savedAyah = prefs.getInt('murotal_last_downloaded_ayah');

      if (savedSurah == currentSurah && savedAyah != null && savedAyah < totalAyahs) {
         startFrom = savedAyah + 1;
      } else {
         // New surah starting
         await prefs.setInt('murotal_current_download_surah', currentSurah);
         await prefs.setInt('murotal_last_downloaded_ayah', 0);
      }

      for (int i = startFrom; i <= totalAyahs; i++) {
        if (status != MurotalDownloadStatus.downloading) break; // Check for pause/stop

        currentAyah = i;
        progress = (i / totalAyahs);
        notifyListeners();
        _showProgressNotification(currentSurah, i, totalAyahs);

        try {
          await _downloadAyahAudio(currentSurah, i);
          // Persist progress
          await prefs.setInt('murotal_last_downloaded_ayah', i);
        } catch (e) {
          debugPrint('Error downloading audio Surah $currentSurah Ayah $i: $e');
        }
      }

      if (status == MurotalDownloadStatus.downloading) {
        // Surah completed
        queue.removeAt(0);
        _saveQueue();
        
        // Reset progress trackers
        await prefs.remove('murotal_current_download_surah');
        await prefs.remove('murotal_last_downloaded_ayah');

        downloadedSurahs.add(currentSurah);
        await _saveDownloadedList();
        notifyListeners();
      }
    }

    if (queue.isEmpty) {
      status = MurotalDownloadStatus.idle;
      progress = 0.0;
      currentSurah = 0;
      currentAyah = 0;
      totalAyahs = 0;
      await flutterLocalNotificationsPlugin.cancel(id: 1);
      notifyListeners();
    }
  }

  Future<void> _downloadAyahAudio(int surahNum, int ayahNum) async {
    if (_localPath == null) await init();

    final String fileName = '${surahNum.toString().padLeft(3, '0')}-${ayahNum.toString().padLeft(3, '0')}.mp3';
    final String localFilePath = '$_localPath/$fileName';
    final File file = File(localFilePath);

    // Skip if already exists and valid
    if (await file.exists()) {
      final length = await file.length();
      if (length > 1024) {
        debugPrint('Audio already exists: $fileName');
        return;
      } else {
        await file.delete();
      }
    }

    final String url = 'https://damarjati1323.github.io/audio/$fileName';
    try {
      await _dio.download(url, localFilePath);
      debugPrint('Downloaded: $fileName');
    } catch (e) {
      debugPrint('Download failed for $url: $e');
      rethrow;
    }
  }

  void pauseDownload() {
    status = MurotalDownloadStatus.paused;
    notifyListeners();
  }

  void stopDownload() async {
    status = MurotalDownloadStatus.idle;
    progress = 0.0;
    currentSurah = 0;
    currentAyah = 0;
    totalAyahs = 0;
    queue.clear();
    
    // Clear persistence
    _saveQueue();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('murotal_current_download_surah');
    await prefs.remove('murotal_last_downloaded_ayah');

    await flutterLocalNotificationsPlugin.cancel(id: 1);
    notifyListeners();
  }

  /// Check if a surah is fully downloaded
  bool isSurahDownloaded(int surahNumber) {
    return downloadedSurahs.contains(surahNumber);
  }

  /// Get download status text
  String getStatusText() {
    switch (status) {
      case MurotalDownloadStatus.idle:
        return 'Idle';
      case MurotalDownloadStatus.downloading:
        return 'Downloading';
      case MurotalDownloadStatus.paused:
        return 'Paused';
    }
  }

  Future<void> _showProgressNotification(int surah, int current, int total) async {
    final AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'murotal_download_channel', 
      'Murotal Downloads',
      channelDescription: 'Show murotal download progress',
      importance: Importance.low,
      priority: Priority.low,
      showProgress: true,
      maxProgress: total,
      progress: current,
      onlyAlertOnce: true,
    );
    final NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
      id: 1, 
      title: 'Downloading Surah $surah', 
      body: 'Ayah $current of $total', 
      notificationDetails: platformChannelSpecifics
    );
  }
}
