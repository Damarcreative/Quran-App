import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

enum DownloadStatus { idle, downloading, paused }

class DownloadService extends ChangeNotifier {
  static final DownloadService _instance = DownloadService._internal();
  factory DownloadService() => _instance;
  DownloadService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  final ApiService _api = ApiService();

  // State
  List<String> queue = [];
  List<String> downloadedEditions = [];
  DownloadStatus status = DownloadStatus.idle;
  double progress = 0.0;
  String currentEdition = '';
  int currentSurah = 0;
  
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    final prefs = await SharedPreferences.getInstance();
    
    // Load persisted data
    downloadedEditions = prefs.getStringList('downloaded_editions_list') ?? [];
    queue = prefs.getStringList('download_queue') ?? [];
    currentEdition = prefs.getString('current_download_edition') ?? '';
    currentSurah = prefs.getInt('last_downloaded_surah') ?? 0;
    
    debugPrint('DownloadService Init: Queue=${queue.length}, Downloaded=${downloadedEditions.length}');
    debugPrint('Resume State: Edition=$currentEdition, LastSurah=$currentSurah');

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

  // ... (unchanged methods)

  Future<void> _saveDownloadedList() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('downloaded_editions_list', downloadedEditions);
    debugPrint('Saved Downloaded List: ${downloadedEditions.length} items');
  }

  Future<void> _saveQueue() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('download_queue', queue);
    debugPrint('Saved Queue: ${queue.length} items');
  }


  void addToQueue(String edition) {
    if (!queue.contains(edition) && !downloadedEditions.contains(edition)) {
      queue.add(edition);
      _saveQueue();
      notifyListeners();
    }
  }

  void removeFromQueue(String edition) {
    queue.remove(edition);
    _saveQueue();
    notifyListeners();
  }

  Future<void> startDownload() async {
    if (queue.isEmpty) return;
    if (status == DownloadStatus.downloading) return;

    status = DownloadStatus.downloading;
    notifyListeners();

    // Process queue
    while (queue.isNotEmpty && status == DownloadStatus.downloading) {
      currentEdition = queue.first;
      int totalSurahs = 114;
      
      // Resume Logic
      int startFrom = 1;
      final prefs = await SharedPreferences.getInstance();
      String? savedEdition = prefs.getString('current_download_edition');
      int? savedSurah = prefs.getInt('last_downloaded_surah');

      if (savedEdition == currentEdition && savedSurah != null && savedSurah < 114) {
         startFrom = savedSurah + 1;
      } else {
         // New edition starting
         await prefs.setString('current_download_edition', currentEdition);
         await prefs.setInt('last_downloaded_surah', 0);
      }

      for (int i = startFrom; i <= totalSurahs; i++) {
        if (status != DownloadStatus.downloading) break; // Check for pause/stop

        currentSurah = i;
        progress = (i / totalSurahs);
        notifyListeners();
        _showProgressNotification(currentEdition, i, totalSurahs);

        try {
          await _api.fetchSurahDetails(i, edition: currentEdition);
          // Persist progress
          await prefs.setInt('last_downloaded_surah', i);
        } catch (e) {
          debugPrint('Error downloading Surah $i for $currentEdition: $e');
        }
      }

      if (status == DownloadStatus.downloading) {
        // Edition completed
        queue.removeAt(0);
        _saveQueue();
        
        // Reset progress trackers
        await prefs.remove('current_download_edition');
        await prefs.remove('last_downloaded_surah');

        downloadedEditions.add(currentEdition);
        await _saveDownloadedList();
        notifyListeners();
      }
    }

    if (queue.isEmpty) {
      status = DownloadStatus.idle;
      progress = 0.0;
      currentEdition = '';
      currentSurah = 0;
      await flutterLocalNotificationsPlugin.cancel(id: 0);
      notifyListeners();
    }
  }

  void pauseDownload() {
    status = DownloadStatus.paused;
    notifyListeners();
  }

  void stopDownload() async {
    status = DownloadStatus.idle;
    progress = 0.0;
    currentEdition = '';
    currentSurah = 0;
    queue.clear();
    
    // Clear persistence
    _saveQueue();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_download_edition');
    await prefs.remove('last_downloaded_surah');

    await flutterLocalNotificationsPlugin.cancel(id: 0);
    notifyListeners();
  }

  Future<void> _showProgressNotification(String edition, int current, int total) async {
    final AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'download_channel', 
      'Downloads',
      channelDescription: 'Show download progress',
      importance: Importance.low,
      priority: Priority.low,
      showProgress: true,
      maxProgress: total,
      progress: current,
      onlyAlertOnce: true,
    );
    final NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
      id: 0, 
      title: 'Downloading $edition', 
      body: 'Surah $current of $total', 
      notificationDetails: platformChannelSpecifics
    );
  }
}
