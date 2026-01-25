import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../core/api_client.dart';
import '../core/api_constants.dart';

class WardrobeApi {
  final ApiClient _client = ApiClient();

  Future<Map<String, dynamic>> fetchWardrobeItems({
    int skip = 0,
    int limit = 20,
    String? category,
  }) async {
    final queryParams = {'skip': skip.toString(), 'limit': limit.toString()};
    if (category != null) {
      queryParams['category'] = category;
    }

    try {
      final response = await _client.get(
        ApiConstants.wardrobeUsersMe,
        queryParams: queryParams,
      );
      return json.decode(utf8.decode(response.bodyBytes));
    } catch (e) {
      throw Exception('Failed to load wardrobe items: $e');
    }
  }

  Future<Map<String, dynamic>> fetchWardrobeItemDetail(String itemId) async {
    try {
      final response = await _client.get(
        '${ApiConstants.wardrobeItems}/$itemId',
      );
      return json.decode(utf8.decode(response.bodyBytes));
    } catch (e) {
      throw Exception('Failed to load item detail: $e');
    }
  }

  Future<Map<String, dynamic>> uploadImage(XFile image) async {
    try {
      final token = await _client.getToken();
      final url = Uri.parse('${_client.baseUrl}${ApiConstants.extract}');

      var request = http.MultipartRequest('POST', url);
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      final mediaType = _getMediaType(image.name);

      if (kIsWeb) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'image',
            await image.readAsBytes(),
            filename: image.name,
            contentType: mediaType,
          ),
        );
      } else {
        request.files.add(
          await http.MultipartFile.fromPath(
            'image',
            image.path,
            contentType: mediaType,
          ),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        throw ApiException(
          response.statusCode,
          utf8.decode(response.bodyBytes),
        );
      }
    } catch (e) {
      throw Exception('Error uploading image: $e');
    }
  }

  MediaType _getMediaType(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      return MediaType('image', 'jpeg');
    } else if (lower.endsWith('.png')) {
      return MediaType('image', 'png');
    } else if (lower.endsWith('.gif')) {
      return MediaType('image', 'gif');
    } else if (lower.endsWith('.webp')) {
      return MediaType('image', 'webp');
    }
    return MediaType('application', 'octet-stream');
  }
}
