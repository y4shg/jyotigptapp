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

class File {
  File(this.path);

  final String path;

  Future<bool> exists() => Future<bool>.error(_unsupported());

  bool existsSync() => throw _unsupported();

  Future<int> length() => Future<int>.error(_unsupported());

  Directory get parent => Directory(path);

  Future<List<int>> readAsBytes() =>
      Future<List<int>>.error(_unsupported());

  Future<File> delete({bool recursive = false}) =>
      Future<File>.error(_unsupported());

  Future<File> writeAsBytes(List<int> bytes, {bool flush = false}) =>
      Future<File>.error(_unsupported());

  Future<File> writeAsString(String contents, {bool flush = false}) =>
      Future<File>.error(_unsupported());
}

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

class HttpClient {
  bool Function(X509Certificate, String, int)? badCertificateCallback;

  void close({bool force = false}) {}
}

class X509Certificate {
  const X509Certificate();
}

UnsupportedError _unsupported() {
  return UnsupportedError('dart:io is not supported on the web.');
}
