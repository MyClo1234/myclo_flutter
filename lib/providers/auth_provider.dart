import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myclo_flutter/api/core/api_client.dart';
import '../services/api_service.dart';

class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final String? error;
  final String? id; // Add user ID
  final String? gender;
  final String? bodyShape;
  final String? token;
  final String? username;
  final int? height;
  final int? weight;
  final int? age;

  AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.error,
    this.id,
    this.gender,
    this.bodyShape,
    this.token,
    this.username,
    this.height,
    this.weight,
    this.age,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    String? error,
    String? id,
    String? gender,
    String? bodyShape,
    String? token,
    String? username,
    int? height,
    int? weight,
    int? age,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      id: id ?? this.id,
      gender: gender ?? this.gender,
      bodyShape: bodyShape ?? this.bodyShape,
      token: token ?? this.token,
      username: username ?? this.username,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      age: age ?? this.age,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiService _apiService = ApiService();

  AuthNotifier() : super(AuthState()) {
    _checkLoginStatus();

    // Listen for global 401 errors
    ApiClient().onAuthError.listen((_) {
      print("Received global 401 event. Logging out.");
      logout();
    });
  }

  Future<void> _checkLoginStatus() async {
    final token = await _apiService.getToken();
    final userData = await _apiService.getUserData();

    if (token != null && userData != null) {
      // 1. Optimistically set authenticated to show UI immediately with restored data
      state = state.copyWith(
        isAuthenticated: true,
        token: token,
        id: userData['id'],
        username: userData['username'],
        gender: userData['gender'],
        bodyShape: userData['body_shape'],
        age: userData['age'],
        height: userData['height'],
        weight: userData['weight'],
      );

      // 2. Verify token validity by making a test API call
      try {
        await _apiService.fetchWardrobeItems();
      } catch (e) {
        if (e is ApiException && e.statusCode == 401) {
          print('Token expired or invalid (401). Logging out.');
          await logout();
        }
      }
    } else if (token != null && userData == null) {
      // Token exists but user data missing -> Force logout
      print('Token exists but user data missing. Logging out.');
      await logout();
    }
  }

  Future<void> login(String username, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _apiService.login(username, password);

    if (result['success']) {
      final user = result['user'];
      final token = result['token'];

      if (user != null) {
        await _apiService.saveUserData(user);
      }

      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        token: token,
        id: user != null ? user['id'] : null,
        username: user != null ? user['username'] : username,
        gender: user != null ? user['gender'] : null,
        bodyShape: user != null ? user['body_shape'] : null,
        age: user != null && user['age'] != null
            ? (user['age'] as num).toInt()
            : null,
        height: user != null && user['height'] != null
            ? (user['height'] as num).toInt()
            : null,
        weight: user != null && user['weight'] != null
            ? (user['weight'] as num).toInt()
            : null,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result['message'] ?? 'Login failed',
      );
    }
  }

  Future<void> register(
    String username,
    String password,
    String gender,
    String bodyShape,
    int age,
    int height,
    int weight,
  ) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _apiService.register(
      username: username,
      password: password,
      age: age,
      height: height,
      weight: weight,
      gender: gender,
      bodyShape: bodyShape,
    );

    print('DEBUG: AuthProvider Register Result: $result');

    if (result['success']) {
      if (result['token'] != null) {
        print('DEBUG: Updating State to Authenticated');
        final user = result['user'];

        // Construct user map if user object from API is incomplete or just to be safe
        final userMap =
            user ??
            {
              'username': username,
              'gender': gender,
              'body_shape': bodyShape,
              'age': age,
              'height': height,
              'weight': weight,
              // id might be missing here if register doesn't return it
            };
        if (user != null && user['id'] != null) {
          userMap['id'] = user['id'];
        }
        await _apiService.saveUserData(userMap);

        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          gender: gender,
          bodyShape: bodyShape,
          token: result['token'],
          id: user != null ? user['id'] : null,
          username: user != null ? user['username'] : username,
          age: user != null && user['age'] != null
              ? (user['age'] as num).toInt()
              : age,
          height: user != null && user['height'] != null
              ? (user['height'] as num).toInt()
              : height,
          weight: user != null && user['weight'] != null
              ? (user['weight'] as num).toInt()
              : weight,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result['message'] ?? 'Registration failed',
      );
    }
  }

  Future<void> updateProfile({
    required int height,
    required int weight,
    required String gender,
    required String bodyShape,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _apiService.updateProfile(
      height: height,
      weight: weight,
      gender: gender,
      bodyShape: bodyShape,
    );

    if (result['success']) {
      final user = result['user'];
      state = state.copyWith(
        isLoading: false,
        height: user != null && user['height'] != null
            ? (user['height'] as num).toInt()
            : height,
        weight: user != null && user['weight'] != null
            ? (user['weight'] as num).toInt()
            : weight,
        gender: user != null ? user['gender'] : gender,
        bodyShape: user != null ? user['body_shape'] : bodyShape,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result['message'] ?? 'Profile update failed',
      );
    }
  }

  Future<void> logout() async {
    await _apiService.logout();
    state = AuthState(); // Reset state
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
