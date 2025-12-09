import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/music_provider.dart';
import '../providers/player_provider.dart';
import '../models/generation.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;

  final List<Map<String, dynamic>> _quickGenres = [
    {'name': 'Pop', 'icon': '🎤', 'color': 0xFFEC4899},
    {'name': 'Hip Hop', 'icon': '🎧', 'color': 0xFF8B5CF6},
    {'name': 'Rock', 'icon': '🎸', 'color': 0xFFEF4444},
    {'name': 'EDM', 'icon': '🎹', 'color': 0xFF06B6D4},
    {'name': 'Jazz', 'icon': '🎷', 'color': 0xFFF59E0B},
    {'name': 'Lo-Fi', 'icon': '🌙', 'color': 0xFF6366F1},
    {'name': 'K-Pop', 'icon': '💜', 'color': 0xFFA855F7},
    {'name': 'Dangdut', 'icon': '🇮🇩', 'color': 0xFF22C55E},
  ];

  final List<Map<String, dynamic>> _moods = [
    {'name': 'Chill', 'icon': '😌', 'gradient': [0xFF3B82F6, 0xFF06B6D4]},
    {'name': 'Energetic', 'icon': '⚡', 'gradient': [0xFFEF4444, 0xFFF97316]},
    {'name': 'Romantic', 'icon': '💕', 'gradient': [0xFFEC4899, 0xFFF43F5E]},
    {'name': 'Focus', 'icon': '🎯', 'gradient': [0xFF8B5CF6, 0xFF6366F1]},
    {'name': 'Sleep', 'icon': '😴', 'gradient': [0xFF1E3A8A, 0xFF312E81]},
    {'name': 'Workout', 'icon': '💪', 'gradient': [0xFF84CC16, 0xFF22C55E]},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Search Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0D0D0D),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Jelajahi', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Temukan musik yang kamu suka', style: TextStyle(color: Colors.grey[500])),
                  const SizedBox(height: 16),
                  // Search Bar
                  GestureDetector(
                    onTap: () => setState(() => _isSearching = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.search, color: Colors.grey[500]),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _isSearching
                                ? TextField(
                                    controller: _searchController,
                                    autofocus: true,
                                    onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                                    decoration: InputDecoration(
                                      hintText: 'Cari lagu, genre, mood...',
                                      hintStyle: TextStyle(color: Colors.grey[600]),
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                    style: const TextStyle(fontSize: 16),
                                  )
                                : Text('Cari lagu, genre, mood...', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                          ),
                          if (_isSearching && _searchQuery.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                  _isSearching = false;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.grey[800],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.close, size: 16, color: Colors.white),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: _searchQuery.isNotEmpty ? _buildSearchResults() : _buildDiscoverContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscoverContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick Actions
          Row(
            children: [
              Expanded(child: _QuickActionCard(
                icon: Icons.shuffle,
                title: 'Acak',
                subtitle: 'Putar random',
                gradient: const [Color(0xFF84CC16), Color(0xFF22C55E)],
                onTap: () => _playRandom(),
              )),
              const SizedBox(width: 12),
              Expanded(child: _QuickActionCard(
                icon: Icons.favorite,
                title: 'Favorit',
                subtitle: 'Lagu tersimpan',
                gradient: const [Color(0xFFEC4899), Color(0xFFF43F5E)],
                onTap: () => _playFavorites(),
              )),
            ],
          ),
          const SizedBox(height: 24),
          
          // Genre Shortcuts
          const Text('Genre Populer', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _quickGenres.length,
              itemBuilder: (context, i) {
                final genre = _quickGenres[i];
                return Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: _GenreCard(
                    name: genre['name'],
                    icon: genre['icon'],
                    color: Color(genre['color']),
                    onTap: () => _searchByGenre(genre['name']),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          
          // Mood Playlists
          const Text('Berdasarkan Mood', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.8,
            ),
            itemCount: _moods.length,
            itemBuilder: (context, i) {
              final mood = _moods[i];
              return _MoodCard(
                name: mood['name'],
                icon: mood['icon'],
                gradient: (mood['gradient'] as List<int>).map((c) => Color(c)).toList(),
                onTap: () => _searchByMood(mood['name']),
              );
            },
          ),
          const SizedBox(height: 24),
          
          // Recent Songs
          Consumer<MusicProvider>(
            builder: (context, music, _) {
              final recent = music.completed.take(5).toList();
              if (recent.isEmpty) return const SizedBox();
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Baru Dibuat', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      TextButton(
                        onPressed: () {},
                        child: const Text('Lihat Semua', style: TextStyle(color: Color(0xFF84CC16))),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...recent.map((song) => _RecentSongTile(song: song)),
                ],
              );
            },
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    return Consumer<MusicProvider>(
      builder: (context, music, _) {
        var results = music.completed.where((s) =>
          s.title.toLowerCase().contains(_searchQuery) ||
          (s.style?.toLowerCase().contains(_searchQuery) ?? false) ||
          (s.lyrics?.toLowerCase().contains(_searchQuery) ?? false)
        ).toList();

        // Also search in genres
        final matchedGenres = _quickGenres.where((g) => 
          g['name'].toString().toLowerCase().contains(_searchQuery)
        ).toList();

        final matchedMoods = _moods.where((m) => 
          m['name'].toString().toLowerCase().contains(_searchQuery)
        ).toList();

        if (results.isEmpty && matchedGenres.isEmpty && matchedMoods.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: const Icon(Icons.search_off, size: 48, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                const Text('Tidak ditemukan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Coba kata kunci lain', style: TextStyle(color: Colors.grey[500])),
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Matched Genres
            if (matchedGenres.isNotEmpty) ...[
              const Text('Genre', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: matchedGenres.map((g) => ActionChip(
                  avatar: Text(g['icon']),
                  label: Text(g['name']),
                  backgroundColor: Color(g['color']).withOpacity(0.2),
                  onPressed: () => _searchByGenre(g['name']),
                )).toList(),
              ),
              const SizedBox(height: 16),
            ],

            // Matched Moods
            if (matchedMoods.isNotEmpty) ...[
              const Text('Mood', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: matchedMoods.map((m) => ActionChip(
                  avatar: Text(m['icon']),
                  label: Text(m['name']),
                  backgroundColor: Color((m['gradient'] as List<int>)[0]).withOpacity(0.2),
                  onPressed: () => _searchByMood(m['name']),
                )).toList(),
              ),
              const SizedBox(height: 16),
            ],

            // Songs
            if (results.isNotEmpty) ...[
              Text('Lagu (${results.length})', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 8),
              ...results.map((song) => _SearchResultTile(song: song)),
            ],
          ],
        );
      },
    );
  }

  void _playRandom() {
    final music = context.read<MusicProvider>();
    final player = context.read<PlayerProvider>();
    final songs = music.completed;
    if (songs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Belum ada musik'), backgroundColor: Colors.orange),
      );
      return;
    }
    songs.shuffle();
    player.setPlaylist(songs);
    player.play(songs.first);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('🔀 Memutar secara acak'), backgroundColor: Color(0xFF84CC16)),
    );
  }

  void _playFavorites() {
    final music = context.read<MusicProvider>();
    final player = context.read<PlayerProvider>();
    final favorites = music.completed.where((s) => s.isFavorite).toList();
    if (favorites.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Belum ada favorit'), backgroundColor: Colors.orange),
      );
      return;
    }
    player.setPlaylist(favorites);
    player.play(favorites.first);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('❤️ Memutar ${favorites.length} lagu favorit'), backgroundColor: const Color(0xFF84CC16)),
    );
  }

  void _searchByGenre(String genre) {
    setState(() {
      _searchQuery = genre.toLowerCase();
      _searchController.text = genre;
      _isSearching = true;
    });
  }

  void _searchByMood(String mood) {
    setState(() {
      _searchQuery = mood.toLowerCase();
      _searchController.text = mood;
      _isSearching = true;
    });
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradient),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: gradient[0].withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GenreCard extends StatelessWidget {
  final String name;
  final String icon;
  final Color color;
  final VoidCallback onTap;

  const _GenreCard({required this.name, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 85,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 6),
            Text(name, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _MoodCard extends StatelessWidget {
  final String name;
  final String icon;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _MoodCard({required this.name, required this.icon, required this.gradient, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradient,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 10),
            Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}

class _RecentSongTile extends StatelessWidget {
  final Generation song;

  const _RecentSongTile({required this.song});

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    final isPlaying = player.currentSong?.id == song.id && player.isPlaying;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        tileColor: isPlaying ? const Color(0xFF84CC16).withOpacity(0.1) : const Color(0xFF1A1A1A),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 48,
            height: 48,
            color: const Color(0xFF84CC16).withOpacity(0.2),
            child: song.fullThumbnailUrl.isNotEmpty
                ? CachedNetworkImage(imageUrl: song.fullThumbnailUrl, fit: BoxFit.cover)
                : const Icon(Icons.music_note, color: Color(0xFF84CC16)),
          ),
        ),
        title: Text(song.title, style: const TextStyle(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(song.style ?? 'AI Music', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
        trailing: IconButton(
          icon: Icon(isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled, color: const Color(0xFF84CC16), size: 36),
          onPressed: () {
            if (isPlaying) {
              player.togglePlay();
            } else {
              player.play(song);
            }
          },
        ),
        onTap: () => player.play(song),
      ),
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  final Generation song;

  const _SearchResultTile({required this.song});

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    final isPlaying = player.currentSong?.id == song.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isPlaying ? const Color(0xFF84CC16).withOpacity(0.1) : const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isPlaying ? const Color(0xFF84CC16).withOpacity(0.3) : Colors.transparent),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(8),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 52,
            height: 52,
            color: const Color(0xFF84CC16).withOpacity(0.2),
            child: song.fullThumbnailUrl.isNotEmpty
                ? CachedNetworkImage(imageUrl: song.fullThumbnailUrl, fit: BoxFit.cover)
                : const Icon(Icons.music_note, color: Color(0xFF84CC16)),
          ),
        ),
        title: Text(song.title, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(song.style ?? 'AI', style: TextStyle(color: Colors.grey[400], fontSize: 10)),
            ),
            if (song.isFavorite) ...[
              const SizedBox(width: 6),
              const Icon(Icons.favorite, size: 12, color: Colors.red),
            ],
          ],
        ),
        trailing: GestureDetector(
          onTap: () {
            if (isPlaying) {
              player.togglePlay();
            } else {
              player.play(song);
            }
          },
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF84CC16),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(isPlaying && player.isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.black),
          ),
        ),
        onTap: () => player.play(song),
      ),
    );
  }
}
