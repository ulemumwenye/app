import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nation_online/models/category.dart';
import 'package:nation_online/models/post.dart';
import 'package:nation_online/screens/home_screen.dart';
import 'package:nation_online/services/wordpress_service.dart';
import 'package:cached_network_image/cached_network_image.dart'; // Import for CachedNetworkImage

// Create a mock WordPressService
class MockWordPressService implements WordPressService {
  final List<Category> _categories = [
    Category(id: 1, name: 'News', description: 'General news'),
    Category(id: 2, name: 'National Sports', description: 'Sports within the nation'),
    Category(id: 3, name: 'Feature', description: 'Featured articles'),
    Category(id: 4, name: 'Entertainment', description: 'Entertainment news'),
    Category(id: 5, name: 'Business', description: 'Business news'),
    Category(id: 6, name: 'Other Category 1', description: 'Other category 1'),
    Category(id: 7, name: 'Other Category 2', description: 'Other category 2'),
  ];

  // Helper to generate a list of posts
  List<Post> _generatePosts(int categoryId, int page, int perPage, String categoryNameBase, {bool useUniqueImageUrls = false}) {
    return List.generate(perPage, (index) {
      final postId = (page - 1) * perPage + index + 1 + (categoryId * 1000);
      String imageUrl = 'https://via.placeholder.com/300x200/0000FF/FFFFFF?Text=Post+$postId';
      if (useUniqueImageUrls) {
        // Simple way to make URLs unique for testing caching behavior if needed,
        // or just to have different images.
        imageUrl = 'https://picsum.photos/seed/$postId/300/200';
      }
      return Post(
          id: postId,
          title: '$categoryNameBase Post ${index + 1} (Page $page)',
          content: 'Content of $categoryNameBase post ${index + 1}',
          excerpt: 'Excerpt of $categoryNameBase post ${index + 1}',
          imageUrl: imageUrl,
          date: DateTime.now().toIso8601String(),
          authorName: 'Author $categoryId',
          categoryName: '$categoryNameBase Category',
          categoryId: categoryId,
          authorId: 1,
          link: 'https://example.com/post$postId');
    });
  }

  @override
  Future<List<Category>> fetchCategories() async {
    await Future.delayed(const Duration(milliseconds: 50)); // Simulate network delay
    return _categories;
  }

  @override
  Future<List<Post>> fetchPosts({int? categoryId, int page = 1, int perPage = 10}) async {
    await Future.delayed(const Duration(milliseconds: 100)); // Simulate network delay

    if (categoryId == 25) { // Featured posts - ensure 3-5 posts
      return _generatePosts(25, page, 5, "Featured", useUniqueImageUrls: true);
    }

    Category category = _categories.firstWhere((cat) => cat.id == categoryId, orElse: () => _categories.first);
    return _generatePosts(category.id, page, perPage, category.name);
  }
}

void main() {
  Future<void> pumpHomeScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(darkMode: false),
      ),
    );
    // Increased duration for safety, allowing all async operations to settle.
    // This includes category fetch, featured posts fetch, initial posts for the first tab,
    // and TabController initialization.
    await tester.pumpAndSettle(const Duration(seconds: 2));
  }

  group('HomeScreen Widget Tests', () {
    group('Category TabBar Tests', () {
      testWidgets('Initial state - Default Tab Selected and Glowing Indicator Present', (WidgetTester tester) async {
        await pumpHomeScreen(tester);
        expect(find.widgetWithText(Tab, 'News'), findsOneWidget);
        final tabBar = tester.widget<TabBar>(find.byType(TabBar));
        expect(tabBar.indicator, isA<Decoration>());
        expect(tabBar.indicator, isNotNull);
      });

      testWidgets('TabBar Interaction - Selecting a different tab updates selection', (WidgetTester tester) async {
        await pumpHomeScreen(tester);
        expect(find.widgetWithText(Tab, 'News'), findsOneWidget);
        final sportsTabFinder = find.widgetWithText(Tab, 'National Sports');
        expect(sportsTabFinder, findsOneWidget);
        await tester.tap(sportsTabFinder);
        await tester.pumpAndSettle();
        // Check if posts for "National Sports" (Category ID 2) are now visible.
        // Mock service generates titles like "National Sports Post 1 (Page 1)"
        expect(find.textContaining('National Sports Post 1', findRichText: true), findsWidgets);
      });
    });

    group('Popular Articles Visibility Tests', () {
      testWidgets('Popular Articles section is visible initially', (WidgetTester tester) async {
        await pumpHomeScreen(tester);
        expect(find.text('Popular Articles'), findsOneWidget);
      });

      testWidgets('Popular Articles section hides on scroll down', (WidgetTester tester) async {
        await pumpHomeScreen(tester);
        expect(find.text('Popular Articles'), findsOneWidget);
        // Find the main ListView (usually the first primary scrollable widget)
        final scrollableFinder = find.byWidgetPredicate(
            (widget) => widget is Scrollable && widget.controller?.debugLabel == _scrollController.debugLabel);

        await tester.drag(scrollableFinder, const Offset(0, -300));
        await tester.pumpAndSettle();
        expect(find.text('Popular Articles'), findsNothing);
      });

      testWidgets('Popular Articles section reappears on scroll up', (WidgetTester tester) async {
        await pumpHomeScreen(tester);
        expect(find.text('Popular Articles'), findsOneWidget);
        final scrollableFinder = find.byWidgetPredicate(
            (widget) => widget is Scrollable && widget.controller?.debugLabel == _scrollController.debugLabel);

        await tester.drag(scrollableFinder, const Offset(0, -300));
        await tester.pumpAndSettle();
        expect(find.text('Popular Articles'), findsNothing);

        await tester.drag(scrollableFinder, const Offset(0, 300));
        await tester.pumpAndSettle();
        expect(find.text('Popular Articles'), findsOneWidget);
      });
    });

    group('Featured Slider Tests', () {
      testWidgets('Slider loads, uses CachedNetworkImage, and auto-slides', (WidgetTester tester) async {
        await pumpHomeScreen(tester);

        // Verify PageView is present
        final pageViewFinder = find.byType(PageView);
        expect(pageViewFinder, findsOneWidget);

        // Verify CachedNetworkImage widgets are present within the PageView
        // Check for at least one, assuming featured posts are loaded.
        // The mock service provides 5 featured posts.
        expect(find.byType(CachedNetworkImage), findsNWidgets(5));

        // Check initial page (should be 0)
        PageController pageController = tester.widget<PageView>(pageViewFinder).controller as PageController;
        expect(pageController.page?.round(), 0);

        // Advance the timer for auto-slide (default is 3 seconds)
        await tester.pump(const Duration(seconds: 3, milliseconds: 100)); // Add a bit more for timer to fire
        await tester.pumpAndSettle(); // Let animation complete

        // Verify PageView has scrolled to the next page (page 1)
        pageController = tester.widget<PageView>(pageViewFinder).controller as PageController;
        expect(pageController.page?.round(), 1);
      });

      testWidgets('User interaction pauses auto-slide, and it resumes', (WidgetTester tester) async {
        await pumpHomeScreen(tester);

        final pageViewFinder = find.byType(PageView);
        expect(pageViewFinder, findsOneWidget);
        PageController pageController = tester.widget<PageView>(pageViewFinder).controller as PageController;

        // Initial page
        expect(pageController.page?.round(), 0);

        // Simulate a user drag on the PageView
        await tester.drag(pageViewFinder, const Offset(-200, 0)); // Swipe left
        await tester.pumpAndSettle();

        final int pageAfterDrag = pageController.page!.round();
        expect(pageAfterDrag, 1); // Page changed due to drag

        // Advance timer by less than auto-slide duration (timer should be paused by drag)
        await tester.pump(const Duration(seconds: 1));
        pageController = tester.widget<PageView>(pageViewFinder).controller as PageController;
        expect(pageController.page?.round(), pageAfterDrag); // Page should not have changed

        // Advance timer for full auto-slide duration (timer should resume and fire)
        await tester.pump(const Duration(seconds: 3, milliseconds: 100));
        await tester.pumpAndSettle();
        pageController = tester.widget<PageView>(pageViewFinder).controller as PageController;
        // Expect page to advance from pageAfterDrag. Since there are 5 featured posts, (1+1)%5 = 2
        expect(pageController.page?.round(), (pageAfterDrag + 1) % 5);
      });

      testWidgets('CachedNetworkImage is constructed with placeholder and errorWidget', (WidgetTester tester) async {
        await pumpHomeScreen(tester);

        // Find all CachedNetworkImage widgets
        final imageFinders = find.byType(CachedNetworkImage);
        expect(imageFinders, findsNWidgets(5)); // Expect 5 for featured posts

        // Check the properties of the first CachedNetworkImage
        // This is a basic check. More detailed would be to use a Key or specific image URL.
        CachedNetworkImage firstImage = tester.widget<CachedNetworkImage>(imageFinders.first);
        expect(firstImage.placeholder, isNotNull);
        expect(firstImage.errorWidget, isNotNull);
        expect(firstImage.memCacheHeight, isNotNull);
        expect(firstImage.memCacheWidth, isNotNull);
      });
    });
  });
}

// Helper to get ScrollController for Popular Articles visibility tests
// This is a bit of a hack. Ideally, the ScrollController would be identifiable via a Key.
// For now, we assume the primary ListView's controller is the one we need.
// Note: This helper is not directly used in the final test code above, as direct finder
// for Scrollable is used. Kept for reference.
// ScrollController _findScrollController(WidgetTester tester) {
//   final scrollableState = tester.state<ScrollableState>(find.byType(Scrollable).first);
//   return scrollableState.widget.controller!;
// }
const _scrollController = ScrollController(debugLabel: "PrimaryScrollController"); // Example, not used by test
