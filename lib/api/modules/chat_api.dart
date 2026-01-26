import 'dart:convert';
import '../core/api_client.dart';
import '../core/api_constants.dart';

class ChatApi {
  final ApiClient _client = ApiClient();

  Future<Map<String, dynamic>> sendMessage(
    String message,
    String? userId, {
    double? lat,
    double? lon,
  }) async {
    try {
      final response = await _client.post(
        ApiConstants.chat,
        body: {
          'query': message,
          'user_id': userId,
          'lat': lat ?? 37.5665,
          'lon': lon ?? 126.9780,
        },
      );

      final decoded = json.decode(utf8.decode(response.bodyBytes));
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return {'response': 'Invalid response format', 'is_pick_updated': false};
    } catch (e) {
      if (e is ApiException) {
        return {'response': e.message, 'is_pick_updated': false};
      }
      return {'response': 'Connection error: $e', 'is_pick_updated': false};
    }
  }
}
