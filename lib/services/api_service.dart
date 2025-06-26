import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mime/mime.dart' as mime;
import '../models/article.dart';
import '../models/orangtua.dart';
import '../models/pesertadidik.dart';

class ApiService {
  final String baseUrl = "https://projek1-production.up.railway.app/api";

  Future<Map<String, String>> _getAuthHeaders({bool withContentType = true}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final headers = {
      'Accept': 'application/json',
    };

    if (withContentType) {
      headers['Content-Type'] = 'application/json; charset=UTF-8';
    }

    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }
  Future<List<Article>> getArticles() async {
    try {
      print('Fetching articles from: $baseUrl/artikels');
      final response = await http.get(
        Uri.parse('$baseUrl/artikels'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw "Koneksi timeout. Silakan coba lagi nanti.",
      );

      print('API Response Status: ${response.statusCode}');
      print('Raw response: ${response.body}');

      if (response.statusCode == 200) {
        try {
          // Check if response is empty
          if (response.body.isEmpty) {
            print('Warning: Empty response body');
            return [];
          }

          // Try to decode the response as JSON
          dynamic decodedResponse;
          try {
            decodedResponse = jsonDecode(response.body);
            print('Decoded JSON type: ${decodedResponse.runtimeType}');
          } catch (e) {
            print('Failed to decode JSON: $e');
            throw "Format respons tidak valid: ${e.toString()}";
          }
          
          // Handle different response formats
          List<dynamic> articlesData;
          
          if (decodedResponse is Map<String, dynamic>) {
            // Format: {"data": [...]} or {"articles": [...]} etc.
            print('Response is a Map with keys: ${decodedResponse.keys}');
            
            // Try to find the appropriate key containing the articles data
            if (decodedResponse.containsKey('data')) {
              articlesData = decodedResponse['data'] as List<dynamic>;
            } else if (decodedResponse.containsKey('articles') || decodedResponse.containsKey('artikels')) {
              articlesData = (decodedResponse['articles'] ?? decodedResponse['artikels']) as List<dynamic>;
            } else {
              // If no known key is found, try to use the whole response as a single article
              if (decodedResponse.containsKey('id') || 
                 (decodedResponse.containsKey('judul') || decodedResponse.containsKey('title'))) {
                articlesData = [decodedResponse];
              } else {
                // Last resort: try all values that are lists
                var listValues = decodedResponse.values.whereType<List>();
                if (listValues.isNotEmpty) {
                  articlesData = listValues.first as List<dynamic>;
                } else {
                  print('No article list found in response');
                  articlesData = [];
                }
              }
            }
          } else if (decodedResponse is List<dynamic>) {
            // Format: direct array of articles
            print('Response is a List of length: ${decodedResponse.length}');
            articlesData = decodedResponse;
          } else {
            print('Unexpected response type: ${decodedResponse.runtimeType}');
            throw "Format data tidak sesuai";
          }
          
          print('Articles data length: ${articlesData.length}');
          
          // Map the articles data to Article objects
          List<Article> articles = articlesData.map<Article>((dynamic item) {
            try {
              // Ensure item is a map
              if (item is Map<String, dynamic>) {
                return Article.fromJson(item);
              } else {
                print('Item is not a Map: $item');
                return Article(
                  id: -1, 
                  title: 'Format Error', 
                  content: 'Data dalam format yang tidak sesuai', 
                  imageUrl: '',
                );
              }
            } catch (e) {
              print('Error parsing article: $e');
              return Article(
                id: -1, 
                title: 'Parse Error', 
                content: 'Gagal memproses data kegiatan: ${e.toString()}', 
                imageUrl: '',
              );
            }
          }).toList();
          
          // Sort articles by ID in descending order (newest first)
          articles.sort((a, b) => b.id.compareTo(a.id));
          
          return articles;
        } catch (parseError) {
          print('JSON Parse Error: $parseError');
          throw "Gagal mengurai data kegiatan: ${parseError.toString()}";
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw "Tidak memiliki izin untuk mengakses data. Silakan login kembali.";
      } else if (response.statusCode == 404) {
        throw "Endpoint tidak ditemukan. Periksa URL API.";
      } else if (response.statusCode >= 500) {
        throw "Server Error (${response.statusCode}). Silakan coba lagi nanti.";
      } else {
        throw "Gagal memuat kegiatan: Status ${response.statusCode}";
      }
    } catch (e) {
      if (e is http.ClientException) {
        print('Client Exception: $e');
        throw "Tidak dapat terhubung ke server. Periksa koneksi internet anda.";
      } else if (e is FormatException) {
        print('Format Exception: $e');
        throw "Format respons tidak valid. Silakan hubungi administrator.";
      } else if (e is String) {
        // If we've already thrown a String, just rethrow it
        rethrow;
      } else {
        print('Unknown Exception: $e');
        throw "Gagal memuat kegiatan: ${e.toString()}";
      }
    }
  }

  Future<Article> createArticle(String title, String content, String imageUrl) async {
    try {
      print('Creating article with title: $title');
      final response = await http.post(
        Uri.parse('$baseUrl/artikels'),
        headers: await _getAuthHeaders(),
        body: jsonEncode(<String, String>{
          'judul': title,
          'konten': content,
          'thumbnail_url': imageUrl,
        }),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw "Koneksi timeout. Silakan coba lagi nanti.",
      );

      print('Create API Response Status: ${response.statusCode}');
      print('Create API Response: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        try {
          final dynamic jsonResponse = jsonDecode(response.body);
          
          // Handle different response formats
          Map<String, dynamic> articleData;
          
          if (jsonResponse is Map<String, dynamic>) {
            if (jsonResponse.containsKey('data')) {
              // If response has a data key, use that
              articleData = jsonResponse['data'] as Map<String, dynamic>;
            } else {
              // Otherwise use the entire response
              articleData = jsonResponse;
            }
          } else {
            throw FormatException('Unexpected response format');
          }
          
          return Article.fromJson(articleData);
        } catch (e) {
          print('Error parsing create response: $e');
          // Return a basic article with the data we sent
          return Article(
            id: -1,  // Temporary ID
            title: title,
            content: content,
            imageUrl: imageUrl,
          );
        }
      } else if (response.statusCode == 401) {
        throw "Sesi Anda telah berakhir. Silakan login kembali.";
      } else if (response.statusCode == 422) {
        // Validation error
        try {
          final Map<String, dynamic> errors = jsonDecode(response.body)['errors'];
          final errorMessages = errors.values.map((e) => e.join(', ')).join('; ');
          throw "Validasi gagal: $errorMessages";
        } catch (e) {
          throw "Validasi gagal. Periksa data yang dimasukkan.";
        }
      } else {
        throw "Gagal membuat kegiatan (${response.statusCode}). Silakan coba lagi.";
      }
    } catch (e) {
      print('Create Article Error: $e');
      if (e is String) {
        rethrow;
      } else {
        throw "Gagal membuat kegiatan: ${e.toString()}";
      }
    }
  }

  Future<Article> updateArticle(int id, String title, String content, String imageUrl) async {
    try {
      print('Updating article id: $id');
      final response = await http.put(
        Uri.parse('$baseUrl/artikels/$id'),
        headers: await _getAuthHeaders(),
        body: jsonEncode(<String, String>{
          'judul': title,
          'konten': content,
          'thumbnail_url': imageUrl,
        }),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw "Koneksi timeout. Silakan coba lagi nanti.",
      );

      print('Update API Response Status: ${response.statusCode}');
      print('Update API Response: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final dynamic jsonResponse = jsonDecode(response.body);
          
          // Handle different response formats
          Map<String, dynamic> articleData;
          
          if (jsonResponse is Map<String, dynamic>) {
            if (jsonResponse.containsKey('data')) {
              // If response has a data key, use that
              articleData = jsonResponse['data'] as Map<String, dynamic>;
            } else {
              // Otherwise use the entire response
              articleData = jsonResponse;
            }
          } else {
            throw FormatException('Unexpected response format');
          }
          
          return Article.fromJson(articleData);
        } catch (e) {
          print('Error parsing update response: $e');
          // Return an article with the updated data
          return Article(
            id: id,
            title: title,
            content: content,
            imageUrl: imageUrl,
          );
        }
      } else if (response.statusCode == 401) {
        throw "Sesi Anda telah berakhir. Silakan login kembali.";
      } else if (response.statusCode == 404) {
        throw "Kegiatan tidak ditemukan. Mungkin sudah dihapus.";
      } else if (response.statusCode == 422) {
        // Validation error
        try {
          final Map<String, dynamic> errors = jsonDecode(response.body)['errors'];
          final errorMessages = errors.values.map((e) => e.join(', ')).join('; ');
          throw "Validasi gagal: $errorMessages";
        } catch (e) {
          throw "Validasi gagal. Periksa data yang dimasukkan.";
        }
      } else {
        throw "Gagal memperbarui kegiatan (${response.statusCode}). Silakan coba lagi.";
      }
    } catch (e) {
      print('Update Article Error: $e');
      if (e is String) {
        rethrow;
      } else {
        throw "Gagal memperbarui kegiatan: ${e.toString()}";
      }
    }
  }

  Future<void> deleteArticle(int id) async {
    try {
      print('Deleting article id: $id');
      final response = await http.delete(
        Uri.parse('$baseUrl/artikels/$id'),
        headers: await _getAuthHeaders(withContentType: false),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw "Koneksi timeout. Silakan coba lagi nanti.",
      );

      print('Delete API Response Status: ${response.statusCode}');
      
      // Accept multiple success status codes, as APIs may respond differently
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return; // Success
      } else if (response.statusCode == 401) {
        throw "Sesi Anda telah berakhir. Silakan login kembali.";
      } else if (response.statusCode == 404) {
        throw "Kegiatan tidak ditemukan. Mungkin sudah dihapus.";
      } else if (response.statusCode == 403) {
        throw "Tidak memiliki izin untuk menghapus kegiatan ini.";
      } else {
        throw "Gagal menghapus kegiatan (${response.statusCode}). Silakan coba lagi.";
      }
    } catch (e) {
      print('Delete Article Error: $e');
      if (e is String) {
        rethrow;
      } else {
        throw "Gagal menghapus kegiatan: ${e.toString()}";
      }
    }
  }

  Future<Article> createArticleMultipart(String title, String content, File? thumbnail) async {
    final uri = Uri.parse('$baseUrl/artikels');
    final request = http.MultipartRequest('POST', uri);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    request.headers['Accept'] = 'application/json';
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.fields['judul'] = title;
    request.fields['konten'] = content;
    if (thumbnail != null) {
      request.files.add(await http.MultipartFile.fromPath('thumbnail', thumbnail.path));
    }
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode == 201 || response.statusCode == 200) {
      return Article.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Gagal membuat artikel: ${response.body}');
    }
  }

  Future<Article> updateArticleMultipart(int id, String title, String content, File? thumbnail) async {
    final uri = Uri.parse('$baseUrl/artikels/$id');
    final request = http.MultipartRequest('POST', uri);
    request.fields['_method'] = 'PUT';
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    request.headers['Accept'] = 'application/json';
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.fields['judul'] = title;
    request.fields['konten'] = content;
    if (thumbnail != null) {
      request.files.add(await http.MultipartFile.fromPath('thumbnail', thumbnail.path));
    }
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode == 200) {
      return Article.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Gagal update artikel: ${response.body}');
    }
  }

  Future<List<Orangtua>> getOrangtuaList() async {
    final response = await http.get(
      Uri.parse('$baseUrl/orangtuas'),
      headers: await _getAuthHeaders(),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> list = data is List ? data : (data['data'] ?? data['orangtuas'] ?? []);
      return list.map((e) => Orangtua.fromJson(e)).toList();
    } else {
      throw Exception('Gagal memuat data orangtua');
    }
  }

  Future<Orangtua> getOrangtuaDetail(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/orangtuas/$id'),
      headers: await _getAuthHeaders(),
    );
    if (response.statusCode == 200) {
      return Orangtua.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Gagal memuat detail orangtua');
    }
  }

  Future<Orangtua> createOrangtua(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/orangtuas'),
      headers: await _getAuthHeaders(),
      body: jsonEncode(data),
    );
    if (response.statusCode == 201 || response.statusCode == 200) {
      return Orangtua.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Gagal menambah orangtua: ${response.body}');
    }
  }

  Future<Orangtua> updateOrangtua(int id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/orangtuas/$id'),
      headers: await _getAuthHeaders(),
      body: jsonEncode(data),
    );
    if (response.statusCode == 200) {
      return Orangtua.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Gagal update orangtua: ${response.body}');
    }
  }

  Future<void> deleteOrangtua(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/orangtuas/$id'),
      headers: await _getAuthHeaders(),
    );
    if (response.statusCode != 204) {
      throw Exception('Gagal menghapus orangtua');
    }
  }

  // Peserta Didik CRUD
  Future<List<PesertaDidik>> getPesertaDidikList() async {
    final response = await http.get(
      Uri.parse('$baseUrl/pesertadidiks'),
      headers: await _getAuthHeaders(),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // Handle paginated response: { pesertadidiks: { data: [...] } }
      List<dynamic> list;
      if (data is List) {
        list = data;
      } else if (data['pesertadidiks'] != null && data['pesertadidiks']['data'] != null) {
        list = data['pesertadidiks']['data'];
      } else if (data['data'] != null) {
        list = data['data'];
      } else {
        throw Exception('Format data peserta didik tidak dikenali');
      }
      return list.map((e) => PesertaDidik.fromJson(e)).toList();
    } else {
      throw Exception('Gagal memuat data peserta didik');
    }
  }

  Future<PesertaDidik> getPesertaDidikDetail(String nis) async {
    final response = await http.get(
      Uri.parse('$baseUrl/pesertadidiks/$nis'),
      headers: await _getAuthHeaders(),
    );
    if (response.statusCode == 200) {
      return PesertaDidik.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Gagal memuat detail peserta didik');
    }
  }

  Future<PesertaDidik> createPesertaDidik(Map<String, dynamic> data, {File? foto, File? filePenilaian}) async {
    final uri = Uri.parse('$baseUrl/pesertadidiks');
    final request = http.MultipartRequest('POST', uri);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    request.headers['Accept'] = 'application/json';
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    data.forEach((key, value) {
      if (value != null) request.fields[key] = value.toString();
    });
    if (foto != null) {
      final mimeType = mime.lookupMimeType(foto.path);
      final length = await foto.length();
      print('Uploading foto: path=[38;5;2m${foto.path}[0m, size=$length, mimeType=$mimeType');
      request.files.add(await http.MultipartFile.fromPath(
        'foto',
        foto.path,
        contentType: mimeType != null ? MediaType.parse(mimeType) : null,
      ));
    }
    // Note: filePenilaian will be uploaded separately using uploadPenilaian method
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode == 201 || response.statusCode == 200) {
      final pesertaDidik = PesertaDidik.fromJson(jsonDecode(response.body)['data'] ?? jsonDecode(response.body));
      
      // Upload file penilaian separately if provided
      if (filePenilaian != null) {
        try {
          await uploadPenilaian(pesertaDidik.nis, filePenilaian);
        } catch (e) {
          print('Warning: Failed to upload penilaian file: $e');
          // Don't throw error here, as the main data is already saved
        }
      }
      
      return pesertaDidik;
    } else {
      print('Gagal menambah peserta didik: status=${response.statusCode}, body=${response.body}');
      throw Exception('Gagal menambah peserta didik: ${response.body}');
    }
  }

  Future<PesertaDidik> updatePesertaDidik(String nis, Map<String, dynamic> data, {File? foto, File? filePenilaian}) async {
    final uri = Uri.parse('$baseUrl/pesertadidiks/$nis');
    final request = http.MultipartRequest('POST', uri);
    request.fields['_method'] = 'PUT';
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    request.headers['Accept'] = 'application/json';
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    data.forEach((key, value) {
      if (value != null) request.fields[key] = value.toString();
    });
    if (foto != null) {
      final mimeType = mime.lookupMimeType(foto.path);
      request.files.add(await http.MultipartFile.fromPath(
        'foto',
        foto.path,
        contentType: mimeType != null ? MediaType.parse(mimeType) : null,
      ));
    }
    // Note: filePenilaian will be uploaded separately using uploadPenilaian method
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode == 200) {
      final pesertaDidik = PesertaDidik.fromJson(jsonDecode(response.body)['data'] ?? jsonDecode(response.body));
      
      // Upload file penilaian separately if provided
      if (filePenilaian != null) {
        try {
          await uploadPenilaian(nis, filePenilaian);
        } catch (e) {
          print('Warning: Failed to upload penilaian file: $e');
          // Don't throw error here, as the main data is already saved
        }
      }
      
      return pesertaDidik;
    } else {
      throw Exception('Gagal update peserta didik: ${response.body}');
    }
  }

  Future<void> deletePesertaDidik(String nis) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/pesertadidiks/$nis'),
      headers: await _getAuthHeaders(),
    );
    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception('Gagal menghapus peserta didik');
    }
  }

  Future<void> uploadPenilaian(String nis, File filePenilaian) async {
    final uri = Uri.parse('$baseUrl/pesertadidiks/$nis/upload-penilaian');
    final request = http.MultipartRequest('POST', uri);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    request.headers['Accept'] = 'application/json';
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    // Ensure the file is uploaded with the correct field name and path
    final mimeType = mime.lookupMimeType(filePenilaian.path);
    request.files.add(await http.MultipartFile.fromPath(
      'file', // Use 'file' as the field name
      filePenilaian.path,
      contentType: mimeType != null ? MediaType.parse(mimeType) : null,
    ));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    print('Upload penilaian response: ${response.statusCode} - ${response.body}');

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Gagal upload file penilaian: ${response.body}');
    }
  }

  Future<dynamic> getStatusGiziAnalysis() async {
    final response = await http.get(
      Uri.parse('$baseUrl/statusgizi'),
      headers: await _getAuthHeaders(),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Gagal memuat data analisis status gizi');
    }
  }

  Future<dynamic> getStatusGiziChartData({String? bulan}) async {
    final url = bulan != null
        ? '$baseUrl/statusgizi/chart/data?bulan=$bulan'
        : '$baseUrl/statusgizi/chart/data';
    final response = await http.get(
      Uri.parse(url),
      headers: await _getAuthHeaders(),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Gagal memuat data chart status gizi');
    }
  }

  Future<dynamic> calculateStatusGizi(String nis) async {
    final response = await http.post(
      Uri.parse('$baseUrl/statusgizi/calculate'),
      headers: await _getAuthHeaders(),
      body: jsonEncode({'nis': nis}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Gagal menghitung status gizi: [38;5;1m${response.body}[0m');
    }
  }

  Future<void> saveStatusGizi(String nis, double zScore, String status) async {
    final response = await http.post(
      Uri.parse('$baseUrl/statusgizi'),
      headers: await _getAuthHeaders(),
      body: jsonEncode({
        'nis': nis,
        'z_score': zScore,
        'status': status,
      }),
    );
    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Gagal menyimpan status gizi: ${response.body}');
    }
  }

  // Ambil detail peserta didik by NIS
  Future<PesertaDidik> getPesertaDidikByNis(String nis) async {
    return getPesertaDidikDetail(nis);
  }

  // Ambil riwayat status gizi by NIS
  Future<List<Map<String, dynamic>>> getStatusGiziByNis(String nis) async {
    final response = await http.get(
      Uri.parse('$baseUrl/statusgizi/nis/$nis'),
      headers: await _getAuthHeaders(),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data.cast<Map<String, dynamic>>();
      } else if (data['data'] is List) {
        return (data['data'] as List).cast<Map<String, dynamic>>();
      } else {
        return [];
      }
    } else {
      throw Exception('Gagal memuat riwayat status gizi');
    }
  }

  // Hapus status gizi by id
  Future<void> deleteStatusGizi(String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/statusgizi/$id'),
      headers: await _getAuthHeaders(),
    );
    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception('Gagal menghapus data status gizi');
    }
  }

  Future<Map<String, dynamic>?> getStatusGiziByStatus(String statusGizi) async {
    if (statusGizi.isEmpty) return null;
    final response = await http.get(
      Uri.parse('$baseUrl/statusgizi/$statusGizi'),
      headers: await _getAuthHeaders(),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic>) return data;
      if (data is List && data.isNotEmpty) return data.first;
      if (data['data'] != null) return data['data'];
    }
    return null;
  }

  // Get user data
  Future<Map<String, dynamic>?> getUser() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user'),
        headers: await _getAuthHeaders(),
      );
      print('Get user response: ${response.statusCode} - ${response.body}'); // Debug log
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data is Map<String, dynamic> ? data : null;
      }
      return null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  // Get current user's orangtua profile
  Future<Orangtua?> getCurrentOrangtua() async {
    try {
      final userData = await getUser();
      if (userData == null || userData['id'] == null) return null;
      
      final userId = userData['id'];
      final orangtuaList = await getOrangtuaList();
      
      // Find orangtua with matching user_id
      for (final orangtua in orangtuaList) {
        if (orangtua.userId == userId) {
          return orangtua;
        }
      }
      return null;
    } catch (e) {
      print('Error getting current orangtua: $e');
      return null;
    }
  }

  // Get peserta didik by parent name (for orangtua role access)
  Future<List<PesertaDidik>> getPesertaDidikByParent({String? parentName}) async {
    try {
      // Get current logged-in parent name if not provided
      String? targetParentName = parentName;
      if (targetParentName == null) {
        final prefs = await SharedPreferences.getInstance();
        targetParentName = prefs.getString('userName');
        if (targetParentName == null || targetParentName.isEmpty) {
          throw Exception('Tidak dapat menemukan data nama orang tua yang sedang login');
        }
      }

      print('=== API DEBUG: Searching students for parent: $targetParentName ===');

      // Get all students from api/pesertadidiks
      final response = await http.get(
        Uri.parse('$baseUrl/pesertadidiks'),
        headers: await _getAuthHeaders(),
      );
      
      print('API Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Raw API response: ${response.body.substring(0, 500)}...'); // First 500 chars
        
        // Handle paginated response: { pesertadidiks: { data: [...] } }
        List<dynamic> list;
        if (data is List) {
          list = data;
        } else if (data['pesertadidiks'] != null && data['pesertadidiks']['data'] != null) {
          list = data['pesertadidiks']['data'];
        } else if (data['data'] != null) {
          list = data['data'];
        } else {
          throw Exception('Format data peserta didik tidak dikenali');
        }

        final allStudents = list.map((e) => PesertaDidik.fromJson(e)).toList();
        print('Total students from API: ${allStudents.length}');
        
        // Get all orangtua to match names
        final orangtuaList = await getOrangtuaList();
        print('Total parents found: ${orangtuaList.length}');
        
        // Debug: print all parent names
        print('Available parent names:');
        for (var parent in orangtuaList) {
          print('  - ID: ${parent.id}, Name: "${parent.namaOrtu}"');
        }
        
        // Filter students by matching parent name
        final filteredStudents = <PesertaDidik>[];
        for (var student in allStudents) {
          final parentData = orangtuaList.firstWhere(
            (orangtua) => orangtua.id == student.idOrtu,
            orElse: () => Orangtua(id: -1, namaOrtu: '', notelpOrtu: '', alamat: '', emailOrtu: '', nickname: ''),
          );
          
          print('Student: "${student.namaPd}" (ID: ${student.nis}) -> Parent ID: ${student.idOrtu} -> Parent Name: "${parentData.namaOrtu}"');
          
          bool matches = parentData.namaOrtu.toLowerCase().trim() == targetParentName!.toLowerCase().trim();
          print('  Comparing: "${parentData.namaOrtu.toLowerCase().trim()}" == "${targetParentName.toLowerCase().trim()}" -> $matches');
          
          if (matches) {
            filteredStudents.add(student);
            print('  ✓ MATCH FOUND!');
          }
        }

        print('Final filtered students count: ${filteredStudents.length}');
        return filteredStudents;
      } else {
        print('API Error - Status: ${response.statusCode}, Body: ${response.body}');
        throw Exception('Gagal memuat data peserta didik dari server');
      }
    } catch (e) {
      print('Error getting peserta didik by parent: $e');
      throw Exception('Gagal memuat data peserta didik: $e');
    }
  }
}
