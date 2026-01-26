class ApiConstants {
  static const String baseUrlLocal = 'http://127.0.0.1:7071';
  static const String baseUrlAndroid = 'http://10.0.2.2:7071';
  static const String baseUrlProd =
      'https://codify-functions-backend-gzaydqgch0ccbdfe.koreacentral-01.azurewebsites.net';

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
