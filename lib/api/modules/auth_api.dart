import 'dart:convert';
import '../core/api_client.dart';
import '../core/api_constants.dart';

class AuthApi {
  final ApiClient _client = ApiClient();

  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await _client.post(
        ApiConstants.login,
        body: {'username': username, 'password': password},
        withAuth: false,
      );

      // Response handling logic similar to original ApiService
      // Assuming ApiClient throws on error, but we might want to return map for UI handling as before
      // or re-throw. Original ApiService returned specific map structure.
      // Let's parse successfully.

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
          token = response.body;
          // If purely raw string or fallback
          if (!token.startsWith('"') && !token.startsWith('{')) {
            // raw
          } else {
            if (decoded is String) token = decoded;
          }
        }
      } catch (e) {
        token = response.body;
      }

      await _client.saveToken(token);

      return {'success': true, 'token': token, 'user': userStr};
    } catch (e) {
      // Return error map to be consistent with previous UI logic usage
      // Or we can let UI catch Parse/Http exceptions.
      // For backward compatibility with UI expecting {'success': false}:
      if (e is ApiException) {
        try {
          final body = json.decode(e.message);
          return {
            'success': false,
            'message': body['detail'] ?? 'Login failed',
          };
        } catch (_) {
          return {'success': false, 'message': e.message};
        }
      }
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
    try {
      final response = await _client.post(
        ApiConstants.register,
        body: {
          'username': username,
          'password': password,
          'age': age,
          'height': height,
          'weight': weight,
          'gender': gender,
          'body_shape': bodyShape,
        },
        withAuth: false,
      );

      final decoded = json.decode(utf8.decode(response.bodyBytes));
      if (decoded is Map<String, dynamic>) {
        final bool success = decoded['success'] ?? false;
        final String? token = decoded['token'];
        final Map<String, dynamic>? user = decoded['user'];

        if (success && token != null) {
          await _client.saveToken(token);
          return {'success': true, 'token': token, 'user': user};
        } else {
          return {
            'success': false,
            'message': 'Registration failed: success=false in response',
          };
        }
      }
      return {'success': false, 'message': 'Invalid response format'};
    } catch (e) {
      if (e is ApiException) {
        dynamic body;
        try {
          body = json.decode(e.message);
        } catch (_) {
          body = e.message;
        }
        return {
          'success': false,
          'message': body is Map
              ? (body['detail'] ?? 'Registration failed')
              : body.toString(),
        };
      }
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  Future<void> logout() async {
    try {
      await _client.post(ApiConstants.logout);
    } catch (_) {
      // Ignore
    } finally {
      await _client.removeToken();
    }
  }
}
