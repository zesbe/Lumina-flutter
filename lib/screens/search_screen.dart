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
  String _filter = 'all'; // all, favorites, recent

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
            // Search header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                border: Border(
                  bottom: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pencarian',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  // Search bar
                  TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                    decoration: InputDecoration(
                      hintText: 'Cari musik, artis, genre...',
                      hintStyle: TextStyle(color: Colors.grey[500]),
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Filter chips
                  Row(
                    children: [
                      _FilterChip(
                        label: 'Semua',
                        isSelected: _filter == 'all',
                        onTap: () => setState(() => _filter = 'all'),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Favorit',
                        isSelected: _filter == 'favorites',
                        onTap: () => setState(() => _filter = 'favorites'),
                        icon: Icons.favorite,
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Terbaru',
                        isSelected: _filter == 'recent',
                        onTap: () => setState(() => _filter = 'recent'),
                        icon: Icons.access_time,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Results
            Expanded(
              child: Consumer<MusicProvider>(
                builder: (context, music, _) {
                  var songs = music.completed;
                  
                  // Apply filter
                  if (_filter == 'favorites') {
                    songs = songs.where((s) => s.isFavorite).toList();
                  } else if (_filter == 'recent') {
                    songs = songs.take(10).toList();
                  }
                  
                  // Apply search
                  if (_searchQuery.isNotEmpty) {
                    songs = songs.where((s) =>
                      s.title.toLowerCase().contains(_searchQuery) ||
                      (s.style?.toLowerCase().contains(_searchQuery) ?? false) ||
                      (s.lyrics?.toLowerCase().contains(_searchQuery) ?? false)
                    ).toList();
                  }

                  if (songs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, size: 64, color: Colors.grey[700]),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isEmpty ? 'Tidak ada musik' : 'Tidak ditemukan',
                            style: TextStyle(color: Colors.grey[500], fontSize: 16),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: songs.length,
                    itemBuilder: (context, index) => _SearchResultTile(song: songs[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? icon;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF84CC16) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: isSelected ? Colors.black : Colors.grey),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
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
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isPlaying ? const Color(0xFF84CC16).withOpacity(0.1) : const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPlaying ? const Color(0xFF84CC16).withOpacity(0.3) : Colors.transparent,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF84CC16).withOpacity(0.3), const Color(0xFF22C55E).withOpacity(0.3)],
              ),
            ),
            child: song.fullThumbnailUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: song.fullThumbnailUrl,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => const Icon(Icons.music_note, color: Color(0xFF84CC16)),
                  )
                : const Icon(Icons.music_note, color: Color(0xFF84CC16)),
          ),
        ),
        title: Text(
          song.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            Text(song.style ?? 'AI Music', style: TextStyle(color: Colors.grey[400], fontSize: 13)),
            if (song.isFavorite) ...[
              const SizedBox(width: 8),
              const Icon(Icons.favorite, size: 14, color: Colors.red),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                isPlaying && player.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                color: const Color(0xFF84CC16),
                size: 40,
              ),
              onPressed: () {
                if (isPlaying) {
                  player.togglePlay();
                } else {
                  player.play(song);
                }
              },
            ),
          ],
        ),
        onTap: () => player.play(song),
      ),
    );
  }
}
