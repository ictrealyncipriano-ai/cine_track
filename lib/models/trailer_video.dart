class TrailerVideo {
  final String id;
  final String key;
  final String name;
  final String site;
  final String type;
  final bool official;
  final String publishedAt;

  TrailerVideo({
    required this.id,
    required this.key,
    required this.name,
    required this.site,
    required this.type,
    required this.official,
    required this.publishedAt,
  });

  factory TrailerVideo.fromJson(Map<String, dynamic> json) {
    return TrailerVideo(
      id: json['id'] as String? ?? '',
      key: json['key'] as String? ?? '',
      name: json['name'] as String? ?? '',
      site: json['site'] as String? ?? '',
      type: json['type'] as String? ?? '',
      official: json['official'] as bool? ?? false,
      publishedAt: json['published_at'] as String? ?? '',
    );
  }

  String get youtubeUrl =>
      'https://www.youtube.com/watch?v=$key';

  bool get isPlayable => site == 'YouTube' && key.isNotEmpty;

  bool get isTeaser => type == 'Teaser';
  bool get isTrailer => type == 'Trailer';
}
