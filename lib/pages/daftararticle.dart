import 'package:flutter/material.dart';
import 'package:sippgkpd/services/api_service.dart';
import 'package:sippgkpd/models/article.dart';
import 'article.dart'; // Assuming article.dart contains the detail screen

class ArticleListPage extends StatefulWidget {
  const ArticleListPage({super.key});

  @override
  State<ArticleListPage> createState() => _ArticleListPageState();
}

class _ArticleListPageState extends State<ArticleListPage> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Daftar Kegiatan",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF00B7FF),
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Fitur pencarian akan segera hadir!'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              // Show refreshing feedback
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Memperbarui data kegiatan...'),
                  duration: Duration(seconds: 1),
                ),
              );
              _loadArticles();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        color: const Color(0xFF00B7FF),
        onRefresh: () async {
          _loadArticles();
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: FutureBuilder<List<Article>>(
          future: futureArticles,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.error_outline, 
                            color: Colors.red, 
                            size: 64
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "Terjadi Kesalahan",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.red[800],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Text(
                              "${snapshot.error}",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.red[700],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: _loadArticles,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Coba Lagi'),
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.article_outlined, 
                            color: Color(0xFF00B7FF), 
                            size: 64
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "Belum Ada Kegiatan",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[800],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Text(
                              "Silahkan tambahkan kegiatan baru dengan menekan tombol '+' di bawah.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.blue[700],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: () => _showArticleDialog(context),
                            icon: const Icon(Icons.add),
                            label: const Text('Tambah Kegiatan'),
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Color(0xFF00B7FF),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            } else {
              return ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final article = snapshot.data![index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ArticleDetailScreen(article: article),
                          ),
                        );
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Image with gradient overlay
                          Stack(
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                child: Image.network(
                                  article.imageUrl,
                                  width: double.infinity,
                                  height: 160,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      height: 160,
                                      color: Colors.grey[300],
                                      child: const Center(
                                        child: Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              // Action buttons positioned on top of the image
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: Colors.white.withOpacity(0.8),
                                      radius: 18,
                                      child: IconButton(
                                        icon: const Icon(Icons.edit, size: 18),
                                        color: Colors.blue,
                                        onPressed: () => _showArticleDialog(context, article: article),
                                        tooltip: 'Edit Kegiatan',
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    CircleAvatar(
                                      backgroundColor: Colors.white.withOpacity(0.8),
                                      radius: 18,
                                      child: IconButton(
                                        icon: const Icon(Icons.delete, size: 18),
                                        color: Colors.red,
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: const Text('Konfirmasi'),
                                              content: const Text('Apakah Anda yakin ingin menghapus kegiatan ini?'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(context),
                                                  child: const Text('Batal'),
                                                ),
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.pop(context);
                                                    _deleteArticle(context, article.id);
                                                  },
                                                  child: const Text(
                                                    'Hapus',
                                                    style: TextStyle(color: Colors.red),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                        tooltip: 'Hapus Kegiatan',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          // Content section
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  article.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  article.content,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // "Baca Selengkapnya" button
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton.icon(
                                      icon: const Icon(Icons.arrow_forward, size: 16),
                                      label: const Text('Baca Selengkapnya'),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => ArticleDetailScreen(article: article),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
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
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showArticleDialog(context),
        icon: const Icon(Icons.add),
        label: const Text("Tambah Kegiatan"),
        backgroundColor: const Color(0xFF00B7FF),
        foregroundColor: Colors.white,
        elevation: 4,
      ),
    );
  }

  void _deleteArticle(BuildContext context, int id) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00B7FF)),
            ),
          ),
        );
      },
    );

    try {
      await apiService.deleteArticle(id);
      
      // Close loading dialog
      Navigator.of(context).pop();
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kegiatan berhasil dihapus!'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Reload articles
      _loadArticles();
    } catch (e) {
      // Close loading dialog
      Navigator.of(context).pop();
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menghapus kegiatan: $e'),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'COBA LAGI',
            textColor: Colors.white,
            onPressed: () {
              _deleteArticle(context, id);
            },
          ),
        ),
      );
    }
  }

  void _showArticleDialog(BuildContext context, {Article? article}) {
    final titleController = TextEditingController(text: article?.title ?? '');
    final contentController = TextEditingController(text: article?.content ?? '');
    final imageUrlController = TextEditingController(text: article?.imageUrl ?? '');
    
    // Form validation state variables
    bool _titleError = false;
    bool _contentError = false;
    bool _imageUrlError = false;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                article == null ? 'Tambah Kegiatan' : 'Edit Kegiatan',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title Field
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: 'Judul Kegiatan',
                        prefixIcon: const Icon(Icons.title),
                        border: const OutlineInputBorder(),
                        errorText: _titleError ? 'Judul tidak boleh kosong' : null,
                      ),
                      onChanged: (value) {
                        if (value.isNotEmpty && _titleError) {
                          setState(() => _titleError = false);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Content Field
                    TextField(
                      controller: contentController,
                      decoration: InputDecoration(
                        labelText: 'Konten Kegiatan',
                        prefixIcon: const Icon(Icons.description),
                        border: const OutlineInputBorder(),
                        errorText: _contentError ? 'Konten tidak boleh kosong' : null,
                        alignLabelWithHint: true,
                      ),
                      maxLines: 5,
                      onChanged: (value) {
                        if (value.isNotEmpty && _contentError) {
                          setState(() => _contentError = false);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Image URL Field
                    TextField(
                      controller: imageUrlController,
                      decoration: InputDecoration(
                        labelText: 'URL Gambar',
                        prefixIcon: const Icon(Icons.image),
                        border: const OutlineInputBorder(),
                        errorText: _imageUrlError ? 'URL gambar tidak boleh kosong' : null,
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.remove_red_eye),
                          onPressed: () {
                            if (imageUrlController.text.isNotEmpty) {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Preview Gambar'),
                                  content: Image.network(
                                    imageUrlController.text,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.error, color: Colors.red, size: 48),
                                          SizedBox(height: 8),
                                          Text('Tidak dapat memuat gambar. URL mungkin tidak valid.'),
                                        ],
                                      );
                                    },
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Tutup'),
                                    ),
                                  ],
                                ),
                              );
                            }
                          },
                        ),
                      ),
                      onChanged: (value) {
                        if (value.isNotEmpty && _imageUrlError) {
                          setState(() => _imageUrlError = false);
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    
                    // Helper Text for Image URL
                    const Text(
                      'Masukkan URL gambar yang valid atau gunakan layanan seperti https://imgur.com/ untuk mengunggah gambar Anda',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.cancel),
                  label: const Text('Batal'),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    // Validate form fields
                    bool isValid = true;
                    
                    if (titleController.text.isEmpty) {
                      setState(() => _titleError = true);
                      isValid = false;
                    }
                    
                    if (contentController.text.isEmpty) {
                      setState(() => _contentError = true);
                      isValid = false;
                    }
                    
                    if (imageUrlController.text.isEmpty) {
                      setState(() => _imageUrlError = true);
                      isValid = false;
                    }

                    if (isValid) {
                      try {
                        // Show loading indicator
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (BuildContext context) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          },
                        );
                        
                        final title = titleController.text;
                        final content = contentController.text;
                        final imageUrl = imageUrlController.text;
                        
                        if (article == null) {
                          await apiService.createArticle(title, content, imageUrl);
                          Navigator.pop(context); // Close loading dialog
                          Navigator.pop(context); // Close form dialog
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Kegiatan berhasil dibuat!'),
                              backgroundColor: Colors.green,
                            )
                          );
                        } else {
                          await apiService.updateArticle(article.id, title, content, imageUrl);
                          Navigator.pop(context); // Close loading dialog
                          Navigator.pop(context); // Close form dialog
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Kegiatan berhasil diperbarui!'),
                              backgroundColor: Colors.green,
                            )
                          );
                        }
                        _loadArticles();
                      } catch (e) {
                        Navigator.pop(context); // Close loading dialog
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Gagal menyimpan kegiatan: $e'),
                            backgroundColor: Colors.red,
                          )
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.save),
                  label: const Text('Simpan'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            );
          }
        );
      },
    );
  }
}