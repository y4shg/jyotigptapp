import 'dart:typed_data';

import 'package:jyotigptapp/shared/utils/platform_io.dart';

import '../../chat/services/file_attachment_service.dart';
import 'image_file_provider_interface.dart';

ImageFileProvider createImageFileProviderImpl() => _IoImageFileProvider();

class _IoImageFileProvider implements ImageFileProvider {
  @override
  Future<Uint8List> readAsBytes(String path) async {
    return File(path).readAsBytes();
  }

  @override
  Future<String?> convertImageToDataUrlIfNeeded({
    required List<int> bytes,
    required String filePath,
  }) async {
    return convertImageFileToDataUrl(File(filePath));
  }
}
