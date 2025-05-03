import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import '../models/post.dart';

class ClienService {
  static const String baseUrl = 'https://www.clien.net/service/group/clien_all';
  
  final _client = http.Client();
  int _currentPage = 0;
  
  Future<List<Post>> getPosts({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 0;
    }
    
    try {
      final url = '$baseUrl?od=T31&po=$_currentPage';
      
      final response = await _client.get(
        Uri.parse(url),
        headers: {
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
        },
      );
      
      if (response.statusCode == 200) {
        final document = parser.parse(response.body);
        final posts = <Post>[];
        
        // Find all post items in the page
        final postElements = document.querySelectorAll('div.list_item');
        
        if (postElements.isEmpty) {
          // Try alternative selectors
          final alternativeElements = document.querySelectorAll('div.list_row');
          
          for (var element in alternativeElements) {
            try {
              final titleElement = element.querySelector('span.subject_fixed, span.subject, a.subject, div.subject');
              final authorElement = element.querySelector('span.nickname, span.nick, div.nickname');
              final viewsElement = element.querySelector('span.hit');
              final timeElement = element.querySelector('span.timestamp, span.time, div.time');
              final linkElement = element.querySelector('a.list_subject, a.subject, div.subject a');
              
              if (titleElement != null && authorElement != null && 
                  viewsElement != null && timeElement != null && linkElement != null) {
                
                final title = titleElement.text.trim();
                final author = authorElement.text.trim();
                final views = int.tryParse(viewsElement.text.trim().replaceAll(',', '')) ?? 0;
                
                // Handle timestamp parsing
                DateTime timestamp;
                try {
                  final timeStr = timeElement.attributes['data-timestamp'] ?? timeElement.text.trim();
                  timestamp = DateTime.parse(timeStr);
                } catch (e) {
                  timestamp = DateTime.now();
                }
                
                final url = 'https://www.clien.net${linkElement.attributes['href']}';
                
                posts.add(Post(
                  title: title,
                  author: author,
                  views: views,
                  timestamp: timestamp,
                  url: url,
                ));
              }
            } catch (e) {
              continue;
            }
          }
        } else {
          for (var element in postElements) {
            try {
              final titleElement = element.querySelector('span.subject_fixed, span.subject, a.subject, div.subject');
              final authorElement = element.querySelector('span.nickname, span.nick, div.nickname');
              final viewsElement = element.querySelector('span.hit');
              final timeElement = element.querySelector('span.timestamp, span.time, div.time');
              final linkElement = element.querySelector('a.list_subject, a.subject, div.subject a');
              
              if (titleElement != null && authorElement != null && 
                  viewsElement != null && timeElement != null && linkElement != null) {
                
                final title = titleElement.text.trim();
                final author = authorElement.text.trim();
                final views = int.tryParse(viewsElement.text.trim().replaceAll(',', '')) ?? 0;
                
                // Handle timestamp parsing
                DateTime timestamp;
                try {
                  final timeStr = timeElement.attributes['data-timestamp'] ?? timeElement.text.trim();
                  timestamp = DateTime.parse(timeStr);
                } catch (e) {
                  timestamp = DateTime.now();
                }
                
                final url = 'https://www.clien.net${linkElement.attributes['href']}';
                
                posts.add(Post(
                  title: title,
                  author: author,
                  views: views,
                  timestamp: timestamp,
                  url: url,
                ));
              }
            } catch (e) {
              continue;
            }
          }
        }
        
        // Always increment page number for next request
        _currentPage += 1;
        
        return posts;
      } else {
        throw Exception('Failed to load posts: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching posts: $e');
    }
  }
  
  void dispose() {
    _client.close();
  }
} 