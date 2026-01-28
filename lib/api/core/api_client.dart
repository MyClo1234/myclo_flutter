import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'api_constants.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  String get baseUrl {
    // Basic local dev setup logic
    if (kIsWeb) {
      if (kReleaseMode) {
        return ApiConstants.baseUrlProd;
      }
      return ApiConstants.baseUrlLocal;
    } else if (Platform.isAndroid) {
      return ApiConstants.baseUrlAndroid;
    } else {
      return ApiConstants.baseUrlLocal;
    }
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(ApiConstants.tokenKey);
  }

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(ApiConstants.tokenKey, token);
  }

  Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(ApiConstants.tokenKey);
  }

  Future<Map<String, String>> _getHeaders({
    bool withAuth = true,
    String? contentType,
  }) async {
    final headers = <String, String>{};
    if (contentType != null) {
      headers['Content-Type'] = contentType;
    }

    if (withAuth) {
      final token = await getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  // --- HTTP Methods ---

  Future<http.Response> get(
    String endpoint, {
    Map<String, String>? queryParams,
    bool withAuth = true,
  }) async {
    final uri = Uri.parse(
      '$baseUrl$endpoint',
    ).replace(queryParameters: queryParams);
    final headers = await _getHeaders(withAuth: withAuth);

    final response = await http.get(uri, headers: headers);
    _checkStatusCode(response);
    return response;
  }

  Future<http.Response> post(
    String endpoint, {
    dynamic body,
    bool withAuth = true,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final headers = await _getHeaders(
      withAuth: withAuth,
      contentType: 'application/json',
    );

    final response = await http.post(
      uri,
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
    _checkStatusCode(response);
    return response;
  }

  Future<http.Response> put(
    String endpoint, {
    dynamic body,
    bool withAuth = true,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final headers = await _getHeaders(
      withAuth: withAuth,
      contentType: 'application/json',
    );

    final response = await http.put(
      uri,
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
    _checkStatusCode(response);
    return response;
  }

  Future<http.Response> delete(String endpoint, {bool withAuth = true}) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final headers = await _getHeaders(withAuth: withAuth);

    final response = await http.delete(uri, headers: headers);
    _checkStatusCode(response);
    return response;
  }

  // Multipart helper can be added specifically in module needing it, or here generically.
  // For now we keep it simple.

  // Auth Error Stream
  final _authErrorController = StreamController<void>.broadcast();
  Stream<void> get onAuthError => _authErrorController.stream;

  void _checkStatusCode(http.Response response) {
    if (response.statusCode == 401) {
      _authErrorController.add(null);
    }

    if (response.statusCode >= 400) {
      // Basic exception throwing. Can be enhanced with custom exceptions.
      throw ApiException(response.statusCode, response.body);
    }
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);
  @override
  String toString() => 'ApiException: $statusCode, $message';
}
