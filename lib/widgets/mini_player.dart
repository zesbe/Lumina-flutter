import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/player_provider.dart';
import '../providers/music_provider.dart';
import '../services/download_service.dart';

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
          gradient: const LinearGradient(
            colors: [Color(0xFF1A1A1A), Color(0xFF252525)],
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
                  _SpinningDisc(
                    imageUrl: song.fullThumbnailUrl,
                    isPlaying: player.isPlaying,
                  ),
                  const SizedBox(width: 12),
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
                          '${song.displayArtist} • ${song.displayGenre}',
                          style: TextStyle(color: Colors.grey[400], fontSize: 12),
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
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
            Container(
              height: 3,
              margin: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(2),
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
  bool _showInfo = false;
  bool _isDownloading = false;
  double _downloadProgress = 0;

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    final music = context.watch<MusicProvider>();
    final song = player.currentSong;

    if (song == null) return const SizedBox();

    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
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
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.keyboard_arrow_down, size: 28),
                  onPressed: () => Navigator.pop(context),
                ),
                const Text('Now Playing', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () => _showOptions(context, song, music),
                ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: _showLyrics && song.lyrics != null
                ? _buildLyricsView(song.lyrics!)
                : _showInfo
                    ? _buildInfoView(song)
                    : _buildAlbumArt(song),
          ),
          
          // Song info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                Text(
                  song.title,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  '${song.displayArtist} • ${song.productionYear}',
                  style: TextStyle(color: Colors.grey[400], fontSize: 14),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _InfoChip(icon: Icons.music_note, label: song.displayGenre),
                    const SizedBox(width: 8),
                    _InfoChip(icon: Icons.mood, label: song.displayMood),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
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
                    overlayColor: const Color(0xFF84CC16).withOpacity(0.2),
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
                      Text(_formatDuration(player.position), style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                      Text(_formatDuration(player.duration), style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          
          // Controls
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Lyrics toggle
                IconButton(
                  icon: Icon(
                    _showLyrics ? Icons.lyrics : Icons.lyrics_outlined,
                    color: _showLyrics ? const Color(0xFF84CC16) : Colors.white,
                  ),
                  iconSize: 26,
                  onPressed: () => setState(() {
                    _showLyrics = !_showLyrics;
                    _showInfo = false;
                  }),
                  tooltip: 'Lirik',
                ),
                // Previous
                IconButton(
                  icon: const Icon(Icons.skip_previous_rounded),
                  iconSize: 36,
                  onPressed: () => player.playPrevious(),
                ),
                // Play/Pause
                GestureDetector(
                  onTap: () => player.togglePlay(),
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF84CC16), Color(0xFF22C55E)],
                      ),
                      borderRadius: BorderRadius.circular(35),
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
                      size: 38,
                    ),
                  ),
                ),
                // Next
                IconButton(
                  icon: const Icon(Icons.skip_next_rounded),
                  iconSize: 36,
                  onPressed: () => player.playNext(),
                ),
                // Info toggle
                IconButton(
                  icon: Icon(
                    _showInfo ? Icons.info : Icons.info_outline,
                    color: _showInfo ? const Color(0xFF84CC16) : Colors.white,
                  ),
                  iconSize: 26,
                  onPressed: () => setState(() {
                    _showInfo = !_showInfo;
                    _showLyrics = false;
                  }),
                  tooltip: 'Info',
                ),
              ],
            ),
          ),
          
          // Bottom actions
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ActionButton(
                  icon: song.isFavorite ? Icons.favorite : Icons.favorite_border,
                  label: 'Favorit',
                  color: song.isFavorite ? Colors.red : Colors.white,
                  onTap: () => music.toggleFavorite(song.id),
                ),
                _ActionButton(
                  icon: Icons.download,
                  label: _isDownloading ? '${(_downloadProgress * 100).toInt()}%' : 'Download',
                  onTap: _isDownloading ? null : () => _downloadMusic(song),
                ),
                _ActionButton(
                  icon: Icons.share,
                  label: 'Bagikan',
                  onTap: () => _shareMusic(song),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildAlbumArt(dynamic song) {
    return Padding(
      padding: const EdgeInsets.all(32),
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
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [const Color(0xFF84CC16).withOpacity(0.3), const Color(0xFF22C55E).withOpacity(0.3)],
        ),
      ),
      child: const Center(
        child: Icon(Icons.music_note, size: 100, color: Color(0xFF84CC16)),
      ),
    );
  }

  Widget _buildLyricsView(String lyrics) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: SingleChildScrollView(
        child: Text(
          lyrics,
          style: const TextStyle(fontSize: 16, height: 2),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildInfoView(dynamic song) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('📋 Informasi Lagu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _InfoRow(icon: Icons.person, label: 'Artis', value: song.displayArtist),
            _InfoRow(icon: Icons.album, label: 'Album', value: song.displayAlbum),
            _InfoRow(icon: Icons.music_note, label: 'Genre', value: song.displayGenre),
            _InfoRow(icon: Icons.mood, label: 'Mood', value: song.displayMood),
            _InfoRow(icon: Icons.calendar_today, label: 'Tahun', value: song.productionYear),
            _InfoRow(icon: Icons.access_time, label: 'Durasi', value: song.formattedDuration),
            _InfoRow(icon: Icons.schedule, label: 'Dibuat', value: song.formattedDate),
            _InfoRow(icon: Icons.smart_toy, label: 'Model AI', value: song.model ?? 'music-2.0'),
            if (song.prompt != null && song.prompt!.isNotEmpty)
              _InfoRow(icon: Icons.text_fields, label: 'Prompt', value: song.prompt!),
          ],
        ),
      ),
    );
  }

  void _showOptions(BuildContext context, dynamic song, MusicProvider music) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey[700], borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.download, color: Color(0xFF84CC16)),
              title: const Text('Download Musik'),
              subtitle: const Text('Simpan MP3 ke perangkat'),
              onTap: () {
                Navigator.pop(ctx);
                _downloadMusic(song);
              },
            ),
            if (song.lyrics != null && song.lyrics!.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.text_snippet, color: Color(0xFF84CC16)),
                title: const Text('Download Lirik'),
                subtitle: const Text('Simpan sebagai file .txt'),
                onTap: () {
                  Navigator.pop(ctx);
                  _downloadLyrics(song);
                },
              ),
            ListTile(
              leading: Icon(
                song.isFavorite ? Icons.favorite : Icons.favorite_border,
                color: song.isFavorite ? Colors.red : Colors.grey,
              ),
              title: Text(song.isFavorite ? 'Hapus dari Favorit' : 'Tambah ke Favorit'),
              onTap: () {
                music.toggleFavorite(song.id);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share, color: Colors.grey),
              title: const Text('Bagikan'),
              onTap: () {
                Navigator.pop(ctx);
                _shareMusic(song);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadMusic(dynamic song) async {
    if (song.fullOutputUrl.isEmpty) {
      _showSnackBar('URL musik tidak tersedia', isError: true);
      return;
    }

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0;
    });

    _showSnackBar('⏬ Mengunduh "${song.title}"...');

    final path = await DownloadService.downloadMusic(
      url: song.fullOutputUrl,
      title: song.title,
      onProgress: (progress) {
        setState(() => _downloadProgress = progress);
      },
    );

    setState(() => _isDownloading = false);

    if (path != null) {
      _showSnackBar('✅ Tersimpan di: LuminaAI/${path.split('/').last}');
    } else {
      _showSnackBar('❌ Gagal mengunduh', isError: true);
    }
  }

  Future<void> _downloadLyrics(dynamic song) async {
    if (song.lyrics == null || song.lyrics!.isEmpty) {
      _showSnackBar('Tidak ada lirik', isError: true);
      return;
    }

    final path = await DownloadService.downloadLyrics(
      lyrics: song.lyrics!,
      title: song.title,
      artist: song.displayArtist,
      style: song.displayGenre,
      year: song.productionYear,
    );

    if (path != null) {
      _showSnackBar('✅ Lirik tersimpan di: LuminaAI/');
    } else {
      _showSnackBar('❌ Gagal menyimpan lirik', isError: true);
    }
  }

  void _shareMusic(dynamic song) {
    // For now just show a snackbar - could integrate share_plus later
    _showSnackBar('🔗 Link disalin! Bagikan ke temanmu');
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : const Color(0xFF84CC16),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF84CC16).withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF84CC16).withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF84CC16)),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF84CC16))),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF84CC16).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: const Color(0xFF84CC16)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                Text(value, style: const TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(icon, color: color ?? Colors.white, size: 24),
          ),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[400])),
        ],
      ),
    );
  }
}
