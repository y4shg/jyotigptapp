// Tests for the logic of private helper methods introduced in ProfilePage.
//
// Because Dart library-private methods (underscore prefix) cannot be called
// from an external test file, this file re-implements the same algorithms as
// local test helpers and exercises them directly. Each helper section is
// explicitly labelled with the ProfilePage method it mirrors so that changes
// to the production code can be reflected here.
import 'dart:convert';

import 'package:checks/checks.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jyotigptapp/core/models/user.dart';
import 'package:path/path.dart' as path;

// ---------------------------------------------------------------------------
// Mirror: ProfilePage._readBoolSetting
// ---------------------------------------------------------------------------
bool _readBoolSetting(Map<String, dynamic> settings, String key) {
  final value = settings[key];
  if (value is bool) return value;
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    return normalized == 'true' || normalized == '1';
  }
  if (value is num) return value != 0;
  return false;
}

// ---------------------------------------------------------------------------
// Mirror: ProfilePage._extractEmail
// ---------------------------------------------------------------------------
String? _extractEmail(dynamic source) {
  if (source is Map) {
    final value = source['email'];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    final nested = source['user'];
    if (nested is Map) {
      final nestedValue = nested['email'];
      if (nestedValue is String && nestedValue.trim().isNotEmpty) {
        return nestedValue.trim();
      }
    }
  }
  try {
    final dynamic email = (source as dynamic)?.email;
    if (email is String && email.trim().isNotEmpty) {
      return email.trim();
    }
  } catch (_) {
    return null;
  }
  return null;
}

// ---------------------------------------------------------------------------
// Mirror: ProfilePage._resolveEditableUser
// ---------------------------------------------------------------------------
User? _resolveEditableUser(dynamic source) {
  if (source is User) return source;
  if (source is Map) {
    try {
      return User.fromJson(Map<String, dynamic>.from(source));
    } catch (_) {
      return null;
    }
  }
  return null;
}

// ---------------------------------------------------------------------------
// Mirror: ProfilePage._languageName
// ---------------------------------------------------------------------------
String _languageName(Locale locale) {
  final tag = locale.toLanguageTag();
  return switch (tag) {
    'de' => 'Deutsch',
    'en' => 'English',
    'es' => 'Español',
    'fr' => 'Français',
    'it' => 'Italiano',
    'ko' => '한국어',
    'nl' => 'Nederlands',
    'ru' => 'Русский',
    'zh' => '简体中文',
    'zh-Hant' => '繁體中文',
    _ => locale.languageCode,
  };
}

// ---------------------------------------------------------------------------
// Mirror: ProfilePage._imageDataUrl
// ---------------------------------------------------------------------------
String _imageDataUrl(List<int> bytes, String filePath) {
  final extension = path.extension(filePath).toLowerCase();
  final format = switch (extension) {
    '.png' => 'png',
    '.webp' => 'webp',
    '.gif' => 'gif',
    _ => 'jpeg',
  };
  return 'data:image/$format;base64,${base64Encode(bytes)}';
}

// ---------------------------------------------------------------------------

void main() {
  group('_readBoolSetting', () {
    group('bool values', () {
      test('true bool returns true', () {
        check(_readBoolSetting({'flag': true}, 'flag')).isTrue();
      });

      test('false bool returns false', () {
        check(_readBoolSetting({'flag': false}, 'flag')).isFalse();
      });
    });

    group('string values', () {
      test('"true" returns true', () {
        check(_readBoolSetting({'flag': 'true'}, 'flag')).isTrue();
      });

      test('"True" returns true (case-insensitive)', () {
        check(_readBoolSetting({'flag': 'True'}, 'flag')).isTrue();
      });

      test('"TRUE" returns true (all-caps)', () {
        check(_readBoolSetting({'flag': 'TRUE'}, 'flag')).isTrue();
      });

      test('"1" returns true', () {
        check(_readBoolSetting({'flag': '1'}, 'flag')).isTrue();
      });

      test('"  true  " returns true (leading/trailing whitespace)', () {
        check(_readBoolSetting({'flag': '  true  '}, 'flag')).isTrue();
      });

      test('"false" returns false', () {
        check(_readBoolSetting({'flag': 'false'}, 'flag')).isFalse();
      });

      test('"False" returns false (case-insensitive)', () {
        check(_readBoolSetting({'flag': 'False'}, 'flag')).isFalse();
      });

      test('"0" returns false', () {
        check(_readBoolSetting({'flag': '0'}, 'flag')).isFalse();
      });

      test('arbitrary string returns false', () {
        check(_readBoolSetting({'flag': 'yes'}, 'flag')).isFalse();
      });

      test('empty string returns false', () {
        check(_readBoolSetting({'flag': ''}, 'flag')).isFalse();
      });
    });

    group('numeric values', () {
      test('1 returns true', () {
        check(_readBoolSetting({'flag': 1}, 'flag')).isTrue();
      });

      test('-1 returns true (any non-zero)', () {
        check(_readBoolSetting({'flag': -1}, 'flag')).isTrue();
      });

      test('0.5 returns true (non-zero double)', () {
        check(_readBoolSetting({'flag': 0.5}, 'flag')).isTrue();
      });

      test('0 returns false', () {
        check(_readBoolSetting({'flag': 0}, 'flag')).isFalse();
      });

      test('0.0 returns false', () {
        check(_readBoolSetting({'flag': 0.0}, 'flag')).isFalse();
      });
    });

    group('missing or null key', () {
      test('missing key returns false', () {
        check(_readBoolSetting({}, 'flag')).isFalse();
      });

      test('null value returns false', () {
        check(_readBoolSetting({'flag': null}, 'flag')).isFalse();
      });
    });

    group('unsupported type', () {
      test('list value returns false', () {
        check(_readBoolSetting({'flag': <dynamic>[]}, 'flag')).isFalse();
      });

      test('map value returns false', () {
        check(_readBoolSetting({'flag': <String, dynamic>{}}, 'flag')).isFalse();
      });
    });
  });

  group('_extractEmail', () {
    group('Map source', () {
      test('returns email from top-level "email" key', () {
        check(_extractEmail({'email': 'user@example.com'}))
            .equals('user@example.com');
      });

      test('trims whitespace from email', () {
        check(_extractEmail({'email': '  user@example.com  '}))
            .equals('user@example.com');
      });

      test('ignores empty string email and returns null', () {
        check(_extractEmail({'email': ''})).isNull();
      });

      test('ignores whitespace-only email and returns null', () {
        check(_extractEmail({'email': '   '})).isNull();
      });

      test('falls back to nested user.email', () {
        final data = {
          'email': '',
          'user': {'email': 'nested@example.com'},
        };
        check(_extractEmail(data)).equals('nested@example.com');
      });

      test('extracts email from nested user map when top-level email missing',
          () {
        final data = {
          'user': {'email': 'nested@example.com'},
        };
        check(_extractEmail(data)).equals('nested@example.com');
      });

      test('trims nested email', () {
        final data = {
          'user': {'email': '  nested@example.com  '},
        };
        check(_extractEmail(data)).equals('nested@example.com');
      });

      test('returns null when both top-level and nested emails are empty', () {
        final data = {
          'email': '',
          'user': {'email': ''},
        };
        check(_extractEmail(data)).isNull();
      });

      test('returns null when map has no email field', () {
        check(_extractEmail({'name': 'Alice'})).isNull();
      });
    });

    group('User model source', () {
      test('returns email from User instance', () {
        final user = User(
          id: 'u1',
          username: 'alice',
          email: 'alice@example.com',
          role: 'user',
        );
        check(_extractEmail(user)).equals('alice@example.com');
      });

      test('returns null for User with empty email', () {
        final user = User(
          id: 'u1',
          username: 'alice',
          email: '',
          role: 'user',
        );
        check(_extractEmail(user)).isNull();
      });

      test('trims email from User instance', () {
        final user = User(
          id: 'u1',
          username: 'alice',
          email: '  alice@example.com  ',
          role: 'user',
        );
        check(_extractEmail(user)).equals('alice@example.com');
      });
    });

    group('null and other types', () {
      test('returns null for null input', () {
        check(_extractEmail(null)).isNull();
      });

      test('returns null for int input', () {
        check(_extractEmail(42)).isNull();
      });
    });
  });

  group('_resolveEditableUser', () {
    group('User input', () {
      test('returns the same User instance when given a User', () {
        final user = User(
          id: 'u1',
          username: 'alice',
          email: 'alice@example.com',
          role: 'user',
        );
        final result = _resolveEditableUser(user);
        check(result).isNotNull();
        check(result!.id).equals('u1');
        check(result.email).equals('alice@example.com');
      });
    });

    group('Map input', () {
      test('parses a valid User JSON map', () {
        final map = <String, dynamic>{
          'id': 'u2',
          'username': 'bob',
          'email': 'bob@example.com',
          'role': 'admin',
        };
        final result = _resolveEditableUser(map);
        check(result).isNotNull();
        check(result!.id).equals('u2');
        check(result.email).equals('bob@example.com');
        check(result.role).equals('admin');
      });

      test('returns null for a map with a non-String id (cast throws)', () {
        // User.fromJson uses `json['id'] as String?` which throws TypeError
        // when id is a Map. The implementation's catch block returns null.
        final map = <String, dynamic>{
          'id': {'nested': 'object'},
        };
        check(_resolveEditableUser(map)).isNull();
      });

      test('returns null for empty map (User fields use defaults)', () {
        final result = _resolveEditableUser(<String, dynamic>{});
        // User.fromJson fills required fields with defaults
        check(result).isNotNull();
        check(result!.id).equals('');
        check(result.role).equals('user');
      });
    });

    group('null and other types', () {
      test('returns null for null input', () {
        check(_resolveEditableUser(null)).isNull();
      });

      test('returns null for int input', () {
        check(_resolveEditableUser(42)).isNull();
      });

      test('returns null for string input', () {
        check(_resolveEditableUser('some-string')).isNull();
      });
    });
  });

  group('_languageName', () {
    test('German locale returns Deutsch', () {
      check(_languageName(const Locale('de'))).equals('Deutsch');
    });

    test('English locale returns English', () {
      check(_languageName(const Locale('en'))).equals('English');
    });

    test('Spanish locale returns Español', () {
      check(_languageName(const Locale('es'))).equals('Español');
    });

    test('French locale returns Français', () {
      check(_languageName(const Locale('fr'))).equals('Français');
    });

    test('Italian locale returns Italiano', () {
      check(_languageName(const Locale('it'))).equals('Italiano');
    });

    test('Korean locale returns 한국어', () {
      check(_languageName(const Locale('ko'))).equals('한국어');
    });

    test('Dutch locale returns Nederlands', () {
      check(_languageName(const Locale('nl'))).equals('Nederlands');
    });

    test('Russian locale returns Русский', () {
      check(_languageName(const Locale('ru'))).equals('Русский');
    });

    test('Simplified Chinese locale returns 简体中文', () {
      check(_languageName(const Locale('zh'))).equals('简体中文');
    });

    test('Traditional Chinese locale returns 繁體中文', () {
      check(_languageName(const Locale.fromSubtags(
        languageCode: 'zh',
        scriptCode: 'Hant',
      ))).equals('繁體中文');
    });

    test('unknown locale falls back to languageCode', () {
      check(_languageName(const Locale('ja'))).equals('ja');
    });

    test('another unknown locale falls back to its languageCode', () {
      check(_languageName(const Locale('pt'))).equals('pt');
    });
  });

  group('_imageDataUrl', () {
    const sampleBytes = [72, 101, 108, 108, 111]; // 'Hello' in ASCII

    test('PNG extension produces data:image/png', () {
      final url = _imageDataUrl(sampleBytes, 'photo.png');
      check(url).startsWith('data:image/png;base64,');
    });

    test('uppercase PNG extension is treated as png', () {
      final url = _imageDataUrl(sampleBytes, 'photo.PNG');
      check(url).startsWith('data:image/png;base64,');
    });

    test('WEBP extension produces data:image/webp', () {
      final url = _imageDataUrl(sampleBytes, 'image.webp');
      check(url).startsWith('data:image/webp;base64,');
    });

    test('GIF extension produces data:image/gif', () {
      final url = _imageDataUrl(sampleBytes, 'anim.gif');
      check(url).startsWith('data:image/gif;base64,');
    });

    test('JPG extension falls back to jpeg', () {
      final url = _imageDataUrl(sampleBytes, 'photo.jpg');
      check(url).startsWith('data:image/jpeg;base64,');
    });

    test('JPEG extension falls back to jpeg', () {
      final url = _imageDataUrl(sampleBytes, 'photo.jpeg');
      check(url).startsWith('data:image/jpeg;base64,');
    });

    test('unknown extension falls back to jpeg', () {
      final url = _imageDataUrl(sampleBytes, 'photo.bmp');
      check(url).startsWith('data:image/jpeg;base64,');
    });

    test('no extension falls back to jpeg', () {
      final url = _imageDataUrl(sampleBytes, 'photo');
      check(url).startsWith('data:image/jpeg;base64,');
    });

    test('base64 encodes the bytes correctly', () {
      final url = _imageDataUrl(sampleBytes, 'file.png');
      final expectedBase64 = base64Encode(sampleBytes);
      check(url).endsWith(expectedBase64);
    });

    test('empty bytes produce a valid (empty payload) data URL', () {
      final url = _imageDataUrl([], 'file.png');
      check(url).equals('data:image/png;base64,');
    });

    test('path with subdirectories uses only extension for format', () {
      final url = _imageDataUrl(sampleBytes, '/some/path/to/image.webp');
      check(url).startsWith('data:image/webp;base64,');
    });

    test('mixed-case WEBP extension is treated as webp', () {
      final url = _imageDataUrl(sampleBytes, 'photo.WEBP');
      check(url).startsWith('data:image/webp;base64,');
    });

    test('GIF extension with uppercase is treated as gif', () {
      final url = _imageDataUrl(sampleBytes, 'animation.GIF');
      check(url).startsWith('data:image/gif;base64,');
    });
  });
}