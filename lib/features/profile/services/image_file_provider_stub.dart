import 'dart:typed_data';

import 'image_file_provider_interface.dart';

ImageFileProvider createImageFileProviderImpl() => _StubImageFileProvider();

class _StubImageFileProvider implements ImageFileProvider {
  @override
  Future<Uint8List> readAsBytes(String path) {
    throw UnsupportedError('Reading files is not supported on this platform.');
  }

  @override
  Future<String?> convertImageToDataUrlIfNeeded({
    required List<int> bytes,
    required String filePath,
  }) async =>
      null;
}
