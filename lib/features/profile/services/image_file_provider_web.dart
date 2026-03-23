// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:typed_data';

import 'image_file_provider_interface.dart';

ImageFileProvider createImageFileProviderImpl() => _WebImageFileProvider();

class _WebImageFileProvider implements ImageFileProvider {
  @override
  Future<Uint8List> readAsBytes(String path) async {
    final response = await html.HttpRequest.request(
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
