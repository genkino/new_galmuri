import 'package:html/parser.dart' as parser;
import '../models/post.dart';
import 'base_service.dart';
import 'package:flutter/material.dart';
import 'package:cp949/cp949.dart' as cp949;

class EtolandService extends BaseBoardService {
  @override
  String get baseUrl => 'https://www.etoland.co.kr/plugin/mobile';
  
  @override
  String get boardName => 'hit';
  
  @override
  String get boardDisplayName => '이토랜드';
  
  @override
  Color get boardColor => Color(0xFF4CAF50);  // 이토랜드 메인 색상

  @override
  String get charset => 'euc-kr';  // 이토랜드는 EUC-KR 인코딩 사용

  @override
  Map<String, String> get headers => {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
    'Accept-Language': 'ko-KR,ko;q=0.9,en-US;q=0.8,en;q=0.7',
  };

  @override
  String get postListSelector => 'ul li.p-4';

  @override
  Map<String, String> get selectors => {
    'title': 'a span.subject',
    'author': 'a div.etc span.member',
    'views': 'a div.etc span.datetime',
    'timestamp': 'a div.etc span.datetime',  // 모든 span.datetime을 선택
    'url': 'a',
  };

  @override
  bool shouldSkipElement(dynamic element) {
    final hasTitle = element.querySelector(selectors['title']) != null;
    print('Checking element: ${hasTitle ? "valid" : "invalid"}');
    return !hasTitle;
  }

  @override
  Post? parsePost(dynamic element) {
    try {
      print('Parsing Etoland post element...');
      
      final titleElement = element.querySelector(selectors['title']);
      final authorElement = element.querySelector(selectors['author']);
      final viewAndtimestampElements = element.querySelectorAll(selectors['timestamp']);  // 모든 span.datetime을 가져옴
      final urlElement = element.querySelector(selectors['url']);

      print('Found elements:');
      print('Title: ${titleElement?.text}');
      print('Author: ${authorElement?.text}');
      print('ViewAndTimestamp elements count: ${viewAndtimestampElements.length}');
      print('URL: ${urlElement?.attributes['href']}');

      if (titleElement == null || authorElement == null || 
          viewAndtimestampElements.length < 3 || urlElement == null) {
        print('Some elements are missing:');
        print('Title: ${titleElement == null ? "missing" : "found"}');
        print('Author: ${authorElement == null ? "missing" : "found"}');
        print('Views: ${viewAndtimestampElements.length < 3  ? "missing" : "found"}');
        print('Timestamp: ${viewAndtimestampElements.length < 3 ? "missing" : "found"}');
        print('URL: ${urlElement == null ? "missing" : "found"}');
        return null;
      }

      // cp949 패키지를 사용하여 EUC-KR 텍스트를 UTF-8로 변환
      final title = cp949.decodeString(titleElement.text.trim());
      final author = cp949.decodeString(authorElement.text.trim());
      final views = int.tryParse(viewAndtimestampElements[1].text.trim().replaceAll(',', '')) ?? 0;
      final timestampStr = cp949.decodeString(viewAndtimestampElements[0].text.trim().replaceAll(RegExp(r"\s+"), ""));
      final timestamp = parseTimestamp(timestampStr);  // 3번째 요소 사용 (0-based index)

      final href = urlElement.attributes['href'].trim().replaceAll('./', '/');
      final url = buildFullUrl(href ?? '');

      print('Parsed post:');
      print('Title: $title');
      print('Author: $author');
      print('Views: $views');
      print('Timestamp: $timestamp');
      print('URL: $url');

      return Post(
        title: title,
        author: author,
        views: views,
        timestamp: timestamp,
        url: url,
      );
    } catch (e, stackTrace) {
      print('Error parsing post: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }

  @override
  String buildUrl() {
    final url = '$baseUrl/$boardName.php?page=${currentPage + 1}';
    print('Building Etoland URL: $url');
    return url;
  }
} 