import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'models/post.dart';
import 'services/base_service.dart';
import 'services/clien_service.dart';
import 'services/ddanzi_service.dart';
import 'services/theqoo_service.dart';

void main() {
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
  };
  
  List<Post> _posts = [];
  bool _isLoading = false;
  bool _isDisposed = false;
  String _selectedBoard = 'all';
  final ScrollController _scrollController = ScrollController();
  Post? _selectedPost;

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
      
      if (_selectedBoard == 'all') {
        for (var service in _services.values) {
          final servicePosts = await service.getPosts(refresh: true);
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
        final service = _services[_selectedBoard];
        if (service != null) {
          final servicePosts = await service.getPosts(refresh: true);
          posts.addAll(servicePosts);
        }
      }

      if (!_isDisposed) {
        setState(() {
          _posts = posts;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedBoard == 'all' ? '전체보기' : 
                    _selectedBoard == 'clien' ? '클리앙' : 
                    _selectedBoard == 'ddanzi' ? '딴지일보' : '더쿠'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPosts,
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
            ListTile(
              title: const Text('전체보기'),
              selected: _selectedBoard == 'all',
              onTap: () {
                setState(() {
                  _selectedBoard = 'all';
                });
                _loadPosts();
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('클리앙'),
              selected: _selectedBoard == 'clien',
              onTap: () {
                setState(() {
                  _selectedBoard = 'clien';
                });
                _loadPosts();
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('딴지일보'),
              selected: _selectedBoard == 'ddanzi',
              onTap: () {
                setState(() {
                  _selectedBoard = 'ddanzi';
                });
                _loadPosts();
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('더쿠'),
              selected: _selectedBoard == 'theqoo',
              onTap: () {
                setState(() {
                  _selectedBoard = 'theqoo';
                });
                _loadPosts();
                Navigator.pop(context);
              },
            ),
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
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  child: ListTile(
                    title: Text(
                      post.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(post.author),
                        const SizedBox(width: 16),
                        Text('${post.views}'),
                        const SizedBox(width: 16),
                        Text(_formatTimestamp(post.timestamp)),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PostDetailScreen(post: post),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}일 전';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}시간 전';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}분 전';
    } else {
      return '방금 전';
    }
  }
}

class PostDetailScreen extends StatefulWidget {
  final Post post;

  const PostDetailScreen({super.key, required this.post});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  late final WebViewController controller;
  bool isLoading = true;
  bool isDisposed = false;

  @override
  void initState() {
    super.initState();
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            if (!isDisposed) {
              setState(() {
                isLoading = true;
              });
            }
          },
          onPageFinished: (String url) {
            if (!isDisposed) {
              setState(() {
                isLoading = false;
              });
            }
          },
          onWebResourceError: (WebResourceError error) {
            if (!isDisposed) {
              setState(() {
                isLoading = false;
              });
            }
          },
        ),
      )
      ..setBackgroundColor(Colors.white)
      ..setUserAgent('Mozilla/5.0 (iPhone; CPU iPhone OS 17_4 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.3.1 Mobile/15E148 Safari/604.1')
      ..loadRequest(Uri.parse(widget.post.url));
  }

  @override
  void dispose() {
    isDisposed = true;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.post.title),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: controller),
          if (isLoading)
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('페이지 로딩 중...'),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
