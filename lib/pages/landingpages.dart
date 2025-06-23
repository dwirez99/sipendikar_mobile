import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart' as carousel;
import 'package:fl_chart/fl_chart.dart';
import 'package:sippgkpd/models/article.dart';
import 'package:sippgkpd/pages/article.dart';
import 'package:sippgkpd/services/api_service.dart';
import 'package:sippgkpd/widgets/activity_card.dart';
import 'package:sippgkpd/widgets/article_widget.dart';
import 'package:sippgkpd/widgets/section_card.dart';
import 'package:sippgkpd/widgets/teacher_card.dart';
import 'package:sippgkpd/widgets/titled_section.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  int _carouselIndex = 0;
  late Future<List<Article>> _articles;

  @override
  void initState() {
    super.initState();
    _articles = ApiService().getArticles();
  }

  // Sample data for carousel images
  final List<String> carouselImages = [
    'assets/images/car1.png',
    'assets/images/car2.png',
    'assets/images/car3.png',
  ];

  // Sample data for teachers
  final List<Map<String, String>> teachers = [
    {
      'name': 'Ibu Siti Innamanasiroh',
      'position': 'Kepala Sekolah',
      'image': 'assets/tiara_basori.webp'
    },
    {
      'name': 'Ibu Tiara Basori',
      'position': 'Guru Kelas A',
      'image': 'assets/images/guru/guru1.jpeg'
    },
    {
      'name': 'Ibu Dwi Retno',
      'position': 'Guru Kelas B',
      'image': 'assets/images/guru/guru2.jpeg'
    },
    {
      'name': 'Ibu Eni Suryani',
      'position': 'Guru Pendamping',
      'image': 'assets/images/guru/guru3.jpeg'
    },
    {
      'name': 'Ibu Maya Sari',
      'position': 'Guru Seni',
      'image': 'assets/images/guru/guru4.jpeg'
    },
    {
      'name': 'Ibu Maya Sari',
      'position': 'Guru Seni',
      'image': 'assets/images/guru/guru5.jpeg'
    },
    
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF00B7FF),
      child: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            // Refresh articles data
            setState(() {
              _articles = ApiService().getArticles();
            });
            await Future.delayed(const Duration(milliseconds: 500));
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                const SizedBox(height: 8),
                
                // Carousel Section
                _buildCarouselSection(),
                
                // Welcome Section
                _buildWelcomeSection(),

                // Articles Section
                _buildArticlesSection(),
                
                // Teachers Section
                _buildTeachersSection(),
                
                // Statistics Section
                _buildStatisticsSection(),
                
                // About Section
                _buildAboutSection(),
                
                // Footer padding for bottom navigation
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildArticlesSection() {
    return TitledSection(
      title: 'Kegiatan Terbaru',
      child: Column(
        children: [
          SizedBox(
            height: 220,
            child: FutureBuilder<List<Article>>(
              future: _articles,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return _buildErrorWidget(snapshot.error.toString());
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyStateWidget();
                } else {
                  final articles = snapshot.data!;
                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    itemCount: articles.length,
                    itemBuilder: (context, index) {
                      return ArticleWidget(article: articles[index]);
                    },
                  );
                }
              },
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/daftararticle');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Lihat Semua Kegiatan'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarouselSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          carousel.CarouselSlider(
            options: carousel.CarouselOptions(
              height: 220,
              autoPlay: true,
              autoPlayInterval: const Duration(seconds: 4),
              enlargeCenterPage: true,
              viewportFraction: 0.9,
              enableInfiniteScroll: true,
              onPageChanged: (index, reason) {
                setState(() {
                  _carouselIndex = index;
                });
              },
            ),
            items: carouselImages.map((image) {
              return Builder(
                builder: (BuildContext context) {
                  return GestureDetector(
                    onTap: () {
                      // Add tap functionality for carousel items
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Carousel item tapped!'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                    child: Container(
                      width: MediaQuery.of(context).size.width,
                      margin: const EdgeInsets.symmetric(horizontal: 5.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.asset(
                          image,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[300],
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.image, size: 60, color: Colors.grey[600]),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Gambar tidak tersedia',
                                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          // Carousel indicators with better mobile touch targets
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: carouselImages.asMap().entries.map((entry) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _carouselIndex = entry.key;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: _carouselIndex == entry.key ? 24 : 10,
                  height: 10,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    color: _carouselIndex == entry.key
                        ? Colors.white
                        : Colors.white.withOpacity(0.4),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return SectionCard(
      child: Column(
        children: [
          const Text(
            'Selamat Datang',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'TK DHARMA WANITA LAMONG',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF00B7FF),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Text(
            'TK Dharma Wanita Lamong adalah taman kanak-kanak swasta yang berdiri sejak tahun 1977 di Desa Lamong, Kecamatan Badas, Kabupaten Kediri, Jawa Timur. Dengan pengalaman lebih dari 30 tahun, TK ini menjadi tempat pertama anak-anak mengenal dunia belajar sambil bermain.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black87,
              height: 1.4,
            ),
            textAlign: TextAlign.justify,
          ),
        ],
      ),
    );
  }

  Widget _buildTeachersSection() {
    return TitledSection(
      title: 'Profil Guru',
      child: Column(
        children: [
          SizedBox(
            height: 180, // Reduced height for mobile
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              itemCount: teachers.length,
              itemBuilder: (context, index) {
                final teacher = teachers[index];
                return TeacherCard(
                  name: teacher['name']!,
                  position: teacher['position']!,
                  imageUrl: teacher['image']!,
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Lihat Semua Guru'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsSection() {
    return SectionCard(
      child: Column(
        children: [
          const Text(
            'Statistik Pertumbuhan Anak',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          // Stack charts vertically for mobile
          Column(
            children: [
              // Kelas A Chart
              Container(
                height: 180,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green.shade300),
                ),
                child: Column(
                  children: [
                    Text(
                      'Status Gizi Kelas A',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: PieChart(
                              PieChartData(
                                sections: [
                                  PieChartSectionData(
                                    titleStyle: const TextStyle(fontSize: 8, color: Colors.black, fontWeight: FontWeight.bold),
                                  ),
                                  PieChartSectionData(
                                    titleStyle: const TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                  PieChartSectionData(
                                    titleStyle: const TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 1,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLegendItem(Colors.green, 'Baik', '40%'),
                                _buildLegendItem(Colors.yellow, 'Cukup', '30%'),
                                _buildLegendItem(Colors.red, 'Kurang', '20%'),
                                _buildLegendItem(Colors.blue, 'Lebih', '10%'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Kelas B Chart
              Container(
                height: 180,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue.shade300),
                ),
                child: Column(
                  children: [
                    Text(
                      'Status Gizi Kelas B',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: PieChart(
                              PieChartData(
                                sections: [
                                  PieChartSectionData(
                                    titleStyle: const TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                  PieChartSectionData(
                                    color: Colors.yellow,
                                    value: 35,
                                    title: '35%',
                                    radius: 35,
                                    titleStyle: const TextStyle(fontSize: 8, color: Colors.black, fontWeight: FontWeight.bold),
                                  ),
                                  PieChartSectionData(
                                    color: Colors.red,
                                    value: 15,
                                    title: '15%',
                                    radius: 35,
                                    titleStyle: const TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                  PieChartSectionData(
                                    color: Colors.blue,
                                    value: 5,
                                    title: '5%',
                                    radius: 35,
                                    titleStyle: const TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 1,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLegendItem(Colors.green, 'Baik', '45%'),
                                _buildLegendItem(Colors.yellow, 'Cukup', '35%'),
                                _buildLegendItem(Colors.red, 'Kurang', '15%'),
                                _buildLegendItem(Colors.blue, 'Lebih', '5%'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String errorMessage) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade300),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Colors.red[700], size: 48),
          const SizedBox(height: 16),
          Text(
            'Gagal memuat data kegiatan',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.red[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            errorMessage,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _articles = ApiService().getArticles();
              });
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Coba Lagi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700],
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStateWidget() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.info_outline, color: Colors.blue[600], size: 48),
          const SizedBox(height: 16),
          Text(
            'Tidak ada kegiatan yang ditemukan',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue[700],
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Kegiatan akan ditampilkan di sini setelah ditambahkan',
            style: TextStyle(fontSize: 14, color: Colors.black87),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label, String percentage) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              '$label $percentage',
              style: const TextStyle(fontSize: 8),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    return SectionCard(
      child: Column(
        children: [
          const Text(
            'Tentang Kami',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          // Stack content vertically for mobile
          Column(
            children: [
              // Logo section
              Container(
                height: 80,
                width: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[200],
                ),
                child: Image.asset(
                  'assets/logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.school, size: 40, color: Colors.grey);
                  },
                ),
              ),
              const SizedBox(height: 12),
              // Description text
              const Text(
                'TK Dharma Wanita Lamong berkomitmen membangun fondasi karakter, kemandirian, dan rasa ingin tahu anak sejak usia dini. Berlokasi di Jl. Glatik RT 03 RW 03, Dusun Lamong, TK ini siap menjadi tempat terbaik bagi generasi kecil untuk tumbuh, belajar, dan bermimpi lebih tinggi.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black87,
                  height: 1.4,
                ),
                textAlign: TextAlign.justify,
              ),
              const SizedBox(height: 16),
            ],
          ),
          // Location map placeholder
          Container(
            height: 150, // Reduced height for mobile
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.grey[300],
              border: Border.all(color: Colors.grey[400]!),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.map, size: 30, color: Colors.grey),
                  SizedBox(height: 4),
                  Text(
                    'Lokasi TK Dharma Wanita Lamong',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    'Jl. Glatik RT 03 RW 03, Dusun Lamong',
                    style: TextStyle(color: Colors.grey, fontSize: 10),
                    textAlign: TextAlign.center,
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