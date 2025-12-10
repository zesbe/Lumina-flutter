import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/api_service.dart';
import '../providers/player_provider.dart';
import '../models/generation.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  List<Generation> _publicSongs = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPublicSongs();
  }

  Future<void> _loadPublicSongs() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await ApiService.getExplore(type: 'music', limit: 50);
      setState(() {
        _publicSongs = data.map((json) => Generation.fromJson(json)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.explore, color: Color(0xFF84CC16), size: 28),
                      const SizedBox(width: 12),
                      const Text('Explore', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Temukan musik dari kreator lain',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF84CC16)))
                  : _error != null
                      ? _buildError()
                      : _publicSongs.isEmpty
                          ? _buildEmpty()
                          : _buildSongList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          const Text('Gagal memuat', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(_error ?? 'Unknown error', style: TextStyle(color: Colors.grey[500])),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadPublicSongs,
            icon: const Icon(Icons.refresh),
            label: const Text('Coba Lagi'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF84CC16)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
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
            child: const Icon(Icons.music_off, size: 48, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          const Text('Belum ada musik publik', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            'Jadilah yang pertama membagikan musikmu!',
            style: TextStyle(color: Colors.grey[500]),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadPublicSongs,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF84CC16)),
          ),
        ],
      ),
    );
  }

  Widget _buildSongList() {
    return RefreshIndicator(
      onRefresh: _loadPublicSongs,
      color: const Color(0xFF84CC16),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _publicSongs.length,
        itemBuilder: (context, index) {
          final song = _publicSongs[index];
          return _PublicSongCard(song: song);
        },
      ),
    );
  }
}

class _PublicSongCard extends StatelessWidget {
  final Generation song;

  const _PublicSongCard({required this.song});

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    final isPlaying = player.currentSong?.id == song.id && player.isPlaying;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isPlaying
              ? [const Color(0xFF84CC16).withOpacity(0.2), const Color(0xFF22C55E).withOpacity(0.1)]
              : [const Color(0xFF1A1A1A), const Color(0xFF1A1A1A)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPlaying ? const Color(0xFF84CC16).withOpacity(0.5) : Colors.white.withOpacity(0.05),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Album Art
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 64,
                height: 64,
                color: const Color(0xFF84CC16).withOpacity(0.2),
                child: song.fullThumbnailUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: song.fullThumbnailUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => const Icon(Icons.music_note, color: Color(0xFF84CC16)),
                        errorWidget: (_, __, ___) => const Icon(Icons.music_note, color: Color(0xFF84CC16)),
                      )
                    : const Icon(Icons.music_note, color: Color(0xFF84CC16), size: 32),
              ),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.person, size: 14, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          song.creatorName ?? 'Unknown Creator',
                          style: TextStyle(color: Colors.grey[500], fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF84CC16).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          song.displayGenre,
                          style: const TextStyle(color: Color(0xFF84CC16), fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.public, size: 12, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text('Public', style: TextStyle(color: Colors.grey[600], fontSize: 10)),
                    ],
                  ),
                ],
              ),
            ),

            // Play Button
            GestureDetector(
              onTap: () {
                if (isPlaying) {
                  player.togglePlay();
                } else {
                  player.setPlaylist([song]);
                  player.play(song);
                }
              },
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF84CC16), Color(0xFF22C55E)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF84CC16).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.black,
                  size: 28,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
