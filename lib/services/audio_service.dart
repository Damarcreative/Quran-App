import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:synchronized/synchronized.dart';
import '../models/surah.dart';
import '../services/api_service.dart';

enum RepeatMode { none, autoNext, repeatOne }
enum SurahOrder { ascending, descending }

class AudioService extends ChangeNotifier {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _player = AudioPlayer();
  final Dio _dio = Dio();
  String? _localPath;
  
  // Locks for downloads
  final Map<String, Lock> _downloadLocks = {};
  
  // State
  Surah? _currentSurah;
  int _currentAyah = 1;
  bool _isPlaying = false;
  bool _isBuffering = false;
  
  // Playback Options
  RepeatMode _repeatMode = RepeatMode.autoNext;
  SurahOrder _surahOrder = SurahOrder.ascending;

  // Additional state for logic
  bool _isPlayingBismillah = false; 
  bool _isCompletionHandled = false;
  bool _isChangingTrack = false; 
  int _loadingOperationId = 0; // Token for cancellation
  Timer? _debounceTimer;
  int? _pendingSurahTarget;

  ConcatenatingAudioSource? _playlist;
  
  // Getters
  Surah? get currentSurah => _currentSurah;
  int get currentAyah => _currentAyah;
  bool get isPlaying => _isPlaying;
  bool get isBuffering => _isBuffering;
  
  RepeatMode get repeatMode => _repeatMode;
  SurahOrder get surahOrder => _surahOrder;

  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  void toggleRepeatMode() {
    if (_repeatMode == RepeatMode.autoNext) {
       _repeatMode = RepeatMode.repeatOne;
    } else if (_repeatMode == RepeatMode.repeatOne) {
       _repeatMode = RepeatMode.none;
    } else {
       _repeatMode = RepeatMode.autoNext;
    }
    notifyListeners();
  }
  
  void toggleSurahOrder() {
    _surahOrder = _surahOrder == SurahOrder.ascending 
        ? SurahOrder.descending 
        : SurahOrder.ascending;
    notifyListeners();
  }
  
  bool hasNextSurah() {
     if (_currentSurah == null) return false;
     if (_surahOrder == SurahOrder.descending) {
        return _currentSurah!.number > 1;
     } else {
        return _currentSurah!.number < 114;
     }
  }

  bool hasPrevSurah() {
     if (_currentSurah == null) return false;
     if (_surahOrder == SurahOrder.descending) {
        return _currentSurah!.number < 114;
     } else {
        return _currentSurah!.number > 1;
     }
  }

  void playNextSurah() {
     if (_currentSurah == null) return;
     
     // Determine direction
     final direction = _surahOrder == SurahOrder.ascending ? 1 : -1;
     
     // Base is either pending target or current surah
     int baseSurah = _pendingSurahTarget ?? _currentSurah!.number;
     int nextNum = baseSurah + direction;

     // Clamp within 1-114
     if (nextNum >= 1 && nextNum <= 114) {
        _pendingSurahTarget = nextNum;
        
        _debounceTimer?.cancel();
        _debounceTimer = Timer(const Duration(milliseconds: 500), () { // Increased to 500ms for better usability
             final target = _pendingSurahTarget;
             _pendingSurahTarget = null;
             if (target != null) {
                _loadAndPlaySurah(target);
             }
        });
     }
  }

  void playPrevSurah() {
     if (_currentSurah == null) return;

     // Determine direction
     final direction = _surahOrder == SurahOrder.ascending ? -1 : 1;

     // Base
     int baseSurah = _pendingSurahTarget ?? _currentSurah!.number;
     int prevNum = baseSurah + direction;

     // Clamp
     if (prevNum >= 1 && prevNum <= 114) {
        _pendingSurahTarget = prevNum;
        
        _debounceTimer?.cancel();
        _debounceTimer = Timer(const Duration(milliseconds: 500), () {
             final target = _pendingSurahTarget;
             _pendingSurahTarget = null;
             if (target != null) {
                _loadAndPlaySurah(target);
             }
        });
     }
  }

  Future<void> init() async {
    if (_localPath != null) return;
    final dir = await getApplicationDocumentsDirectory();
    _localPath = '${dir.path}/audio';
    await Directory(_localPath!).create(recursive: true);

    // Listen to playback state
    _player.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      _isBuffering = state.processingState == ProcessingState.buffering || 
                     state.processingState == ProcessingState.loading;
      notifyListeners();
    });

    // Listen to current item change for UI update and progressive loading
    _player.currentIndexStream.listen((index) {
      if (index != null && _playlist != null && index < _playlist!.length) {
        final source = _playlist!.children[index] as UriAudioSource;
        if (source.tag != null && source.tag is int) {
           final newAyah = source.tag as int;
           // Allow 0 (Bismillah) to trigger update
           if (newAyah >= 0 && _currentAyah != newAyah) {
             _currentAyah = newAyah;
             notifyListeners();
             _maintainPlaylistQueue();
           }
        }
      }
    });

    // Listen for completion (in case playlist ends)
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
         if (!_isChangingTrack && !_isCompletionHandled) {
             _isCompletionHandled = true;
             // Playlist finished implies end of Surah logic if not caught by queue
             _handleSurahCompletion();
         }
      } else if (state.processingState != ProcessingState.completed) {
         _isCompletionHandled = false;
      }
    });
  }

  Future<void> playAyah(Surah surah, int ayahNumber) async {
    final int opId = ++_loadingOperationId; // Start new operation
    
    _currentSurah = surah;
    _currentAyah = ayahNumber;
    _isChangingTrack = true;
    notifyListeners(); 

    // Stop current playback quickly
    try {
      await _player.stop();
    } catch (e) {
      // Ignore stop errors (e.g. abort/interrupted)
    }
    
    if (opId != _loadingOperationId) return; // Cancelled

    try {
      final List<AudioSource> initialSources = [];

      // 1. Handle Bismillah Logic - only for first ayah, not surah 1 or 9
      if (ayahNumber == 1 && surah.number != 1 && surah.number != 9) {
        // Check if bismillah already cached, don't wait for download
        final bismillahPath = await _getFileWithLock(1, 1, onlyCheck: true);
        if (opId != _loadingOperationId) return; // Cancelled

        final uri = bismillahPath != null 
            ? Uri.parse(bismillahPath) 
            : Uri.parse('https://damarjati1323.github.io/audio/001-001.mp3');
        initialSources.add(AudioSource.uri(uri, tag: 0));
      }

      // 2. Add ONLY the target ayah first - quick check or use remote URL
      final targetPath = await _getFileWithLock(surah.number, ayahNumber, onlyCheck: true);
      if (opId != _loadingOperationId) return; // Cancelled

      final targetUri = targetPath != null
          ? Uri.parse(targetPath)
          : Uri.parse('https://damarjati1323.github.io/audio/${surah.number.toString().padLeft(3, '0')}-${ayahNumber.toString().padLeft(3, '0')}.mp3');
      initialSources.add(AudioSource.uri(targetUri, tag: ayahNumber));

      // 3. Create minimal playlist and PLAY IMMEDIATELY
      _playlist = ConcatenatingAudioSource(children: initialSources);
      
      try {
         await _player.setAudioSource(_playlist!);
      } catch (e) {
         if (e.toString().contains("Platform player") && e.toString().contains("already exists")) {
            debugPrint("Player race condition detected in playAyah, retrying...");
            await Future.delayed(const Duration(milliseconds: 100));
            if (opId != _loadingOperationId) return;
            await _player.setAudioSource(_playlist!);
         } else {
            rethrow;
         }
      }
      
      if (opId != _loadingOperationId) return; // Cancelled before play
      
      _isChangingTrack = false;
      _player.play();
      notifyListeners();

      // 4. BACKGROUND: Add buffer ayahs while playing
      _bufferNextAyahsInBackground(surah, ayahNumber);
      
    } catch (e) {
      if (opId == _loadingOperationId) {
         debugPrint("Error initializing playlist: $e");
         _isChangingTrack = false;
         notifyListeners(); // Ensure loading state is cleared on error
      }
    }
  }

  /// Buffer next ayahs in background without blocking playback
  Future<void> _bufferNextAyahsInBackground(Surah surah, int startAyah) async {
    // Small delay to let playback start smoothly
    await Future.delayed(const Duration(milliseconds: 100));
    
    // Add next 3 ayahs to playlist in background
    for (int i = 1; i <= 3; i++) {
      final target = startAyah + i;
      if (target <= surah.totalAyahs && _playlist != null) {
        try {
          final source = await _resolveAudioSource(surah, target);
          await _playlist!.add(source);
        } catch (e) {
          debugPrint("Buffer error for ayah $target: $e");
        }
      }
    }
    
    // Also prefetch more ayahs for cache
    _prefetch(surah, startAyah);
  }

  bool _isAddingToPlaylist = false;

  void _maintainPlaylistQueue() async {
    if (_playlist == null || _currentSurah == null || _isAddingToPlaylist) return;
    
    _isAddingToPlaylist = true;
    
    try {
      final index = _player.currentIndex ?? 0;
      final length = _playlist!.length;
      
      // Check if we are approaching end of current playlist
      if (length - index <= 2) {
         final lastSource = _playlist!.children.last as UriAudioSource;
         final lastAyahNum = lastSource.tag as int;
         
         // Next ayah in current Surah?
         int nextAyahNum = (lastAyahNum == 0) ? 1 : lastAyahNum + 1;

         if (nextAyahNum <= _currentSurah!.totalAyahs) {
            // Continue adding current surah ayahs
            final source = await _resolveAudioSource(_currentSurah!, nextAyahNum);
            await _playlist!.add(source);
         } else {
            // We are at the end of the surah. 
            // PREFETCH NEXT SURAH DATA for seamless transition
            // We don't add to playlist yet (keep logic simple), but we ensure cache is hot.
            if (!_isPrefetchingNext) {
               _prefetchNextSurahInfo();
            }
         }
      }
      
      _prefetch(_currentSurah!, _currentAyah);
    } finally {
      _isAddingToPlaylist = false;
    }
  }

  bool _isPrefetchingNext = false;

  Future<void> _prefetchNextSurahInfo() async {
     if (_currentSurah == null) return;
     _isPrefetchingNext = true;
     try {
       final nextSurahNum = _currentSurah!.number + 1;
       if (nextSurahNum <= 114) {
          debugPrint("Prefetching Next Surah: $nextSurahNum...");
          // 1. Warm API Cache
          final _api = ApiService();
          await _api.fetchSurahDetails(nextSurahNum);

          // 2. Prefetch Audio for Bismillah & First Ayah
          // Bismillah (Ayah 1 of 1? No, 1:1 is Bismillah)
          // File 1:1 (Al-Fatihah 1) is Bismillah.
          // But strict Bismillah audio is often shared.
          // We'll just prefetch 1,1 (re-used often) and NextSurah,1.
          
          await _getFileWithLock(1, 1); // Bismillah/Fatihah 1
          await _getFileWithLock(nextSurahNum, 1);
       }
     } catch (e) {
        debugPrint("Prefetch Warning: $e");
     } finally {
       _isPrefetchingNext = false; // Allow retry if called again much later
     }
  }

  void _handleSurahCompletion() async {
     debugPrint("Surah Completed.");
     if (_currentSurah == null) return;
     
     if (_repeatMode == RepeatMode.repeatOne) {
        debugPrint("Repeating Surah...");
        playAyah(_currentSurah!, 1);
     } else if (_repeatMode == RepeatMode.autoNext) {
        // Next logic
        playNextSurah();
     } else {
       // Stop
       _player.stop();
     }
  }

  // Helper to load next surah - OPTIMIZED for speed
  Future<void> _loadAndPlaySurah(int number) async {
     final int opId = ++_loadingOperationId; // Start new operation

     try {
       // Use cached surah list (should be instant from SharedPreferences)
       final surahs = await ApiService().fetchSurahs();
       if (opId != _loadingOperationId) return;

       final nextSurah = surahs.firstWhere(
         (s) => s.number == number, 
         orElse: () => Surah(number: number, name: 'Surah $number', nameAr: '', type: '', totalAyahs: 7)
       );
       
       // Update state IMMEDIATELY before loading audio
       _currentSurah = nextSurah;
       _currentAyah = 1;
       notifyListeners(); // UI updates NOW
       
       // Now play with bismillah-first strategy
       await _playWithBismillahFirst(nextSurah, opId);
     } catch (e) {
       if (opId == _loadingOperationId) {
          debugPrint("Cannot load surah $number: $e");
          _player.stop();
          _isChangingTrack = false;
          notifyListeners();
       }
     }
  }
  
  /// Play bismillah first (for surah 2-113), then add ayah 1 in background
  Future<void> _playWithBismillahFirst(Surah surah, int opId) async {
    _isChangingTrack = true;
    notifyListeners();
    
    try {
       await _player.stop();
    } catch (e) {
       // Ignore
    }
    
    if (opId != _loadingOperationId) return;

    try {
      final List<AudioSource> initialSources = [];

      // For surah 2-113 (not 1 and not 9), play bismillah first
      if (surah.number != 1 && surah.number != 9) {
        // Use cached or remote bismillah
        final bismillahPath = await _getFileWithLock(1, 1, onlyCheck: true);
        if (opId != _loadingOperationId) return;

        final uri = bismillahPath != null 
            ? Uri.parse(bismillahPath) 
            : Uri.parse('https://damarjati1323.github.io/audio/001-001.mp3');
        initialSources.add(AudioSource.uri(uri, tag: 0));
      }

      // Add ayah 1 (quick check only)
      final ayah1Path = await _getFileWithLock(surah.number, 1, onlyCheck: true);
      if (opId != _loadingOperationId) return;

      final ayah1Uri = ayah1Path != null
          ? Uri.parse(ayah1Path)
          : Uri.parse('https://damarjati1323.github.io/audio/${surah.number.toString().padLeft(3, '0')}-001.mp3');
      initialSources.add(AudioSource.uri(ayah1Uri, tag: 1));

      // Create playlist and PLAY IMMEDIATELY
      _playlist = ConcatenatingAudioSource(children: initialSources);
      
      try {
         await _player.setAudioSource(_playlist!);
      } catch (e) {
         if (e.toString().contains("Platform player") && e.toString().contains("already exists")) {
            debugPrint("Player race condition detected, retrying...");
            await Future.delayed(const Duration(milliseconds: 100));
            if (opId != _loadingOperationId) return;
            await _player.setAudioSource(_playlist!);
         } else {
            rethrow;
         }
      }
      
      if (opId != _loadingOperationId) return;

      _isChangingTrack = false;
      _player.play();
      notifyListeners();

      // Buffer next ayahs in background
      _bufferNextAyahsInBackground(surah, 1);
      
    } catch (e) {
      if (opId == _loadingOperationId) {
         debugPrint("Error playing surah: $e");
         _isChangingTrack = false;
         notifyListeners();
      }
    }
  }
  
  Future<AudioSource> _resolveAudioSource(Surah surah, int ayahNum) async {
     final path = await _getFileWithLock(surah.number, ayahNum, onlyCheck: true);
     
     if (path != null) {
        return AudioSource.uri(Uri.parse(path), tag: ayahNum);
     } else {
        final fileName = '${surah.number.toString().padLeft(3, '0')}-${ayahNum.toString().padLeft(3, '0')}.mp3';
        final url = 'https://damarjati1323.github.io/audio/$fileName';
        return AudioSource.uri(Uri.parse(url), tag: ayahNum);
     }
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> resume() async {
    await _player.play();
  }
  
  Future<void> stop() async {
    await _player.stop();
  }

  Future<void> next() async {
    if (_player.hasNext) {
      await _player.seekToNext();
    } else {
      // Manually trigger completion logic (Next Surah)
      _handleSurahCompletion();
    }
  }

  Future<void> skipToNextSurah() async {
     // Force skip to next surah regardless of current state
     if (_currentSurah != null) {
       await _player.stop(); 
       playNextSurah();
     }
  }
  
  Future<void> previous() async {
     if (_player.hasPrevious) {
       await _player.seekToPrevious();
     } else {
       if (_currentSurah != null && _currentAyah > 1) {
          playAyah(_currentSurah!, _currentAyah - 1);
       } else {
         // Prev Surah?
         // _handleSurahPrev();
       }
     }
  }

  Future<void> _prefetch(Surah surah, int startAyah) async {
    for (int i = 1; i <= 5; i++) {
        int targetAyah = startAyah + i;
        if (targetAyah > surah.totalAyahs) break;
        _getFileWithLock(surah.number, targetAyah).then((_) {});
    }
  }

  // Thread-safe file getter
  Future<String?> _getFileWithLock(int surahNum, int ayahNum, {bool onlyCheck = false}) async {
    if (_localPath == null) await init();

    final String fileName = '${surahNum.toString().padLeft(3, '0')}-${ayahNum.toString().padLeft(3, '0')}.mp3';
    
    final lock = _downloadLocks.putIfAbsent(fileName, () => Lock());

    return await lock.synchronized(() async {
      final String localFilePath = '$_localPath/$fileName';
      final File file = File(localFilePath);

      if (await file.exists()) {
        final length = await file.length();
        if (length > 1024) { 
           return file.uri.toString();
        } else {
           debugPrint("Corrupt file found ($length bytes): $fileName. Deleting...");
           await file.delete(); 
        }
      }
      
      if (onlyCheck) return null;

      final String url = 'https://damarjati1323.github.io/audio/$fileName';
      try {
        await _dio.download(url, localFilePath);
        
        final length = await file.length();
        if (length <= 1024) {
           debugPrint("Downloaded file too small ($length bytes): $fileName");
        }
        
        return file.uri.toString();
      } catch (e) {
        debugPrint("Download failed for $url: $e");
        return url; 
      }
    });
  }
  
  @override
  void dispose() {
    _debounceTimer?.cancel();
    _player.dispose();
    super.dispose();
  }
}
