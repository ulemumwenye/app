import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart'; // Make sure to add shimmer package in your pubspec.yaml
import 'package:url_launcher/url_launcher.dart';
import '../models/category.dart';
import '../models/post.dart';
import '../services/wordpress_service.dart';
import 'post_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  final bool darkMode;

  const HomeScreen({super.key, required this.darkMode});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final WordPressService _wordPressService = WordPressService();
  late Future<List<Category>> _futureCategories;
  final List<Post> _posts = [];
  int _page = 1;
  bool _isLoading = false;
  int? _selectedCategoryId;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _futureCategories = _wordPressService.fetchCategories();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    setState(() {
      _isLoading = true;
    });

    final newPosts = await _wordPressService.fetchPosts(
      categoryId: _selectedCategoryId,
      page: _page,
    );

    setState(() {
      _posts.addAll(newPosts);
      _page++;
      _isLoading = false;
    });
  }

  void _onCategorySelected(int categoryId) {
    setState(() {
      _selectedCategoryId = categoryId;
      _posts.clear();
      _page = 1;
      _loadPosts();
    });
  }

  Future<void> _launchUrl(String urlString) async {
    final url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch $urlString')),
      );
    }
  }

  void _showSocialMediaPopup() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Follow Us'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Image.asset('assets/facebook.png', width: 24, height: 24),
                title: const Text('Facebook'),
                onTap: () {
                  _launchUrl('https://facebook.com');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Image.asset('assets/twitter.png', width: 24, height: 24),
                title: const Text('Twitter'),
                onTap: () {
                  _launchUrl('https://twitter.com');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Image.asset('assets/instagram.png', width: 24, height: 24),
                title: const Text('Instagram'),
                onTap: () {
                  _launchUrl('https://instagram.com');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Image.asset('assets/tik-tok.png', width: 24, height: 24),
                title: const Text('TikTok'),
                onTap: () {
                  _launchUrl('https://tiktok.com');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Image.asset('assets/whatsapp.png', width: 24, height: 24),
                title: const Text('WhatsApp'),
                onTap: () {
                  _launchUrl('https://whatsapp.com');
                  Navigator.pop(context);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _onBottomNavTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
        break;
      case 1:
        _launchUrl('https://youtube.com');
        break;
      case 2:
        _launchUrl('https://podcasts.com');
        break;
      case 3:
        _showSocialMediaPopup();
        break;
    }
  }

  // Your enhanced category menu widget
  Widget _buildCategoryTabBar(List<Category> categories) {
    return Container(
      height: 60.0,
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      decoration: BoxDecoration(
        color: Colors.blue.shade800,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: categories.map((category) {
            final isSelected = _selectedCategoryId == category.id;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20.0),
                gradient: isSelected
                    ? const LinearGradient(
                  colors: [Colors.orange, Colors.deepOrange],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
                    : null,
                color: isSelected ? null : Colors.white.withOpacity(0.2),
                boxShadow: isSelected
                    ? [
                  BoxShadow(
                    color: Colors.pinkAccent.withOpacity(0.6),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
                    : [],
              ),
              child: GestureDetector(
                onTap: () => _onCategorySelected(category.id),
                child: Text(
                  category.name,
                  style: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : Colors.white70,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // Shimmer effect widget to show while loading
  Widget _buildShimmerEffect() {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
        crossAxisSpacing: 8.0,
        mainAxisSpacing: 8.0,
        childAspectRatio: 0.8,
      ),
      padding: const EdgeInsets.all(8.0),
      itemCount: 6, // Number of shimmer placeholders
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Card(
            elevation: 4.0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    color: Colors.white,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 16.0,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 4.0),
                      Container(
                        width: double.infinity,
                        height: 14.0,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nation Online'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: PostSearchDelegate(_posts),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Implement settings functionality
            },
          ),
          TextButton(
            onPressed: () {
              _launchUrl('https://mwnation.com/epaper/membership/');
            },
            child: const Text(
              'Sign In',
              style: TextStyle(color: Colors.white, fontSize: 16.0),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          FutureBuilder<List<Category>>(
            future: _futureCategories,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('No categories found.'));
              } else {
                final categories = snapshot.data!;
                return _buildCategoryTabBar(categories);
              }
            },
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                setState(() {
                  _posts.clear();
                  _page = 1;
                });
                await _loadPosts();
              },
              // Use shimmer effect if loading and no posts are available
              child: _isLoading && _posts.isEmpty
                  ? _buildShimmerEffect()
                  : GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                  crossAxisSpacing: 8.0,
                  mainAxisSpacing: 8.0,
                  childAspectRatio: 0.8,
                ),
                padding: const EdgeInsets.all(8.0),
                itemCount: _posts.length + 1,
                itemBuilder: (context, index) {
                  if (index < _posts.length) {
                    final post = _posts[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => PostDetailScreen(post: post)),
                        );
                      },
                      child: Card(
                        elevation: 4.0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(8.0)),
                                child: Image.network(
                                  post.imageUrl,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Image.asset(
                                      'assets/placeholder.png',
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    );
                                  },
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    post.title,
                                    style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4.0),
                                  Text(
                                    post.excerpt,
                                    style: TextStyle(fontSize: 14.0, color: Colors.grey[600]),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  } else {
                    return _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : Container();
                  }
                },
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onBottomNavTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.video_library), label: 'Videos'),
          BottomNavigationBarItem(icon: Icon(Icons.mic), label: 'Podcasts'),
          BottomNavigationBarItem(icon: Icon(Icons.more_horiz), label: 'More'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _posts.clear();
            _page = 1;
          });
          _loadPosts();
        },
        child: const Icon(Icons.refresh),
      ),
    );
  }
}

class PostSearchDelegate extends SearchDelegate<Post?> {
  final List<Post> posts;

  PostSearchDelegate(this.posts);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = posts
        .where((post) => post.title.toLowerCase().contains(query.toLowerCase()))
        .toList();
    return _buildSearchResults(results);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = posts
        .where((post) => post.title.toLowerCase().contains(query.toLowerCase()))
        .toList();
    return _buildSearchResults(suggestions);
  }

  Widget _buildSearchResults(List<Post> results) {
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final post = results[index];
        return ListTile(
          title: Text(post.title),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => PostDetailScreen(post: post)),
            );
          },
        );
      },
    );
  }
}
