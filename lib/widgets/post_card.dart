import 'package:flutter/material.dart';
import '../models/post.dart';
import '../services/base_service.dart';
import '../screens/post_detail_screen.dart';

class PostCard extends StatelessWidget {
  final String title;
  final String author;
  final int views;
  final DateTime timestamp;
  final String url;
  final BaseBoardService service;

  const PostCard({
    Key? key,
    required this.title,
    required this.author,
    required this.views,
    required this.timestamp,
    required this.url,
    required this.service,
  }) : super(key: key);

  // 제목에서 사이트 이름 추출
  String _getSiteName() {
    final match = RegExp(r'^\[(.*?)\]').firstMatch(title);
    return match?.group(1) ?? '';
  }

  // 사이트 이름의 첫 글자 추출
  String _getSiteInitial() {
    return service.boardDisplayName[0];
  }

  // 사이트별 색상 가져오기
  Color _getSiteColor() {
    return service.boardColor;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}분 전';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}시간 전';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}일 전';
    } else {
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final siteName = _getSiteName();
    final displayTitle = title.replaceFirst(RegExp(r'^\[.*?\]\s*'), '');

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _getSiteColor(),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              _getSiteInitial(),
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        title: Text(
          displayTitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              '$author · $views · ${_formatDate(timestamp)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PostDetailScreen(
                post: Post(
                  boardId: service.boardId,
                  title: title,
                  author: author,
                  views: views,
                  timestamp: timestamp,
                  url: url,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
} 