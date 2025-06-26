import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:sipendikar/pages/login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pages/landingpages.dart';
import 'pages/daftararticle.dart';
import 'pages/manage_kegiatan_page.dart';
import 'pages/manage_orangtua_page.dart';
import 'pages/manage_pesertadidik_page.dart';
import 'pages/analisis_statusgizi_page.dart';
import 'pages/nilai_siswa_page.dart';
import 'pages/status_gizi_page.dart';
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
      title: 'Sipendikar',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        FlutterQuillLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'), // English
        Locale('id'), // Indonesian
      ],
      initialRoute: '/',
      routes: {
        '/': (context) => const MainApp(),
        '/login': (context) => const LoginPage(),
        '/home': (context) => const MainApp(),
        '/daftararticle': (context) => const ArticleListPage(),
        '/guru': (context) => const Scaffold(body: Center(child: Text('Halaman Guru'))),
        '/about': (context) => const Scaffold(body: Center(child: Text('Tentang Kami'))),
        '/kegiatan-instansi': (context) => const ManageKegiatanPage(),
        '/kelola-orangtua': (context) => const ManageOrangtuaPage(),
        '/kelola-pesertadidik': (context) => const ManagePesertaDidikPage(),
        '/analisis-statusgizi': (context) => const AnalisisStatusGiziPage(),
        '/nilai-siswa': (context) => const NilaiSiswaPage(),
        '/status-gizi': (context) => const StatusGiziPage(),
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
  ];

  String _userRole = 'guest';
  String _userName = 'Guest';
  
  // Position for draggable FAB
  double _fabX = 0;
  double _fabY = 0;
  bool _fabInitialized = false;

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
    // Initialize FAB position if not done yet
    if (!_fabInitialized) {
      _fabX = MediaQuery.of(context).size.width - 100;
      _fabY = MediaQuery.of(context).size.height - 200;
      _fabInitialized = true;
    }

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
          // Draggable Floating Action Button
          Positioned(
            left: _fabX,
            top: _fabY,
            child: Draggable(
              feedback: _buildFAB(isDragging: true),
              childWhenDragging: Container(), // Hide original when dragging
              child: _buildFAB(),
              onDragEnd: (details) {
                setState(() {
                  // Get screen dimensions
                  final screenWidth = MediaQuery.of(context).size.width;
                  final screenHeight = MediaQuery.of(context).size.height;
                  
                  // Calculate new position with boundaries
                  _fabX = details.offset.dx.clamp(0, screenWidth - 56);
                  _fabY = details.offset.dy.clamp(0, screenHeight - 56);
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAB({bool isDragging = false}) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDragging ? 0.3 : 0.2),
            spreadRadius: isDragging ? 3 : 2,
            blurRadius: isDragging ? 8 : 5,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.white, width: 3),
      ),
      child: FloatingActionButton(
        onPressed: () {
          _navbarKey.currentState?.openSidebar();
        },
        elevation: isDragging ? 8 : 4,
        backgroundColor: const Color(0xFFF58B05),
        shape: const CircleBorder(),
        heroTag: "draggable_fab",
        child: ClipOval(
          child: Image.asset(
            'assets/images/logo/logo_dw.png',
            width: 40,
            height: 40,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.school, color: Colors.white, size: 24);
            },
          ),
        ),
      ),
    );
  }
}
