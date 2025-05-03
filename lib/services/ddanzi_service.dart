import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import '../models/post.dart';

class DdanziService {
  static const String baseUrl = 'https://www.ddanzi.com/free';
  
  int _currentPage = 0;
  
  Future<List<Post>> getPosts({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 0;
    }
    
    final client = http.Client();
    try {
      final url = '$baseUrl?page=${_currentPage + 1}';
      print('Fetching URL: $url');
      
      final response = await client.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8',
          'Accept-Language': 'ko-KR,ko;q=0.9,en-US;q=0.8,en;q=0.7',
          'Cache-Control': 'no-cache',
          'Pragma': 'no-cache',
        },
      );
      
      if (response.statusCode == 200) {
        print('Response status: ${response.statusCode}');
        final document = parser.parse(response.body);
        final posts = <Post>[];
        
        // Find all post items in the page
        final postElements = document.querySelectorAll('table tbody tr');
        print('Found ${postElements.length} post elements');
        
        for (var element in postElements) {
          try {
            // Skip header row
            if (element.querySelector('th') != null) {
              print('Skipping header row');
              continue;
            }
            
            final titleElement = element.querySelector('td.title a');
            final authorElement = element.querySelector('td.author a');
            final viewsElement = element.querySelector('td.readNum');
            final timeElement = element.querySelector('td.time');
            final linkElement = element.querySelector('td.title a');
            
            print('Parsing post:');
            print('Title element: ${titleElement?.text}');
            print('Author element: ${authorElement?.text}');
            print('Views element: ${viewsElement?.text}');
            print('Time element: ${timeElement?.text}');
            print('Link element: ${linkElement?.attributes['href']}');
            
            if (titleElement != null && authorElement != null && 
                viewsElement != null && timeElement != null && linkElement != null) {
              
              final title = titleElement.text.trim();
              final author = authorElement.text.trim();
              final views = int.tryParse(viewsElement.text.trim().replaceAll(',', '')) ?? 0;
              
              // Handle timestamp parsing
              DateTime timestamp;
              try {
                final timeStr = timeElement.text.trim();
                print('Parsing timestamp: $timeStr');
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
                    0,
                  );
                }
              } catch (e) {
                print('Error parsing timestamp: $e');
                timestamp = DateTime.now();
              }
              
              final url = linkElement.attributes['href'] ?? '';
              if (url.isNotEmpty) {
                // 상대 경로인 경우에만 baseUrl 추가
                final fullUrl = url.startsWith('http') ? url : 'https://www.ddanzi.com$url';
                posts.add(Post(
                  title: title,
                  author: author,
                  views: views,
                  timestamp: timestamp,
                  url: fullUrl,
                ));
                print('Successfully added post: $title');
              } else {
                print('Missing URL for post');
              }
            } else {
              print('Missing required elements for post');
            }
          } catch (e) {
            print('Error processing post: $e');
            continue;
          }
        }
        
        print('Total posts parsed: ${posts.length}');
        // Always increment page number for next request
        _currentPage += 1;
        
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
} 