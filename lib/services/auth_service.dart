import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  static const String baseUrl = 'https://projek1-production.up.railway.app/api';

  Future<Map<String, dynamic>> login(String username, String password) async {
    final url = Uri.parse('$baseUrl/login');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'login': username, 'password': password}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // Ambil role dan nama dari response
      final user = data['user'];
      final roles = user['roles'] as List?;
      final userRole = (roles != null && roles.isNotEmpty) ? roles.first : 'guest';
      final userName = user['name'] ?? 'Guest';
      final result = {
        ...data,
        'userRole': userRole,
        'userName': userName,
      };
      // Pastikan result bertipe Map<String, dynamic>
      return Map<String, dynamic>.from(result);
    } else {
      throw Exception('Login gagal: ${response.body}');
    }
  }

  // Tambahkan fungsi logout jika diperlukan
}
