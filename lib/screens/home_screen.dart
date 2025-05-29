import 'dart:async'; // Import for Timer
import 'package:cached_network_image/cached_network_image.dart'; // Added import
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart'; // Import for SpinKit
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/category.dart';
import '../models/post.dart';
import '../services/wordpress_service.dart';
import '../screens/post_detail_screen.dart';
import '../screens/post_search_delegate.dart';

class HomeScreen extends StatefulWidget {
  final bool darkMode;
  final VoidCallback onToggleTheme; // Added callback

  const HomeScreen({
    super.key,
    required this.darkMode,
    required this.onToggleTheme, // Added callback to constructor
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final WordPressService _wordPressService = WordPressService();
  late Future<List<Category>> _futureCategories;
  late Future<List<Post>> _featuredPostsFuture;
  final List<Post> _posts = [];
  final PageController _pageController = PageController(viewportFraction: 0.9);
  final ScrollController _scrollController = ScrollController(); // For back-to-top button
  late AnimationController _animationController; // For animations
  late Animation<double> _fadeAnimation; // For fade-in animations

  int _page = 1;
  bool _isLoading = false;
  int? _selectedCategoryId;
  int _selectedIndex = 0;
  int _currentPage = 0;
  Timer? _timer; // Timer for auto-slide

  @override
  void initState() {
    super.initState();
    _futureCategories = _wordPressService.fetchCategories().then((categories) {
      print('Fetched Categories: $categories'); // Debugging: Print fetched categories
      return categories;
    });
    _featuredPostsFuture = _fetchFeaturedPosts().then((posts) {
      // Pre-cache the first few images after they are fetched
      if (posts.isNotEmpty && mounted) {
        // Ensure the widget is still in the tree
        for (int i = 0; i < posts.length && i < 3; i++) { // Pre-cache up to 3 images
          precacheImage(
            CachedNetworkImageProvider(posts[i].imageUrl),
            context,
            onError: (e, stackTrace) { // Optional error handling for pre-caching
              print('Error precaching image ${posts[i].imageUrl}: $e');
            },
          );
        }
      }
      return posts; // Return the posts for the FutureBuilder
    });
    _loadPosts();
    _startAutoSlide(); // Start auto-slide

    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(_animationController);
    _animationController.forward(); // Start the animation
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancel the timer when the widget is disposed
    _pageController.dispose(); // Dispose the PageController
    _scrollController.dispose(); // Dispose the ScrollController
    _animationController.dispose(); // Dispose the AnimationController
    super.dispose();
  }

  void _startAutoSlide() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_pageController.hasClients) {
        final nextPage = _currentPage + 1;
        if (nextPage >= (_posts.length)) {
          _pageController.animateToPage(
            0,
            duration: const Duration(milliseconds: 300), // Smoother transition
            curve: Curves.easeInOut,
          );
          setState(() => _currentPage = 0);
        } else {
          _pageController.animateToPage(
            nextPage,
            duration: const Duration(milliseconds: 300), // Smoother transition
            curve: Curves.easeInOut,
          );
          setState(() => _currentPage = nextPage);
        }
      }
    });
  }

  Future<List<Post>> _fetchFeaturedPosts() async {
    final posts = await _wordPressService.fetchPosts(
      categoryId: 25, // Fetch posts only from category 25
      page: 1,
      perPage: 5, // Fetch 5 featured posts
    );
    // Log image URLs for investigation
    for (var post in posts) {
      print('Featured Post Image URL: ${post.imageUrl}');
    }
    return posts;
  }

  Future<void> _loadPosts() async {
    setState(() => _isLoading = true);

    try {
      final newPosts = await _wordPressService.fetchPosts(
        categoryId: _selectedCategoryId,
        page: _page,
        perPage: 10, // Fetch 10 posts per page
      );

      setState(() {
        _posts.addAll(newPosts);
        _page++;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load posts: $e')),
      );
    }
  }

  void _onCategorySelected(int categoryId) {
    setState(() {
      _selectedCategoryId = categoryId;
      _posts.clear();
      _page = 1;
      _loadPosts();
    });
  }

  void _onBottomNavTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
      // Scroll to the top of the page
        _scrollController.animateTo(
          0,
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

  Widget _buildFeaturedSlider(List<Post> posts) {
    return SizedBox(
      height: 200,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: posts.length,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (context, index) {
              final post = posts[index];
              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PostDetailScreen(post: post)),
                ),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: post.imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Center(child: CircularProgressIndicator()),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[100],
                        child: Icon(Icons.image_not_supported_outlined, color: Colors.grey[400], size: 48),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          Positioned(
            bottom: 12, // Slightly increased bottom padding
            child: Row(
              children: List.generate(posts.length, (index) {
                return Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentPage == index ? Colors.white : Colors.white.withOpacity(0.5),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabBar(List<Category> categories) {
    // Define the main categories you want to display
    final mainCategories = ['News', 'National Sports', 'Feature', 'Entertainment', 'Business'];

    // Filter the categories to only include the main categories
    final mainCategoryList = categories.where((category) => mainCategories.contains(category.name)).toList();

    // Debugging: Print the fetched and filtered categories
    print('Fetched Categories: $categories');
    print('Filtered Categories: $mainCategoryList');

    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    return Container(
      height: 68, // Adjusted height
      padding: const EdgeInsets.symmetric(vertical: 12.0), // Adjusted padding
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.dividerColor, width: 1.0)),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: mainCategoryList.length,
        itemBuilder: (context, index) {
          final category = mainCategoryList[index];
          final isSelected = _selectedCategoryId == category.id;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8), // Slightly reduced outer padding to accommodate larger chips
            child: ChoiceChip(
              label: Text(category.name),
              selected: isSelected,
              onSelected: (_) => _onCategorySelected(category.id),
              showCheckmark: false,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              labelStyle: isSelected
                  ? TextStyle(
                      color: theme.colorScheme.onPrimary, // Ensures contrast with primaryColor
                      fontWeight: FontWeight.bold,
                    )
                  : TextStyle(
                      color: theme.textTheme.bodyLarge?.color?.withOpacity(0.8),
                    ),
              selectedColor: theme.primaryColor,
              backgroundColor: theme.chipTheme.backgroundColor ?? (isDark ? Colors.grey.shade700 : Colors.grey.shade200),
              shape: isSelected
                  ? const StadiumBorder()
                  : StadiumBorder(
                      side: BorderSide(
                        color: theme.colorScheme.outline.withOpacity(0.5),
                      ),
                    ),
              elevation: isSelected ? 2.0 : 0.0,
              selectedShadowColor: Colors.black.withOpacity(0.2),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPopularArticles(List<Post> posts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12), // Increased vertical padding
          child: Text(
            'Popular Articles',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: 150,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PostDetailScreen(post: post)),
                ),
                child: Card(
                  elevation: 2, // Reduced elevation
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade300, width: 0.5), // Added subtle border
                  ),
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      post.imageUrl,
                      width: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 120,
                        color: Colors.grey[100], // Lighter background for error
                        child: Icon(Icons.image_not_supported_outlined, color: Colors.grey[400], size: 40), // Softer error icon
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Get theme for convenience

    return Scaffold(
      appBar: AppBar(
        elevation: 0.0, // Set elevation to 0
        title: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Nation',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.titleLarge?.color, // Theme-aware color
                ),
              ),
              const TextSpan(
                text: ' Online',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue, // Accent color
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton( // Added Theme Toggle IconButton
            icon: Icon(
              Theme.of(context).brightness == Brightness.dark 
                  ? Icons.light_mode 
                  : Icons.dark_mode,
            ),
            onPressed: widget.onToggleTheme,
            tooltip: 'Toggle Theme',
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(context: context, delegate: PostSearchDelegate(_posts));
            },
          ),
          TextButton(
            onPressed: () {
              _launchUrl('https://mwnation.com/epaper/membership/');
            },
            style: TextButton.styleFrom(
              backgroundColor: Colors.red, // Red background
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6), // Slightly rounded corners
              ),
            ),
            child: const Text(
              'Sign In',
              style: TextStyle(
                color: Colors.white, // White text
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      drawer: Drawer(
        child: FutureBuilder<List<Category>>(
          future: _futureCategories,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No categories found.'));
            }
            final categories = snapshot.data!;
            final mainCategories = ['News', 'Sports', 'Feature', 'Entertainment', 'Business'];
            final drawerCategories = categories.where((category) => !mainCategories.contains(category.name)).toList();

            // Debugging: Print the drawer categories
            print('Drawer Categories: $drawerCategories');

            return ListView.builder(
              itemCount: drawerCategories.length,
              itemBuilder: (context, index) {
                final category = drawerCategories[index];
                return ListTile(
                  title: Text(category.name),
                  onTap: () {
                    _onCategorySelected(category.id);
                    Navigator.pop(context); // Close the drawer
                  },
                );
              },
            );
          },
        ),
      ),
      body: _isLoading && _posts.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/placeholder.png', width: 100, height: 100), // Splash screen image
            const SizedBox(height: 16),
            SpinKitFadingCircle( // Replaced CircularProgressIndicator
              color: Theme.of(context).primaryColor,
              size: 50.0,
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _posts.clear();
            _page = 1;
            _featuredPostsFuture = _fetchFeaturedPosts(); // Refresh featured posts
          });
          await _loadPosts();
        },
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverToBoxAdapter(
              child: FutureBuilder<List<Post>>(
                future: _featuredPostsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error, color: Colors.red, size: 48),
                          const SizedBox(height: 16),
                          Text(
                            'Failed to load featured posts. Please try again.',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _featuredPostsFuture = _fetchFeaturedPosts();
                              });
                            },
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox.shrink();
                  return _buildFeaturedSlider(snapshot.data!);
                },
              ),
            ),
            SliverToBoxAdapter(
              child: FutureBuilder<List<Category>>(
                future: _futureCategories,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error, color: Colors.red, size: 48),
                          const SizedBox(height: 16),
                          Text(
                            'Failed to load categories. Please try again.',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _futureCategories = _wordPressService.fetchCategories();
                              });
                            },
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox.shrink();
                  return _buildCategoryTabBar(snapshot.data!);
                },
              ),
            ),
            SliverToBoxAdapter(
              child: _buildPopularArticles(
                _posts.isNotEmpty 
                    ? _posts.sublist(0, (_posts.length < 5 ? _posts.length : 5)) 
                    : [],
              ), // Display first 5 posts as popular or fewer if not enough posts
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  // If _isLoading is true and we are at the end of the list, show a loading indicator
                  if (index == _posts.length) {
                    return _isLoading 
                        ? const Center(child: CircularProgressIndicator()) 
                        : const SizedBox.shrink(); // Or some other placeholder
                  }
                  final post = _posts[index];
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: Card(
                      elevation: 2, // Reduced elevation
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade300, width: 0.5), // Added subtle border
                      ),
                      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => PostDetailScreen(post: post)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                              child: Image.network(
                                post.imageUrl,
                                height: 150,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  height: 150,
                                  color: Colors.grey[100], // Lighter background for error
                                  child: Icon(Icons.image_not_supported_outlined, color: Colors.grey[400], size: 48), // Softer error icon
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    post.title,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: theme.textTheme.titleMedium?.color, // Theme-aware color
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 10), 
                                  Text(
                                    post.excerpt,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8), // Theme-aware color
                                      height: 1.4, // Added line height
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 16), 
                                  Row(
                                    children: [
                                      Icon(Icons.calendar_today, size: 14, color: theme.textTheme.bodySmall?.color?.withOpacity(0.7)), // Theme-aware icon color
                                      const SizedBox(width: 4),
                                      Text(
                                        'Oct 10, 2023', // Replace with actual post date
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: theme.textTheme.bodySmall?.color?.withOpacity(0.7), // Theme-aware color
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Icon(Icons.person, size: 14, color: theme.textTheme.bodySmall?.color?.withOpacity(0.7)), // Theme-aware icon color
                                      const SizedBox(width: 4),
                                      Text(
                                        'Author Name', // Replace with actual author name
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: theme.textTheme.bodySmall?.color?.withOpacity(0.7), // Theme-aware color
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
                childCount: _posts.length + (_isLoading ? 1 : 0), 
              ),
            ),
          ],
        ),
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
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () {
              _scrollController.animateTo(
                0,
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
              );
            },
            child: const Icon(Icons.arrow_upward),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            onPressed: () {
              setState(() {
                _posts.clear();
                _page = 1;
              });
              _loadPosts();
            },
            child: const Icon(Icons.refresh),
          ),
        ],
      ),
    );
  }
}