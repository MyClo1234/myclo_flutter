import 'package:image_picker/image_picker.dart';
import '../api/core/api_client.dart';
import '../api/modules/auth_api.dart';
import '../api/modules/wardrobe_api.dart';
import '../api/modules/weather_api.dart';
import '../api/modules/user_api.dart';
import '../api/modules/recommendation_api.dart';
import '../models/weather_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Legacy ApiService acting as a Facade for the new modular API architecture.
/// This allows existing code to continue working while we migrate to using individual modules.
class ApiService {
  // Modules
  final AuthApi _authApi = AuthApi();
  final WardrobeApi _wardrobeApi = WardrobeApi();
  final WeatherApi _weatherApi = WeatherApi();
  final UserApi _userApi = UserApi();
  final RecommendationApi _recommendationApi = RecommendationApi();

  // Shared Client for token management access if needed (or use ApiClient singleton)
  final ApiClient _client = ApiClient();

  static String get baseUrl => ApiClient().baseUrl;

  // --- Auth ---
  Future<Map<String, dynamic>> login(String username, String password) {
    return _authApi.login(username, password);
  }

  Future<Map<String, dynamic>> register({
    required String username,
    required String password,
    required int age,
    required int height,
    required int weight,
    required String gender,
    required String bodyShape,
  }) {
    return _authApi.register(
      username: username,
      password: password,
      age: age,
      height: height,
      weight: weight,
      gender: gender,
      bodyShape: bodyShape,
    );
  }

  Future<void> logout() async {
    await _authApi.logout();
    await removeUserData();
  }

  Future<String?> getToken() => _client.getToken();

  // --- Wardrobe ---
  Future<Map<String, dynamic>> fetchWardrobeItems({
    int skip = 0,
    int limit = 20,
    String? category,
  }) {
    return _wardrobeApi.fetchWardrobeItems(
      skip: skip,
      limit: limit,
      category: category,
    );
  }

  Future<Map<String, dynamic>> fetchWardrobeItemDetail(String itemId) {
    return _wardrobeApi.fetchWardrobeItemDetail(itemId);
  }

  Future<Map<String, dynamic>> uploadImage(XFile image) {
    return _wardrobeApi.uploadImage(image);
  }

  // --- Weather ---
  Future<DailyWeather> getDailyWeather(double lat, double lon) {
    return _weatherApi.getDailyWeather(lat, lon);
  }

  // --- User Profile ---
  Future<Map<String, dynamic>> updateProfile({
    required int height,
    required int weight,
    required String gender,
    required String bodyShape,
  }) {
    return _userApi.updateProfile(
      height: height,
      weight: weight,
      gender: gender,
      bodyShape: bodyShape,
    );
  }

  // --- Recommendation ---
  Future<Map<String, dynamic>> fetchRecommendedOutfit({
    int count = 1,
    bool useGemini = true,
  }) {
    return _recommendationApi.fetchRecommendedOutfit(
      count: count,
      useGemini: useGemini,
    );
  }

  Future<Map<String, dynamic>> fetchTodaysPick({
    required double lat,
    required double lon,
  }) {
    return _recommendationApi.fetchTodaysPick(lat, lon);
  }

  // --- Persistence (Keep here for now or move to Refactored Auth/User Repository) ---
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
}
