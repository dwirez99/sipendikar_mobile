import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CustomNavbar extends StatefulWidget {
  final String userRole;
  final String userName;
  final VoidCallback? onLogout;
  final VoidCallback? onProfile;

  const CustomNavbar({
    Key? key,
    required this.userRole,
    required this.userName,
    this.onLogout,
    this.onProfile,
  }) : super(key: key);

  @override
  CustomNavbarState createState() => CustomNavbarState();
}

class CustomNavbarState extends State<CustomNavbar>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isSidebarOpen = false;

  String _userRole = 'guest';
  String _userName = 'Guest';

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _slideAnimation = Tween<Offset>(
      begin: const Offset(-1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    String userRole = 'guest';
    final rolesString = prefs.getString('userRole');
    if (rolesString != null && rolesString.isNotEmpty) {
      // Cek jika rolesString adalah list JSON
      if ((rolesString.startsWith('[') && rolesString.endsWith(']')) || rolesString.contains(',')) {
        // Coba parse sebagai list
        try {
          final rolesList = rolesString
              .replaceAll('[', '')
              .replaceAll(']', '')
              .replaceAll('"', '')
              .replaceAll("'", '')
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();
          if (rolesList.isNotEmpty) {
            userRole = rolesList.first;
          }
        } catch (_) {
          userRole = rolesString;
        }
      } else {
        userRole = rolesString;
      }
    }
    setState(() {
      _userRole = userRole;
      _userName = prefs.getString('userName') ?? widget.userName;
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleSidebar() {
    setState(() {
      _isSidebarOpen = !_isSidebarOpen;
    });

    if (_isSidebarOpen) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  void _closeSidebar() {
    if (_isSidebarOpen) {
      setState(() {
        _isSidebarOpen = false;
      });
      _animationController.reverse();
    }
  }

  void openSidebar() {
    if (!_isSidebarOpen) {
      setState(() {
        _isSidebarOpen = true;
      });
      _animationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Overlay untuk menutup sidebar
        if (_isSidebarOpen)
          GestureDetector(
            onTap: _closeSidebar,
            child: AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (context, child) {
                return Container(
                  color: Colors.black.withOpacity(0.5 * _fadeAnimation.value),
                  width: double.infinity,
                  height: double.infinity,
                );
              },
            ),
          ),
        // Sidebar
        AnimatedBuilder(
          animation: _slideAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(
                _slideAnimation.value.dx * MediaQuery.of(context).size.width,
                0,
              ),
              child: _isSidebarOpen
                  ? Container(
                      width: MediaQuery.of(context).size.width * 0.85,
                      height: MediaQuery.of(context).size.height,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 10,
                            offset: Offset(2, 0),
                          ),
                        ],
                      ),
                      child: _buildSidebarContent(),
                    )
                  : const SizedBox.shrink(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSidebarContent() {
    final userRole = _userRole;
    final userName = _userName;
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Color(0xFFF58B05),
            border: Border(
              bottom: BorderSide(color: Colors.black, width: 2),
            ),
          ),
          child: SafeArea(
            child: Row(
              children: [
                Image.asset(
                  'assets/images/logo/logo_dw.png',
                  width: 40,
                  height: 40,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Menu Navigasi',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _closeSidebar,
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Menu Items
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 10),
            children: [
              _buildMenuItem(
                icon: Icons.home,
                title: 'Halaman Utama',
                onTap: () {
                  _closeSidebar();
                  Navigator.pushNamed(context, '/home');
                },
              ),
              _buildMenuItem(
                icon: Icons.event,
                title: 'Kegiatan',
                onTap: () {
                  _closeSidebar();
                  Navigator.pushNamed(context, '/daftararticle');
                },
              ),
              _buildMenuItem(
                icon: Icons.login,
                title: 'Login',
                onTap: () {
                  _closeSidebar();
                  Navigator.pushNamed(context, '/login');
                },
              ),
              if (userRole == 'orangtua') ...[
                const Divider(),
                _buildExpansionTile(
                  icon: Icons.child_care,
                  title: 'Siswa',
                  children: [
                    _buildSubMenuItem(
                      title: 'Nilai Siswa',
                      onTap: () {
                        _closeSidebar();
                        Navigator.pushNamed(context, '/nilai-siswa');
                      },
                    ),
                    _buildSubMenuItem(
                      title: 'Status Gizi Siswa',
                      onTap: () {
                        _closeSidebar();
                        Navigator.pushNamed(context, '/status-gizi');
                      },
                    ),
                  ],
                ),
              ],
              if (userRole == 'guru') ...[
                const Divider(),
                _buildExpansionTile(
                  icon: Icons.manage_accounts,
                  title: 'Guru',
                  children: [
                    _buildSubMenuItem(
                      title: 'Kelola Peserta Didik',
                      onTap: () {
                        _closeSidebar();
                        Navigator.pushNamed(context, '/kelola-pesertadidik');
                      },
                    ),
                    _buildSubMenuItem(
                      title: 'Deteksi Stunting',
                      onTap: () {
                        _closeSidebar();
                        Navigator.pushNamed(context, '/stunting');
                      },
                    ),
                    _buildSubMenuItem(
                      title: 'Kelola Kegiatan Instansi',
                      onTap: () {
                        _closeSidebar();
                        Navigator.pushNamed(context, '/kegiatan-instansi');
                      },
                    ),
                    _buildSubMenuItem(
                      title: 'Kelola Orangtua',
                      onTap: () {
                        _closeSidebar();
                        Navigator.pushNamed(context, '/kelola-orangtua');
                      },
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),

        // User Info & Logout
        Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: Colors.grey, width: 1),
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF58B05),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(
                        userName.length >= 2 ? userName.substring(0, 2).toUpperCase() : userName.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      userName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (userRole == 'orangtua')
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.person,
                        label: 'Profile',
                        onTap: () {
                          _closeSidebar();
                          widget.onProfile?.call();
                        },
                      ),
                    ),
                  if (userRole == 'orangtua') const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.logout,
                      label: 'Logout',
                      color: Colors.red,
                      onTap: () async {
                        _closeSidebar();
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.remove('token');
                        await prefs.remove('userRole');
                        await prefs.remove('userName');
                        if (context.mounted) {
                          Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: const Color(0xFFF58B05),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }

  Widget _buildExpansionTile({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return ExpansionTile(
      leading: Icon(
        icon,
        color: const Color(0xFFF58B05),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      children: children,
    );
  }

  Widget _buildSubMenuItem({
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      title: Text(
        title,
        style: const TextStyle(fontSize: 14),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.only(left: 60, right: 20),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(
        icon,
        size: 18,
        color: color ?? Colors.white,
      ),
      label: Text(
        label,
        style: TextStyle(
          color: color ?? Colors.white,
          fontSize: 14,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color ?? const Color(0xFFF58B05),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}