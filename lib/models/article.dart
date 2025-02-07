class Article {
  final String title;
  final String description;
  final String imageUrl;
  final String publishedAt;

  const Article({
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.publishedAt,
  });

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      title: json['title'] ?? 'No Title',
      description: json['description'] ?? 'No Description',
      imageUrl: json['urlToImage'] ?? 'https://via.placeholder.com/150',
      publishedAt: json['publishedAt'] ?? 'No Date',
    );
  }
}