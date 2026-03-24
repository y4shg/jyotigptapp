/// Web-only stubs for `dart:io` APIs used in shared code.
///
/// These classes exist so code can compile on the web when `dart:io` is
/// unavailable. All blocking I/O operations throw [UnsupportedError].
library;  // ← add this line
import 'dart:typed_data';

/// Web-only stub for platform detection.
class Platform {
  static bool get isAndroid => false;
  static bool get isFuchsia => false;
  static bool get isIOS => false;
  static bool get isLinux => false;
  static bool get isMacOS => false;
  static bool get isWindows => false;

  static String get operatingSystem => 'web';
  static String get operatingSystemVersion => '';

  static Map<String, String> get environment => const <String, String>{};
}

/// Web-only stub for file access.
class WebFile {
  WebFile(this.path);

  final String path;

  WebFile get absolute => this;

  Future<bool> exists() => Future<bool>.error(_unsupported());

  bool existsSync() => throw _unsupported();

  Future<int> length() => Future<int>.error(_unsupported());

  int lengthSync() => throw _unsupported();

  Directory get parent => Directory(path);

  Future<Uint8List> readAsBytes() =>
      Future<Uint8List>.error(_unsupported());

  Future<WebFile> delete({bool recursive = false}) =>
      Future<WebFile>.error(_unsupported());

  Future<WebFile> writeAsBytes(List<int> bytes, {bool flush = false}) =>
      Future<WebFile>.error(_unsupported());

  Future<WebFile> writeAsString(String contents, {bool flush = false}) =>
      Future<WebFile>.error(_unsupported());
}

/// Web-only stub for directories.
class Directory {
  Directory(this.path);

  final String path;

  static Directory get systemTemp => Directory('/tmp');

  bool existsSync() => throw _unsupported();

  Future<Directory> createTemp([String? prefix]) =>
      Future<Directory>.error(_unsupported());

  Future<Directory> delete({bool recursive = false}) =>
      Future<Directory>.error(_unsupported());

  void deleteSync({bool recursive = false}) => throw _unsupported();
}

/// Web-only stub for HTTP client configuration.
class HttpClient {
  bool Function(X509Certificate, String, int)? badCertificateCallback;

  void close({bool force = false}) {}
}

/// Web-only stub for X509 certificates.
class X509Certificate {
  const X509Certificate();
}

/// Throws for unsupported blocking I/O operations on the web.
UnsupportedError _unsupported() {
  return UnsupportedError(
    'dart:io is not supported on the web. This is a web stub for '
    'blocking I/O operations.',
  );
}
