/// Native platform export for `dart:io`.
///
/// This file is selected by `platform_io.dart` on platforms where
/// `dart.library.io` is available. It re-exports `dart:io` and provides
/// a `WebFile` typedef so shared code can reference a single file type
/// across platforms.
library;  // ← add this line
import 'dart:io';
export 'dart:io';

/// Alias for the platform file type on native platforms.
typedef WebFile = File;
