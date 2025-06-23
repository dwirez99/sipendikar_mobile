import 'package:flutter/material.dart';

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
  State<CustomNavbar> createState() => _CustomNavbarState();
}

class _CustomNavbarState extends State<CustomNavbar>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isSidebarOpen = false;

  @override
  void initState() {
    super.initState();
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

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // FAB logo button (kanan bawah)
        Positioned(
          right: 24,
          bottom: 24,
          child: GestureDetector(
            onTap: _toggleSidebar,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: Colors.black, width: 2),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Image.asset(
                  'assets/logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.school, size: 32, color: Colors.grey);
                  },
                ),
              ),
            ),
          ),
        ),
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
                  'assets/logo.png',
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
                icon: Icons.info,
                title: 'Tentang Kami',
                onTap: () {
                  _closeSidebar();
                  Navigator.pushNamed(context, '/about');
                },
              ),
              _buildMenuItem(
                icon: Icons.school,
                title: 'Daftar Guru',
                onTap: () {
                  _closeSidebar();
                  Navigator.pushNamed(context, '/guru');
                },
              ),

              // Menu khusus berdasarkan role
              if (widget.userRole == 'orangtua') ...[
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

              if (widget.userRole == 'guru') ...[
                const Divider(),
                _buildExpansionTile(
                  icon: Icons.manage_accounts,
                  title: 'Guru',
                  children: [
                    _buildSubMenuItem(
                      title: 'Kelola Peserta Didik',
                      onTap: () {
                        _closeSidebar();
                        Navigator.pushNamed(context, '/peserta-didik');
                      },
                    ),
                    _buildSubMenuItem(
                      title: 'Kelola Wali Murid',
                      onTap: () {
                        _closeSidebar();
                        Navigator.pushNamed(context, '/wali-murid');
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
                        widget.userName.substring(0, 2).toUpperCase(),
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
                      widget.userName,
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
                  if (widget.userRole == 'orangtua')
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
                  if (widget.userRole == 'orangtua') const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.logout,
                      label: 'Logout',
                      color: Colors.red,
                      onTap: () {
                        _closeSidebar();
                        widget.onLogout?.call();
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