import 'package:flutter/material.dart';
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

class _CollectionScreenState extends State<CollectionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MusicProvider>().loadGenerations();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Koleksi', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Consumer<MusicProvider>(
        builder: (context, musicProvider, _) {
          if (musicProvider.isLoading && musicProvider.generations.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final songs = musicProvider.completed;

          if (songs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('📚', style: TextStyle(fontSize: 64)),
                  const SizedBox(height: 16),
                  Text(
                    'Koleksi kosong',
                    style: TextStyle(color: Colors.grey[400], fontSize: 18),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => musicProvider.loadGenerations(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: songs.length,
              itemBuilder: (context, index) {
                return _SongTile(song: songs[index]);
              },
            ),
          );
        },
      ),
    );
  }
}

class _SongTile extends StatelessWidget {
  final Generation song;

  const _SongTile({required this.song});

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    final isPlaying = player.currentSong?.id == song.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isPlaying 
            ? const Color(0xFF84CC16).withOpacity(0.1)
            : const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPlaying 
              ? const Color(0xFF84CC16).withOpacity(0.3)
              : Colors.white.withOpacity(0.05),
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
                colors: [
                  const Color(0xFF84CC16).withOpacity(0.2),
                  const Color(0xFF22C55E).withOpacity(0.2),
                ],
              ),
            ),
            child: song.fullThumbnailUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: song.fullThumbnailUrl,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => const Icon(Icons.music_note),
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
        subtitle: Text(
          song.style ?? 'AI Music',
          style: TextStyle(color: Colors.grey[400], fontSize: 13),
        ),
        trailing: IconButton(
          icon: Icon(
            isPlaying && player.isPlaying ? Icons.pause : Icons.play_arrow,
            color: const Color(0xFF84CC16),
          ),
          onPressed: () {
            if (isPlaying) {
              context.read<PlayerProvider>().togglePlay();
            } else {
              context.read<PlayerProvider>().play(song);
            }
          },
        ),
        onTap: () => context.read<PlayerProvider>().play(song),
      ),
    );
  }
}
