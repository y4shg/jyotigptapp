import 'dart:typed_data';

/// Platform-aware access to image file bytes and conversions.
abstract class ImageFileProvider {
  /// Reads bytes from the given file or blob path.
  Future<Uint8List> readAsBytes(String path);

  /// Converts image data to a data URL when a platform-specific conversion
  /// is required (for example HEIC/HEIF on iOS).
  Future<String?> convertImageToDataUrlIfNeeded({
    required List<int> bytes,
    required String filePath,
  });
}
