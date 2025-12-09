class Generation {
  final int id;
  final String type;
  final String status;
  final String title;
  final String? prompt;
  final String? lyrics;
  final String? style;
  final String? outputUrl;
  final String? thumbnailUrl;
  final bool isFavorite;
  final DateTime createdAt;

  Generation({
    required this.id,
    required this.type,
    required this.status,
    required this.title,
    this.prompt,
    this.lyrics,
    this.style,
    this.outputUrl,
    this.thumbnailUrl,
    required this.isFavorite,
    required this.createdAt,
  });

  factory Generation.fromJson(Map<String, dynamic> json) {
    return Generation(
      id: json['id'],
      type: json['type'] ?? 'music',
      status: json['status'] ?? 'pending',
      title: json['title'] ?? 'Untitled',
      prompt: json['prompt'],
      lyrics: json['lyrics'],
      style: json['style'],
      outputUrl: json['output_url'],
      thumbnailUrl: json['thumbnail_url'],
      isFavorite: json['is_favorite'] ?? false,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  String get fullOutputUrl {
    if (outputUrl == null) return '';
    if (outputUrl!.startsWith('http')) return outputUrl!;
    return 'https://luminaai.zesbe.my.id$outputUrl';
  }

  String get fullThumbnailUrl {
    if (thumbnailUrl == null) return '';
    if (thumbnailUrl!.startsWith('http')) return thumbnailUrl!;
    return 'https://luminaai.zesbe.my.id$thumbnailUrl';
  }
}
