import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/music_provider.dart';
import '../providers/player_provider.dart';
import '../models/generation.dart';

class CollectionScreen extends StatefulWidget {
  const CollectionScreen({super.key});

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MusicProvider>().loadGenerations();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Koleksi Musik', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                      Consumer<MusicProvider>(
                        builder: (context, music, _) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF84CC16).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${music.completed.length} lagu',
                              style: const TextStyle(color: Color(0xFF84CC16), fontWeight: FontWeight.bold),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Tabs
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: const Color(0xFF84CC16),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      labelColor: Colors.black,
                      unselectedLabelColor: Colors.grey,
                      labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                      tabs: const [
                        Tab(text: 'Semua'),
                        Tab(text: 'Favorit'),
                        Tab(text: 'Proses'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: Consumer<MusicProvider>(
                builder: (context, music, _) {
                  return TabBarView(
                    controller: _tabController,
                    children: [
                      _buildSongList(music.completed),
                      _buildSongList(music.completed.where((s) => s.isFavorite).toList()),
                      _buildSongList(music.generations.where((s) => s.status == 'processing').toList(), isProcessing: true),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSongList(List<Generation> songs, {bool isProcessing = false}) {
    if (songs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isProcessing ? Icons.hourglass_empty : Icons.library_music,
              size: 64,
              color: Colors.grey[700],
            ),
            const SizedBox(height: 16),
            Text(
              isProcessing ? 'Tidak ada yang diproses' : 'Tidak ada musik',
              style: TextStyle(color: Colors.grey[500], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFF84CC16),
      onRefresh: () => context.read<MusicProvider>().loadGenerations(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: songs.length,
        itemBuilder: (context, index) => _CollectionTile(
          song: songs[index],
          isProcessing: isProcessing,
        ),
      ),
    );
  }
}

class _CollectionTile extends StatelessWidget {
  final Generation song;
  final bool isProcessing;

  const _CollectionTile({required this.song, this.isProcessing = false});

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _OptionsSheet(song: song),
    );
  }

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
        leading: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 60,
                height: 60,
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
                    : const Icon(Icons.music_note, color: Color(0xFF84CC16), size: 30),
              ),
            ),
            if (isProcessing)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF84CC16)),
                    ),
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          song.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    song.style ?? 'AI',
                    style: TextStyle(color: Colors.grey[400], fontSize: 11),
                  ),
                ),
                if (song.isFavorite) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.favorite, size: 14, color: Colors.red),
                ],
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isProcessing) ...[
              // Play button
              GestureDetector(
                onTap: () {
                  if (isPlaying) {
                    player.togglePlay();
                  } else {
                    player.play(song);
                  }
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF84CC16),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Icon(
                    isPlaying && player.isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            // More options
            IconButton(
              icon: const Icon(Icons.more_vert, color: Colors.grey),
              onPressed: () => _showOptions(context),
            ),
          ],
        ),
        onTap: isProcessing ? null : () => player.play(song),
      ),
    );
  }
}

class _OptionsSheet extends StatelessWidget {
  final Generation song;

  const _OptionsSheet({required this.song});

  @override
  Widget build(BuildContext context) {
    final music = context.read<MusicProvider>();
    
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[700],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
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
                    Text(song.style ?? 'AI Music', style: TextStyle(color: Colors.grey[400])),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Options
          _OptionTile(
            icon: song.isFavorite ? Icons.favorite : Icons.favorite_border,
            iconColor: song.isFavorite ? Colors.red : Colors.grey,
            title: song.isFavorite ? 'Hapus dari Favorit' : 'Tambah ke Favorit',
            onTap: () {
              music.toggleFavorite(song.id);
              Navigator.pop(context);
            },
          ),
          
          if (song.lyrics != null && song.lyrics!.isNotEmpty) ...[
            _OptionTile(
              icon: Icons.lyrics,
              title: 'Lihat Lirik',
              onTap: () {
                Navigator.pop(context);
                _showLyricsDialog(context);
              },
            ),
            _OptionTile(
              icon: Icons.copy,
              title: 'Salin Lirik',
              onTap: () {
                Clipboard.setData(ClipboardData(text: song.lyrics!));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Lirik disalin!'), backgroundColor: Color(0xFF84CC16)),
                );
              },
            ),
            _OptionTile(
              icon: Icons.download,
              title: 'Download Lirik (.txt)',
              onTap: () {
                Navigator.pop(context);
                _downloadLyrics(context);
              },
            ),
          ],
          
          _OptionTile(
            icon: Icons.delete_outline,
            iconColor: Colors.red,
            title: 'Hapus',
            onTap: () {
              Navigator.pop(context);
              _confirmDelete(context);
            },
          ),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _showLyricsDialog(BuildContext context) {
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
                  const Text('Lirik', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              Flexible(
                child: SingleChildScrollView(
                  child: Text(
                    song.lyrics ?? '',
                    style: const TextStyle(fontSize: 16, height: 1.8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _downloadLyrics(BuildContext context) {
    // For now, just copy to clipboard with formatted text
    final content = '''
${song.title}
${song.style ?? 'AI Music'}
==================

${song.lyrics}
''';
    Clipboard.setData(ClipboardData(text: content));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            const Expanded(child: Text('Lirik disalin! Paste ke notepad untuk simpan.')),
          ],
        ),
        backgroundColor: const Color(0xFF84CC16),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Musik?'),
        content: Text('Yakin hapus "${song.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<MusicProvider>().delete(song.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    this.iconColor,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? Colors.white),
      title: Text(title),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
