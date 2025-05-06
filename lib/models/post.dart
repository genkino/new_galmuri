class Post {
  final String boardId;
  final String title;
  final String author;
  final int views;
  final DateTime timestamp;
  final String url;

  Post({
    required this.boardId,
    required this.title,
    required this.author,
    required this.views,
    required this.timestamp,
    required this.url,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      boardId: json['boardId'] as String,
      title: json['title'] as String,
      author: json['author'] as String,
      views: json['views'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
      url: json['url'] as String,
    );
  }
} 