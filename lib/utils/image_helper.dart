import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ImageHelper {
  /// Compresses and resizes the image file.
  ///
  /// - [file]: The original XFile from image picker
  /// - [minWidth]: Target minimum width (default 1024)
  /// - [minHeight]: Target minimum height (default 1024)
  /// - [quality]: Compression quality (0-100, default 85)
  ///
  /// Returns a new [XFile] of the compressed image.
  static Future<XFile> compressImage(
    XFile file, {
    int minWidth = 1000,
    int minHeight = 1000,
    int quality = 80,
  }) async {
    final File originalFile = File(file.path);
    final String targetPath = await _generateTargetPath(originalFile);

    var result = await FlutterImageCompress.compressAndGetFile(
      originalFile.absolute.path,
      targetPath,
      minWidth: minWidth,
      minHeight: minHeight,
      quality: quality,
      // Maintain aspect ratio is default behavior for minWidth/minHeight constraints
    );

    if (result == null) {
      // Fallback to original if compression fails
      return file;
    }

    return result;
  }

  static Future<String> _generateTargetPath(File originalFile) async {
    final Directory tempDir = await getTemporaryDirectory();
    final String extension = p.extension(originalFile.path); // e.g. .jpg
    final String name = p.basenameWithoutExtension(originalFile.path);
    final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();

    // Create a new filename to avoid overwriting
    return p.join(tempDir.path, '${name}_compressed_$timestamp$extension');
  }
}
