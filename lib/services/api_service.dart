import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb, kReleaseMode;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/weather_model.dart';

class ApiService {
  static const String _tokenKey = 'auth_token';

  static String get baseUrl {
    if (kIsWeb) {
      if (kReleaseMode) {
        // In production (Azure SWA), API is at the same origin /api
        // We return empty string so Uri.parse('$baseUrl/api/...') becomes '/api/...'
        return '';
      }
      return 'http://localhost:7071';
    } else if (Platform.isAndroid) {
      return 'http://10.0.2.2:7071';
    } else {
      return 'http://localhost:7071';
    }
  }

  // --- Auth ---

  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );

      if (response.statusCode == 200) {
        // The Swagger says response is "string".
        // It might be a plain string (token) or a JSON.
        // We'll try to decode as JSON first, if distinct key exists.
        // If it's just a string body, use it as token.
        String token;
        Map<String, dynamic>? userStr;

        try {
          final decoded = json.decode(response.body);
          if (decoded is Map<String, dynamic> && decoded.containsKey('token')) {
            token = decoded['token'];
            userStr = decoded['user'];
          } else if (decoded is String) {
            token = decoded;
          } else {
            // Fallback: assume the body text is the token if it's not a variation of above
            token = response.body;
            // Start of string "ey..." for JWT
            if (!token.startsWith('"') && !token.startsWith('{')) {
              // raw string
            } else {
              // If it was valid json string like '"token"', json.decode handles it.
              if (decoded is String) token = decoded;
            }
          }
        } catch (e) {
          // Not JSON, assume raw string
          token = response.body;
        }

        await _saveToken(token);

        return {
          'success': true,
          'token': token,
          'user': userStr, // might be null
        };
      } else {
        final body = json.decode(utf8.decode(response.bodyBytes));
        return {'success': false, 'message': body['detail'] ?? 'Login failed'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> register({
    required String username,
    required String password,
    required int age,
    required int height,
    required int weight,
    required String gender,
    required String bodyShape,
  }) async {
    // ... existing implementation ...
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
          'age': age,
          'height': height,
          'weight': weight,
          'gender': gender,
          'body_shape': bodyShape,
        }),
      );
      // ... (rest of register)

      if (response.statusCode == 200) {
        final decoded = json.decode(utf8.decode(response.bodyBytes));
        if (decoded is Map<String, dynamic>) {
          final bool success = decoded['success'] ?? false;
          final String? token = decoded['token'];
          final Map<String, dynamic>? user = decoded['user'];

          if (success && token != null) {
            await _saveToken(token);
            return {'success': true, 'token': token, 'user': user};
          } else {
            return {
              'success': false,
              'message': 'Registration failed: success=false in response',
            };
          }
        }
        return {'success': false, 'message': 'Invalid response format'};
      } else {
        // ... err handling
        dynamic body;
        try {
          body = json.decode(utf8.decode(response.bodyBytes));
        } catch (_) {
          body = response.body;
        }
        return {
          'success': false,
          'message': body is Map
              ? (body['detail'] ?? 'Registration failed')
              : body.toString(),
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> updateProfile({
    required int height,
    required int weight,
    required String gender,
    required String bodyShape,
  }) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'No token found'};
      }

      final response = await http.put(
        Uri.parse('$baseUrl/api/users/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'height': height,
          'weight': weight,
          'gender': gender,
          'body_shape': bodyShape,
        }),
      );

      if (response.statusCode == 200) {
        // Returns the updated user object directly according to Swagger
        return {
          'success': true,
          'user': json.decode(utf8.decode(response.bodyBytes)),
        };
      } else {
        dynamic body;
        try {
          body = json.decode(utf8.decode(response.bodyBytes));
        } catch (_) {
          body = response.body;
        }
        return {
          'success': false,
          'message': body is Map
              ? (body['detail'] ?? 'Update failed')
              : body.toString(),
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  Future<void> logout() async {
    try {
      final token = await getToken();
      if (token != null) {
        await http.post(
          Uri.parse('$baseUrl/api/auth/logout'),
          headers: {'Authorization': 'Bearer $token'},
        );
      }
    } catch (_) {
      // Ignore errors on logout
    } finally {
      await _removeToken();
      await removeUserData();
    }
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<void> _removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // --- User Data Persistence ---

  Future<void> saveUserData(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    if (user['username'] != null)
      await prefs.setString('user_username', user['username']);
    if (user['gender'] != null)
      await prefs.setString('user_gender', user['gender']);
    if (user['body_shape'] != null)
      await prefs.setString('user_body_shape', user['body_shape']);
    if (user['age'] != null)
      await prefs.setInt('user_age', (user['age'] as num).toInt());
    if (user['height'] != null)
      await prefs.setInt('user_height', (user['height'] as num).toInt());
    if (user['weight'] != null)
      await prefs.setInt('user_weight', (user['weight'] as num).toInt());
  }

  Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('user_username');
    if (username == null) return null;

    return {
      'username': username,
      'gender': prefs.getString('user_gender'),
      'body_shape': prefs.getString('user_body_shape'),
      'age': prefs.getInt('user_age'),
      'height': prefs.getInt('user_height'),
      'weight': prefs.getInt('user_weight'),
    };
  }

  Future<void> removeUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_username');
    await prefs.remove('user_gender');
    await prefs.remove('user_body_shape');
    await prefs.remove('user_age');
    await prefs.remove('user_height');
    await prefs.remove('user_weight');
  }

  // --- Wardrobe / Features ---

  Future<Map<String, dynamic>> fetchRecommendedOutfit({
    int count = 1,
    bool useGemini = true,
  }) async {
    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse(
          '$baseUrl/api/recommend/outfit?count=$count&use_gemini=$useGemini',
        ),
        headers: token != null ? {'Authorization': 'Bearer $token'} : {},
      );

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception('Failed to load outfit recommendations');
      }
    } catch (e) {
      throw Exception('Failed to connect to server: $e');
    }
  }

  Future<Map<String, dynamic>> fetchWardrobeItems() async {
    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/api/wardrobe/items'),
        headers: token != null ? {'Authorization': 'Bearer $token'} : {},
      );

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        throw ApiException(
          response.statusCode,
          'Failed to load wardrobe items',
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow; // Pass through ApiException
      throw Exception('Failed to connect to server: $e');
    }
  }

  Future<Map<String, dynamic>> uploadImage(XFile image) async {
    try {
      final token = await getToken();
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/extract'),
      );
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      final mediaType = _getMediaType(image.name);

      if (kIsWeb) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'image',
            await image.readAsBytes(),
            filename: image.name,
            contentType: mediaType,
          ),
        );
      } else {
        request.files.add(
          await http.MultipartFile.fromPath(
            'image',
            image.path,
            contentType: mediaType,
          ),
        );
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        // Response is ExtractionResponse (Map)
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        final body = utf8.decode(response.bodyBytes);
        print('Upload failed: ${response.statusCode} - $body');
        throw ApiException(response.statusCode, 'Failed to upload: $body');
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw Exception('Error uploading image: $e');
    }
  }

  Future<DailyWeather> getDailyWeather(double lat, double lon) async {
    try {
      final token = await getToken();
      // Changed to pass lat/lon instead of nx/ny. Backend handles mapping.
      final url = '$baseUrl/api/today/summary?lat=$lat&lon=$lon';

      final response = await http.get(
        Uri.parse(url),
        headers: token != null ? {'Authorization': 'Bearer $token'} : {},
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(utf8.decode(response.bodyBytes));
        return DailyWeather.fromJson(decoded);
      } else {
        throw Exception('Failed to load weather data');
      }
    } catch (e) {
      throw Exception('Failed to connect to server: $e');
    }
  }

  MediaType _getMediaType(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      return MediaType('image', 'jpeg');
    } else if (lower.endsWith('.png')) {
      return MediaType('image', 'png');
    } else if (lower.endsWith('.gif')) {
      return MediaType('image', 'gif');
    } else if (lower.endsWith('.webp')) {
      return MediaType('image', 'webp');
    }
    return MediaType('application', 'octet-stream');
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException: $statusCode, $message';
}
