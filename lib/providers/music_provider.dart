import 'package:flutter/foundation.dart';
import '../models/generation.dart';
import '../services/api_service.dart';

class MusicProvider with ChangeNotifier {
  List<Generation> _generations = [];
  bool _isLoading = false;
  bool _isGenerating = false;
  String? _error;

  List<Generation> get generations => _generations;
  List<Generation> get completed => _generations.where((g) => g.status == 'completed').toList();
  List<Generation> get processing => _generations.where((g) => g.status == 'processing').toList();
  bool get isLoading => _isLoading;
  bool get isGenerating => _isGenerating;
  String? get error => _error;

  Future<void> loadGenerations() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await ApiService.getGenerations(type: 'music');
      _generations = data.map((json) => Generation.fromJson(json)).toList();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    }

    _isLoading = false;
    notifyListeners();
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
      
      // Add new generation to list if returned
      if (result['generation'] != null) {
        final newGen = Generation.fromJson(result['generation']);
        _generations.insert(0, newGen);
      }
      
      _isGenerating = false;
      notifyListeners();
      
      // Reload after a short delay to get updated status
      Future.delayed(const Duration(seconds: 3), () => loadGenerations());
      
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
      }
      
      _isGenerating = false;
      notifyListeners();
      
      Future.delayed(const Duration(seconds: 2), () => loadGenerations());
      
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
      }
      
      _isGenerating = false;
      notifyListeners();
      
      Future.delayed(const Duration(seconds: 2), () => loadGenerations());
      
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isGenerating = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> toggleFavorite(int id) async {
    try {
      await ApiService.toggleFavorite(id);
      final index = _generations.indexWhere((g) => g.id == id);
      if (index != -1) {
        _generations[index] = Generation(
          id: _generations[index].id,
          type: _generations[index].type,
          status: _generations[index].status,
          title: _generations[index].title,
          prompt: _generations[index].prompt,
          style: _generations[index].style,
          lyrics: _generations[index].lyrics,
          outputUrl: _generations[index].outputUrl,
          thumbnailUrl: _generations[index].thumbnailUrl,
          isFavorite: !_generations[index].isFavorite,
          createdAt: _generations[index].createdAt,
        );
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  Future<void> delete(int id) async {
    try {
      await ApiService.deleteGeneration(id);
      _generations.removeWhere((g) => g.id == id);
      notifyListeners();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
