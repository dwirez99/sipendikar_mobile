import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart' as carousel;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlng;
import 'package:geolocator/geolocator.dart';
import 'package:video_player/video_player.dart';
import 'package:sipendikar/models/article.dart';
import 'package:sipendikar/services/api_service.dart';
import 'package:sipendikar/widgets/article_widget.dart';
import 'package:sipendikar/widgets/section_card.dart';
import 'package:sipendikar/widgets/teacher_card.dart';
import 'package:sipendikar/widgets/titled_section.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  int _carouselIndex = 0;
  late Future<List<Article>> _articles;

  // Video Player Controllers for multiple videos
  List<VideoPlayerController> _videoControllers = [];
  int _currentVideoIndex = 0;
  bool _isShowingControls = false; // To toggle visibility of controls
  Future<void>? _initializeVideoPlayerFuture;

  // Koordinat TK Dharma Wanita Lamong
  static const latlng.LatLng _tkLocation =
      latlng.LatLng(-7.758924828361875, 112.21004309854357); // Ganti dengan koordinat sebenarnya
  latlng.LatLng? _userLatLng;
  double? _distanceInMeters;

  // List of video asset paths
  final List<String> _videoPaths = [
    'assets/videos/kinderflix1.mp4',
    'assets/videos/kinderflix2.mp4',
    // 'assets/videos/kinderflix3.mp4',
  ];

  // Tambahkan state untuk chart status gizi
  Map<String, dynamic>? _statusGiziChartData;
  String? _chartBulan;
  bool _isLoadingChart = false;
  String? _chartError;

  @override
  void initState() {
    super.initState();
    _articles = ApiService().getArticles();
    _getUserLocation();
    _initializeVideoPlayers();
    _fetchStatusGiziChart();
  }

  Future<void> _fetchStatusGiziChart() async {
    setState(() { _isLoadingChart = true; _chartError = null; });
    try {
      final data = await ApiService().getStatusGiziChartData();
      setState(() {
        _statusGiziChartData = data['data'];
        _chartBulan = data['bulan'];
        _isLoadingChart = false;
      });
    } catch (e) {
      setState(() {
        _chartError = e.toString();
        _isLoadingChart = false;
      });
    }
  }

  // Initializes all video controllers from the _videoPaths list
  void _initializeVideoPlayers() async {
    _videoControllers = [];
    List<Future<void>> futures = [];
    for (String path in _videoPaths) {
      final controller = VideoPlayerController.asset(path);
      _videoControllers.add(controller);
      futures.add(controller.initialize());
      controller.setLooping(true); // Loop each video
    }

    _initializeVideoPlayerFuture = Future.wait(futures).then((_) {
      setState(() {});
      // DO NOT AUTOPLAY: Do not call play() here
    });

    // Add a listener to the currently playing video controller to update UI (progress bar)
    // and also to handle video completion (if not looping) or other states.
    if (_videoControllers.isNotEmpty) {
      bool wasPlaying = false;
      _videoControllers[_currentVideoIndex].addListener(() {
        final controller = _videoControllers[_currentVideoIndex];
        final isPlaying = controller.value.isPlaying;
        if (!isPlaying && wasPlaying) {
          // Log only once when paused
          debugPrint('Video paused at: [38;5;2m${controller.value.position}[0m');
        }
        wasPlaying = isPlaying;
        if (mounted) setState(() {});
      });
    }
  }

  // Toggles the play/pause state of the current video
  void _togglePlayPause() {
    if (_videoControllers.isEmpty) return;
    final controller = _videoControllers[_currentVideoIndex];
    if (controller.value.isPlaying) {
      controller.pause();
      debugPrint('User pressed PAUSE at: [38;5;2m[1m${controller.value.position}[0m');
    } else {
      controller.play();
      debugPrint('User pressed PLAY at: [38;5;2m[1m${controller.value.position}[0m');
    }
    setState(() {}); // Update the icon
  }

  // Plays the next video in the list
  void _playNextVideo() {
    if (_videoControllers.isEmpty) return;
    _videoControllers[_currentVideoIndex].pause(); // Pause current video
    _currentVideoIndex = (_currentVideoIndex + 1) % _videoControllers.length;
    _videoControllers[_currentVideoIndex].seekTo(Duration.zero); // Rewind new video
    _videoControllers[_currentVideoIndex].play(); // Play new video
    setState(() {}); // Update UI
  }

  // Plays the previous video in the list
  void _playPreviousVideo() {
    if (_videoControllers.isEmpty) return;
    _videoControllers[_currentVideoIndex].pause(); // Pause current video
    _currentVideoIndex = (_currentVideoIndex - 1 + _videoControllers.length) % _videoControllers.length;
    _videoControllers[_currentVideoIndex].seekTo(Duration.zero); // Rewind new video
    _videoControllers[_currentVideoIndex].play(); // Play new video
    setState(() {}); // Update UI
  }

  @override
  void dispose() {
    // Dispose all video controllers when the widget is disposed
    for (var controller in _videoControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  // Fetches user's current location and calculates distance to TK Dharma Wanita Lamong
  Future<void> _getUserLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // If not, simply return without requesting permission
      return;
    }

    // Check location permission status
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      // Request permission if denied
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // If permission is still denied, return
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      // If permission is permanently denied, return
      return;
    }

    // Get current position and calculate distance
    final position = await Geolocator.getCurrentPosition();
    final userLatLng = latlng.LatLng(position.latitude, position.longitude);
    final distance = latlng.Distance().as(
          latlng.LengthUnit.Meter,
          userLatLng,
          _tkLocation,
        );
    setState(() {
      _userLatLng = userLatLng;
      _distanceInMeters = distance;
    });
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
                // New Video Section with enhanced controls
                _buildVideoSection(),
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

  // Builds the video player section with custom controls as an overlay
  Widget _buildVideoSection() {
    return TitledSection(
      title: 'Video Pembelajaran Siswa',
      child: FutureBuilder(
        future: _initializeVideoPlayerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done && _videoControllers.isNotEmpty) {
            VideoPlayerController currentController = _videoControllers[_currentVideoIndex];
            return Column(
              children: [
                GestureDetector(
                  onTap: () {
                    // Toggle controls visibility on tap
                    setState(() {
                      _isShowingControls = !_isShowingControls;
                    });
                  },
                  child: AspectRatio(
                    aspectRatio: currentController.value.aspectRatio,
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      children: <Widget>[
                        VideoPlayer(currentController),
                        // Animated overlay for controls
                        AnimatedOpacity(
                          opacity: _isShowingControls ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 300),
                          child: Container(
                            color: Colors.black.withOpacity(0.4), // Semi-transparent background for controls
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                // Video Progress Indicator (Slider)
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                  child: VideoProgressIndicator(
                                    currentController,
                                    allowScrubbing: true, // Allows scrubbing through the video
                                    colors: VideoProgressColors(
                                      playedColor: Colors.blue[700]!,
                                      bufferedColor: Colors.grey[400]!,
                                      backgroundColor: Colors.grey[700]!,
                                    ),
                                  ),
                                ),
                                // Play/Pause, Next/Previous buttons
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.skip_previous,
                                        color: Colors.white,
                                        size: 32,
                                      ),
                                      onPressed: _playPreviousVideo,
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        currentController.value.isPlaying
                                            ? Icons.pause_circle_filled // Pause icon if playing
                                            : Icons.play_circle_fill, // Play icon if paused
                                        color: Colors.white,
                                        size: 48,
                                      ),
                                      onPressed: _togglePlayPause,
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.skip_next,
                                        color: Colors.white,
                                        size: 32,
                                      ),
                                      onPressed: _playNextVideo,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8), // Padding below controls
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Display current video time and total duration
                Text(
                  'Video ${currentController.value.position.inMinutes}:${(currentController.value.position.inSeconds % 60).toString().padLeft(2, '0')} / ${currentController.value.duration.inMinutes}:${(currentController.value.duration.inSeconds % 60).toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 8),
                // Display current video index
                Text(
                  'Video ke ${_currentVideoIndex + 1} dari ${_videoControllers.length}',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            );
          } else {
            // Show a loading indicator while videos are initializing
            return Container(
              height: 200, // Placeholder height for loading
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
        },
      ),
    );
  }

  // Builds the articles section, fetching data from API
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

  // Builds the carousel section with image slides and indicators
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
                                  Icon(Icons.image,
                                      size: 60, color: Colors.grey[600]),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Gambar tidak tersedia',
                                    style: TextStyle(
                                        color: Colors.grey[600], fontSize: 12),
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

  // Builds the welcome section with general information about the school
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

  // Builds the teachers profile section
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
              onPressed: () {
                // Action for "Lihat Semua Guru" button
              },
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

  // Builds the statistics section with pie charts for nutrition status
  Widget _buildStatisticsSection() {
    return SectionCard(
      child: Column(
        children: [
          const Text(
            'Statistik Status Gizi Siswa',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          if (_isLoadingChart)
            const CircularProgressIndicator()
          else if (_chartError != null)
            Text('Gagal memuat data: [38;5;1m[1m[0m[38;5;1m$_chartError[0m', style: TextStyle(color: Colors.red))
          else if (_statusGiziChartData != null)
            Column(
              children: [
                const Text('Kelas A', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(
                  height: 180,
                  child: PieChart(
                    PieChartData(
                      sections: _buildPieSections(_statusGiziChartData!['kelasA']),
                      sectionsSpace: 2,
                      centerSpaceRadius: 30,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text('Kelas B', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(
                  height: 180,
                  child: PieChart(
                    PieChartData(
                      sections: _buildPieSections(_statusGiziChartData!['kelasB']),
                      sectionsSpace: 2,
                      centerSpaceRadius: 30,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                if (_chartBulan != null)
                  Text('Bulan: $_chartBulan', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            )
          else
            const Text('Belum ada data status gizi.'),
        ],
      ),
    );
  }

  // Tambahkan helper untuk PieChart
  List<PieChartSectionData> _buildPieSections(Map<String, dynamic>? data) {
    if (data == null) return [];
    final colors = [
      const Color(0xFFe57373), // Gizi Kurang
      const Color(0xFF81c784), // Gizi Baik
      const Color(0xFFffd54f), // Gizi Lebih
      const Color(0xFF64b5f6), // Obesitas
    ];
    final labels = ['Gizi Kurang', 'Gizi Baik', 'Gizi Lebih', 'Obesitas'];
    final total = labels.fold<int>(0, (sum, k) => sum + ((data[k] ?? 0) as int));
    return List.generate(labels.length, (i) {
      final value = (data[labels[i]] ?? 0) as int;
      final percent = total > 0 ? (value / total * 100) : 0;
      return PieChartSectionData(
        color: colors[i],
        value: value.toDouble(),
        title: value > 0 ? '${labels[i]}\n${percent.toStringAsFixed(1)}%' : '',
        radius: 50,
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black),
      );
    });
  }

  // Helper widget to display error messages for data loading failures
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
                _articles = ApiService().getArticles(); // Retry fetching articles
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

  // Helper widget to display when no data is found
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

  // Builds the "About Us" section including school information and a map
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
          Column(
            children: [
              Container(
                height: 80,
                width: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[200],
                ),
                child: Image.asset(
                  'assets/images/logo/logo_dw.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.school, size: 40, color: Colors.grey);
                  },
                ),
              ),
              const SizedBox(height: 12),
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
              // OpenStreetMap displaying TK location and user's current location
              SizedBox(
                height: 200,
                width: double.infinity,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: _tkLocation, // Center map on TK location
                      initialZoom: 16,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                        subdomains: const ['a', 'b', 'c'],
                        userAgentPackageName: 'com.example.sippgkpd',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            width: 40,
                            height: 40,
                            point: _tkLocation, // Marker for TK location
                            child: const Icon(Icons.location_on,
                                color: Colors.red, size: 36),
                          ),
                          if (_userLatLng != null)
                            Marker(
                              width: 40,
                              height: 40,
                              point: _userLatLng!, // Marker for user's location
                              child: const Icon(Icons.person_pin_circle,
                                  color: Colors.blue, size: 36),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Display distance to TK if user location is available
              if (_distanceInMeters != null)
                Text(
                  'Jarak ke TK: ' +
                      (_distanceInMeters! > 1000
                          ? (_distanceInMeters! / 1000).toStringAsFixed(2) +
                              ' km'
                          : _distanceInMeters!.toStringAsFixed(0) + ' m'),
                  style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      fontWeight: FontWeight.bold),
                ),
              // Message if user location is still being fetched
              if (_userLatLng == null)
                const Text(
                  'Mengambil lokasi Anda... (Pastikan izin lokasi aktif)',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
