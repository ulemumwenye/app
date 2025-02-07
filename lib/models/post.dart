class Post {
  final int id;
  final String title;
  final String content;
  final String excerpt;
  final String imageUrl;
  final String date;
  final int? categoryId; // Nullable in case there are no categories

  Post({
    required this.id,
    required this.title,
    required this.content,
    required this.excerpt,
    required this.imageUrl,
    required this.date,
    this.categoryId, // Made nullable
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    // Extract the featured image URL safely
    String imageUrl = 'https://via.placeholder.com/150'; // Default placeholder
    if (json['_embedded'] != null &&
        json['_embedded']['wp:featuredmedia'] != null &&
        json['_embedded']['wp:featuredmedia'].isNotEmpty &&
        json['_embedded']['wp:featuredmedia'][0]['source_url'] != null) {
      imageUrl = json['_embedded']['wp:featuredmedia'][0]['source_url'];
    }

    // Extract category safely
    int? categoryId;
    if (json['categories'] != null && json['categories'].isNotEmpty) {
      categoryId = json['categories'][0];
    }

    return Post(
      id: json['id'],
      title: json['title']['rendered'] ?? 'No Title',
      content: json['content']['rendered'] ?? 'No Content',
      excerpt: json['excerpt']['rendered'] ?? 'No Excerpt',
      imageUrl: imageUrl,
      date: json['date'] ?? 'Unknown Date',
      categoryId: categoryId, // This might be null if there are no categories
    );
  }
}
