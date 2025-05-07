import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/post.dart';
import '../models/category.dart';

class WordPressService {
  final String baseUrl = 'https://mwnation.com/wp-json/wp/v2';

  // Fetch categories
  Future<List<Category>> fetchCategories() async {
    final response = await http.get(Uri.parse('$baseUrl/categories?per_page=50&hide_empty=false'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as List;
      return data.map((json) => Category.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load categories');
    }
  }

  // **This method might be missing in your file**
  Future<List<Post>> fetchPosts({int? categoryId, int page = 1, int perPage = 10}) async {
    String url = '$baseUrl/posts?per_page=$perPage&page=$page&_embed';

    if (categoryId != null) {
      url += '&categories=$categoryId';
    }

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as List;
      return data.map((json) => Post.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load posts');
    }
  }
}
