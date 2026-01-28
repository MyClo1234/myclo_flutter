import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  static String get baseUrlLocal =>
      dotenv.get('API_BASE_URL', fallback: 'http://localhost:7071');
  static String get baseUrlAndroid {
    String url = dotenv.get('API_BASE_URL', fallback: 'http://10.0.2.2:7071');
    // Android Emulator cannot access 'localhost' or '127.0.0.1' directly.
    // It must use '10.0.2.2'.
    if (url.contains('localhost')) {
      url = url.replaceAll('localhost', '10.0.2.2');
    } else if (url.contains('127.0.0.1')) {
      url = url.replaceAll('127.0.0.1', '10.0.2.2');
    }
    return url;
  }

  static String get baseUrlProd {
    final url = dotenv.get(
      'API_BASE_URL',
      fallback:
          'https://codify-functions-backend-gzaydqgch0ccbdfe.koreacentral-01.azurewebsites.net',
    );
    // If the variable substitution fails in the pipeline, it returns $(API_BASE_URL)
    if (url.startsWith(r'$(')) {
      return 'https://codify-functions-backend-gzaydqgch0ccbdfe.koreacentral-01.azurewebsites.net';
    }
    return url;
  }

  static const String tokenKey = 'auth_token';

  // Endpoints
  static const String login = '/api/auth/login';
  static const String register = '/api/auth/signup';
  static const String logout = '/api/auth/logout';
  static const String extract = '/api/extract';
  static const String userProfile = '/api/users/profile';
  static const String wardrobeUsersMe = '/api/wardrobe/users/me/images';
  static const String wardrobeItems = '/api/wardrobe/items';
  static const String recommendOutfit = '/api/recommend/outfit';
  static const String todaysPick = '/api/recommend/todays-pick';
  static const String weatherSummary = '/api/today/summary';
  static const String chat = '/api/chat';
}
