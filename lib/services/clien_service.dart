import '../models/post.dart';
import 'base_service.dart';
import 'package:flutter/material.dart';

class ClienService extends BaseBoardService {
  @override
  String get baseUrl => 'https://www.clien.net';
  
  @override
  String get boardName => 'clien';
  
  @override
  String get boardDisplayName => '클리앙';
  
  @override
  Color get boardColor => Color(0xFF0066CC);  // 클리앙 메인 색상
  
  @override
  Map<String, String> get headers => {
    'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8',
    'Accept-Language': 'ko-KR,ko;q=0.9,en-US;q=0.8,en;q=0.7',
    'Cache-Control': 'no-cache',
    'Pragma': 'no-cache',
    'Sec-Ch-Ua': '"Chromium";v="122", "Not(A:Brand";v="24", "Google Chrome";v="122"',
    'Sec-Ch-Ua-Mobile': '?0',
    'Sec-Ch-Ua-Platform': '"macOS"',
    'Sec-Fetch-Dest': 'document',
    'Sec-Fetch-Mode': 'navigate',
    'Sec-Fetch-Site': 'none',
    'Sec-Fetch-User': '?1',
    'Upgrade-Insecure-Requests': '1',
  };
  
  @override
  String get postListSelector => 'div.list_item';
  
  @override
  Map<String, String> get selectors => {
    'title': 'span.subject_fixed, span.subject, a.subject, div.subject',
    'author': 'span.nickname, span.nick, div.nickname',
    'views': 'span.hit',
    'time': 'span.timestamp',
    'link': 'a.list_subject, a.subject, div.subject a',
  };
  
  @override
  String buildUrl() {
    return '$baseUrl/service/group/clien_all?od=T31&po=$currentPage';
  }
  
  @override
  bool shouldSkipElement(dynamic element) {
    return false;
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
    
    final timeStr = timeElement.attributes['data-timestamp'] ?? timeElement.text.trim();

    print('timeStr: $timeStr');
    
    final timestamp = parseTimestamp(timeStr);
    final url = buildFullUrl(linkElement.attributes['href'] ?? '');
    
    return Post(
      title: title,
      author: author,
      views: views,
      timestamp: timestamp,
      url: url,
    );
  }  
} 