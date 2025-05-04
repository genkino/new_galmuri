import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import '../models/post.dart';
import 'base_service.dart';
import 'package:intl/intl.dart';

class TheqooService extends BaseBoardService {
  @override
  String get baseUrl => 'https://theqoo.net';
  
  @override
  String get boardName => 'hot';
  
  @override
  String get boardDisplayName => '더쿠';
  
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
    'views': 'td.m_no',
    'time': 'td.time',
    'link': 'td.title a',
  };
  
  @override
  String buildUrl() {
    return '$baseUrl/hot?page=${currentPage + 1}';
  }
  
  @override
  bool shouldSkipElement(dynamic element) {
    // 공지사항이나 헤더 행 건너뛰기
    final isHeader = element.querySelector('th') != null;
    final isNotice = element.className.contains('notice');
    print('Checking element: isHeader=$isHeader, isNotice=$isNotice');
    return isHeader || isNotice;
  }
  
  @override
  Post? parsePost(dynamic element) {
    print('Parsing post element: ${element.outerHtml}');
    
    final titleElement = element.querySelector(selectors['title']);
    final authorElement = element.querySelector(selectors['author']);
    final viewsElement = element.querySelector(selectors['views']);
    final timeElement = element.querySelector(selectors['time']);
    final linkElement = element.querySelector(selectors['link']);
    
    print('Found elements:');
    print('Title: ${titleElement?.text}');
    print('Author: ${authorElement?.text}');
    print('Views: ${viewsElement?.text}');
    print('Time: ${timeElement?.text}');
    print('Link: ${linkElement?.attributes['href']}');
    
    if (titleElement == null ||
        viewsElement == null || timeElement == null || linkElement == null) {
      print('Missing required elements for post');
      return null;
    }
    
    final title = titleElement.text.trim();
    final author = "";
    final views = int.tryParse(viewsElement.text.trim().replaceAll(',', '')) ?? 0;
    
    final timeStr = timeElement.text.trim();
    final timestamp = _parseTimestamp(timeStr);
    final url = buildFullUrl(linkElement.attributes['href'] ?? '');
    
    print('Parsed post:');
    print('Title: $title');
    print('Author: $author');
    print('Views: $views');
    print('Time: $timestamp');
    print('URL: $url');
    
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
        // 시간만 있는 경우 (HH:mm 또는 HH:mm:ss)
        if (timestamp.contains(':') && !timestamp.contains('.')) {
          final now = DateTime.now();
          final timeParts = timestamp.split(':');
          if (timeParts.length == 2) {
            // HH:mm 형식
            return DateTime(now.year, now.month, now.day,
              int.parse(timeParts[0]), int.parse(timeParts[1]), 0);
          } else {
            // HH:mm:ss 형식
            return DateTime(now.year, now.month, now.day,
              int.parse(timeParts[0]), int.parse(timeParts[1]), int.parse(timeParts[2]));
          }
        }
        // 날짜만 있는 경우 (MM.dd)
        else if (timestamp.contains('.') && timestamp.split('.').length == 2) {
          final now = DateTime.now();
          final dateParts = timestamp.split('.');
          return DateTime(now.year,
            int.parse(dateParts[0]), // month
            int.parse(dateParts[1]), // day
            23, 59, 59 // 23:59:59
          );
        }
        // 날짜와 시간이 모두 있는 경우 (yyyy-MM-dd HH:mm:ss)
        else {
          return DateFormat('yyyy-MM-dd HH:mm:ss').parse(timestamp);
        }
      }
    } catch (e) {
      print('Error parsing timestamp: $e');
      return DateTime.now();
    }
  }
} 