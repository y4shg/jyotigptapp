export 'image_file_provider_interface.dart';

import 'image_file_provider_interface.dart';
import 'image_file_provider_stub.dart'
    if (dart.library.io) 'image_file_provider_io.dart'
    if (dart.library.html) 'image_file_provider_web.dart';

/// Returns the platform-specific image file provider.
ImageFileProvider createImageFileProvider() => createImageFileProviderImpl();
