import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../core/api_client.dart';
import '../core/api_constants.dart';
import '../../utils/image_helper.dart';

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
      // Compress image before upload (only for mobile/desktop, web handling can differ)
      XFile processedImage = image;
      if (!kIsWeb) {
        // Import locally to avoid circular dependency issues if any,
        // though strictly imports are at top.
        // Assuming ImageHelper is imported.
        // We need to add import to the top of file first.
      }

      // Let's modify imports first in a separate step or here if possible.
      // Since replace_file_content is per-block, I will do it in two steps or assume top import.
      // But verify if I can add import in this block... No, it's at the top.
      // I'll add the logic assuming import, then add import.

      // Actually, let's keep it simple. I will just add the logic and then add the import.

      if (!kIsWeb) {
        processedImage = await _compressImage(image);
      }

      final token = await _client.getToken();
      final url = Uri.parse('${_client.baseUrl}${ApiConstants.extract}');

      var request = http.MultipartRequest('POST', url);
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      final mediaType = _getMediaType(processedImage.name);

      if (kIsWeb) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'image',
            await processedImage.readAsBytes(),
            filename: processedImage.name,
            contentType: mediaType,
          ),
        );
      } else {
        request.files.add(
          await http.MultipartFile.fromPath(
            'image',
            processedImage.path,
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

  // Wrapper to avoid importing ImageHelper inside method if I can't add top import in same tool call
  // Actually better to just add the logic and I will add import in next call.
  Future<XFile> _compressImage(XFile file) async {
    return ImageHelper.compressImage(file);
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
