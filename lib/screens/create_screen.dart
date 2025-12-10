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
  List<String> _selectedGenres = [];
  String _selectedMood = 'Happy';
  String _selectedTempo = 'medium';
  bool _isInstrumental = false;
  bool _isGenerating = false;
  bool _generatingLyrics = false;
  int _step = 1;
  String _activeCategory = 'Popular';
  String? _lyricTheme;

  // Complete genre list from SvelteKit
  final List<Map<String, dynamic>> _genreCategories = [
    {'name': 'Popular', 'icon': '🔥', 'genres': ['Pop', 'Rock', 'Hip Hop', 'R&B', 'EDM', 'Dance', 'Disco', 'Funk']},
    {'name': 'Electronic', 'icon': '🎧', 'genres': ['House', 'Deep House', 'Tech House', 'Techno', 'Trance', 'Dubstep', 'Drum & Bass', 'Lo-Fi', 'Synthwave', 'Ambient', 'Chillwave', 'Future Bass', 'Electro', 'Progressive']},
    {'name': 'Rock', 'icon': '🎸', 'genres': ['Classic Rock', 'Hard Rock', 'Alternative', 'Indie Rock', 'Punk Rock', 'Metal', 'Heavy Metal', 'Grunge', 'Emo', 'Post-Rock', 'Psychedelic', 'Garage Rock', 'Soft Rock']},
    {'name': 'Urban', 'icon': '🎤', 'genres': ['Trap', 'Drill', 'Afrobeats', 'Afropop', 'Reggaeton', 'Latin Pop', 'Latin Trap', 'Dancehall', 'Grime', 'UK Garage', 'Amapiano', 'Kizomba']},
    {'name': 'Classic', 'icon': '🎷', 'genres': ['Jazz', 'Smooth Jazz', 'Blues', 'Soul', 'Neo Soul', 'Gospel', 'Country', 'Folk', 'Bluegrass', 'Americana', 'Swing', 'Bebop']},
    {'name': 'World', 'icon': '🌍', 'genres': ['K-Pop', 'J-Pop', 'C-Pop', 'Bollywood', 'Dangdut', 'Koplo', 'Reggae', 'Ska', 'Bossa Nova', 'Samba', 'Salsa', 'Cumbia', 'Flamenco', 'Celtic', 'Arabic', 'Turkish']},
    {'name': 'Orchestra', 'icon': '🎻', 'genres': ['Classical', 'Orchestral', 'Cinematic', 'Epic', 'Piano Solo', 'Violin', 'Opera', 'Chamber', 'Symphony', 'Baroque', 'Romantic Era', 'Contemporary Classical']},
    {'name': 'Mood', 'icon': '✨', 'genres': ['Acoustic', 'Ballad', 'Chill', 'Relax', 'Sleep', 'Meditation', 'Workout', 'Party', 'Romantic', 'Sad', 'Happy', 'Dark', 'Mysterious', 'Uplifting', 'Nostalgic']},
    {'name': 'Indonesia', 'icon': '🇮🇩', 'genres': ['Dangdut', 'Koplo', 'Pop Indo', 'Rock Indo', 'Jazz Indo', 'Keroncong', 'Campursari', 'Melayu', 'Sunda', 'Batak', 'Minang', 'Jawa']},
    {'name': 'Gaming', 'icon': '🎮', 'genres': ['8-Bit', 'Chiptune', 'Game OST', 'Boss Battle', 'Adventure', 'RPG Theme', 'Retro Game', 'Cyberpunk', 'Sci-Fi']},
    {'name': 'Film', 'icon': '🎬', 'genres': ['Soundtrack', 'Trailer Music', 'Horror', 'Action', 'Drama', 'Comedy', 'Documentary', 'Noir', 'Western']},
    {'name': 'Experimental', 'icon': '🔬', 'genres': ['Avant-Garde', 'Noise', 'Industrial', 'Glitch', 'IDM', 'Drone', 'Experimental', 'Art Rock', 'Math Rock']},
  ];

  final Map<String, String> _genreIcons = {
    'Pop': '🎤', 'Rock': '🎸', 'Hip Hop': '🎧', 'R&B': '🎵', 'EDM': '🎹', 'Dance': '💃', 'Disco': '🪩', 'Funk': '🕺',
    'House': '🏠', 'Deep House': '🌊', 'Tech House': '🔧', 'Techno': '🤖', 'Trance': '🌀', 'Dubstep': '🔊', 'Drum & Bass': '🥁',
    'Lo-Fi': '🌙', 'Synthwave': '🌆', 'Ambient': '🌌', 'Chillwave': '🏖️', 'Future Bass': '🚀', 'Electro': '⚡', 'Progressive': '📈',
    'Classic Rock': '🎸', 'Hard Rock': '🤘', 'Alternative': '🎭', 'Indie Rock': '🎪', 'Punk Rock': '🔥', 'Metal': '⚙️', 'Heavy Metal': '🔩',
    'Grunge': '🖤', 'Emo': '💔', 'Post-Rock': '🌅', 'Psychedelic': '🍄', 'Garage Rock': '🚗', 'Soft Rock': '🪨',
    'Trap': '💎', 'Drill': '🔫', 'Afrobeats': '🌍', 'Afropop': '🌴', 'Reggaeton': '🌴', 'Latin Pop': '💃', 'Latin Trap': '🔥',
    'Dancehall': '🇯🇲', 'Grime': '🇬🇧', 'UK Garage': '🚗', 'Amapiano': '🇿🇦', 'Kizomba': '💑',
    'Jazz': '🎷', 'Smooth Jazz': '🍷', 'Blues': '🎺', 'Soul': '💜', 'Neo Soul': '✨', 'Gospel': '🙏', 'Country': '🤠',
    'Folk': '🪕', 'Bluegrass': '🌾', 'Americana': '🇺🇸', 'Swing': '🎩', 'Bebop': '🎺',
    'K-Pop': '💜', 'J-Pop': '🌸', 'C-Pop': '🇨🇳', 'Bollywood': '🇮🇳', 'Dangdut': '🇮🇩', 'Koplo': '🎉', 'Reggae': '🦁',
    'Ska': '🎺', 'Bossa Nova': '🇧🇷', 'Samba': '🥁', 'Salsa': '💃', 'Cumbia': '🎵', 'Flamenco': '🇪🇸', 'Celtic': '☘️', 'Arabic': '🕌', 'Turkish': '🇹🇷',
    'Classical': '🎻', 'Orchestral': '🎼', 'Cinematic': '🎬', 'Epic': '⚔️', 'Piano Solo': '🎹', 'Violin': '🎻', 'Opera': '🎭',
    'Chamber': '🏛️', 'Symphony': '🎼', 'Baroque': '👑', 'Romantic Era': '💕', 'Contemporary Classical': '🆕',
    'Acoustic': '🪗', 'Ballad': '💝', 'Chill': '😌', 'Relax': '🧘', 'Sleep': '😴', 'Meditation': '🧘', 'Workout': '💪',
    'Party': '🎉', 'Romantic': '💕', 'Sad': '😢', 'Happy': '😊', 'Dark': '🌑', 'Mysterious': '🔮', 'Uplifting': '🌟', 'Nostalgic': '📼',
    'Pop Indo': '🇮🇩', 'Rock Indo': '🎸', 'Jazz Indo': '🎷', 'Keroncong': '🎸', 'Campursari': '🎵', 'Melayu': '🌺', 'Sunda': '🎶', 'Batak': '🏔️', 'Minang': '🏠', 'Jawa': '🏛️',
    '8-Bit': '👾', 'Chiptune': '🎮', 'Game OST': '🎮', 'Boss Battle': '👹', 'Adventure': '🗺️', 'RPG Theme': '⚔️', 'Retro Game': '🕹️', 'Cyberpunk': '🤖', 'Sci-Fi': '🚀',
    'Soundtrack': '🎬', 'Trailer Music': '📽️', 'Horror': '👻', 'Action': '💥', 'Drama': '🎭', 'Comedy': '😂', 'Documentary': '📹', 'Noir': '🖤', 'Western': '🤠',
    'Avant-Garde': '🎨', 'Noise': '📢', 'Industrial': '🏭', 'Glitch': '📺', 'IDM': '🧠', 'Drone': '〰️', 'Experimental': '🧪', 'Art Rock': '🎨', 'Math Rock': '🔢',
  };

  final List<Map<String, dynamic>> _moods = [
    {'id': 'Happy', 'icon': '😊', 'color': 0xFFFFD700},
    {'id': 'Sad', 'icon': '😢', 'color': 0xFF6B7280},
    {'id': 'Energetic', 'icon': '⚡', 'color': 0xFFEF4444},
    {'id': 'Romantic', 'icon': '💕', 'color': 0xFFEC4899},
    {'id': 'Chill', 'icon': '😌', 'color': 0xFF3B82F6},
    {'id': 'Epic', 'icon': '🔥', 'color': 0xFFF97316},
    {'id': 'Dark', 'icon': '🖤', 'color': 0xFF6366F1},
    {'id': 'Nostalgic', 'icon': '📼', 'color': 0xFF8B5CF6},
  ];

  final List<Map<String, String>> _tempos = [
    {'id': 'slow', 'name': 'Slow', 'bpm': '60-80', 'icon': '🐢'},
    {'id': 'medium', 'name': 'Medium', 'bpm': '80-120', 'icon': '🚶'},
    {'id': 'fast', 'name': 'Fast', 'bpm': '120-150', 'icon': '🏃'},
    {'id': 'very_fast', 'name': 'Hyper', 'bpm': '150+', 'icon': '⚡'},
  ];

  final List<Map<String, String>> _lyricThemes = [
    {'id': 'love', 'name': '💕 Cinta', 'prompt': 'tentang cinta dan kasih sayang'},
    {'id': 'breakup', 'name': '💔 Patah Hati', 'prompt': 'tentang putus cinta dan kesedihan'},
    {'id': 'motivation', 'name': '🔥 Motivasi', 'prompt': 'tentang semangat dan motivasi hidup'},
    {'id': 'party', 'name': '🎉 Party', 'prompt': 'tentang pesta dan bersenang-senang'},
    {'id': 'friendship', 'name': '🤝 Persahabatan', 'prompt': 'tentang teman dan persahabatan'},
    {'id': 'nature', 'name': '🌿 Alam', 'prompt': 'tentang keindahan alam'},
    {'id': 'dreams', 'name': '✨ Mimpi', 'prompt': 'tentang impian dan harapan'},
    {'id': 'life', 'name': '🌅 Kehidupan', 'prompt': 'tentang perjalanan hidup'},
  ];

  final Map<String, String> _lyricTemplates = {
    'love': '''[verse]
Saat pertama ku melihatmu
Hatiku berdebar tak karuan
Matamu yang indah memikat
Membuatku jatuh dalam pelukanmu

[chorus]
Kaulah cintaku, kaulah hidupku
Bersamamu selamanya
Tak akan ku lepas tanganmu
Kau yang tercinta''',
    'breakup': '''[verse]
Kau pergi tanpa kata
Meninggalkanku sendiri
Kenangan kita berdua
Kini hanya tinggal luka

[chorus]
Mengapa harus berakhir
Semua yang kita bangun
Air mata ini mengalir
Untuk cinta yang hilang''',
    'motivation': '''[verse]
Bangkit dari keterpurukan
Langkah mantap ke depan
Tak ada yang mustahil
Bila kita terus berjuang

[chorus]
Kita bisa! Kita mampu!
Raih mimpi setinggi langit
Jangan pernah menyerah
Terus melangkah maju''',
    'party': '''[verse]
Malam ini kita rayakan
Lupakan semua masalah
Musik menghentak keras
Goyang sampai pagi

[chorus]
Party all night long
Angkat tanganmu tinggi
Rasakan getaran ini
Kita berpesta!''',
    'friendship': '''[verse]
Kau selalu ada untukku
Di saat suka dan duka
Bersama kita lalui
Semua rintangan hidup

[chorus]
Sahabat selamanya
Takkan pernah terganti
Kau yang terbaik bagiku
Terima kasih kawan''',
    'nature': '''[verse]
Hembusan angin pagi
Menerpa wajahku lembut
Pepohonan menari
Burung berkicau merdu

[chorus]
Indahnya alam ini
Ciptaan yang sempurna
Kita harus jaga
Untuk anak cucu kita''',
    'dreams': '''[verse]
Ku punya mimpi besar
Ingin ku raih suatu hari
Tak peduli apa kata mereka
Aku akan terus bermimpi

[chorus]
Mimpi-mimpiku terbang tinggi
Melayang menembus awan
Suatu hari nanti
Akan jadi kenyataan''',
    'life': '''[verse]
Perjalanan hidup ini
Penuh liku dan tantangan
Tapi ku tak menyerah
Terus melangkah maju

[chorus]
Hidup adalah anugerah
Yang harus ku syukuri
Setiap detik berharga
Ku jalani dengan ikhlas''',
  };

  @override
  void dispose() {
    _titleController.dispose();
    _lyricsController.dispose();
    super.dispose();
  }

  void _toggleGenre(String genre) {
    setState(() {
      if (_selectedGenres.contains(genre)) {
        _selectedGenres.remove(genre);
      } else if (_selectedGenres.length < 3) {
        _selectedGenres.add(genre);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Maksimal 3 genre'), backgroundColor: Colors.orange),
        );
      }
    });
  }

  void _generateLyrics() {
    if (_lyricTheme == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih tema lirik dulu'), backgroundColor: Colors.orange),
      );
      return;
    }
    
    setState(() => _generatingLyrics = true);
    
    Future.delayed(const Duration(milliseconds: 1500), () {
      setState(() {
        _lyricsController.text = _lyricTemplates[_lyricTheme] ?? '';
        _generatingLyrics = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✨ Lirik berhasil dibuat!'), backgroundColor: Color(0xFF84CC16)),
      );
    });
  }

  Future<void> _generate() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan judul lagu'), backgroundColor: Colors.red),
      );
      return;
    }
    if (_selectedGenres.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih minimal 1 genre'), backgroundColor: Colors.red),
      );
      return;
    }
    if (!_isInstrumental && _lyricsController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan lirik atau aktifkan Instrumental'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isGenerating = true);

    final success = await context.read<MusicProvider>().generateMusic(
      title: _titleController.text,
      prompt: '${_selectedGenres.join(", ")} music, $_selectedMood mood, $_selectedTempo tempo${_isInstrumental ? ", instrumental" : ""}',
      lyrics: _isInstrumental ? '[Instrumental]' : _lyricsController.text,
      style: '${_selectedGenres.join(", ")}, $_selectedMood',
    );
    
    setState(() => _isGenerating = false);
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            const Expanded(child: Text('🎵 Musik sedang dibuat! Cek di tab Koleksi')),
          ]),
          backgroundColor: const Color(0xFF84CC16),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'LIHAT',
            textColor: Colors.black,
            onPressed: () {
              // Navigate to collection tab would be handled by parent
            },
          ),
        ),
      );
      _titleController.clear();
      _lyricsController.clear();
      setState(() {
        _selectedGenres = [];
        _step = 1;
        _lyricTheme = null;
      });
    } else if (!success && mounted) {
      final error = context.read<MusicProvider>().error ?? 'Gagal membuat musik';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error'), backgroundColor: Colors.red),
      );
      context.read<MusicProvider>().clearError();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: _buildStepContent(),
              ),
            ),
            _buildBottomButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.1))),
      ),
      child: Column(
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
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Buat Musik AI', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    Text('120+ genre tersedia', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  ],
                ),
              ),
              if (_selectedGenres.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF84CC16).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('${_selectedGenres.length}/3', style: const TextStyle(color: Color(0xFF84CC16), fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _StepDot(step: 1, current: _step, label: 'Genre'),
              Expanded(child: Container(height: 2, color: _step > 1 ? const Color(0xFF84CC16) : Colors.grey[800])),
              _StepDot(step: 2, current: _step, label: 'Detail'),
              Expanded(child: Container(height: 2, color: _step > 2 ? const Color(0xFF84CC16) : Colors.grey[800])),
              _StepDot(step: 3, current: _step, label: 'Lirik'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_step) {
      case 1: return _buildGenreStep();
      case 2: return _buildDetailStep();
      case 3: return _buildLyricsStep();
      default: return const SizedBox();
    }
  }

  Widget _buildGenreStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Selected genres
        if (_selectedGenres.isNotEmpty) ...[
          const Text('Genre Terpilih', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedGenres.map((g) => Chip(
              label: Text('${_genreIcons[g] ?? "🎵"} $g'),
              deleteIcon: const Icon(Icons.close, size: 16),
              onDeleted: () => _toggleGenre(g),
              backgroundColor: const Color(0xFF84CC16),
              labelStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            )).toList(),
          ),
          const SizedBox(height: 16),
        ],
        
        // Category tabs
        SizedBox(
          height: 44,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _genreCategories.length,
            itemBuilder: (context, i) {
              final cat = _genreCategories[i];
              final isActive = _activeCategory == cat['name'];
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _activeCategory = cat['name']),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: isActive ? const Color(0xFF84CC16) : const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: isActive ? const Color(0xFF84CC16) : Colors.grey[800]!),
                    ),
                    child: Row(
                      children: [
                        Text(cat['icon'], style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 6),
                        Text(cat['name'], style: TextStyle(
                          color: isActive ? Colors.black : Colors.white,
                          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                        )),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        
        // Genres grid
        ..._genreCategories.where((c) => c['name'] == _activeCategory).map((cat) {
          final genres = cat['genres'] as List<String>;
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: genres.map((genre) {
              final isSelected = _selectedGenres.contains(genre);
              return GestureDetector(
                onTap: () => _toggleGenre(genre),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF84CC16) : const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isSelected ? const Color(0xFF84CC16) : Colors.grey[700]!),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_genreIcons[genre] ?? '🎵', style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),
                      Text(genre, style: TextStyle(
                        color: isSelected ? Colors.black : Colors.white,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 13,
                      )),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        }),
      ],
    );
  }

  Widget _buildDetailStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Mood
        const Text('Pilih Mood', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 1),
          itemCount: _moods.length,
          itemBuilder: (context, i) {
            final mood = _moods[i];
            final isSelected = _selectedMood == mood['id'];
            return GestureDetector(
              onTap: () => setState(() => _selectedMood = mood['id']),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? Color(mood['color']).withOpacity(0.2) : const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isSelected ? Color(mood['color']) : Colors.grey[800]!, width: isSelected ? 2 : 1),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(mood['icon'], style: const TextStyle(fontSize: 24)),
                    const SizedBox(height: 4),
                    Text(mood['id'], style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 24),
        
        // Tempo
        const Text('Pilih Tempo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          children: _tempos.map((t) {
            final isSelected = _selectedTempo == t['id'];
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedTempo = t['id']!),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF84CC16).withOpacity(0.2) : const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isSelected ? const Color(0xFF84CC16) : Colors.grey[800]!),
                  ),
                  child: Column(
                    children: [
                      Text(t['icon']!, style: const TextStyle(fontSize: 20)),
                      const SizedBox(height: 4),
                      Text(t['name']!, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                      Text(t['bpm']!, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        
        // Instrumental toggle
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              const Text('🎹', style: TextStyle(fontSize: 24)),
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
              Switch(value: _isInstrumental, onChanged: (v) => setState(() => _isInstrumental = v), activeColor: const Color(0xFF84CC16)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLyricsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        const Text('Judul Lagu *', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
        
        if (!_isInstrumental) ...[
          const SizedBox(height: 24),
          
          // AI Lyrics Generator
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [const Color(0xFF84CC16).withOpacity(0.1), const Color(0xFF22C55E).withOpacity(0.1)]),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF84CC16).withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.auto_awesome, color: Color(0xFF84CC16), size: 20),
                    SizedBox(width: 8),
                    Text('AI Lyrics Generator', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _lyricThemes.map((t) {
                    final isSelected = _lyricTheme == t['id'];
                    return GestureDetector(
                      onTap: () => setState(() => _lyricTheme = t['id']),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF84CC16) : Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: isSelected ? const Color(0xFF84CC16) : Colors.grey[700]!),
                        ),
                        child: Text(t['name']!, style: TextStyle(color: isSelected ? Colors.black : Colors.white, fontSize: 12)),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _generatingLyrics ? null : _generateLyrics,
                    icon: _generatingLyrics ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.auto_awesome),
                    label: Text(_generatingLyrics ? 'Generating...' : 'Generate Lirik'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF84CC16),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Lyrics input
          const Text('Lirik *', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _lyricsController,
            maxLines: 12,
            decoration: InputDecoration(
              hintText: '[verse]\nTulis lirik di sini...\n\n[chorus]\nTulis chorus...',
              hintStyle: TextStyle(color: Colors.grey[600]),
              filled: true,
              fillColor: const Color(0xFF1A1A1A),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
        ],
        
        const SizedBox(height: 20),
        
        // Summary
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('📋 Ringkasan', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ..._selectedGenres.map((g) => _SummaryChip(icon: _genreIcons[g] ?? '🎵', label: g)),
                  _SummaryChip(icon: _moods.firstWhere((m) => m['id'] == _selectedMood)['icon'], label: _selectedMood),
                  _SummaryChip(icon: _tempos.firstWhere((t) => t['id'] == _selectedTempo)['icon']!, label: _tempos.firstWhere((t) => t['id'] == _selectedTempo)['name']!),
                  if (_isInstrumental) const _SummaryChip(icon: '🎹', label: 'Instrumental'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButtons() {
    return Container(
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
                  if (_step == 1 && _selectedGenres.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Pilih minimal 1 genre'), backgroundColor: Colors.orange),
                    );
                    return;
                  }
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
                        Text(_step < 3 ? 'Lanjut' : '🎵 Generate Musik', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  final int step;
  final int current;
  final String label;

  const _StepDot({required this.step, required this.current, required this.label});

  @override
  Widget build(BuildContext context) {
    final isActive = current >= step;
    final isDone = current > step;
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
            child: isDone
                ? const Icon(Icons.check, size: 18, color: Colors.black)
                : Text('$step', style: TextStyle(color: isActive ? Colors.black : Colors.grey, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 10, color: isActive ? const Color(0xFF84CC16) : Colors.grey)),
      ],
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String icon;
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
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
