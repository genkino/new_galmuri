import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'models/post.dart';
import 'services/base_service.dart';
import 'services/clien_service.dart';
import 'services/ddanzi_service.dart';
import 'services/theqoo_service.dart';
import 'services/etoland_service.dart';
import 'services/dcinside_service.dart';
import 'screens/settings_screen.dart';
import 'database/database_helper.dart';
import 'package:url_launcher/url_launcher.dart';
import 'widgets/post_card.dart';
import 'models/board_type.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '게시판 통합 뷰어',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const PostListScreen(),
    );
  }
}

class PostListScreen extends StatefulWidget {
  const PostListScreen({super.key});

  @override
  State<PostListScreen> createState() => _PostListScreenState();
}

class _PostListScreenState extends State<PostListScreen> {
  final Map<String, BaseBoardService> _services = {
    'clien': ClienService(),
    'ddanzi': DdanziService(),
    'theqoo': TheqooService(),
    'etoland': EtolandService(),
    'dcinside': DcinsideService(),
  };
  
  List<Post> _posts = [];
  bool _isLoading = false;
  bool _isDisposed = false;
  BoardType _selectedBoard = BoardType.all;
  final ScrollController _scrollController = ScrollController();
  Post? _selectedPost;
  final _dbHelper = DatabaseHelper();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _loadPosts();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _isDisposed = true;
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_isLoading && _scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.position.pixels;
      final delta = MediaQuery.of(context).size.height * 0.2;
      
      if (maxScroll - currentScroll <= delta) {
        _loadPosts();
      }
    }
  }

  Future<void> _loadPosts() async {
    if (_isDisposed) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      List<Post> posts = [];
      
      if (_selectedBoard == BoardType.all) {
        for (var service in _services.values) {
          service.currentPage = _currentPage;  // 0-based index로 변환
          final servicePosts = await service.getPosts();
          posts.addAll(servicePosts.map((post) => Post(
            title: '[${service.boardDisplayName}] ${post.title}',
            author: post.author,
            views: post.views,
            timestamp: post.timestamp,
            url: post.url,
          )).toList());
        }
        // 전체보기일 경우 시간순으로 정렬
        posts.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      } else {
        final service = _services[_selectedBoard.serviceKey];
        if (service != null) {
          service.currentPage = _currentPage;  // 0-based index로 변환
          final servicePosts = await service.getPosts();
          posts.addAll(servicePosts.map((post) => Post(
            title: post.title,
            author: post.author,
            views: post.views,
            timestamp: post.timestamp,
            url: post.url,
          )).toList());
        }
      }

      if (!_isDisposed) {
        setState(() {
          if (_currentPage == 0) {
            _posts = posts;  // 첫 페이지일 경우 목록 교체
          } else {
            _posts.addAll(posts);  // 다음 페이지일 경우 목록 추가
          }
          _currentPage++;  // 페이지 번호 증가
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!_isDisposed) {
        setState(() {
          _isLoading = false;
        });
      }
      print('Error loading posts: $e');
    }
  }

  Future<void> _onRefresh() async {
    setState(() {
      _posts = [];
      _currentPage = 0;
    });
    await _loadPosts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedBoard.displayName),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsScreen(services: _services),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _onRefresh,
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                '게시판 선택',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ...BoardType.values.map((boardType) => ListTile(
              title: Text(boardType.displayName),
              selected: _selectedBoard == boardType,
              onTap: () {
                setState(() {
                  _selectedBoard = boardType;
                  _posts = [];
                  _currentPage = 0;
                });
                _loadPosts();
                Navigator.pop(context);
              },
            )),
          ],
        ),
      ),
      body: _isLoading && _posts.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              controller: _scrollController,
              itemCount: _posts.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _posts.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                
                final post = _posts[index];
                // 서비스 키 추출 로직 수정
                String serviceKey = '';
                if (_selectedBoard == BoardType.all) {
                  if (post.title.startsWith('[')) {
                    final endBracket = post.title.indexOf(']');
                    if (endBracket != -1) {
                      final siteName = post.title.substring(1, endBracket);
                      switch (siteName) {
                        case '클리앙':
                          serviceKey = 'clien';
                          break;
                        case '딴지일보':
                          serviceKey = 'ddanzi';
                          break;
                        case '더쿠':
                          serviceKey = 'theqoo';
                          break;
                        case '이토랜드':
                          serviceKey = 'etoland';
                          break;
                        case '디씨인사이드':
                          serviceKey = 'dcinside';
                          break;
                      }
                    }
                  }
                } else {
                  serviceKey = _selectedBoard.serviceKey;
                }

                final service = _services[serviceKey];
                if (service == null) {
                  return const SizedBox.shrink();  // 서비스를 찾을 수 없는 경우 빈 위젯 반환
                }

                return PostCard(
                  title: post.title,
                  author: post.author,
                  views: post.views,
                  timestamp: post.timestamp,
                  url: post.url,
                  service: service,
                );
              },
            ),
    );
  }
}
