import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import '../models/post.dart';

abstract class BaseBoardService {
  String get baseUrl;
  String get boardName;
  String get boardDisplayName;
  Map<String, String> get headers;
  String get postListSelector;
  Map<String, String> get selectors;
  
  int currentPage = 0;
  
  Future<List<Post>> getPosts({bool refresh = false}) async {
    if (refresh) {
      currentPage = 0;
    }
    
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
        final document = parser.parse(response.body);
        final posts = <Post>[];
        
        final postElements = document.querySelectorAll(postListSelector);
        print('Found ${postElements.length} post elements');
        
        for (var element in postElements) {
          try {
            if (shouldSkipElement(element)) {
              continue;
            }
            
            final post = parsePost(element);
            if (post != null) {
              posts.add(post);
            }
          } catch (e) {
            print('Error processing post: $e');
            continue;
          }
        }
        
        print('Total posts parsed: ${posts.length}');
        currentPage += 1;
        
        return posts;
      } else {
        print('Failed to load posts: ${response.statusCode}');
        throw Exception('Failed to load posts: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching posts: $e');
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
      print('Parsing timestamp: $timeStr');
      
      if (timeStr.contains(':')) {
        // 시간만 있는 경우 (HH:mm 형식)
        final now = DateTime.now();
        final timeParts = timeStr.split(':');
        return DateTime(
          now.year,
          now.month,
          now.day,
          int.parse(timeParts[0]),
          int.parse(timeParts[1]),
        );
      } else {
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
} 