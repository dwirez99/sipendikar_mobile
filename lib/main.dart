import 'package:flutter/material.dart';
import 'pages/landingpages.dart';
import 'pages/daftararticle.dart';
import 'pages/siswa.dart';
import 'widgets/navigation_button.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TK Dharma Wanita Lamong',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const MainApp(),
        '/home': (context) => const MainApp(),
        '/daftararticle': (context) => const ArticleListPage(),
        '/guru': (context) => const Scaffold(body: Center(child: Text('Halaman Guru'))),
        '/about': (context) => const Scaffold(body: Center(child: Text('Tentang Kami'))),
      },
    );
  }
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  int _currentPageIndex = 0;
  final PageController _pageController = PageController();

  final List<Widget> _pages = const <Widget>[
    LandingPage(),
    ArticleListPage(),
    DaftarSiswaPage(),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _navigateToPage(int index) {
    setState(() {
      _currentPageIndex = index;
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  // State for controlling the visibility of the navigation sidebar
  bool _isNavbarVisible = false;

  void _toggleNavbar() {
    setState(() {
      _isNavbarVisible = !_isNavbarVisible;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Main content using PageView for smooth transitions
          PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPageIndex = index;
              });
            },
            children: _pages,
          ),
          
          // Conditional display of the CustomNavbar
          if (_isNavbarVisible)
            Positioned.fill(
              child: GestureDetector(
                onTap: _toggleNavbar,
                child: Container(
                  color: Colors.black.withOpacity(0.5),
                  child: Stack(
                    children: [
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        width: MediaQuery.of(context).size.width * 0.85,
                        child: CustomNavbar(
                          userRole: 'orangtua',
                          userName: 'Dwi Rez',
                          onLogout: () {
                            _toggleNavbar();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Logout pressed')),
                            );
                          },
                          onProfile: () {
                            _toggleNavbar();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Profile pressed')),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentPageIndex,
        onTap: _navigateToPage,
        selectedItemColor: const Color(0xFF00B7FF),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event),
            label: 'Kegiatan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Siswa',
          ),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(color: Colors.white, width: 3),
        ),
        child: FloatingActionButton(
          onPressed: _toggleNavbar,
          elevation: 4,
          backgroundColor: const Color(0xFFF58B05),  // Orange color to match nav header
          shape: const CircleBorder(),
          child: ClipOval(
            child: Image.asset(
              'assets/images/logo/logo_dw.png',
              width: 40,
              height: 40,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                print('Error loading logo: $error');
                return const Icon(Icons.school, color: Colors.white, size: 32);
              },
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}

// Because we're no longer using the Z-Score page, we can remove this class.
// If you need to add it back in the future, you can create a separate file for it.
