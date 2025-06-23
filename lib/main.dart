import 'package:flutter/material.dart';
import 'package:sippgkpd/pages/login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pages/landingpages.dart';
import 'pages/daftararticle.dart';
import 'pages/siswa.dart';
import 'widgets/navigation_button.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');
  runApp(MyApp(isLoggedIn: token != null));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SIPPGKPD',
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const MainApp(),
        '/login': (context) => const LoginPage(),
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
  final PageController _pageController = PageController();
  final GlobalKey<CustomNavbarState> _navbarKey = GlobalKey<CustomNavbarState>();

  final List<Widget> _pages = const <Widget>[
    LandingPage(),
    ArticleListPage(),
    DaftarSiswaPage(),
  ];

  String _userRole = 'guest';
  String _userName = 'Guest';

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userRole = prefs.getString('userRole') ?? 'guest';
      _userName = prefs.getString('userName') ?? 'Guest';
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            children: _pages,
          ),
          CustomNavbar(
            key: _navbarKey,
            userRole: _userRole,
            userName: _userName,
            onLogout: null,
            onProfile: null,
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
          onPressed: () {
            _navbarKey.currentState?.openSidebar();
          },
          elevation: 4,
          backgroundColor: const Color(0xFFF58B05),
          shape: const CircleBorder(),
          child: ClipOval(
            child: Image.asset(
              'assets/images/logo/logo_dw.png',
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
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
