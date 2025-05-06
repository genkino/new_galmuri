import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import '../models/post.dart';
import '../database/database_helper.dart';
import 'package:flutter/material.dart';
import 'dart:convert';

abstract class BaseBoardService {
  String get baseUrl;
  String get boardName;
  String get boardDisplayName;
  Map<String, String> get headers;
  String get postListSelector;
  Map<String, String> get selectors;
  Color get boardColor;
  String get charset => 'utf-8';  // 기본값은 utf-8
  
  int currentPage = 0;
  final _dbHelper = DatabaseHelper();
  
  Future<List<Post>> getPosts({bool refresh = false}) async {
    if (refresh) {
      currentPage = 0;
    }
    
    // 데이터베이스에서 cutLine 값 가져오기
    final cutLine = await _dbHelper.getCutLine(boardName);
    print('Current cutLine for $boardName: $cutLine');  // 디버깅을 위한 로그 추가
    
    final client = http.Client();
    try {
      final url = buildUrl();
      print('Fetching URL: $url');
      
      final response = await client.get(
        Uri.parse(url),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        print('Response status: ${response.statusCode}');
        print('Response body length: ${response.body.length}');  // 응답 본문 길이 출력
        
        String decodedBody;
        if (charset.toLowerCase() == 'euc-kr') {
          // EUC-KR 인코딩 처리
          final bytes = response.bodyBytes;
          final decoder = Encoding.getByName('windows-949');
          if (decoder != null) {
            decodedBody = decoder.decode(bytes);
          } else {
            // windows-949 디코더를 찾을 수 없는 경우 Latin1로 처리
            decodedBody = Latin1Decoder().convert(bytes);
          }
        } else {
          // EUC-KR이 아닌 경우 UTF-8로 디코딩
          decodedBody = utf8.decode(response.bodyBytes);
        }
        
        print('Decoded body length: ${decodedBody.length}');
        final document = parser.parse(decodedBody);
        final posts = <Post>[];
        
        final postElements = document.querySelectorAll(postListSelector);
        print('Found ${postElements.length} post elements');
        
        for (var element in postElements) {
          try {
            if (shouldSkipElement(element)) {
              print('Skipping invalid element');  // 디버깅 메시지 추가
              continue;
            }
            
            final post = parsePost(element);
            if (post != null) {
              // 조회수 기준선 적용
              if (cutLine == 0 || (cutLine > 0 && post.views >= cutLine)) {
                print('Adding post: ${post.title} (views: ${post.views}, cutLine: $cutLine)');
                posts.add(post);
              } else {
                print('Skipping post due to cutLine: ${post.title} (views: ${post.views}, cutLine: $cutLine)');
              }
            }
          } catch (e, stackTrace) {  // 스택 트레이스 추가
            print('Error processing post: $e');
            print('Stack trace: $stackTrace');  // 스택 트레이스 출력
            continue;
          }
        }
        
        print('Total posts after cutLine filtering: ${posts.length}');
        currentPage += 1;
        
        return posts;
      } else {
        print('Failed to load posts: ${response.statusCode}');
        print('Response body: ${response.body}');  // 에러 응답 본문 출력
        throw Exception('Failed to load posts: ${response.statusCode}');
      }
    } catch (e, stackTrace) {  // 스택 트레이스 추가
      print('Error fetching posts: $e');
      print('Stack trace: $stackTrace');  // 스택 트레이스 출력
      throw Exception('Error fetching posts: $e');
    } finally {
      client.close();
    }
  }
  
  String buildUrl();
  bool shouldSkipElement(dynamic element);
  Post? parsePost(dynamic element);
  
  DateTime parseTimestamp(String timeStr) {
    try {
      if (timeStr.contains(':')) {
        // YYYY-MM-DD HH:mm:ss 형식
        final parts = timeStr.split(' ');
        if (parts.length == 2) {
          final dateParts = parts[0].split('-');
          final timeParts = parts[1].split(':');
          if (dateParts.length == 3 && timeParts.length == 3) {
            return DateTime(
              int.parse(dateParts[0]), // year
              int.parse(dateParts[1]), // month
              int.parse(dateParts[2]), // day
              int.parse(timeParts[0]), // hour
              int.parse(timeParts[1]), // minute
              int.parse(timeParts[2]), // second
            );
          }
        }
      }
      
      // 기존 로직
      if (timeStr.contains('분 전')) {
        final minutes = int.parse(timeStr.replaceAll('분 전', ''));
        return DateTime.now().subtract(Duration(minutes: minutes));
      } else if (timeStr.contains('시간 전')) {
        final hours = int.parse(timeStr.replaceAll('시간 전', ''));
        return DateTime.now().subtract(Duration(hours: hours));
      } else if (timeStr.contains('일 전')) {
        final days = int.parse(timeStr.replaceAll('일 전', ''));
        return DateTime.now().subtract(Duration(days: days));
      } else if (timeStr.contains('분전')) {
        final minutes = int.parse(timeStr.replaceAll('분전', ''));
        return DateTime.now().subtract(Duration(minutes: minutes));
      } else if (timeStr.contains('시간전')) {
        final hours = int.parse(timeStr.replaceAll('시간전', ''));
        return DateTime.now().subtract(Duration(hours: hours));
      } else if (timeStr.contains('일전')) {
        final days = int.parse(timeStr.replaceAll('일전', ''));
        return DateTime.now().subtract(Duration(days: days));
      }
      else {
        // 날짜만 있는 경우
        final date = DateTime.parse(timeStr);
        return DateTime(
          date.year,
          date.month,
          date.day,
          23,
          59,
          0,
        );
      }
    } catch (e) {
      print('Error parsing timestamp: $e');
      return DateTime.now();
    }
  }
  
  String buildFullUrl(String url) {
    if (url.startsWith('http')) {
      return url;
    }
    return '$baseUrl$url';
  }

  /// 텍스트에서 숫자만 추출하여 반환합니다.
  /// 예: "조회수 1,234" -> "1234"
  /// 예: "댓글 56개" -> "56"
  String extractNumber(String text) {
    if (text.isEmpty) return '0';
    return text.replaceAll(RegExp(r'[^0-9]'), '');
  }
} 