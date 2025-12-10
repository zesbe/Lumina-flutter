import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/generation.dart';
import '../services/api_service.dart';

class MusicProvider with ChangeNotifier {
  List<Generation> _generations = [];
  bool _isLoading = false;
  bool _isGenerating = false;
  String? _error;
  Timer? _pollingTimer;
  bool _hasInitialLoad = false;

  List<Generation> get generations => _generations;
  List<Generation> get completed => _generations.where((g) => g.status == 'completed').toList();
  List<Generation> get processing => _generations.where((g) => g.status == 'processing').toList();
  bool get isLoading => _isLoading;
  bool get isGenerating => _isGenerating;
  String? get error => _error;
  bool get hasData => _generations.isNotEmpty;

  // Initialize and start loading
  void init() {
    if (!_hasInitialLoad) {
      loadGenerations();
    }
  }

  // Load generations with optional force refresh
  Future<void> loadGenerations({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    try {
      final data = await ApiService.getGenerations(type: 'music');
      _generations = data.map((json) => Generation.fromJson(json)).toList();
      _hasInitialLoad = true;
      
      // Pre-cache album art images
      _preCacheImages();
      
      // Start polling if there are processing items
      _checkAndStartPolling();
      
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    }

    if (!silent) {
      _isLoading = false;
    }
    notifyListeners();
  }

  // Pre-cache images for faster display
  void _preCacheImages() {
    for (final gen in _generations) {
      if (gen.fullThumbnailUrl.isNotEmpty) {
        // This triggers the cache
        CachedNetworkImageProvider(gen.fullThumbnailUrl);
      }
    }
  }

  // Auto-poll when there are processing items
  void _checkAndStartPolling() {
    final hasProcessing = _generations.any((g) => g.status == 'processing');
    
    if (hasProcessing && _pollingTimer == null) {
      // Poll every 5 seconds for processing items
      _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        loadGenerations(silent: true);
      });
    } else if (!hasProcessing && _pollingTimer != null) {
      _pollingTimer?.cancel();
      _pollingTimer = null;
    }
  }

  Future<bool> generateMusic({
    required String title,
    required String prompt,
    required String lyrics,
    String? style,
  }) async {
    _isGenerating = true;
    _error = null;
    notifyListeners();

    try {
      final result = await ApiService.generateMusic(
        title: title,
        prompt: prompt,
        lyrics: lyrics,
        style: style,
      );
      
      // Add new generation to list immediately
      if (result['generation'] != null) {
        final newGen = Generation.fromJson(result['generation']);
        _generations.insert(0, newGen);
        notifyListeners();
      }
      
      _isGenerating = false;
      notifyListeners();
      
      // Start polling for this new processing item
      _checkAndStartPolling();
      
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isGenerating = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> generateVoice({
    required String text,
    required String title,
    String voiceId = 'male-qn-qingse',
    double speed = 1.0,
  }) async {
    _isGenerating = true;
    _error = null;
    notifyListeners();

    try {
      final result = await ApiService.generateVoice(
        text: text,
        title: title,
        voiceId: voiceId,
        speed: speed,
      );
      
      if (result['generation'] != null) {
        final newGen = Generation.fromJson(result['generation']);
        _generations.insert(0, newGen);
        notifyListeners();
      }
      
      _isGenerating = false;
      notifyListeners();
      
      _checkAndStartPolling();
      
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isGenerating = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> generateVideo({
    required String prompt,
    required String title,
    int duration = 5,
  }) async {
    _isGenerating = true;
    _error = null;
    notifyListeners();

    try {
      final result = await ApiService.generateVideo(
        prompt: prompt,
        title: title,
        duration: duration,
      );
      
      if (result['generation'] != null) {
        final newGen = Generation.fromJson(result['generation']);
        _generations.insert(0, newGen);
        notifyListeners();
      }
      
      _isGenerating = false;
      notifyListeners();
      
      _checkAndStartPolling();
      
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isGenerating = false;
      notifyListeners();
      return false;
    }
  }

  // Optimistic update - update UI immediately, then sync with server
  Future<void> toggleFavorite(int id) async {
    // Optimistic update
    final index = _generations.indexWhere((g) => g.id == id);
    if (index != -1) {
      final old = _generations[index];
      _generations[index] = _copyWithFavorite(old, !old.isFavorite);
      notifyListeners();
    }

    try {
      await ApiService.toggleFavorite(id);
    } catch (e) {
      // Revert on error
      if (index != -1) {
        final current = _generations[index];
        _generations[index] = _copyWithFavorite(current, !current.isFavorite);
        notifyListeners();
      }
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  // Optimistic update for public toggle
  Future<void> togglePublic(int id) async {
    // Optimistic update
    final index = _generations.indexWhere((g) => g.id == id);
    if (index != -1) {
      final old = _generations[index];
      _generations[index] = _copyWithPublic(old, !old.isPublic);
      notifyListeners();
    }

    try {
      await ApiService.togglePublic(id);
    } catch (e) {
      // Revert on error
      if (index != -1) {
        final current = _generations[index];
        _generations[index] = _copyWithPublic(current, !current.isPublic);
        notifyListeners();
      }
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  Future<void> delete(int id) async {
    // Optimistic delete
    final index = _generations.indexWhere((g) => g.id == id);
    Generation? backup;
    if (index != -1) {
      backup = _generations[index];
      _generations.removeAt(index);
      notifyListeners();
    }

    try {
      await ApiService.deleteGeneration(id);
    } catch (e) {
      // Revert on error
      if (backup != null && index != -1) {
        _generations.insert(index, backup);
        notifyListeners();
      }
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  // Helper to copy Generation with new favorite value
  Generation _copyWithFavorite(Generation old, bool isFavorite) {
    return Generation(
      id: old.id,
      type: old.type,
      status: old.status,
      title: old.title,
      prompt: old.prompt,
      style: old.style,
      lyrics: old.lyrics,
      outputUrl: old.outputUrl,
      thumbnailUrl: old.thumbnailUrl,
      isFavorite: isFavorite,
      isPublic: old.isPublic,
      createdAt: old.createdAt,
      artist: old.artist,
      album: old.album,
      duration: old.duration,
      genre: old.genre,
      mood: old.mood,
      model: old.model,
    );
  }

  // Helper to copy Generation with new public value
  Generation _copyWithPublic(Generation old, bool isPublic) {
    return Generation(
      id: old.id,
      type: old.type,
      status: old.status,
      title: old.title,
      prompt: old.prompt,
      style: old.style,
      lyrics: old.lyrics,
      outputUrl: old.outputUrl,
      thumbnailUrl: old.thumbnailUrl,
      isFavorite: old.isFavorite,
      isPublic: isPublic,
      createdAt: old.createdAt,
      artist: old.artist,
      album: old.album,
      duration: old.duration,
      genre: old.genre,
      mood: old.mood,
      model: old.model,
    );
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }
}
