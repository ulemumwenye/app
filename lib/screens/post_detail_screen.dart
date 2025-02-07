import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/post.dart';

class PostDetailScreen extends StatelessWidget {
  final Post post;

  const PostDetailScreen({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(post.title),
        elevation: 2,
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12.0),
              child: Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      offset: Offset(0, 4),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Image.network(
                  post.imageUrl,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  height: 250,
                  errorBuilder: (context, error, stackTrace) {
                    return Image.asset(
                      'assets/placeholder.png',
                      width: double.infinity,
                      fit: BoxFit.cover,
                      height: 250,
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 20.0),
            Text(
              post.title,
              style: const TextStyle(
                fontSize: 26.0,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8.0),
            Text(
              'Posted on ${post.date}', // Assuming post.date is a valid field
              style: const TextStyle(
                fontSize: 14.0,
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16.0),
            Html(
              data: post.content,
              style: {
                "p": Style(
                  fontSize: FontSize(18.0),
                  lineHeight: LineHeight(1.6),
                  margin: Margins.only(bottom: 16.0),
                ),
                "img": Style(
                  width: Width.auto(),
                  height: Height.auto(),
                  display: Display.block,
                  margin: Margins.only(bottom: 16.0),
                ),
              },
              extensions: [
                TagExtension(
                  tagsToExtend: {"img"},
                  builder: (context) {
                    final String? imageUrl = context.attributes['src'];
                    if (imageUrl != null) {
                      return GestureDetector(
                        onTap: () => launchUrl(Uri.parse(imageUrl)),
                        child: Image.network(imageUrl, fit: BoxFit.cover),
                      );
                    }
                    return Container(); // Empty if no image
                  },
                ),
              ],
              onAnchorTap: (url, attributes, element) {
                if (url != null) {
                  launchUrl(Uri.parse(url));
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
