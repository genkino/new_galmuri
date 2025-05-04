import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'package:intl/intl.dart';
import '../models/post.dart';
import 'base_service.dart';

class DdanziService extends BaseBoardService {
  @override
  String get baseUrl => 'https://www.ddanzi.com';
  
  @override
  String get boardName => 'ddanzi';
  
  @override
  String get boardDisplayName => '딴지';
  
  @override
  Map<String, String> get headers => {
    'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8',
    'Accept-Language': 'ko-KR,ko;q=0.9,en-US;q=0.8,en;q=0.7',
    'Cache-Control': 'no-cache',
    'Pragma': 'no-cache',
  };
  
  @override
  String get postListSelector => 'table tbody tr';
  
  @override
  Map<String, String> get selectors => {
    'title': 'td.title a',
    'author': 'td.author a',
    'views': 'td.readNum',
    'time': 'td.time',
    'link': 'td.title a',
  };
  
  @override
  String buildUrl() {
    return '$baseUrl/free?page=${currentPage + 1}';
  }
  
  @override
  bool shouldSkipElement(dynamic element) {
    return element.querySelector('th') != null;
  }
  
  @override
  Post? parsePost(dynamic element) {
    final titleElement = element.querySelector(selectors['title']);
    final authorElement = element.querySelector(selectors['author']);
    final viewsElement = element.querySelector(selectors['views']);
    final timeElement = element.querySelector(selectors['time']);
    final linkElement = element.querySelector(selectors['link']);
    
    if (titleElement == null || authorElement == null || 
        viewsElement == null || timeElement == null || linkElement == null) {
      print('Missing required elements for post');
      return null;
    }
    
    final title = titleElement.text.trim();
    final author = authorElement.text.trim();
    final views = int.tryParse(viewsElement.text.trim().replaceAll(',', '')) ?? 0;
    
    final timeStr = timeElement.text.trim();
    final timestamp = _parseTimestamp(timeStr);
    final url = buildFullUrl(linkElement.attributes['href'] ?? '');
    
    return Post(
      title: title,
      author: author,
      views: views,
      timestamp: timestamp,
      url: url,
    );
  }

  DateTime _parseTimestamp(String timestamp) {
    try {
      if (timestamp.contains('분 전')) {
        final minutes = int.parse(timestamp.replaceAll('분 전', ''));
        return DateTime.now().subtract(Duration(minutes: minutes));
      } else if (timestamp.contains('시간 전')) {
        final hours = int.parse(timestamp.replaceAll('시간 전', ''));
        return DateTime.now().subtract(Duration(hours: hours));
      } else if (timestamp.contains('일 전')) {
        final days = int.parse(timestamp.replaceAll('일 전', ''));
        return DateTime.now().subtract(Duration(days: days));
      } else {
        // 시간만 있는 경우 (HH:mm)
        if (timestamp.contains(':') && !timestamp.contains('.')) {
          final now = DateTime.now();
          final timeParts = timestamp.split(':');
          return DateTime(now.year, now.month, now.day, 
            int.parse(timeParts[0]), int.parse(timeParts[1]));
        }
        // 날짜만 있는 경우 (YYYY.MM.DD)
        else if (timestamp.contains('.')) {
          final dateParts = timestamp.split('.');
          return DateTime(
            int.parse(dateParts[0]), // year
            int.parse(dateParts[1]), // month
            int.parse(dateParts[2]), // day
            23, 59, 0 // 23:59:00
          );
        }
        // 날짜와 시간이 모두 있는 경우 (YYYY.MM.DD HH:mm)
        else {
          return DateFormat('yyyy.MM.dd HH:mm').parse(timestamp);
        }
      }
    } catch (e) {
      print('Error parsing timestamp: $e');
      return DateTime.now();
    }
  }
} 