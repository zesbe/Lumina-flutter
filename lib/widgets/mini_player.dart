import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                '${song.displayArtist} • ${song.displayGenre}',
                                style: TextStyle(color: Colors.grey[400], fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (player.hasSleepTimer) ...[
                              const SizedBox(width: 8),
                              Icon(Icons.bedtime, size: 12, color: Colors.amber[400]),
                              const SizedBox(width: 2),
                              Text(
                                _formatTimer(player.sleepTimerRemaining),
                                style: TextStyle(color: Colors.amber[400], fontSize: 11),
                              ),
                            ],
                          ],
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

  String _formatTimer(Duration? d) {
    if (d == null) return '';
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
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
  Set<int> _likedPublicSongs = {};

  @override
  void initState() {
    super.initState();
    _loadLikedPublicSongs();
  }

  Future<void> _loadLikedPublicSongs() async {
    final prefs = await SharedPreferences.getInstance();
    final liked = prefs.getStringList('liked_public_songs') ?? [];
    setState(() {
      _likedPublicSongs = liked.map((e) => int.tryParse(e) ?? 0).toSet();
    });
  }

  Future<void> _togglePublicLike(int songId) async {
    setState(() {
      if (_likedPublicSongs.contains(songId)) {
        _likedPublicSongs.remove(songId);
      } else {
        _likedPublicSongs.add(songId);
      }
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('liked_public_songs', _likedPublicSongs.map((e) => e.toString()).toList());
  }

  bool _isPublicSong(dynamic song) {
    return song.creatorName != null && song.creatorName!.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    final music = context.watch<MusicProvider>();
    final song = player.currentSong;

    if (song == null) return const SizedBox();

    final isPublic = _isPublicSong(song);
    final isLikedPublic = _likedPublicSongs.contains(song.id);

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
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[700],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.keyboard_arrow_down, size: 28),
                  onPressed: () => Navigator.pop(context),
                ),
                Column(
                  children: [
                    Text(
                      isPublic ? 'From Explore' : 'Now Playing',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    if (isPublic)
                      Text(
                        'by ${song.creatorName}',
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      )
                    else if (player.hasSleepTimer)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.bedtime, size: 12, color: Colors.amber[400]),
                          const SizedBox(width: 4),
                          Text(
                            'Sleep in ${_formatTimerFull(player.sleepTimerRemaining)}',
                            style: TextStyle(color: Colors.amber[400], fontSize: 11),
                          ),
                        ],
                      ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () => _showOptions(context, song, music, isPublic, isLikedPublic),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: _showLyrics && song.cleanedLyrics.isNotEmpty
                ? _buildLyricsView(song.cleanedLyrics)
                : _showInfo
                    ? _buildInfoView(song, isPublic)
                    : _buildAlbumArt(song),
          ),
          
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
              ],
            ),
          ),
          const SizedBox(height: 16),
          
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
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.shuffle_rounded,
                    color: player.shuffleEnabled ? const Color(0xFF84CC16) : Colors.grey,
                  ),
                  iconSize: 24,
                  onPressed: () => player.toggleShuffle(),
                  tooltip: 'Shuffle',
                ),
                IconButton(
                  icon: const Icon(Icons.skip_previous_rounded),
                  iconSize: 36,
                  onPressed: () => player.playPrevious(),
                ),
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
                IconButton(
                  icon: const Icon(Icons.skip_next_rounded),
                  iconSize: 36,
                  onPressed: () => player.playNext(),
                ),
                IconButton(
                  icon: Icon(
                    player.repeatMode == RepeatMode.one
                        ? Icons.repeat_one_rounded
                        : Icons.repeat_rounded,
                    color: player.repeatMode != RepeatMode.off 
                        ? const Color(0xFF84CC16) 
                        : Colors.grey,
                  ),
                  iconSize: 24,
                  onPressed: () => player.toggleRepeatMode(),
                  tooltip: _repeatModeText(player.repeatMode),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _SmallActionButton(
                  icon: _showLyrics ? Icons.lyrics : Icons.lyrics_outlined,
                  label: 'Lirik',
                  isActive: _showLyrics,
                  onTap: () => setState(() {
                    _showLyrics = !_showLyrics;
                    _showInfo = false;
                  }),
                ),
                _SmallActionButton(
                  icon: Icons.bedtime,
                  label: player.hasSleepTimer ? _formatTimerShort(player.sleepTimerRemaining) : 'Timer',
                  isActive: player.hasSleepTimer,
                  activeColor: Colors.amber,
                  onTap: () => _showSleepTimerDialog(context, player),
                ),
                // Favorite button - different behavior for public vs own songs
                _SmallActionButton(
                  icon: isPublic
                      ? (isLikedPublic ? Icons.favorite : Icons.favorite_border)
                      : (song.isFavorite ? Icons.favorite : Icons.favorite_border),
                  label: 'Favorit',
                  isActive: isPublic ? isLikedPublic : song.isFavorite,
                  activeColor: Colors.red,
                  onTap: () {
                    if (isPublic) {
                      _togglePublicLike(song.id);
                      _showSnackBar(isLikedPublic ? 'Dihapus dari favorit' : 'Ditambahkan ke favorit');
                    } else {
                      music.toggleFavorite(song.id);
                    }
                  },
                ),
                // Download button - only show for OWN songs, not public
                if (!isPublic)
                  _SmallActionButton(
                    icon: Icons.download,
                    label: _isDownloading ? '${(_downloadProgress * 100).toInt()}%' : 'Unduh',
                    onTap: _isDownloading ? null : () => _downloadMusic(song),
                  )
                else
                  _SmallActionButton(
                    icon: Icons.public,
                    label: 'Publik',
                    isActive: true,
                    activeColor: Colors.blue,
                    onTap: () => _showSnackBar('Musik ini dari kreator lain'),
                  ),
                _SmallActionButton(
                  icon: _showInfo ? Icons.info : Icons.info_outline,
                  label: 'Info',
                  isActive: _showInfo,
                  onTap: () => setState(() {
                    _showInfo = !_showInfo;
                    _showLyrics = false;
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
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

  Widget _buildInfoView(dynamic song, bool isPublic) {
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
            Text(
              isPublic ? '📋 Info Musik Publik' : '📋 Informasi Lagu',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            if (isPublic) _InfoRow(icon: Icons.person, label: 'Kreator', value: song.creatorName ?? 'Unknown'),
            _InfoRow(icon: Icons.person, label: 'Artis', value: song.displayArtist),
            _InfoRow(icon: Icons.album, label: 'Album', value: song.displayAlbum),
            _InfoRow(icon: Icons.music_note, label: 'Genre', value: song.displayGenre),
            _InfoRow(icon: Icons.mood, label: 'Mood', value: song.displayMood),
            _InfoRow(icon: Icons.calendar_today, label: 'Tahun', value: song.productionYear),
            _InfoRow(icon: Icons.access_time, label: 'Durasi', value: song.formattedDuration),
            _InfoRow(icon: Icons.schedule, label: 'Dibuat', value: song.formattedDate),
            _InfoRow(icon: Icons.smart_toy, label: 'Model AI', value: song.model ?? 'music-2.0'),
            if (!isPublic && song.prompt != null && song.prompt!.isNotEmpty)
              _InfoRow(icon: Icons.text_fields, label: 'Prompt', value: song.prompt!),
          ],
        ),
      ),
    );
  }

  void _showSleepTimerDialog(BuildContext context, PlayerProvider player) {
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('⏰ Sleep Timer', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                if (player.hasSleepTimer)
                  TextButton(
                    onPressed: () {
                      player.cancelSleepTimer();
                      Navigator.pop(ctx);
                    },
                    child: const Text('Batalkan', style: TextStyle(color: Colors.red)),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              player.hasSleepTimer 
                  ? 'Musik akan berhenti dalam ${_formatTimerFull(player.sleepTimerRemaining)}'
                  : 'Pilih durasi untuk menghentikan musik otomatis',
              style: TextStyle(color: Colors.grey[400]),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _TimerOption(label: '5 menit', duration: const Duration(minutes: 5), player: player, ctx: ctx),
                _TimerOption(label: '15 menit', duration: const Duration(minutes: 15), player: player, ctx: ctx),
                _TimerOption(label: '30 menit', duration: const Duration(minutes: 30), player: player, ctx: ctx),
                _TimerOption(label: '45 menit', duration: const Duration(minutes: 45), player: player, ctx: ctx),
                _TimerOption(label: '1 jam', duration: const Duration(hours: 1), player: player, ctx: ctx),
                _TimerOption(label: '2 jam', duration: const Duration(hours: 2), player: player, ctx: ctx),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showOptions(BuildContext context, dynamic song, MusicProvider music, bool isPublic, bool isLikedPublic) {
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
            // Show creator info for public songs
            if (isPublic) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.public, color: Colors.blue),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Musik Publik', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('Dibuat oleh ${song.creatorName}', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Download - only for own songs
            if (!isPublic)
              ListTile(
                leading: const Icon(Icons.download, color: Color(0xFF84CC16)),
                title: const Text('Download Musik'),
                subtitle: const Text('Simpan MP3 ke perangkat'),
                onTap: () {
                  Navigator.pop(ctx);
                  _downloadMusic(song);
                },
              ),
            
            // Download lyrics - only for own songs
            if (!isPublic && song.cleanedLyrics.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.text_snippet, color: Color(0xFF84CC16)),
                title: const Text('Download Lirik'),
                onTap: () {
                  Navigator.pop(ctx);
                  _downloadLyrics(song);
                },
              ),
            
            // Favorite - different behavior
            ListTile(
              leading: Icon(
                isPublic
                    ? (isLikedPublic ? Icons.favorite : Icons.favorite_border)
                    : (song.isFavorite ? Icons.favorite : Icons.favorite_border),
                color: (isPublic ? isLikedPublic : song.isFavorite) ? Colors.red : Colors.grey,
              ),
              title: Text(
                isPublic
                    ? (isLikedPublic ? 'Hapus dari Favorit' : 'Tambah ke Favorit')
                    : (song.isFavorite ? 'Hapus dari Favorit' : 'Tambah ke Favorit'),
              ),
              onTap: () {
                if (isPublic) {
                  _togglePublicLike(song.id);
                  Navigator.pop(ctx);
                  _showSnackBar(isLikedPublic ? 'Dihapus dari favorit' : 'Ditambahkan ke favorit');
                } else {
                  music.toggleFavorite(song.id);
                  Navigator.pop(ctx);
                }
              },
            ),
            
            // Message for public songs
            if (isPublic)
              ListTile(
                leading: const Icon(Icons.block, color: Colors.grey),
                title: const Text('Download tidak tersedia'),
                subtitle: const Text('Musik ini milik kreator lain', style: TextStyle(fontSize: 12)),
                enabled: false,
              ),
            
            const SizedBox(height: 10),
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
      _showSnackBar('✅ Tersimpan di: Download/LuminaAI/');
    } else {
      _showSnackBar('❌ Gagal mengunduh', isError: true);
    }
  }

  Future<void> _downloadLyrics(dynamic song) async {
    final path = await DownloadService.downloadLyrics(
      lyrics: song.cleanedLyrics,
      title: song.title,
      artist: song.displayArtist,
      style: song.displayGenre,
      year: song.productionYear,
    );

    if (path != null) {
      _showSnackBar('✅ Lirik tersimpan!');
    } else {
      _showSnackBar('❌ Gagal menyimpan', isError: true);
    }
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

  String _formatTimerFull(Duration? d) {
    if (d == null) return '--:--';
    if (d.inHours > 0) {
      return '${d.inHours}j ${d.inMinutes.remainder(60)}m';
    }
    return '${d.inMinutes}m ${d.inSeconds.remainder(60)}s';
  }

  String _formatTimerShort(Duration? d) {
    if (d == null) return 'Timer';
    if (d.inHours > 0) {
      return '${d.inHours}:${d.inMinutes.remainder(60).toString().padLeft(2, '0')}';
    }
    return '${d.inMinutes}:${d.inSeconds.remainder(60).toString().padLeft(2, '0')}';
  }

  String _repeatModeText(RepeatMode mode) {
    switch (mode) {
      case RepeatMode.off: return 'Repeat: Off';
      case RepeatMode.one: return 'Repeat: One';
      case RepeatMode.all: return 'Repeat: All';
    }
  }
}

class _SmallActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final Color? activeColor;
  final VoidCallback? onTap;

  const _SmallActionButton({
    required this.icon,
    required this.label,
    this.isActive = false,
    this.activeColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? (activeColor ?? const Color(0xFF84CC16)) : Colors.grey;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 10, color: color)),
        ],
      ),
    );
  }
}

class _TimerOption extends StatelessWidget {
  final String label;
  final Duration duration;
  final PlayerProvider player;
  final BuildContext ctx;

  const _TimerOption({
    required this.label,
    required this.duration,
    required this.player,
    required this.ctx,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        player.setSleepTimer(duration);
        Navigator.pop(ctx);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⏰ Sleep timer: $label'),
            backgroundColor: Colors.amber[700],
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.amber.withOpacity(0.3)),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
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
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF84CC16).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: const Color(0xFF84CC16)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                Text(value, style: const TextStyle(fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
