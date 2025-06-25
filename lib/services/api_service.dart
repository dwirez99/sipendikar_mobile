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
      print('Uploading foto: path=${foto.path}, size=$length, mimeType=$mimeType');
      request.files.add(await http.MultipartFile.fromPath(
        'foto',
        foto.path,
        contentType: mimeType != null ? MediaType.parse(mimeType) : null,
      ));
    }
    if (filePenilaian != null) {
      final mimeType = mime.lookupMimeType(filePenilaian.path);
      request.files.add(await http.MultipartFile.fromPath(
        'file_penilaian',
        filePenilaian.path,
        contentType: mimeType != null ? MediaType.parse(mimeType) : null,
      ));
    }
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode == 201 || response.statusCode == 200) {
      return PesertaDidik.fromJson(jsonDecode(response.body));
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
    if (filePenilaian != null) {
      final mimeType = mime.lookupMimeType(filePenilaian.path);
      request.files.add(await http.MultipartFile.fromPath(
        'file_penilaian',
        filePenilaian.path,
        contentType: mimeType != null ? MediaType.parse(mimeType) : null,
      ));
    }
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode == 200) {
      return PesertaDidik.fromJson(jsonDecode(response.body));
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
    request.files.add(await http.MultipartFile.fromPath('file_penilaian', filePenilaian.path));
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Gagal upload file penilaian: ${response.body}');
    }
  }
}
