import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/player_provider.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    final song = player.currentSong;
    
    if (song == null) return const SizedBox();

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF84CC16).withOpacity(0.3),
                    const Color(0xFF22C55E).withOpacity(0.3),
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
          const SizedBox(width: 12),
          
          // Song info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  song.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  song.style ?? 'AI Music',
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  maxLines: 1,
                ),
              ],
            ),
          ),
          
          // Controls
          IconButton(
            icon: const Icon(Icons.skip_previous),
            onPressed: () => player.playPrevious(),
            color: Colors.white,
          ),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF84CC16),
              borderRadius: BorderRadius.circular(24),
            ),
            child: IconButton(
              icon: Icon(
                player.isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.black,
              ),
              onPressed: () => player.togglePlay(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.skip_next),
            onPressed: () => player.playNext(),
            color: Colors.white,
          ),
        ],
      ),
    );
  }
}
