import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/music_provider.dart';
import '../providers/player_provider.dart';
import '../models/generation.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _showLyrics = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MusicProvider>().loadGenerations();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MusicProvider>(
      builder: (context, musicProvider, _) {
        if (musicProvider.isLoading && musicProvider.generations.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Color(0xFF84CC16)),
                SizedBox(height: 16),
                Text('Memuat musik...', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        final songs = musicProvider.completed;
        
        if (songs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF84CC16).withOpacity(0.2), Color(0xFF22C55E).withOpacity(0.2)],
                    ),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: const Icon(Icons.music_note, size: 50, color: Color(0xFF84CC16)),
                ),
                const SizedBox(height: 24),
                const Text('Belum ada musik', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Buat musik pertamamu!', style: TextStyle(color: Colors.grey[400])),
              ],
            ),
          );
        }

        context.read<PlayerProvider>().setPlaylist(songs);

        return Stack(
          children: [
            RefreshIndicator(
              color: const Color(0xFF84CC16),
              onRefresh: () => musicProvider.loadGenerations(),
              child: PageView.builder(
                controller: _pageController,
                scrollDirection: Axis.vertical,
                itemCount: songs.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                    _showLyrics = false;
                  });
                  context.read<PlayerProvider>().play(songs[index]);
                },
                itemBuilder: (context, index) {
                  return _SongCard(
                    song: songs[index],
                    index: index,
                    showLyrics: _showLyrics && _currentPage == index,
                    onToggleLyrics: () => setState(() => _showLyrics = !_showLyrics),
                  );
                },
              ),
            ),
            // Page indicator
            Positioned(
              right: 16,
              top: MediaQuery.of(context).padding.top + 60,
              child: Column(
                children: List.generate(
                  songs.length > 5 ? 5 : songs.length,
                  (i) {
                    final idx = _currentPage > 2 ? _currentPage - 2 + i : i;
                    if (idx >= songs.length) return const SizedBox();
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      width: 4,
                      height: idx == _currentPage ? 20 : 8,
                      decoration: BoxDecoration(
                        color: idx == _currentPage ? const Color(0xFF84CC16) : Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SongCard extends StatelessWidget {
  final Generation song;
  final int index;
  final bool showLyrics;
  final VoidCallback onToggleLyrics;

  const _SongCard({
    required this.song,
    required this.index,
    required this.showLyrics,
    required this.onToggleLyrics,
  });

  static const _gradients = [
    [Color(0xFF6366F1), Color(0xFF8B5CF6)],
    [Color(0xFFF97316), Color(0xFFEAB308)],
    [Color(0xFFEC4899), Color(0xFFF43F5E)],
    [Color(0xFF22C55E), Color(0xFF14B8A6)],
    [Color(0xFF3B82F6), Color(0xFF06B6D4)],
    [Color(0xFF8B5CF6), Color(0xFFEC4899)],
  ];

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    final music = context.watch<MusicProvider>();
    final isPlaying = player.currentSong?.id == song.id && player.isPlaying;
    final gradient = _gradients[index % _gradients.length];

    return GestureDetector(
      onDoubleTap: () => music.toggleFavorite(song.id),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradient,
              ),
            ),
          ),
          
          // Album art overlay
          if (song.fullThumbnailUrl.isNotEmpty)
            Opacity(
              opacity: 0.4,
              child: CachedNetworkImage(
                imageUrl: song.fullThumbnailUrl,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => const SizedBox(),
              ),
            ),
          
          // Dark gradient overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.transparent,
                  Colors.black.withOpacity(0.8),
                ],
                stops: const [0.0, 0.3, 1.0],
              ),
            ),
          ),

          // Lyrics overlay
          if (showLyrics && song.lyrics != null && song.lyrics!.isNotEmpty)
            Container(
              color: Colors.black.withOpacity(0.85),
              padding: const EdgeInsets.all(24),
              child: Center(
                child: SingleChildScrollView(
                  child: Text(
                    song.lyrics!,
                    style: const TextStyle(fontSize: 18, height: 1.8),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          
          // Content
          SafeArea(
            child: Column(
              children: [
                // Top bar
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.auto_awesome, size: 14, color: Color(0xFF84CC16)),
                            SizedBox(width: 4),
                            Text('AI Music', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${index + 1}',
                        style: TextStyle(color: Colors.white.withOpacity(0.5)),
                      ),
                    ],
                  ),
                ),
                
                const Spacer(),
                
                // Song info & controls
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        song.title,
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      
                      // Style/Genre
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              song.style ?? 'AI Music',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            song.isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: song.isFavorite ? Colors.red : Colors.white,
                            size: 20,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // Progress bar
                      Column(
                        children: [
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 4,
                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                              activeTrackColor: const Color(0xFF84CC16),
                              inactiveTrackColor: Colors.white.withOpacity(0.2),
                              thumbColor: Colors.white,
                            ),
                            child: Slider(
                              value: player.progress.clamp(0.0, 1.0),
                              onChanged: (v) => player.seek(v),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(_formatDuration(player.position), style: TextStyle(fontSize: 12, color: Colors.white70)),
                                Text(_formatDuration(player.duration), style: TextStyle(fontSize: 12, color: Colors.white70)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Controls
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Lyrics button
                          IconButton(
                            icon: Icon(showLyrics ? Icons.lyrics : Icons.lyrics_outlined),
                            color: showLyrics ? const Color(0xFF84CC16) : Colors.white,
                            iconSize: 28,
                            onPressed: onToggleLyrics,
                          ),
                          // Previous
                          IconButton(
                            icon: const Icon(Icons.skip_previous_rounded),
                            color: Colors.white,
                            iconSize: 36,
                            onPressed: () => player.playPrevious(),
                          ),
                          // Play/Pause
                          GestureDetector(
                            onTap: () {
                              if (player.currentSong?.id == song.id) {
                                player.togglePlay();
                              } else {
                                player.play(song);
                              }
                            },
                            child: Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(36),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 20,
                                  ),
                                ],
                              ),
                              child: Icon(
                                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                color: Colors.black,
                                size: 40,
                              ),
                            ),
                          ),
                          // Next
                          IconButton(
                            icon: const Icon(Icons.skip_next_rounded),
                            color: Colors.white,
                            iconSize: 36,
                            onPressed: () => player.playNext(),
                          ),
                          // Favorite
                          IconButton(
                            icon: Icon(song.isFavorite ? Icons.favorite : Icons.favorite_border),
                            color: song.isFavorite ? Colors.red : Colors.white,
                            iconSize: 28,
                            onPressed: () => music.toggleFavorite(song.id),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 80), // Space for bottom nav
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
