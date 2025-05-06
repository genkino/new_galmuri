import 'package:html/parser.dart' as parser;
import 'package:intl/intl.dart';
import '../models/post.dart';
import 'base_service.dart';
import 'package:flutter/material.dart';

class DcinsideService extends BaseBoardService {
  @override
  String get boardId => "dcinside";

  @override
  String get baseUrl => 'https://gall.dcinside.com';
  
  @override
  String get boardName => 'dcbest';
  
  @override
  String get boardDisplayName => '디시인사이드';
  
  @override
  Color get boardColor => Color(0xFF1E88E5);  // 디시인사이드 메인 색상

  @override
  Map<String, String> get headers => {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
    'Accept-Language': 'ko-KR,ko;q=0.9,en-US;q=0.8,en;q=0.7',
  };

  @override
  String get postListSelector => 'tr.ub-content';

  @override
  Map<String, String> get selectors => {
    'title': 'td.gall_tit a',
    'author': 'td.gall_writer',
    'views': 'td.gall_num',
    'timestamp': 'td.gall_date',
    'url': 'td.gall_tit a',
  };

  @override
  bool shouldSkipElement(dynamic element) {
      final numElement = element.querySelector('td.gall_num');

      // numElement가 숫자가 아니면 무시
      if (numElement == null || !RegExp(r'^\d+$').hasMatch(numElement.text.trim())) {
        return true;
      }

    final hasTitle = element.querySelector(selectors['title']) != null;
    print('Checking element: ${hasTitle ? "valid" : "invalid"}');
    return !hasTitle;
  }

  @override
  Post? parsePost(dynamic element) {
    try {
      print('Parsing Dcinside post element...');
      
      final titleElement = element.querySelector(selectors['title']);
      final authorElement = element.querySelector(selectors['author']);
      final viewsElement = element.querySelector(selectors['views']);
      final timestampElement = element.querySelector(selectors['timestamp']);
      final urlElement = element.querySelector(selectors['url']);

      print('Found elements:');
      print('Title: ${titleElement?.text}');
      print('Author: ${authorElement?.text}');
      print('Views: ${viewsElement?.text}');
      print('Timestamp: ${timestampElement?.text}');
      print('URL: ${urlElement?.attributes['href']}');

      if (titleElement == null || authorElement == null || 
          viewsElement == null || timestampElement == null || urlElement == null) {
        print('Some elements are missing:');
        print('Title: ${titleElement == null ? "missing" : "found"}');
        print('Author: ${authorElement == null ? "missing" : "found"}');
        print('Views: ${viewsElement == null ? "missing" : "found"}');
        print('Timestamp: ${timestampElement == null ? "missing" : "found"}');
        print('URL: ${urlElement == null ? "missing" : "found"}');
        return null;
      }

      final title = titleElement.text.trim();
      final author = authorElement.text.trim();
      final views = int.tryParse(viewsElement.text.trim().replaceAll(',', '')) ?? 0;
      final timestamp = _parseTimestamp(timestampElement.text.trim());

      final href = urlElement.attributes['href'];
      if (!href.startsWith('/board')) {
        return null;
      }

      final url = buildFullUrl(href);

      print('Parsed post:');
      print('Title: $title');
      print('Author: $author');
      print('Views: $views');
      print('Timestamp: $timestamp');
      print('URL: $url');

      return Post(
        boardId: boardId,
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
    final url = '$baseUrl/board/lists/?id=$boardName&_$boardName=9&page=${currentPage + 1}';
    print('Building Dcinside URL: $url');
    return url;
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