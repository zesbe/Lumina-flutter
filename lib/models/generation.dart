class Generation {
  final int id;
  final String type;
  final String status;
  final String title;
  final String? prompt;
  final String? style;
  final String? lyrics;
  final String? outputUrl;
  final String? thumbnailUrl;
  final bool isFavorite;
  final DateTime? createdAt;
  final String? errorMessage;
  final String? artist;
  final String? album;
  final int? duration;
  final String? genre;
  final String? mood;
  final String? model;

  Generation({
    required this.id,
    required this.type,
    required this.status,
    required this.title,
    this.prompt,
    this.style,
    this.lyrics,
    this.outputUrl,
    this.thumbnailUrl,
    this.isFavorite = false,
    this.createdAt,
    this.errorMessage,
    this.artist,
    this.album,
    this.duration,
    this.genre,
    this.mood,
    this.model,
  });

  factory Generation.fromJson(Map<String, dynamic> json) {
    return Generation(
      id: json['id'] ?? 0,
      type: json['type'] ?? 'music',
      status: json['status'] ?? 'pending',
      title: json['title'] ?? 'Untitled',
      prompt: json['prompt'],
      style: json['style'],
      lyrics: _cleanLyrics(json['lyrics']),
      outputUrl: json['output_url'],
      thumbnailUrl: json['thumbnail_url'],
      isFavorite: json['is_favorite'] ?? false,
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at']) 
          : null,
      errorMessage: json['error_message'],
      artist: json['artist'] ?? 'Lumina AI',
      album: json['album'] ?? 'AI Generated',
      duration: json['duration'],
      genre: json['genre'],
      mood: json['mood'],
      model: json['model'] ?? 'music-2.0',
    );
  }

  static String? _cleanLyrics(String? lyrics) {
    if (lyrics == null || lyrics.isEmpty) return lyrics;
    
    String cleaned = lyrics
      .replaceAll('â≡!', '')
      .replaceAll('â€™', "'")
      .replaceAll('â€"', '-')
      .replaceAll('â€œ', '"')
      .replaceAll('â€', '"')
      .replaceAll('Ã©', 'e')
      .replaceAll('Ã¡', 'a')
      .replaceAll('Ã±', 'n')
      .replaceAll('Ã³', 'o')
      .replaceAll('Ã­', 'i')
      .replaceAll('Ã¼', 'u')
      .replaceAll('â™ª', '')
      .replaceAll('â™«', '')
      .replaceAll('âˆ!', '')
      .replaceAll(RegExp(r'[â][^\s\n]{1,3}'), '')
      .replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'), '')
      .trim();
    
    cleaned = cleaned.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    return cleaned;
  }

  String get cleanedLyrics => _cleanLyrics(lyrics) ?? '';

  String get fullOutputUrl {
    if (outputUrl == null || outputUrl!.isEmpty) return '';
    if (outputUrl!.startsWith('http')) return outputUrl!;
    return 'https://luminaai.zesbe.my.id$outputUrl';
  }

  String get fullThumbnailUrl {
    if (thumbnailUrl == null || thumbnailUrl!.isEmpty) return '';
    if (thumbnailUrl!.startsWith('http')) return thumbnailUrl!;
    return 'https://luminaai.zesbe.my.id$thumbnailUrl';
  }

  String get formattedDuration {
    if (duration == null) return '--:--';
    final minutes = (duration! ~/ 60).toString().padLeft(2, '0');
    final seconds = (duration! % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String get formattedDate {
    if (createdAt == null) return 'Unknown';
    final now = DateTime.now();
    final diff = now.difference(createdAt!);
    
    if (diff.inDays == 0) {
      if (diff.inHours == 0) return '${diff.inMinutes} menit lalu';
      return '${diff.inHours} jam lalu';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} hari lalu';
    }
    return '${createdAt!.day}/${createdAt!.month}/${createdAt!.year}';
  }

  String get productionYear => createdAt?.year.toString() ?? DateTime.now().year.toString();
  String get displayArtist => artist ?? 'Lumina AI';
  String get displayAlbum => album ?? 'AI Generated';

  String get displayGenre {
    if (style != null && style!.isNotEmpty) {
      final parts = style!.split(',');
      if (parts.isNotEmpty) return parts.first.trim();
    }
    return genre ?? 'AI Music';
  }

  String get displayMood {
    if (style != null && style!.contains(',')) {
      final parts = style!.split(',');
      if (parts.length > 1) return parts[1].trim();
    }
    return mood ?? 'Unknown';
  }
}
