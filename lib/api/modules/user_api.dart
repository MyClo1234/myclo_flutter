import 'dart:convert';
import '../core/api_client.dart';
import '../core/api_constants.dart';

class UserApi {
  final ApiClient _client = ApiClient();

  // Re-implementing logic from ApiService regarding SharedPrefs sync?
  // Ideally, API module should only handle Network.
  // Persistence logic (SharedPreferences) should be in a Repository or Provider.
  // However, specifically for updateProfile, previous ApiService did:
  // PUT /api/users/profile

  Future<Map<String, dynamic>> updateProfile({
    required int height,
    required int weight,
    required String gender,
    required String bodyShape,
  }) async {
    try {
      final response = await _client.put(
        ApiConstants.userProfile,
        body: {
          'height': height,
          'weight': weight,
          'gender': gender,
          'body_shape': bodyShape,
        },
      );

      return {
        'success': true,
        'user': json.decode(utf8.decode(response.bodyBytes)),
      };
    } catch (e) {
      if (e is ApiException) {
        try {
          final body = json.decode(e.message);
          return {
            'success': false,
            'message': body['detail'] ?? 'Update failed',
          };
        } catch (_) {
          return {'success': false, 'message': e.message};
        }
      }
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }
}
