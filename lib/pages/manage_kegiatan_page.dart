import 'package:flutter/material.dart';
import 'package:sippgkpd/services/api_service.dart';
import 'package:sippgkpd/models/article.dart';
import 'manage_article_form.dart';

class ManageKegiatanPage extends StatefulWidget {
  const ManageKegiatanPage({super.key});

  @override
  State<ManageKegiatanPage> createState() => _ManageKegiatanPageState();
}

class _ManageKegiatanPageState extends State<ManageKegiatanPage> {
  final ApiService apiService = ApiService();
  late Future<List<Article>> futureArticles;

  @override
  void initState() {
    super.initState();
    _loadArticles();
  }

  void _loadArticles() {
    setState(() {
      futureArticles = apiService.getArticles();
    });
  }

  void _showForm({Article? article}) async {
    final isEdit = article != null;
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ManageArticleForm(
          article: article == null
              ? null
              : {
                  'id': article.id,
                  'title': article.title,
                  'content': article.content,
                  'thumbnail': article.imageUrl,
                },
          isEdit: isEdit,
          onSubmit: (data, thumbnail) async {
            if (isEdit) {
              if (thumbnail != null) {
                await apiService.updateArticleMultipart(
                  article.id,
                  data['title'],
                  data['content'],
                  thumbnail,
                );
              } else {
                await apiService.updateArticle(
                  article.id,
                  data['title'],
                  data['content'],
                  data['thumbnail'] ?? '',
                );
              }
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Kegiatan berhasil diperbarui!'), backgroundColor: Colors.green),
              );
            } else {
              if (thumbnail != null) {
                await apiService.createArticleMultipart(
                  data['title'],
                  data['content'],
                  thumbnail,
                );
              } else {
                await apiService.createArticle(
                  data['title'],
                  data['content'],
                  data['thumbnail'] ?? '',
                );
              }
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Kegiatan berhasil ditambahkan!'), backgroundColor: Colors.green),
              );
            }
            _loadArticles();
          },
        ),
      ),
    );
    if (result == true) _loadArticles();
  }

  void _deleteArticle(int id) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    try {
      await apiService.deleteArticle(id);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kegiatan berhasil dihapus!'), backgroundColor: Colors.green),
      );
      _loadArticles();
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghapus kegiatan: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Kegiatan Instansi'),
        backgroundColor: const Color(0xFF00B7FF),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadArticles,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Kegiatan'),
        backgroundColor: const Color(0xFF00B7FF),
      ),
      body: FutureBuilder<List<Article>>(
        future: futureArticles,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Gagal memuat data: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Belum ada kegiatan.'));
          } else {
            final articles = snapshot.data!;
            return ListView.builder(
              itemCount: articles.length,
              itemBuilder: (context, index) {
                final article = articles[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: Image.network(
                      article.imageUrl,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.image, size: 40),
                    ),
                    title: Text(article.title),
                    subtitle: Text(
                      article.content,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _showForm(article: article),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Konfirmasi'),
                                content: const Text('Hapus kegiatan ini?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Batal'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      _deleteArticle(article.id);
                                    },
                                    child: const Text('Hapus', style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
