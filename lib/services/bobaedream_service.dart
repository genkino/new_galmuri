import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:flutter/material.dart';
import 'dart:convert';
import 'base_service.dart';
import '../models/post.dart';

class BobaedreamService extends BaseBoardService {
  @override
  String get boardId => "bobaedream";

  @override
  String get boardDisplayName => '보배드림';

  @override
  String get boardName => 'best';

  @override
  String get baseUrl => 'https://m.bobaedream.co.kr';

  @override
  String get postListSelector => 'ul.rank li';

  @override
  Map<String, String> get headers => {
    'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8',
    'Accept-Encoding': 'gzip, deflate, br, zstd',
    'Accept-Language': 'ko-KR,ko;q=0.9,en-US;q=0.8,en;q=0.7',
    'Cache-Control': 'no-cache',
    'Pragma': 'no-cache',
    'Referer': 'https://m.bobaedream.co.kr/board/new_writing/best',
    'Sec-Ch-Ua': '"Chromium";v="122", "Not(A:Brand";v="24", "Google Chrome";v="122"',
    'Sec-Ch-Ua-Mobile': '?0',
    'Sec-Ch-Ua-Platform': '"macOS"',
    'Sec-Fetch-Dest': 'document',
    'Sec-Fetch-Mode': 'navigate',
    'Sec-Fetch-Site': 'same-origin',
    'Sec-Fetch-User': '?1',
    'Upgrade-Insecure-Requests': '1',
  };

  @override
  Color get boardColor => const Color(0xFF795548);

  @override
  Map<String, String> get selectors => {
    'title': 'div.info a',
    'author': 'div.info div.txt2 span.block',
    'views': 'div.info div.txt2 span.block',
    'date': 'div.txt2 span.block',
    'images': 'div.txt2 span.block',
  };

  @override
  String buildUrl() {
    return '$baseUrl/board/new_writing/${boardName}/${currentPage + 1}';
  }

  @override
  bool shouldSkipElement(dynamic element) {
    if (element == null) return true;
    
    final titleElement = element.querySelector(selectors['title']);
    return titleElement == null;
  }

  @override
  Post? parsePost(dynamic element) {
    try {
      final titleElement = element.querySelector(selectors['title']);
      if (titleElement == null) return null;

      final title = element.querySelector('${selectors['title']} span.cont')?.text.trim();

      if (title == '') return null;

      final url = '$baseUrl${titleElement.attributes['href']}';

      final etcElement = element.querySelectorAll(selectors['author']);  // 모든 span.datetime을 가져옴

      final author = etcElement[0]?.text.trim() ?? '알 수 없음';
      final views = int.tryParse(extractNumber(etcElement[2]?.text.trim() ?? '0')) ?? 0;
      
      final dateStr = etcElement[1]?.text.trim() ?? '';
      
      // 날짜 파싱
      DateTime timestamp;
      if (dateStr.contains('.')) {
        // YY.MM.DD HH:mm 형식
        final parts = dateStr.split(' ');
        if (parts.length == 2) {
          final dateParts = parts[0].split('.');
          final timeParts = parts[1].split(':');
          if (dateParts.length == 3 && timeParts.length == 2) {
            final year = 2000 + int.parse(dateParts[0]); // YY를 YYYY로 변환
            timestamp = DateTime(
              year,
              int.parse(dateParts[1]),
              int.parse(dateParts[2]),
              int.parse(timeParts[0]),
              int.parse(timeParts[1]),
              0,
            );
          } else {
            timestamp = DateTime.now();
          }
        } else {
          timestamp = DateTime.now();
        }
      } else if (dateStr.contains(':')) {
        // HH:mm 형식
        final timeParts = dateStr.split(':');
        if (timeParts.length == 2) {
          final now = DateTime.now();
          timestamp = DateTime(
            now.year,
            now.month,
            now.day,
            int.parse(timeParts[0]),
            int.parse(timeParts[1]),
            0,
          );
        } else {
          timestamp = DateTime.now();
        }
      } else {
        timestamp = DateTime.now();
      }
      
      return Post(
        boardId: boardId,
        title: title,
        author: author,
        views: views,
        timestamp: timestamp,
        url: url,
      );
    } catch (e) {
      print('Error parsing post: $e');
      return null;
    }
  }
} 