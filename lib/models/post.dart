class Post {
  final String title;
  final String author;
  final int views;
  final DateTime timestamp;
  final String url;

  Post({
    required this.title,
    required this.author,
    required this.views,
    required this.timestamp,
    required this.url,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      title: json['title'] as String,
      author: json['author'] as String,
      views: json['views'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
      url: json['url'] as String,
    );
  }
} 