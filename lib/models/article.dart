class Article {
  final int id;
  final String title;
  final String content;
  final String imageUrl;

  Article({
    required this.id,
    required this.title,
    required this.content,
    required this.imageUrl,
  });

  factory Article.fromJson(Map<String, dynamic> json) {
    print('Processing JSON in Article.fromJson: $json');
    
    // Safely extract id with type checking
    int id;
    try {
      id = json['id'] is int ? json['id'] : int.parse(json['id'].toString());
    } catch (e) {
      print('Error parsing id: ${json['id']}');
      id = -1;
    }
    
    return Article(
      id: id,
      title: json['judul']?.toString() ?? json['title']?.toString() ?? '',
      content: json['konten']?.toString() ?? json['content']?.toString() ?? '',
      imageUrl: json['thumbnail_url']?.toString() ?? json['image_url']?.toString() ?? json['imageUrl']?.toString() ?? '',
    );
  }
}
