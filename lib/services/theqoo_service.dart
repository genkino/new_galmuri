import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import '../models/post.dart';
import 'base_service.dart';

class TheqooService extends BaseBoardService {
  @override
  String get baseUrl => 'https://theqoo.net';
  
  @override
  String get boardName => 'theqoo';
  
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
    'author': 'td.author',
    'views': 'td.m_no',
    'time': 'td.time',
    'link': 'td.title a',
  };
  
  @override
  String buildUrl() {
    return '$baseUrl/hot';
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
    final viewsElement = element.querySelector(selectors['views']);
    final timeElement = element.querySelector(selectors['time']);
    final linkElement = element.querySelector(selectors['link']);
    
    print('Found elements:');
    print('Title: ${titleElement?.text}');
    print('Views: ${viewsElement?.text}');
    print('Time: ${timeElement?.text}');
    print('Link: ${linkElement?.attributes['href']}');
    
    if (titleElement == null || viewsElement == null || 
        timeElement == null || linkElement == null) {
      print('Missing required elements for post');
      return null;
    }
    
    final title = titleElement.text.trim();
    // 말머리 제거 (예: [이슈], [유머] 등)
    final cleanTitle = title.replaceAll(RegExp(r'^\[.*?\]\s*'), '');
    final views = int.tryParse(viewsElement.text.trim().replaceAll(',', '')) ?? 0;
    
    final timeStr = timeElement.text.trim();
    DateTime timestamp;
    
    try {
      if (timeStr.contains(':')) {
        // 시간만 있는 경우 (HH:mm 형식)
        final now = DateTime.now();
        final timeParts = timeStr.split(':');
        timestamp = DateTime(
          now.year,
          now.month,
          now.day,
          int.parse(timeParts[0]),
          int.parse(timeParts[1]),
        );
      } else {
        // 날짜만 있는 경우
        final date = DateTime.parse(timeStr);
        timestamp = DateTime(
          date.year,
          date.month,
          date.day,
          23,
          59,
        );
      }
    } catch (e) {
      print('Error parsing timestamp: $e');
      // 파싱 실패시 현재 날짜의 23:59로 설정
      final now = DateTime.now();
      timestamp = DateTime(now.year, now.month, now.day, 23, 59);
    }
    
    final url = buildFullUrl(linkElement.attributes['href'] ?? '');
    
    print('Parsed post:');
    print('Title: $cleanTitle');
    print('Views: $views');
    print('Time: $timestamp');
    print('URL: $url');
    
    return Post(
      title: '[더쿠] $cleanTitle',  // 제목 앞에 [더쿠] 추가
      author: '',  // 빈 값으로 설정
      views: views,
      timestamp: timestamp,
      url: url,
    );
  }
} 