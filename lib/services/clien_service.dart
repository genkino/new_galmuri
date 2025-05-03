import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import '../models/post.dart';
import 'base_service.dart';

class ClienService extends BaseBoardService {
  @override
  String get baseUrl => 'https://www.clien.net';
  
  @override
  String get boardName => 'clien';
  
  @override
  String get boardDisplayName => '클리앙';
  
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
  String get postListSelector => 'div.list_item, div.list_row';
  
  @override
  Map<String, String> get selectors => {
    'title': 'span.subject_fixed, span.subject, a.subject, div.subject',
    'author': 'span.nickname, span.nick, div.nickname',
    'views': 'span.hit',
    'time': 'span.timestamp, span.time, div.time',
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
    final timeLines = timeStr.split('\n').map((line) => line.trim()).where((line) => line.isNotEmpty).toList();
    final actualTimeStr = timeLines.last;
    
    final timestamp = parseTimestamp(actualTimeStr);
    final url = buildFullUrl(linkElement.attributes['href'] ?? '');
    
    return Post(
      title: title,
      author: author,
      views: views,
      timestamp: timestamp,
      url: url,
    );
  }
  
  int _currentPage = 0;
  
  Future<List<Post>> getPosts({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 0;
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
        
        // Find all post items in the page
        final postElements = document.querySelectorAll(postListSelector);
        print('Found ${postElements.length} post elements');
        
        if (postElements.isEmpty) {
          // Try alternative selectors
          final alternativeElements = document.querySelectorAll('div.list_row');
          print('Trying alternative selectors, found ${alternativeElements.length} elements');
          
          for (var element in alternativeElements) {
            try {
              final titleElement = element.querySelector('span.subject_fixed, span.subject, a.subject, div.subject');
              final authorElement = element.querySelector('span.nickname, span.nick, div.nickname');
              final viewsElement = element.querySelector('span.hit');
              final timeElement = element.querySelector('span.timestamp');
              final linkElement = element.querySelector('a.list_subject, a.subject, div.subject a');
              
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
                  final timeStr = timeElement.attributes['data-timestamp'] ?? timeElement.text.trim();
                  print('Parsing timestamp: $timeStr');
                  
                  // 여러 줄의 시간 문자열이 있는 경우 마지막 줄 사용
                  final timeLines = timeStr.split('\n').map((line) => line.trim()).where((line) => line.isNotEmpty).toList();
                  final actualTimeStr = timeLines.last;
                  print('Using time string: $actualTimeStr');
                  
                  if (actualTimeStr.contains(':')) {
                    // YYYY-MM-DD HH:mm:ss 형식
                    final parts = actualTimeStr.split(' ');
                    final dateParts = parts[0].split('-');
                    final timeParts = parts[1].split(':');
                    timestamp = DateTime(
                      int.parse(dateParts[0]), // year
                      int.parse(dateParts[1]), // month
                      int.parse(dateParts[2]), // day
                      int.parse(timeParts[0]), // hour
                      int.parse(timeParts[1]), // minute
                      int.parse(timeParts[2]), // second
                    );
                  } else {
                    // 날짜만 있는 경우
                    final date = DateTime.parse(actualTimeStr);
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
                
                final url = 'https://www.clien.net${linkElement.attributes['href']}';
                
                posts.add(Post(
                  title: title,
                  author: author,
                  views: views,
                  timestamp: timestamp,
                  url: url,
                ));
                print('Successfully added post: $title');
              } else {
                print('Missing required elements for post');
              }
            } catch (e) {
              print('Error processing post: $e');
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
                  final timeStr = timeElement.attributes['data-timestamp'] ?? timeElement.text.trim();
                  print('Parsing timestamp: $timeStr');
                  
                  // 여러 줄의 시간 문자열이 있는 경우 마지막 줄 사용
                  final timeLines = timeStr.split('\n').map((line) => line.trim()).where((line) => line.isNotEmpty).toList();
                  final actualTimeStr = timeLines.last;
                  print('Using time string: $actualTimeStr');
                  
                  if (actualTimeStr.contains(':')) {
                    // YYYY-MM-DD HH:mm:ss 형식
                    final parts = actualTimeStr.split(' ');
                    final dateParts = parts[0].split('-');
                    final timeParts = parts[1].split(':');
                    timestamp = DateTime(
                      int.parse(dateParts[0]), // year
                      int.parse(dateParts[1]), // month
                      int.parse(dateParts[2]), // day
                      int.parse(timeParts[0]), // hour
                      int.parse(timeParts[1]), // minute
                      int.parse(timeParts[2]), // second
                    );
                  } else {
                    // 날짜만 있는 경우
                    final date = DateTime.parse(actualTimeStr);
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
                
                final url = 'https://www.clien.net${linkElement.attributes['href']}';
                
                posts.add(Post(
                  title: title,
                  author: author,
                  views: views,
                  timestamp: timestamp,
                  url: url,
                ));
                print('Successfully added post: $title');
              } else {
                print('Missing required elements for post');
              }
            } catch (e) {
              print('Error processing post: $e');
              continue;
            }
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
  
  void dispose() {
    // No need to close client here anymore
  }
} 