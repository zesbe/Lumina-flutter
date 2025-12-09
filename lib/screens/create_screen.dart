import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/music_provider.dart';

class CreateScreen extends StatefulWidget {
  const CreateScreen({super.key});

  @override
  State<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends State<CreateScreen> {
  final _titleController = TextEditingController();
  final _lyricsController = TextEditingController();
  String _selectedGenre = 'Pop';
  String _selectedMood = 'Happy';
  bool _isGenerating = false;

  final _genres = ['Pop', 'Rock', 'Jazz', 'Electronic', 'Hip Hop', 'R&B', 'Classical', 'Indie'];
  final _moods = ['Happy', 'Sad', 'Energetic', 'Calm', 'Romantic', 'Dark', 'Uplifting'];

  @override
  void dispose() {
    _titleController.dispose();
    _lyricsController.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    if (_titleController.text.isEmpty || _lyricsController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Isi judul dan lirik terlebih dahulu')),
      );
      return;
    }

    setState(() => _isGenerating = true);

    try {
      await context.read<MusicProvider>().generateMusic(
        title: _titleController.text,
        prompt: '$_selectedGenre music, $_selectedMood mood',
        lyrics: _lyricsController.text,
        style: '$_selectedGenre, $_selectedMood',
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🎵 Musik sedang dibuat!')),
        );
        _titleController.clear();
        _lyricsController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }

    setState(() => _isGenerating = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buat Musik', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Judul Lagu',
                filled: true,
                fillColor: const Color(0xFF1A1A1A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Genre
            const Text('Genre', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _genres.map((genre) {
                final isSelected = _selectedGenre == genre;
                return ChoiceChip(
                  label: Text(genre),
                  selected: isSelected,
                  selectedColor: const Color(0xFF84CC16),
                  onSelected: (_) => setState(() => _selectedGenre = genre),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Mood
            const Text('Mood', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _moods.map((mood) {
                final isSelected = _selectedMood == mood;
                return ChoiceChip(
                  label: Text(mood),
                  selected: isSelected,
                  selectedColor: const Color(0xFF84CC16),
                  onSelected: (_) => setState(() => _selectedMood = mood),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Lyrics
            TextField(
              controller: _lyricsController,
              maxLines: 8,
              decoration: InputDecoration(
                labelText: 'Lirik',
                alignLabelWithHint: true,
                filled: true,
                fillColor: const Color(0xFF1A1A1A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Generate button
            ElevatedButton(
              onPressed: _isGenerating ? null : _generate,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF84CC16),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isGenerating
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      '🎵 Generate Musik',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
