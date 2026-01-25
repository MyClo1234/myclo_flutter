import 'dart:convert';
import '../core/api_client.dart';
import '../core/api_constants.dart';
import '../../models/weather_model.dart';

class WeatherApi {
  final ApiClient _client = ApiClient();

  Future<DailyWeather> getDailyWeather(double lat, double lon) async {
    try {
      final response = await _client.get(
        '${ApiConstants.weatherSummary}?lat=$lat&lon=$lon',
      );
      final decoded = json.decode(utf8.decode(response.bodyBytes));
      return DailyWeather.fromJson(decoded);
    } catch (e) {
      throw Exception('Failed to load weather data: $e');
    }
  }
}
