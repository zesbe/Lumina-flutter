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
  bool _isInstrumental = false;
  bool _isGenerating = false;
  int _step = 1;

  final Map<String, List<String>> _genreCategories = {
    '🎵 Popular': ['Pop', 'Rock', 'Hip Hop', 'R&B', 'Country', 'Indie'],
    '🎹 Electronic': ['EDM', 'House', 'Techno', 'Trance', 'Dubstep', 'Lo-Fi'],
    '🎸 Rock': ['Classic Rock', 'Metal', 'Punk', 'Alternative', 'Grunge'],
    '🎺 Jazz & Soul': ['Jazz', 'Blues', 'Soul', 'Funk', 'Gospel'],
    '🌍 World': ['Latin', 'Reggae', 'K-Pop', 'Afrobeat', 'Dangdut'],
    '🎻 Classical': ['Orchestra', 'Piano', 'Cinematic', 'Ambient'],
  };

  final Map<String, Map<String, dynamic>> _moods = {
    'Happy': {'icon': '😊', 'color': Color(0xFFFFD700)},
    'Sad': {'icon': '😢', 'color': Color(0xFF6B7280)},
    'Energetic': {'icon': '⚡', 'color': Color(0xFFEF4444)},
    'Calm': {'icon': '🧘', 'color': Color(0xFF3B82F6)},
    'Romantic': {'icon': '💕', 'color': Color(0xFFEC4899)},
    'Dark': {'icon': '🌙', 'color': Color(0xFF6366F1)},
    'Uplifting': {'icon': '🌟', 'color': Color(0xFF84CC16)},
    'Melancholic': {'icon': '🍂', 'color': Color(0xFFF97316)},
  };

  final List<Map<String, String>> _templates = [
    {'name': 'Cinta', 'icon': '💕', 'lyrics': '[Verse 1]\nKau hadir dalam hidupku\nBagai mentari pagi\n\n[Chorus]\nKu cinta kau selamanya\nTak akan pernah berubah'},
    {'name': 'Semangat', 'icon': '🔥', 'lyrics': '[Verse 1]\nBangkit dan berjuang\nTak ada yang mustahil\n\n[Chorus]\nKita pasti bisa\nMeraih semua mimpi'},
    {'name': 'Galau', 'icon': '💔', 'lyrics': '[Verse 1]\nMalam ini sepi\nTanpamu di sisi\n\n[Chorus]\nMengapa kau pergi\nTinggalkan luka di hati'},
    {'name': 'Party', 'icon': '🎉', 'lyrics': '[Verse 1]\nMalam ini kita rayakan\nLupakan semua masalah\n\n[Chorus]\nAyo kita berpesta\nSampai pagi menjelang'},
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _lyricsController.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    if (_titleController.text.isEmpty) {
      _showError('Masukkan judul lagu');
      return;
    }
    if (!_isInstrumental && _lyricsController.text.isEmpty) {
      _showError('Masukkan lirik atau aktifkan mode instrumental');
      return;
    }

    setState(() => _isGenerating = true);

    try {
      await context.read<MusicProvider>().generateMusic(
        title: _titleController.text,
        prompt: '$_selectedGenre music, $_selectedMood mood${_isInstrumental ? ", instrumental" : ""}',
        lyrics: _isInstrumental ? '[Instrumental]' : _lyricsController.text,
        style: '$_selectedGenre, $_selectedMood',
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                const Text('🎵 Musik sedang dibuat!'),
              ],
            ),
            backgroundColor: const Color(0xFF84CC16),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        // Reset form
        _titleController.clear();
        _lyricsController.clear();
        setState(() => _step = 1);
      }
    } catch (e) {
      _showError(e.toString());
    }

    setState(() => _isGenerating = false);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.1))),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF84CC16), Color(0xFF22C55E)]),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.auto_awesome, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Buat Musik AI', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          Text('Wujudkan musikmu dengan AI', style: TextStyle(color: Colors.grey, fontSize: 13)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Step indicator
                  Row(
                    children: [
                      _StepIndicator(step: 1, currentStep: _step, label: 'Genre'),
                      Expanded(child: Container(height: 2, color: _step > 1 ? const Color(0xFF84CC16) : Colors.grey[800])),
                      _StepIndicator(step: 2, currentStep: _step, label: 'Mood'),
                      Expanded(child: Container(height: 2, color: _step > 2 ? const Color(0xFF84CC16) : Colors.grey[800])),
                      _StepIndicator(step: 3, currentStep: _step, label: 'Lirik'),
                    ],
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: _buildStepContent(),
              ),
            ),
            
            // Bottom buttons
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
              ),
              child: Row(
                children: [
                  if (_step > 1)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() => _step--),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: Colors.grey[700]!),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Kembali'),
                      ),
                    ),
                  if (_step > 1) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isGenerating ? null : () {
                        if (_step < 3) {
                          setState(() => _step++);
                        } else {
                          _generate();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF84CC16),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isGenerating
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(_step < 3 ? Icons.arrow_forward : Icons.auto_awesome),
                                const SizedBox(width: 8),
                                Text(_step < 3 ? 'Lanjut' : 'Generate Musik', style: const TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
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

  Widget _buildStepContent() {
    switch (_step) {
      case 1:
        return _buildGenreStep();
      case 2:
        return _buildMoodStep();
      case 3:
        return _buildLyricsStep();
      default:
        return const SizedBox();
    }
  }

  Widget _buildGenreStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Pilih Genre', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        ..._genreCategories.entries.map((category) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(category.key, style: TextStyle(color: Colors.grey[400], fontSize: 14)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: category.value.map((genre) {
                  final isSelected = _selectedGenre == genre;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedGenre = genre),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF84CC16) : const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF84CC16) : Colors.grey[800]!,
                        ),
                      ),
                      child: Text(
                        genre,
                        style: TextStyle(
                          color: isSelected ? Colors.black : Colors.white,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
          );
        }).toList(),
      ],
    );
  }

  Widget _buildMoodStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Pilih Mood', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.5,
          ),
          itemCount: _moods.length,
          itemBuilder: (context, index) {
            final mood = _moods.keys.elementAt(index);
            final data = _moods[mood]!;
            final isSelected = _selectedMood == mood;
            
            return GestureDetector(
              onTap: () => setState(() => _selectedMood = mood),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected ? (data['color'] as Color).withOpacity(0.2) : const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? data['color'] as Color : Colors.grey[800]!,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Text(data['icon'] as String, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 8),
                    Text(
                      mood,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? data['color'] as Color : Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildLyricsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title input
        const Text('Judul Lagu', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: _titleController,
          decoration: InputDecoration(
            hintText: 'Masukkan judul lagu...',
            filled: true,
            fillColor: const Color(0xFF1A1A1A),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            prefixIcon: const Icon(Icons.music_note, color: Color(0xFF84CC16)),
          ),
        ),
        const SizedBox(height: 20),
        
        // Instrumental toggle
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.piano, color: Color(0xFF84CC16)),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Mode Instrumental', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('Buat musik tanpa vokal', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              Switch(
                value: _isInstrumental,
                onChanged: (v) => setState(() => _isInstrumental = v),
                activeColor: const Color(0xFF84CC16),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        
        if (!_isInstrumental) ...[
          // Templates
          const Text('Template Lirik', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _templates.map((t) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => _lyricsController.text = t['lyrics']!,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey[800]!),
                      ),
                      child: Row(
                        children: [
                          Text(t['icon']!, style: const TextStyle(fontSize: 16)),
                          const SizedBox(width: 6),
                          Text(t['name']!),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          
          // Lyrics input
          const Text('Lirik', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _lyricsController,
            maxLines: 10,
            decoration: InputDecoration(
              hintText: '[Verse 1]\nTulis lirik di sini...\n\n[Chorus]\nTulis chorus...',
              hintStyle: TextStyle(color: Colors.grey[600]),
              filled: true,
              fillColor: const Color(0xFF1A1A1A),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              alignLabelWithHint: true,
            ),
          ),
        ],
        
        // Summary
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [const Color(0xFF84CC16).withOpacity(0.1), const Color(0xFF22C55E).withOpacity(0.1)],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF84CC16).withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Ringkasan', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _SummaryChip(icon: Icons.music_note, label: _selectedGenre),
                  const SizedBox(width: 8),
                  _SummaryChip(icon: Icons.mood, label: _selectedMood),
                  if (_isInstrumental) ...[
                    const SizedBox(width: 8),
                    _SummaryChip(icon: Icons.piano, label: 'Instrumental'),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final int step;
  final int currentStep;
  final String label;

  const _StepIndicator({required this.step, required this.currentStep, required this.label});

  @override
  Widget build(BuildContext context) {
    final isActive = currentStep >= step;
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF84CC16) : Colors.grey[800],
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: isActive && currentStep > step
                ? const Icon(Icons.check, size: 18, color: Colors.black)
                : Text('$step', style: TextStyle(color: isActive ? Colors.black : Colors.grey, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 11, color: isActive ? const Color(0xFF84CC16) : Colors.grey)),
      ],
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SummaryChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF84CC16)),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
