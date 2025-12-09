import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/player_provider.dart';
import '../providers/music_provider.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    final song = player.currentSong;
    
    if (song == null) return const SizedBox();

    return GestureDetector(
      onTap: () => _showFullPlayer(context),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [const Color(0xFF1A1A1A), const Color(0xFF252525)],
          ),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Spinning disc
                  _SpinningDisc(
                    imageUrl: song.fullThumbnailUrl,
                    isPlaying: player.isPlaying,
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
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          song.style ?? 'AI Music',
                          style: TextStyle(color: Colors.grey[400], fontSize: 12),
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                  
                  // Controls
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.skip_previous_rounded),
                        onPressed: () => player.playPrevious(),
                        color: Colors.white,
                        iconSize: 28,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                      ),
                      GestureDetector(
                        onTap: () => player.togglePlay(),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF84CC16), Color(0xFF22C55E)],
                            ),
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Icon(
                            player.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                            color: Colors.black,
                            size: 28,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.skip_next_rounded),
                        onPressed: () => player.playNext(),
                        color: Colors.white,
                        iconSize: 28,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Progress bar
            Container(
              height: 3,
              margin: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: player.progress.clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF84CC16), Color(0xFF22C55E)],
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  void _showFullPlayer(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _FullPlayerSheet(),
    );
  }
}

class _SpinningDisc extends StatefulWidget {
  final String imageUrl;
  final bool isPlaying;

  const _SpinningDisc({required this.imageUrl, required this.isPlaying});

  @override
  State<_SpinningDisc> createState() => _SpinningDiscState();
}

class _SpinningDiscState extends State<_SpinningDisc> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    );
    if (widget.isPlaying) _controller.repeat();
  }

  @override
  void didUpdateWidget(_SpinningDisc oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.isPlaying && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.rotate(
          angle: _controller.value * 2 * 3.14159,
          child: child,
        );
      },
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF84CC16), width: 2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF84CC16).withOpacity(0.3),
              blurRadius: 8,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: widget.imageUrl.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: widget.imageUrl,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => _defaultIcon(),
                )
              : _defaultIcon(),
        ),
      ),
    );
  }

  Widget _defaultIcon() {
    return Container(
      color: const Color(0xFF84CC16).withOpacity(0.2),
      child: const Icon(Icons.music_note, color: Color(0xFF84CC16), size: 24),
    );
  }
}

class _FullPlayerSheet extends StatefulWidget {
  const _FullPlayerSheet();

  @override
  State<_FullPlayerSheet> createState() => _FullPlayerSheetState();
}

class _FullPlayerSheetState extends State<_FullPlayerSheet> {
  bool _showLyrics = false;

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    final music = context.watch<MusicProvider>();
    final song = player.currentSong;

    if (song == null) return const SizedBox();

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A1A1A), Color(0xFF0D0D0D)],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[700],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.keyboard_arrow_down),
                  onPressed: () => Navigator.pop(context),
                ),
                const Text('Now Playing', style: TextStyle(fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () {},
                ),
              ],
            ),
          ),
          
          Expanded(
            child: _showLyrics && song.lyrics != null
                ? _buildLyricsView(song.lyrics!)
                : _buildAlbumArt(song),
          ),
          
          // Song info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                Text(
                  song.title,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF84CC16).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        song.style ?? 'AI Music',
                        style: const TextStyle(color: Color(0xFF84CC16), fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Progress
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    activeTrackColor: const Color(0xFF84CC16),
                    inactiveTrackColor: Colors.white.withOpacity(0.1),
                    thumbColor: Colors.white,
                  ),
                  child: Slider(
                    value: player.progress.clamp(0.0, 1.0),
                    onChanged: (v) => player.seek(v),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_formatDuration(player.position), style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                    Text(_formatDuration(player.duration), style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Controls
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: Icon(
                    _showLyrics ? Icons.lyrics : Icons.lyrics_outlined,
                    color: _showLyrics ? const Color(0xFF84CC16) : Colors.white,
                  ),
                  iconSize: 28,
                  onPressed: () => setState(() => _showLyrics = !_showLyrics),
                ),
                IconButton(
                  icon: const Icon(Icons.skip_previous_rounded),
                  iconSize: 40,
                  onPressed: () => player.playPrevious(),
                ),
                GestureDetector(
                  onTap: () => player.togglePlay(),
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF84CC16), Color(0xFF22C55E)],
                      ),
                      borderRadius: BorderRadius.circular(36),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF84CC16).withOpacity(0.4),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: Icon(
                      player.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: Colors.black,
                      size: 40,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.skip_next_rounded),
                  iconSize: 40,
                  onPressed: () => player.playNext(),
                ),
                IconButton(
                  icon: Icon(
                    song.isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: song.isFavorite ? Colors.red : Colors.white,
                  ),
                  iconSize: 28,
                  onPressed: () => music.toggleFavorite(song.id),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildAlbumArt(dynamic song) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF84CC16).withOpacity(0.3),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: song.fullThumbnailUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: song.fullThumbnailUrl,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => _defaultArt(),
                  )
                : _defaultArt(),
          ),
        ),
      ),
    );
  }

  Widget _defaultArt() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF84CC16).withOpacity(0.3), const Color(0xFF22C55E).withOpacity(0.3)],
        ),
      ),
      child: const Center(
        child: Icon(Icons.music_note, size: 100, color: Color(0xFF84CC16)),
      ),
    );
  }

  Widget _buildLyricsView(String lyrics) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SingleChildScrollView(
        child: Text(
          lyrics,
          style: const TextStyle(fontSize: 18, height: 2),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
