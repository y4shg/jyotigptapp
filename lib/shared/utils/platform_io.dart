/// Platform abstraction for `dart:io` APIs.
///
/// On native platforms, this conditionally exports `platform_io_io.dart`,
/// which re-exports `dart:io`. On the web, it exports `platform_io_stub.dart`,
/// which provides web-safe stubs like [Platform] and [WebFile].
library;  // ← add this line
export 'platform_io_stub.dart'
    if (dart.library.io) 'platform_io_io.dart';
