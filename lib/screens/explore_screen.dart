import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
                  Text('Temukan musik dari kreator lain', style: TextStyle(color: Colors.grey[500])),
                ],
              ),
            ),
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
            decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(50)),
            child: const Icon(Icons.music_off, size: 48, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          const Text('Belum ada musik publik', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Jadilah yang pertama membagikan musikmu!', style: TextStyle(color: Colors.grey[500])),
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
          return _PublicSongCard(
            song: song,
            onTap: () => _showSongOptions(song),
          );
        },
      ),
    );
  }

  void _showSongOptions(Generation song) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _SongOptionsSheet(song: song),
    );
  }
}

class _PublicSongCard extends StatelessWidget {
  final Generation song;
  final VoidCallback onTap;

  const _PublicSongCard({required this.song, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    final isPlaying = player.currentSong?.id == song.id && player.isPlaying;

    return GestureDetector(
      onTap: onTap,
      child: Container(
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(song.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.person, size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(song.creatorName ?? 'Unknown', style: TextStyle(color: Colors.grey[500], fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: const Color(0xFF84CC16).withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                          child: Text(song.displayGenre, style: const TextStyle(color: Color(0xFF84CC16), fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  final player = context.read<PlayerProvider>();
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
                    gradient: const LinearGradient(colors: [Color(0xFF84CC16), Color(0xFF22C55E)]),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Icon(isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.black, size: 28),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SongOptionsSheet extends StatelessWidget {
  final Generation song;

  const _SongOptionsSheet({required this.song});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[700], borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          
          // Song info
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 60,
                  height: 60,
                  color: const Color(0xFF84CC16).withOpacity(0.2),
                  child: song.fullThumbnailUrl.isNotEmpty
                      ? CachedNetworkImage(imageUrl: song.fullThumbnailUrl, fit: BoxFit.cover)
                      : const Icon(Icons.music_note, color: Color(0xFF84CC16)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(song.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('by ${song.creatorName ?? "Unknown"}', style: TextStyle(color: Colors.grey[400])),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Play button
          _OptionTile(
            icon: Icons.play_circle_fill,
            iconColor: const Color(0xFF84CC16),
            title: '▶️ Putar Musik',
            onTap: () {
              Navigator.pop(context);
              final player = context.read<PlayerProvider>();
              player.setPlaylist([song]);
              player.play(song);
            },
          ),
          
          // View Lyrics
          _OptionTile(
            icon: Icons.lyrics,
            title: '📜 Lihat Lirik',
            onTap: () {
              Navigator.pop(context);
              _showLyrics(context, song);
            },
          ),
          
          // Download
          _OptionTile(
            icon: Icons.download,
            title: '📥 Download Musik',
            subtitle: 'Salin link ke clipboard',
            onTap: () {
              Clipboard.setData(ClipboardData(text: song.fullOutputUrl));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Link musik disalin! Paste di browser untuk download'),
                  backgroundColor: Color(0xFF84CC16),
                ),
              );
            },
          ),
          
          // Share
          _OptionTile(
            icon: Icons.share,
            title: '📤 Bagikan',
            onTap: () {
              Clipboard.setData(ClipboardData(
                text: 'Dengarkan "${song.title}" oleh ${song.creatorName ?? "Unknown"} di Lumina AI!\n${song.fullOutputUrl}',
              ));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Link dibagikan!'), backgroundColor: Color(0xFF84CC16)),
              );
            },
          ),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _showLyrics(BuildContext context, Generation song) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(20),
          constraints: const BoxConstraints(maxHeight: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.lyrics, color: Color(0xFF84CC16)),
                      const SizedBox(width: 8),
                      const Text('Lirik', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const Divider(),
              Flexible(
                child: SingleChildScrollView(
                  child: Text(
                    song.cleanedLyrics.isEmpty ? 'Tidak ada lirik' : song.cleanedLyrics,
                    style: const TextStyle(fontSize: 16, height: 1.8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (song.cleanedLyrics.isNotEmpty)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: song.cleanedLyrics));
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Lirik disalin!'), backgroundColor: Color(0xFF84CC16)),
                          );
                        },
                        icon: const Icon(Icons.copy, size: 18),
                        label: const Text('Salin Lirik'),
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: BorderSide(color: Colors.grey[700]!)),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _OptionTile({required this.icon, this.iconColor, required this.title, this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: (iconColor ?? const Color(0xFF84CC16)).withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor ?? const Color(0xFF84CC16), size: 20),
      ),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!, style: TextStyle(color: Colors.grey[500], fontSize: 12)) : null,
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
