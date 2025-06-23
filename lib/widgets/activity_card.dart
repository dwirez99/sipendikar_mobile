import 'package:flutter/material.dart';
import '../utils/constants.dart';

class ArticleCard extends StatelessWidget {
  final String title;
  final String imageUrl;
  final String description;

  const ArticleCard({
    Key? key,
    required this.title,
    required this.imageUrl,
    required this.description,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get screen width for responsive design
    final screenWidth = MediaQuery.of(context).size.width;

    // Determine font sizes based on screen width
    final titleFontSize = screenWidth <= 640
        ? 10.0
        : (screenWidth <= 991 ? 11.0 : 12.0);

    final descriptionFontSize = screenWidth <= 640
        ? 4.0
        : (screenWidth <= 991 ? 5.0 : 6.0);

    return Container(
      width: 127,
      decoration: const BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.25),
            blurRadius: 4,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBackgroundColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black, width: 2),
          boxShadow: const [
            BoxShadow(
              color: Colors.black,
              offset: Offset(14, 14),
            ),
          ],
        ),
        padding: const EdgeInsets.all(6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: titleFontSize,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 5),
            Image.network(
              imageUrl,
              width: 106,
              height: 51,
              fit: BoxFit.cover,
              semanticLabel: 'Article image',
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 106,
                  height: 51,
                  color: Colors.grey[300],
                  child: const Center(
                    child: Icon(Icons.image_not_supported),
                  ),
                );
              },
            ),
            const SizedBox(height: 5),
            Text(
              description,
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: descriptionFontSize,
                color: Colors.black,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 5),
            Text(
              'Selengkapnya',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: descriptionFontSize,
                color: Colors.black,
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ArticleCardWithTwoImages extends StatelessWidget {
  final String title;
  final String imageUrl1;
  final String imageUrl2;
  final String description;

  const ArticleCardWithTwoImages({
    Key? key,
    required this.title,
    required this.imageUrl1,
    required this.imageUrl2,
    required this.description,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get screen width for responsive design
    final screenWidth = MediaQuery.of(context).size.width;

    // Determine font sizes based on screen width
    final titleFontSize = screenWidth <= 640
        ? 10.0
        : (screenWidth <= 991 ? 11.0 : 12.0);

    final descriptionFontSize = screenWidth <= 640
        ? 4.0
        : (screenWidth <= 991 ? 5.0 : 6.0);

    return Container(
      width: 127,
      decoration: const BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.25),
            blurRadius: 4,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBackgroundColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black, width: 2),
          boxShadow: const [
            BoxShadow(
              color: Colors.black,
              offset: Offset(14, 14),
            ),
          ],
        ),
        padding: const EdgeInsets.all(6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: titleFontSize,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 5),
            // First image (hidden on mobile)
            if (screenWidth > 640)
              Image.network(
                imageUrl1,
                width: 106,
                height: 51,
                fit: BoxFit.cover,
                semanticLabel: 'Article image',
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 106,
                    height: 51,
                    color: Colors.grey[300],
                    child: const Center(
                      child: Icon(Icons.image_not_supported),
                    ),
                  );
                },
              ),
            if (screenWidth > 640) const SizedBox(height: 5),
            // Second image (always visible)
            Image.network(
              imageUrl2,
              width: 106,
              height: 51,
              fit: BoxFit.cover,
              semanticLabel: 'Article image',
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 106,
                  height: 51,
                  color: Colors.grey[300],
                  child: const Center(
                    child: Icon(Icons.image_not_supported),
                  ),
                );
              },
            ),
            const SizedBox(height: 5),
            Text(
              description,
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: descriptionFontSize,
                color: Colors.black,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 5),
            Text(
              'Selengkapnya',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: descriptionFontSize,
                color: Colors.black,
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ActivityCard extends StatelessWidget {
  final String title;
  final String description;
  final String imageUrl;

  const ActivityCard({
    super.key,
    required this.title,
    required this.description,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.asset(
                imageUrl,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.local_activity, size: 40, color: Colors.grey),
                  );
                },
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}