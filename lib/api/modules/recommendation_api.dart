import 'dart:convert';
import '../core/api_client.dart';
import '../core/api_constants.dart';

class RecommendationApi {
  final ApiClient _client = ApiClient();

  Future<Map<String, dynamic>> fetchRecommendedOutfit({
    int count = 1,
    bool useGemini = true,
  }) async {
    try {
      final response = await _client.get(
        '${ApiConstants.recommendOutfit}?count=$count&use_gemini=$useGemini',
      );
      return json.decode(utf8.decode(response.bodyBytes));
    } catch (e) {
      throw Exception('Failed to load outfit recommendations: $e');
    }
  }

  Future<Map<String, dynamic>> fetchTodaysPick(double lat, double lon) async {
    try {
      final response = await _client.post(
        ApiConstants.todaysPick,
        body: {'lat': lat, 'lon': lon},
      );
      return json.decode(utf8.decode(response.bodyBytes));
    } catch (e) {
      throw Exception('Failed to load todays pick: $e');
    }
  }
}
