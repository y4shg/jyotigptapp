import 'dart:typed_data';

import 'package:universal_web/web.dart' as web;

import 'image_file_provider_interface.dart';

/// Creates the web-specific [ImageFileProvider] implementation.
///
/// Returns an instance of [_WebImageFileProvider] for browser environments.
ImageFileProvider createImageFileProviderImpl() => _WebImageFileProvider();

class _WebImageFileProvider implements ImageFileProvider {
  @override
  Future<Uint8List> readAsBytes(String path) async {
    final response = await web.HttpRequest.request(
      path,
      responseType: 'arraybuffer',
    );
    final buffer = response.response as ByteBuffer;
    return buffer.asUint8List();
  }

  @override
  Future<String?> convertImageToDataUrlIfNeeded({
    required List<int> bytes,
    required String filePath,
  }) async =>
      null;
}
