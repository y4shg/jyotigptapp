import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/models/user.dart';
import '../../../core/providers/app_providers.dart';
import '../../auth/providers/unified_auth_providers.dart';

part 'profile_user_settings_provider.g.dart';

/// Coordinates user-level settings stored on the backend.
///
/// Settings keys are string identifiers (snake_case or camelCase) and values
/// are JSON-serializable primitives (`bool`, `num`, `String`) or null to unset.
/// Updates are applied optimistically to local state and then persisted to the
/// server in order; failures roll back to the last confirmed snapshot or force
/// a refresh, so callers should handle exceptions from [updateSetting].
@Riverpod(keepAlive: true)
class ProfileUserSettings extends _$ProfileUserSettings {
  Future<void> _pendingWrite = Future<void>.value();
  Map<String, dynamic>? _lastConfirmedSettings;
  String? _activeSessionKey;
  int _sessionGeneration = 0;

  @override
  Future<Map<String, dynamic>> build() async {
    final currentUser = ref.watch(currentUserProvider2);
    final sessionKey = _sessionKeyForUser(currentUser);
    if (sessionKey != _activeSessionKey) {
      _resetSession(sessionKey);
    }

    final api = ref.watch(apiServiceProvider);
    if (api == null) {
      throw StateError('No API client available for user settings.');
    }

    final startGeneration = _sessionGeneration;
    final settings = await api.getUserSettings();
    if (!ref.mounted || startGeneration != _sessionGeneration) {
      return _lastConfirmedSettings ?? const <String, dynamic>{};
    }
    _lastConfirmedSettings = Map.unmodifiable(
      Map<String, dynamic>.from(settings),
    );
    return _lastConfirmedSettings!;
  }

  /// Updates a single backend user setting.
  ///
  /// The [key] should match a supported setting identifier (for example,
  /// `enableNotifications`, `enableSounds`, `hapticFeedback`). The [value] must
  /// be JSON-serializable; pass null to remove the key. The update is applied
  /// optimistically and then persisted to the server. Returns a future that
  /// completes when the server write finishes. Throws if the API client is
  /// unavailable or if the server rejects the update.
  Future<void> updateSetting(String key, Object? value) async {
    final startGeneration = _sessionGeneration;
    final current = Map<String, dynamic>.from(
      state.maybeWhen(data: (value) => value, orElse: () => null) ??
          await future,
    );
    if (!ref.mounted || startGeneration != _sessionGeneration) {
      return;
    }

    final api = ref.read(apiServiceProvider);
    if (api == null) {
      throw StateError('No API client available for user settings.');
    }

    final next = Map<String, dynamic>.from(current);
    if (value == null) {
      next.remove(key);
    } else {
      next[key] = value;
    }

    state = AsyncData(Map.unmodifiable(next));

    final generation = _sessionGeneration;
    final write = _pendingWrite.then((_) async {
      if (generation != _sessionGeneration) {
        return;
      }
      try {
        final latestApi = ref.read(apiServiceProvider);
        if (latestApi == null) {
          throw StateError('No API client available for user settings.');
        }
        if (generation != _sessionGeneration) {
          return;
        }
        await latestApi.updateUserSettings(next);
        if (generation != _sessionGeneration) {
          return;
        }
        _lastConfirmedSettings = Map.unmodifiable(
          Map<String, dynamic>.from(next),
        );
      } catch (error, stackTrace) {
        final currentState = state.asData?.value;
        if (ref.mounted &&
            currentState != null &&
            _mapsEqual(currentState, next)) {
          if (_lastConfirmedSettings != null) {
            state = AsyncData(_lastConfirmedSettings!);
          } else {
            ref.invalidateSelf();
          }
        }
        Error.throwWithStackTrace(error, stackTrace);
      }
    });

    _pendingWrite = write.catchError((_) {});
    await write;
  }

  void _resetSession(String? sessionKey) {
    _activeSessionKey = sessionKey;
    _sessionGeneration++;
    _pendingWrite = Future<void>.value();
    _lastConfirmedSettings = null;
    state = const AsyncLoading();
  }

  String? _sessionKeyForUser(Object? user) {
    if (user is! User) return null;
    if (user.id.isNotEmpty) return user.id;
    final email = user.email.trim().toLowerCase();
    return email.isEmpty ? null : email;
  }

  bool _mapsEqual(Map<String, dynamic> left, Map<String, dynamic> right) {
    if (identical(left, right)) {
      return true;
    }
    if (left.length != right.length) {
      return false;
    }

    for (final entry in left.entries) {
      if (right[entry.key] != entry.value) {
        return false;
      }
    }
    return true;
  }
}
