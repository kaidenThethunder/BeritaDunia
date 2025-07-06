class VideoArticle {
  final String id;
  final String title;
  final String description;
  final String thumbnailUrl;
  final String channelTitle;
  final DateTime publishedAt;

  VideoArticle({
    required this.id,
    required this.title,
    required this.description,
    required this.thumbnailUrl,
    required this.channelTitle,
    required this.publishedAt,
  });

  factory VideoArticle.fromJson(Map<String, dynamic> json) {
    final snippet = json['snippet'];
    return VideoArticle(
      id: json['id']['videoId'] ?? '',
      title: snippet['title'] ?? 'No Title',
      description: snippet['description'] ?? 'No Description',
      thumbnailUrl: snippet['thumbnails']['high']?['url'] ?? 
                    snippet['thumbnails']['medium']?['url'] ?? 
                    snippet['thumbnails']['default']?['url'] ?? 
                    '', // Fallback for thumbnails
      channelTitle: snippet['channelTitle'] ?? 'Unknown Channel',
      publishedAt: DateTime.tryParse(snippet['publishedAt'] ?? '') ?? DateTime.now(),
    );
  }
}