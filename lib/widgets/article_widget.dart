import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:sipendikar/models/article.dart';
import 'package:sipendikar/pages/article.dart';

class AuthorInfoWidget extends StatelessWidget {
  const AuthorInfoWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Author Avatar
        Container(
          margin: const EdgeInsets.only(right: 10),
          child: ClipOval(
            child: CustomPaint(
              size: const Size(45, 43),
              painter: AuthorAvatarPainter(),
            ),
          ),
        ),

        // Author Details
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Author Name
            Text(
              'Ibu Sholikah',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w700,
                fontSize: _getResponsiveFontSize(screenWidth, 13, 11, 9),
                color: Colors.black,
              ),
            ),

            // Author Role
            Text(
              'Guru',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w700,
                fontSize: _getResponsiveFontSize(screenWidth, 9, 11, 9),
                color: const Color(0xFF828282),
              ),
            ),

            // Publication Info
            Row(
              children: [
                Text(
                  'Di Publikasikan',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w700,
                    fontSize: _getResponsiveFontSize(screenWidth, 9, 11, 9),
                    color: const Color(0xFF828282),
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  '12-12-2012',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w700,
                    fontSize: _getResponsiveFontSize(screenWidth, 9, 11, 9),
                    color: const Color(0xFF828282),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // Helper method to calculate responsive font sizes
  double _getResponsiveFontSize(double screenWidth, double defaultSize, double mediumSize, double smallSize) {
    if (screenWidth <= 640) {
      return smallSize;
    } else if (screenWidth <= 991) {
      return mediumSize;
    } else {
      return defaultSize;
    }
  }
}

// Custom painter to create the author avatar SVG-like appearance
class AuthorAvatarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Create a placeholder circular avatar with gray background
    final Paint paint = Paint()
      ..color = const Color(0xFFD9D9D9)
      ..style = PaintingStyle.fill;

    // Draw ellipse for the avatar
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2),
        width: size.width,
        height: size.height,
      ),
      paint,
    );

    // In a real implementation, you would load and draw the actual image here
    // This is a simplified version that mimics the SVG mask effect
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

class RelatedArticleItem extends StatelessWidget {
  final String title;

  const RelatedArticleItem({
    Key? key,
    required this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          // Thumbnail
          Container(
            width: 62,
            height: 50,
            margin: const EdgeInsets.only(right: 10),
            color: const Color(0xFFD9D9D9),
          ),

          // Article Title
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w700,
                fontSize: _getResponsiveFontSize(screenWidth, 23, 20, 18),
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to calculate responsive font sizes
  double _getResponsiveFontSize(double screenWidth, double defaultSize, double mediumSize, double smallSize) {
    if (screenWidth <= 640) {
      return smallSize;
    } else if (screenWidth <= 991) {
      return mediumSize;
    } else {
      return defaultSize;
    }
  }
}

class ArticleWidget extends StatelessWidget {
  final Article article;

  const ArticleWidget({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ArticleDetailScreen(article: article),
          ),
        );
      },
      child: Container(
        width: 150,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                child: Hero(
                  tag: 'article-image-${article.id}',
                  child: Image.network(
                    article.imageUrl,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: Colors.grey[200],
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00B7FF)),
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
                        child:
                            const Icon(Icons.image, size: 40, color: Colors.grey),
                      );
                    },
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  article.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}