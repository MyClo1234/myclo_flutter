import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final String? error;
  final String? gender;
  final String? bodyShape;

  AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.error,
    this.gender,
    this.bodyShape,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    String? error,
    String? gender,
    String? bodyShape,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      gender: gender ?? this.gender,
      bodyShape: bodyShape ?? this.bodyShape,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState());

  final Map<String, String> _users = {'1': '1'};

  Future<void> login(String id, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    await Future.delayed(const Duration(seconds: 1));

    if (_users.containsKey(id) && _users[id] == password) {
      state = state.copyWith(isLoading: false, isAuthenticated: true);
    } else {
      state = state.copyWith(isLoading: false, error: '아이디 또는 비밀번호가 틀렸습니다.');
    }
  }

  Future<void> register(
    String id,
    String password,
    String gender,
    String bodyShape,
  ) async {
    state = state.copyWith(isLoading: true, error: null);
    await Future.delayed(const Duration(seconds: 1));

    if (_users.containsKey(id)) {
      state = state.copyWith(isLoading: false, error: '이미 존재하는 아이디입니다.');
    } else {
      _users[id] = password;
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        gender: gender,
        bodyShape: bodyShape,
      );
    }
  }

  void logout() {
    state = AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
