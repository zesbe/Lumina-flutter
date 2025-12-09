import 'package:flutter/foundation.dart';
import '../models/generation.dart';
import '../services/api_service.dart';

class MusicProvider with ChangeNotifier {
  List<Generation> _generations = [];
  bool _isLoading = false;
  String? _error;

  List<Generation> get generations => _generations;
  List<Generation> get completed => _generations.where((g) => g.status == 'completed').toList();
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadGenerations() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await ApiService.getGenerations(type: 'music');
      _generations = data.map((json) => Generation.fromJson(json)).toList();
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> generateMusic({
    required String title,
    required String prompt,
    required String lyrics,
    String? style,
  }) async {
    await ApiService.generateMusic(
      title: title,
      prompt: prompt,
      lyrics: lyrics,
      style: style,
    );
    await loadGenerations();
  }

  Future<void> toggleFavorite(int id) async {
    await ApiService.toggleFavorite(id);
    final index = _generations.indexWhere((g) => g.id == id);
    if (index != -1) {
      // Reload to get updated data
      await loadGenerations();
    }
  }

  Future<void> delete(int id) async {
    await ApiService.deleteGeneration(id);
    _generations.removeWhere((g) => g.id == id);
    notifyListeners();
  }
}
