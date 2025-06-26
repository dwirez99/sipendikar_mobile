import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pesertadidik.dart';
import '../services/api_service.dart';
import '../widgets/qr_code_widget.dart';

class NilaiSiswaPage extends StatefulWidget {
  const NilaiSiswaPage({Key? key}) : super(key: key);

  @override
  State<NilaiSiswaPage> createState() => _NilaiSiswaPageState();
}

class _NilaiSiswaPageState extends State<NilaiSiswaPage> {
  final ApiService apiService = ApiService();
  late Future<List<PesertaDidik>> pesertaDidikFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      pesertaDidikFuture = _loadStudentData();
    });
  }

  Future<List<PesertaDidik>> _loadStudentData() async {
    try {
      print('=== DEBUG: Loading student data for parent ===');
      
      // Check if user is logged in and has userName
      final prefs = await SharedPreferences.getInstance();
      final userName = prefs.getString('userName');
      final userRole = prefs.getString('userRole');
      
      print('Username from SharedPreferences: $userName');
      print('User role: $userRole');
      
      if (userName == null || userName.isEmpty) {
        throw Exception('Username tidak ditemukan. Silakan login ulang.');
      }
      
      if (userRole != 'orangtua') {
        throw Exception('Halaman ini hanya untuk orang tua siswa.');
      }
      
      final students = await apiService.getPesertaDidikByParent();
      print('Found ${students.length} students for parent: $userName');
      
      if (students.isEmpty) {
        print('No students found. This could mean:');
        print('1. Parent name in database does not match username: $userName');
        print('2. No students are linked to this parent');
        print('3. API endpoint returned empty data');
      }
      
      return students;
    } catch (e) {
      print('Error loading student data: $e');
      rethrow;
    }
  }

  Future<void> _downloadPenilaian(String filePath, String studentName) async {
    if (filePath.isEmpty) return;
    
    try {
      String url = filePath;
      if (!url.startsWith('http')) {
        // Handle different path formats from backend
        String cleanPath = url.replaceFirst(RegExp(r'^/?'), '');
        
        // Check if path already contains 'penilaian/' prefix
        if (!cleanPath.startsWith('penilaian/')) {
          cleanPath = 'penilaian/' + cleanPath;
        }
        
        url = 'https://projek1-production.up.railway.app/storage/' + cleanPath;
      }
      
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membuka file: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showQrCode(String filePath, String studentName) {
    if (filePath.isEmpty) return;
    
    try {
      String url = filePath;
      if (!url.startsWith('http')) {
        // Handle different path formats from backend
        String cleanPath = url.replaceFirst(RegExp(r'^/?'), '');
        
        // Check if path already contains 'penilaian/' prefix
        if (!cleanPath.startsWith('penilaian/')) {
          cleanPath = 'penilaian/' + cleanPath;
        }
        
        url = 'https://projek1-production.up.railway.app/storage/' + cleanPath;
      }
      
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return QrCodeWidget(
            data: url,
            title: 'QR Code File Penilaian',
            subtitle: 'Penilaian untuk $studentName',
          );
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuat QR Code: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Nilai Siswa',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFFF58B05),
        elevation: 2,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: FutureBuilder<List<PesertaDidik>>(
        future: pesertaDidikFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF58B05)),
                  ),
                  SizedBox(height: 16),
                  Text('Memuat data siswa...'),
                ],
              ),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Gagal memuat data',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF58B05),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.school_outlined,
                      size: 64,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Belum ada data siswa',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Data siswa Anda akan muncul di sini',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
          }

          final students = snapshot.data!;
          return RefreshIndicator(
            color: const Color(0xFFF58B05),
            onRefresh: () async {
              _loadData();
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: students.length,
              itemBuilder: (context, index) {
                final student = students[index];
                String? fotoUrl = student.foto;
                if (fotoUrl != null && fotoUrl.isNotEmpty && !fotoUrl.startsWith('http')) {
                  fotoUrl = 'https://projek1-production.up.railway.app/storage/' + 
                            fotoUrl.replaceFirst(RegExp(r'^/?'), '');
                }

                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header dengan foto dan info siswa
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Foto siswa
                            CircleAvatar(
                              radius: 35,
                              backgroundColor: Colors.grey[300],
                              backgroundImage: fotoUrl != null && fotoUrl.isNotEmpty
                                  ? NetworkImage(fotoUrl)
                                  : null,
                              child: (fotoUrl == null || fotoUrl.isEmpty)
                                  ? Icon(Icons.person, size: 35, color: Colors.grey[600])
                                  : null,
                            ),
                            const SizedBox(width: 16),
                            // Info siswa
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    student.namaPd,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2C3E50),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF58B05).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          'NIS: ${student.nis}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: Color(0xFFF58B05),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          'Kelas ${student.kelas}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.blue,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Tanggal Lahir: ${student.tanggalLahir}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  Text(
                                    'Jenis Kelamin: ${student.jenisKelamin}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 16),
                        
                        // Section Nilai/Penilaian
                        Row(
                          children: [
                            Icon(
                              Icons.assignment,
                              color: const Color(0xFFF58B05),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'File Penilaian',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2C3E50),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        
                        if (student.filePenilaian != null && student.filePenilaian!.isNotEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              border: Border.all(color: Colors.green.withOpacity(0.3)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.description,
                                      color: Colors.green[700],
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'File penilaian tersedia',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.green[700],
                                            ),
                                          ),
                                          Text(
                                            student.filePenilaian!.split('/').last,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.green[600],
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () => _showQrCode(
                                          student.filePenilaian!,
                                          student.namaPd,
                                        ),
                                        icon: const Icon(Icons.qr_code, size: 16),
                                        label: const Text('QR Code'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFFF58B05),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                          textStyle: const TextStyle(fontSize: 12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () => _downloadPenilaian(
                                          student.filePenilaian!,
                                          student.namaPd,
                                        ),
                                        icon: const Icon(Icons.download, size: 16),
                                        label: const Text('Unduh'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                          textStyle: const TextStyle(fontSize: 12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          )
                        else
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              border: Border.all(color: Colors.orange.withOpacity(0.3)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Colors.orange[700],
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'File penilaian belum tersedia',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.orange[700],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
